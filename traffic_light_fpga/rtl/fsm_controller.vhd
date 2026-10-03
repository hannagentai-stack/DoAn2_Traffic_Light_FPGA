--------------------------------------------------------------------------------
-- Project   : DE2-115 FPGA Traffic Light Controller
-- File      : fsm_controller.vhd
-- Standard  : IEEE 1164 & numeric_std
-- Target    : Altera Cyclone IV E (EP4CE115F29C7)
-- Description:
--   Moore Finite State Machine for Traffic Light Controller.
--   States:
--     - S_PHASE1   : Route A Green (25s), Route B Red (28s)
--     - S_PHASE2   : Route A Yellow (3s), Route B Red (3s remaining)
--     - S_PHASE3   : Route A Red (33s), Route B Green (30s)
--     - S_PHASE4   : Route A Red (3s remaining), Route B Yellow (3s)
--     - S_NIGHT    : Night Caution Mode (Both Yellow blinking at 1 Hz, 7-seg blanked)
--     - S_EMERGENCY: Emergency Force Override (Route A Green, Route B Red)
--   Priority Preemption Hierarchy:
--     Reset (KEY[0]='0') > Emergency (KEY[1]='0') > Night Mode (SW[0]='1') > Pause (SW[1]='1') > Normal Cycle
--   Generates synchronous 1-cycle load_phase pulse on every state transition.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fsm_controller is
    port (
        clk_50m      : in  std_logic;
        reset_n      : in  std_logic;
        blink_1hz    : in  std_logic;
        timer_done   : in  std_logic;
        sw_night     : in  std_logic;
        sw_pause     : in  std_logic;
        key_emerg_n  : in  std_logic;
        phase_sel    : out std_logic_vector(1 downto 0);
        load_phase   : out std_logic;
        blank_seg7   : out std_logic;
        fsm_ra       : out std_logic;
        fsm_ya       : out std_logic;
        fsm_ga       : out std_logic;
        fsm_rb       : out std_logic;
        fsm_yb       : out std_logic;
        fsm_gb       : out std_logic
    );
end entity fsm_controller;

architecture rtl of fsm_controller is

    type state_type is (S_PHASE1, S_PHASE2, S_PHASE3, S_PHASE4, S_NIGHT, S_EMERGENCY);
    signal current_state : state_type := S_PHASE1;
    signal next_state    : state_type := S_PHASE1;
    signal prev_state    : state_type := S_PHASE4;

begin

    -- Synchronous State Register and State Change Tracker
    process(clk_50m, reset_n)
    begin
        if reset_n = '0' then
            current_state <= S_PHASE1;
            prev_state    <= S_PHASE4;
        elsif rising_edge(clk_50m) then
            current_state <= next_state;
            prev_state    <= current_state;
        end if;
    end process;

    -- Generate a clean 1-cycle load_phase pulse on state transition
    load_phase <= '1' when (current_state /= prev_state) else '0';

    -- Next-State Combinational Logic with Strict Priority Encoding
    process(current_state, key_emerg_n, sw_night, sw_pause, timer_done)
    begin
        next_state <= current_state; -- Default: prevent inferred latches

        -- Priority 1: Emergency Force (KEY[1] Active-Low)
        if key_emerg_n = '0' then
            next_state <= S_EMERGENCY;

        -- Priority 2: Night Mode (SW[0] Active-High)
        elsif sw_night = '1' then
            next_state <= S_NIGHT;

        -- Exit condition from override states when triggers are deasserted
        elsif current_state = S_EMERGENCY or current_state = S_NIGHT then
            next_state <= S_PHASE1;

        -- Priority 3: Pause/Hold (SW[1] Active-High)
        elsif sw_pause = '1' then
            next_state <= current_state; -- Freeze current phase

        -- Priority 4: Normal Traffic Flow Progression
        else
            case current_state is
                when S_PHASE1 =>
                    if timer_done = '1' then
                        next_state <= S_PHASE2;
                    end if;

                when S_PHASE2 =>
                    if timer_done = '1' then
                        next_state <= S_PHASE3;
                    end if;

                when S_PHASE3 =>
                    if timer_done = '1' then
                        next_state <= S_PHASE4;
                    end if;

                when S_PHASE4 =>
                    if timer_done = '1' then
                        next_state <= S_PHASE1;
                    end if;

                when others =>
                    next_state <= S_PHASE1;
            end case;
        end if;
    end process;

    -- Moore Output Logic (Strictly dependent on current_state and synchronous blink_1hz)
    process(current_state, blink_1hz)
    begin
        -- Default assignments to prevent latches
        phase_sel  <= "00";
        blank_seg7 <= '0';
        fsm_ra     <= '0';
        fsm_ya     <= '0';
        fsm_ga     <= '0';
        fsm_rb     <= '0';
        fsm_yb     <= '0';
        fsm_gb     <= '0';

        case current_state is
            when S_PHASE1 =>
                phase_sel <= "00";
                fsm_ga    <= '1';
                fsm_rb    <= '1';

            when S_PHASE2 =>
                phase_sel <= "01";
                fsm_ya    <= '1';
                fsm_rb    <= '1';

            when S_PHASE3 =>
                phase_sel <= "10";
                fsm_ra    <= '1';
                fsm_gb    <= '1';

            when S_PHASE4 =>
                phase_sel <= "11";
                fsm_ra    <= '1';
                fsm_yb    <= '1';

            when S_NIGHT =>
                phase_sel  <= "00";
                blank_seg7 <= '1';
                fsm_ya     <= blink_1hz;
                fsm_yb     <= blink_1hz;

            when S_EMERGENCY =>
                phase_sel <= "00";
                fsm_ga    <= '1';
                fsm_rb    <= '1';

            when others =>
                phase_sel <= "00";
                fsm_ra    <= '1';
                fsm_rb    <= '1';
        end case;
    end process;

end architecture rtl;
