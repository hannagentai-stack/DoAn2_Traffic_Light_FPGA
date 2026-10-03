--------------------------------------------------------------------------------
-- Project   : DE2-115 FPGA Traffic Light Controller
-- File      : traffic_light_top.vhd
-- Standard  : IEEE 1164 & numeric_std
-- Target    : Altera Cyclone IV E (EP4CE115F29C7)
-- Description:
--   Top-level structural integration for DE2-115 Traffic Light Controller.
--   Integrates:
--     - clk_divider     : 50 MHz to 1 Hz synchronous pulse and toggle
--     - fsm_controller  : Moore traffic flow FSM with priority preemption
--     - timer_counter   : Dual synchronous countdown timers with BCD conversion
--     - 4x seg7_decoder : HEX0 (A units), HEX1 (A tens), HEX2 (B units), HEX3 (B tens)
--     - Hardware Interlock Safety Barrier:
--       Guarantees Route A Green and Route B Green are mutually exclusive.
--       If conflict detected, forces immediate All-Red fail-safe mode.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity traffic_light_top is
    generic (
        SIMULATION : boolean := false
    );
    port (
        CLOCK_50 : in  std_logic;
        KEY      : in  std_logic_vector(1 downto 0); -- KEY(0): Reset_n, KEY(1): Emergency_n
        SW       : in  std_logic_vector(1 downto 0); -- SW(0): NightMode, SW(1): Pause
        LEDR     : out std_logic_vector(3 downto 0); -- [0]=Red A, [1]=Yellow A, [2]=Red B, [3]=Yellow B
        LEDG     : out std_logic_vector(1 downto 0); -- [0]=Green A, [1]=Green B
        HEX0     : out std_logic_vector(6 downto 0); -- Route A Units
        HEX1     : out std_logic_vector(6 downto 0); -- Route A Tens
        HEX2     : out std_logic_vector(6 downto 0); -- Route B Units
        HEX3     : out std_logic_vector(6 downto 0)  -- Route B Tens
    );
end entity traffic_light_top;

architecture structural of traffic_light_top is

    -- Internal Interconnect Signals
    signal tick_1hz_s   : std_logic;
    signal blink_1hz_s  : std_logic;
    signal timer_done_s : std_logic;
    signal phase_sel_s  : std_logic_vector(1 downto 0);
    signal load_phase_s : std_logic;
    signal blank_seg7_s : std_logic;

    signal bcd_a_tens_s  : std_logic_vector(3 downto 0);
    signal bcd_a_units_s : std_logic_vector(3 downto 0);
    signal bcd_b_tens_s  : std_logic_vector(3 downto 0);
    signal bcd_b_units_s : std_logic_vector(3 downto 0);

    -- Raw FSM Lamp Outputs (prior to Hardware Safety Interlock Layer)
    signal fsm_ra_s : std_logic;
    signal fsm_ya_s : std_logic;
    signal fsm_ga_s : std_logic;
    signal fsm_rb_s : std_logic;
    signal fsm_yb_s : std_logic;
    signal fsm_gb_s : std_logic;

begin

    -- 1. Clock Divider Instance
    u_clk_divider: entity work.clk_divider
        generic map (
            SIMULATION => SIMULATION
        )
        port map (
            clk_50m   => CLOCK_50,
            reset_n   => KEY(0),
            tick_1hz  => tick_1hz_s,
            blink_1hz => blink_1hz_s
        );

    -- 2. FSM Controller Instance
    u_fsm_controller: entity work.fsm_controller
        port map (
            clk_50m     => CLOCK_50,
            reset_n     => KEY(0),
            blink_1hz   => blink_1hz_s,
            timer_done  => timer_done_s,
            sw_night    => SW(0),
            sw_pause    => SW(1),
            key_emerg_n => KEY(1),
            phase_sel   => phase_sel_s,
            load_phase  => load_phase_s,
            blank_seg7  => blank_seg7_s,
            fsm_ra      => fsm_ra_s,
            fsm_ya      => fsm_ya_s,
            fsm_ga      => fsm_ga_s,
            fsm_rb      => fsm_rb_s,
            fsm_yb      => fsm_yb_s,
            fsm_gb      => fsm_gb_s
        );

    -- 3. Timer Counter Instance
    u_timer_counter: entity work.timer_counter
        port map (
            clk_50m     => CLOCK_50,
            reset_n     => KEY(0),
            tick_1hz    => tick_1hz_s,
            pause       => SW(1),
            load_phase  => load_phase_s,
            phase_sel   => phase_sel_s,
            timer_done  => timer_done_s,
            bcd_a_tens  => bcd_a_tens_s,
            bcd_a_units => bcd_a_units_s,
            bcd_b_tens  => bcd_b_tens_s,
            bcd_b_units => bcd_b_units_s
        );

    -- 4. 7-Segment Display Decoders
    -- Route A Displays (HEX1: Tens, HEX0: Units)
    u_hex0: entity work.seg7_decoder
        port map (
            bcd_in  => bcd_a_units_s,
            blank   => blank_seg7_s,
            seg_out => HEX0
        );

    u_hex1: entity work.seg7_decoder
        port map (
            bcd_in  => bcd_a_tens_s,
            blank   => blank_seg7_s,
            seg_out => HEX1
        );

    -- Route B Displays (HEX3: Tens, HEX2: Units)
    u_hex2: entity work.seg7_decoder
        port map (
            bcd_in  => bcd_b_units_s,
            blank   => blank_seg7_s,
            seg_out => HEX2
        );

    u_hex3: entity work.seg7_decoder
        port map (
            bcd_in  => bcd_b_tens_s,
            blank   => blank_seg7_s,
            seg_out => HEX3
        );

    -- 5. Fail-Safe Hardware Interlock Layer (Conflict Monitor)
    -- Guarantee: LEDG(0) = '1' and LEDG(1) = '1' is mathematically prevented at the pins.
    -- If a dual-green fault condition ever arises, both routes are forced to RED (All-Red Fail-Safe).
    process(fsm_ga_s, fsm_gb_s, fsm_ya_s, fsm_yb_s, fsm_ra_s, fsm_rb_s)
    begin
        if (fsm_ga_s = '1' and fsm_gb_s = '1') then
            -- Interlock tripped: Force safe All-Red condition
            LEDG(0) <= '0';
            LEDG(1) <= '0';
            LEDR(0) <= '1'; -- Red A
            LEDR(1) <= '0';
            LEDR(2) <= '1'; -- Red B
            LEDR(3) <= '0';
        else
            -- Normal transparent passthrough
            LEDG(0) <= fsm_ga_s;
            LEDG(1) <= fsm_gb_s;
            LEDR(0) <= fsm_ra_s;
            LEDR(1) <= fsm_ya_s;
            LEDR(2) <= fsm_rb_s;
            LEDR(3) <= fsm_yb_s;
        end if;
    end process;

end architecture structural;
