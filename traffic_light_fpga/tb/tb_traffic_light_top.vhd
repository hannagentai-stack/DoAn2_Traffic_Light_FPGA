--------------------------------------------------------------------------------
-- Project    : DE2-115 FPGA Traffic Light Controller
-- File       : tb_traffic_light_top.vhd
-- Standard   : IEEE 1164 & numeric_std
-- Target     : Altera Cyclone IV E (EP4CE115F29C7)
-- Description:
--   Comprehensive self-checking testbench for traffic_light_top.
--   Instantiates DUT with generic SIMULATION => true.
--   Provides 50 MHz clock (20 ns period) and active-low reset on KEY(0).
--   Includes:
--     - Continuous concurrent safety check:
--       assert not (ledg(0) = '1' and ledg(1) = '1')
--     - Scenario 1: 2 consecutive normal cycles (122 us)
--     - Scenario 2: Night Mode (SW(0) = '1')
--     - Scenario 3: Pause/Hold Mode (SW(1) = '1')
--     - Scenario 4: Emergency Force Mode (KEY(1) = '0') during Phase 3
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_traffic_light_top is
end entity tb_traffic_light_top;

architecture sim of tb_traffic_light_top is

    -- 50 MHz Clock Constant (Period = 20 ns)
    constant CLK_PERIOD : time := 20 ns;

    -- DUT Signals
    signal clk_50m : std_logic := '0';
    signal key     : std_logic_vector(1 downto 0) := "11"; -- [0]=reset_n, [1]=emerg_n
    signal sw      : std_logic_vector(1 downto 0) := "00"; -- [0]=night,   [1]=pause
    signal ledr    : std_logic_vector(3 downto 0);         -- [0]=RA, [1]=YA, [2]=RB, [3]=YB
    signal ledg    : std_logic_vector(1 downto 0);         -- [0]=GA, [1]=GB
    signal hex0    : std_logic_vector(6 downto 0);         -- Route A Units
    signal hex1    : std_logic_vector(6 downto 0);         -- Route A Tens
    signal hex2    : std_logic_vector(6 downto 0);         -- Route B Units
    signal hex3    : std_logic_vector(6 downto 0);         -- Route B Tens

    -- Active-Low 7-Segment Constant Encodings (seg7_decoder output)
    constant SEG_0     : std_logic_vector(6 downto 0) := "1000000"; -- 0x40 ('0')
    constant SEG_1     : std_logic_vector(6 downto 0) := "1111001"; -- 0x79 ('1')
    constant SEG_2     : std_logic_vector(6 downto 0) := "0100100"; -- 0x24 ('2')
    constant SEG_3     : std_logic_vector(6 downto 0) := "0110000"; -- 0x30 ('3')
    constant SEG_4     : std_logic_vector(6 downto 0) := "0011001"; -- 0x19 ('4')
    constant SEG_5     : std_logic_vector(6 downto 0) := "0010010"; -- 0x12 ('5')
    constant SEG_6     : std_logic_vector(6 downto 0) := "0000010"; -- 0x02 ('6')
    constant SEG_7     : std_logic_vector(6 downto 0) := "1111000"; -- 0x78 ('7')
    constant SEG_8     : std_logic_vector(6 downto 0) := "0000000"; -- 0x00 ('8')
    constant SEG_9     : std_logic_vector(6 downto 0) := "0010000"; -- 0x10 ('9')
    constant SEG_BLANK : std_logic_vector(6 downto 0) := "1111111"; -- 0x7F (Blank)

    signal sim_done : boolean := false;

begin

    ----------------------------------------------------------------------------
    -- 1. DUT Instantiation with SIMULATION => true
    ----------------------------------------------------------------------------
    dut: entity work.traffic_light_top
        generic map (
            SIMULATION => true
        )
        port map (
            CLOCK_50 => clk_50m,
            KEY      => key,
            SW       => sw,
            LEDR     => ledr,
            LEDG     => ledg,
            HEX0     => hex0,
            HEX1     => hex1,
            HEX2     => hex2,
            HEX3     => hex3
        );

    ----------------------------------------------------------------------------
    -- 2. 50 MHz Master Clock Generator
    ----------------------------------------------------------------------------
    clk_gen: process
    begin
        while not sim_done loop
            clk_50m <= '0';
            wait for CLK_PERIOD / 2;
            clk_50m <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    ----------------------------------------------------------------------------
    -- 3. Continuous Concurrent Safety Check
    --    Guarantees that Route A and Route B never have Green simultaneously!
    ----------------------------------------------------------------------------
    assert not (ledg(0) = '1' and ledg(1) = '1')
        report "CRITICAL SAFETY VIOLATION: Both Route A and Route B have GREEN light simultaneously!"
        severity failure;

    ----------------------------------------------------------------------------
    -- 4. Main Verification Stimulus Process
    ----------------------------------------------------------------------------
    stim_proc: process
        variable t_phase_start : time;
        variable t_phase_dur   : time;
        variable frozen_hex0   : std_logic_vector(6 downto 0);
        variable frozen_hex1   : std_logic_vector(6 downto 0);
        variable frozen_hex2   : std_logic_vector(6 downto 0);
        variable frozen_hex3   : std_logic_vector(6 downto 0);
        variable frozen_ledg   : std_logic_vector(1 downto 0);
        variable frozen_ledr   : std_logic_vector(3 downto 0);
        variable t_blink_start : time;
        variable t_blink_high  : time;
        variable t_blink_low   : time;
    begin
        report "================================================================";
        report "  STARTING DE2-115 TRAFFIC LIGHT CONTROLLER TESTBENCH";
        report "================================================================";

        -- Initial idle inputs
        key <= "11";
        sw  <= "00";
        wait for 40 ns;

        ------------------------------------------------------------------------
        -- RESET PHASE: Asynchronous Reset on KEY(0)
        ------------------------------------------------------------------------
        report "[INIT] Applying Hardware Reset (KEY(0) = '0')...";
        key(0) <= '0';
        wait for 100 ns;
        key(0) <= '1'; -- Release Reset
        wait for 40 ns;

        -- Check initial state is Phase 1 (Route A Green, Route B Red)
        assert (ledg(0) = '1' and ledr(2) = '1' and ledg(1) = '0' and ledr(0) = '0' and ledr(1) = '0' and ledr(3) = '0')
            report "FAIL: Post-reset state is not Phase 1 (Route A Green, Route B Red)!"
            severity failure;

        -- Check initial countdown displays: Route A = 25 (HEX1='2', HEX0='5'), Route B = 28 (HEX3='2', HEX2='8')
        assert (hex1 = SEG_2 and hex0 = SEG_5)
            report "FAIL: Initial Route A counter BCD not 25!"
            severity failure;
        assert (hex3 = SEG_2 and hex2 = SEG_8)
            report "FAIL: Initial Route B counter BCD not 28!"
            severity failure;
        report "[INIT] PASS: Reset successfully initialized system to Phase 1 (25s Green A / 28s Red B).";

        ------------------------------------------------------------------------
        -- SCENARIO 1: Two (2) Consecutive Normal Cycles (122 us)
        -- Cycle-accurate assertions verifying 7-segment / counter values at phase entry:
        --   * Phase 1 entry: Route A is 25 (hex1=0x24, hex0=0x12), Route B is 28 (hex3=0x24, hex2=0x00)
        --   * Phase 2 entry: Route A is 3  (hex1=0x40, hex0=0x30), Route B is 3  (hex3=0x40, hex2=0x30)
        --   * Phase 3 entry: Route A is 33 (hex1=0x30, hex0=0x30), Route B is 30 (hex3=0x30, hex2=0x40)
        --   * Phase 4 entry: Route A is 3  (hex1=0x40, hex0=0x30), Route B is 3  (hex3=0x40, hex2=0x30)
        -- Along with boundary checks at transition edges before reload takes effect.
        ------------------------------------------------------------------------
        report "----------------------------------------------------------------";
        report "[SCENARIO 1] Commencing 2 Full Consecutive Normal Cycles (122 us)...";
        report "----------------------------------------------------------------";

        -- === CYCLE 1 === --
        -- Cycle 1 - Phase 1 (25s Green A / 28s Red B)
        t_phase_start := now;
        report "  [Cycle 1 - Phase 1] Route A Green (25s), Route B Red (28s)";
        assert (ledg(0) = '1' and ledr(2) = '1' and ledg(1) = '0' and ledr(0) = '0')
            report "FAIL: Cycle 1 Phase 1 lights invalid at start!" severity failure;
        assert (hex1 = SEG_2 and hex0 = SEG_5)
            report "FAIL: Cycle 1 Phase 1 entry: Route A counter expected 25 (hex1=0x24, hex0=0x12)!" severity failure;
        assert (hex3 = SEG_2 and hex2 = SEG_8)
            report "FAIL: Cycle 1 Phase 1 entry: Route B counter expected 28 (hex3=0x24, hex2=0x00)!" severity failure;
        
        -- Wait until transition to Phase 2 (Route A Yellow goes HIGH)
        wait until rising_edge(clk_50m) and ledr(1) = '1';
        t_phase_dur := now - t_phase_start;
        assert (t_phase_dur >= 24980 ns and t_phase_dur <= 25020 ns)
            report "FAIL: Cycle 1 Phase 1 duration not 25 us!" severity failure;
        t_phase_start := now;

        -- Boundary check at expiration of Phase 1: Route A counted to 1, Route B counted to 3
        assert (hex1 = SEG_0 and hex0 = SEG_1)
            report "FAIL: Cycle 1 Phase 1 boundary: Route A counter expected 1 (hex1=0x40, hex0=0x79)!" severity failure;
        assert (hex3 = SEG_0 and hex2 = SEG_3)
            report "FAIL: Cycle 1 Phase 1 boundary: Route B counter expected 3 (hex3=0x40, hex2=0x30)!" severity failure;

        -- Wait 1 clock cycle for synchronous timer reload
        wait until rising_edge(clk_50m);

        -- Cycle 1 - Phase 2 (3s Yellow A / 3s Red B)
        report "  [Cycle 1 - Phase 2] Route A Yellow (3s), Route B Red (3s)";
        assert (ledr(1) = '1' and ledr(2) = '1' and ledg(0) = '0' and ledg(1) = '0')
            report "FAIL: Cycle 1 Phase 2 lights invalid (expected Yellow A, Red B)!" severity failure;
        assert (hex1 = SEG_0 and hex0 = SEG_3)
            report "FAIL: Cycle 1 Phase 2 entry: Route A counter expected 3 (hex1=0x40, hex0=0x30)!" severity failure;
        assert (hex3 = SEG_0 and hex2 = SEG_3)
            report "FAIL: Cycle 1 Phase 2 entry: Route B counter expected 3 (hex3=0x40, hex2=0x30)!" severity failure;

        -- Wait until transition to Phase 3 (Route B Green goes HIGH)
        wait until rising_edge(clk_50m) and ledg(1) = '1';
        t_phase_dur := now - t_phase_start;
        assert (t_phase_dur >= 2980 ns and t_phase_dur <= 3020 ns)
            report "FAIL: Cycle 1 Phase 2 duration not 3 us!" severity failure;
        t_phase_start := now;

        -- Boundary check at expiration of Phase 2: Route A counted to 1, Route B counted to 1
        assert (hex1 = SEG_0 and hex0 = SEG_1)
            report "FAIL: Cycle 1 Phase 2 boundary: Route A counter expected 1 (hex1=0x40, hex0=0x79)!" severity failure;
        assert (hex3 = SEG_0 and hex2 = SEG_1)
            report "FAIL: Cycle 1 Phase 2 boundary: Route B counter expected 1 (hex3=0x40, hex2=0x79)!" severity failure;

        -- Wait 1 clock cycle for synchronous timer reload
        wait until rising_edge(clk_50m);

        -- Cycle 1 - Phase 3 (33s Red A / 30s Green B)
        report "  [Cycle 1 - Phase 3] Route A Red (33s), Route B Green (30s)";
        assert (ledr(0) = '1' and ledg(1) = '1' and ledg(0) = '0' and ledr(2) = '0')
            report "FAIL: Cycle 1 Phase 3 lights invalid (expected Red A, Green B)!" severity failure;
        assert (hex1 = SEG_3 and hex0 = SEG_3)
            report "FAIL: Cycle 1 Phase 3 entry: Route A counter expected 33 (hex1=0x30, hex0=0x30)!" severity failure;
        assert (hex3 = SEG_3 and hex2 = SEG_0)
            report "FAIL: Cycle 1 Phase 3 entry: Route B counter expected 30 (hex3=0x30, hex2=0x40)!" severity failure;

        -- Wait until transition to Phase 4 (Route B Yellow goes HIGH)
        wait until rising_edge(clk_50m) and ledr(3) = '1';
        t_phase_dur := now - t_phase_start;
        assert (t_phase_dur >= 29980 ns and t_phase_dur <= 30020 ns)
            report "FAIL: Cycle 1 Phase 3 duration not 30 us!" severity failure;
        t_phase_start := now;

        -- Boundary check at expiration of Phase 3: Route A counted to 3, Route B counted to 1
        assert (hex1 = SEG_0 and hex0 = SEG_3)
            report "FAIL: Cycle 1 Phase 3 boundary: Route A counter expected 3 (hex1=0x40, hex0=0x30)!" severity failure;
        assert (hex3 = SEG_0 and hex2 = SEG_1)
            report "FAIL: Cycle 1 Phase 3 boundary: Route B counter expected 1 (hex3=0x40, hex2=0x79)!" severity failure;

        -- Wait 1 clock cycle for synchronous timer reload
        wait until rising_edge(clk_50m);

        -- Cycle 1 - Phase 4 (3s Red A / 3s Yellow B)
        report "  [Cycle 1 - Phase 4] Route A Red (3s), Route B Yellow (3s)";
        assert (ledr(0) = '1' and ledr(3) = '1' and ledg(0) = '0' and ledg(1) = '0')
            report "FAIL: Cycle 1 Phase 4 lights invalid (expected Red A, Yellow B)!" severity failure;
        assert (hex1 = SEG_0 and hex0 = SEG_3)
            report "FAIL: Cycle 1 Phase 4 entry: Route A counter expected 3 (hex1=0x40, hex0=0x30)!" severity failure;
        assert (hex3 = SEG_0 and hex2 = SEG_3)
            report "FAIL: Cycle 1 Phase 4 entry: Route B counter expected 3 (hex3=0x40, hex2=0x30)!" severity failure;

        -- Wait until transition to Phase 1 of Cycle 2 (Route A Green goes HIGH)
        wait until rising_edge(clk_50m) and ledg(0) = '1';
        t_phase_dur := now - t_phase_start;
        assert (t_phase_dur >= 2980 ns and t_phase_dur <= 3020 ns)
            report "FAIL: Cycle 1 Phase 4 duration not 3 us!" severity failure;
        t_phase_start := now;

        -- Boundary check at expiration of Phase 4: Route A counted to 1, Route B counted to 1
        assert (hex1 = SEG_0 and hex0 = SEG_1)
            report "FAIL: Cycle 1 Phase 4 boundary: Route A counter expected 1 (hex1=0x40, hex0=0x79)!" severity failure;
        assert (hex3 = SEG_0 and hex2 = SEG_1)
            report "FAIL: Cycle 1 Phase 4 boundary: Route B counter expected 1 (hex3=0x40, hex2=0x79)!" severity failure;

        -- Wait 1 clock cycle for synchronous timer reload
        wait until rising_edge(clk_50m);

        report "  -> Cycle 1 Complete (61 us). Commencing Cycle 2...";

        -- === CYCLE 2 === --
        -- Cycle 2 - Phase 1 (25s Green A / 28s Red B)
        report "  [Cycle 2 - Phase 1] Route A Green (25s), Route B Red (28s)";
        assert (ledg(0) = '1' and ledr(2) = '1' and ledg(1) = '0' and ledr(0) = '0')
            report "FAIL: Cycle 2 Phase 1 lights invalid at start!" severity failure;
        assert (hex1 = SEG_2 and hex0 = SEG_5)
            report "FAIL: Cycle 2 Phase 1 entry: Route A counter expected 25 (hex1=0x24, hex0=0x12)!" severity failure;
        assert (hex3 = SEG_2 and hex2 = SEG_8)
            report "FAIL: Cycle 2 Phase 1 entry: Route B counter expected 28 (hex3=0x24, hex2=0x00)!" severity failure;

        -- Wait until transition to Phase 2 (Route A Yellow goes HIGH)
        wait until rising_edge(clk_50m) and ledr(1) = '1';
        t_phase_dur := now - t_phase_start;
        assert (t_phase_dur >= 24980 ns and t_phase_dur <= 25020 ns)
            report "FAIL: Cycle 2 Phase 1 duration not 25 us!" severity failure;
        t_phase_start := now;

        -- Boundary check at expiration of Phase 1: Route A counted to 1, Route B counted to 3
        assert (hex1 = SEG_0 and hex0 = SEG_1)
            report "FAIL: Cycle 2 Phase 1 boundary: Route A counter expected 1 (hex1=0x40, hex0=0x79)!" severity failure;
        assert (hex3 = SEG_0 and hex2 = SEG_3)
            report "FAIL: Cycle 2 Phase 1 boundary: Route B counter expected 3 (hex3=0x40, hex2=0x30)!" severity failure;

        -- Wait 1 clock cycle for synchronous timer reload
        wait until rising_edge(clk_50m);

        -- Cycle 2 - Phase 2 (3s Yellow A / 3s Red B)
        report "  [Cycle 2 - Phase 2] Route A Yellow (3s), Route B Red (3s)";
        assert (ledr(1) = '1' and ledr(2) = '1' and ledg(0) = '0' and ledg(1) = '0')
            report "FAIL: Cycle 2 Phase 2 lights invalid!" severity failure;
        assert (hex1 = SEG_0 and hex0 = SEG_3)
            report "FAIL: Cycle 2 Phase 2 entry: Route A counter expected 3 (hex1=0x40, hex0=0x30)!" severity failure;
        assert (hex3 = SEG_0 and hex2 = SEG_3)
            report "FAIL: Cycle 2 Phase 2 entry: Route B counter expected 3 (hex3=0x40, hex2=0x30)!" severity failure;

        -- Wait until transition to Phase 3 (Route B Green goes HIGH)
        wait until rising_edge(clk_50m) and ledg(1) = '1';
        t_phase_dur := now - t_phase_start;
        assert (t_phase_dur >= 2980 ns and t_phase_dur <= 3020 ns)
            report "FAIL: Cycle 2 Phase 2 duration not 3 us!" severity failure;
        t_phase_start := now;

        -- Boundary check at expiration of Phase 2: Route A counted to 1, Route B counted to 1
        assert (hex1 = SEG_0 and hex0 = SEG_1)
            report "FAIL: Cycle 2 Phase 2 boundary: Route A counter expected 1 (hex1=0x40, hex0=0x79)!" severity failure;
        assert (hex3 = SEG_0 and hex2 = SEG_1)
            report "FAIL: Cycle 2 Phase 2 boundary: Route B counter expected 1 (hex3=0x40, hex2=0x79)!" severity failure;

        -- Wait 1 clock cycle for synchronous timer reload
        wait until rising_edge(clk_50m);

        -- Cycle 2 - Phase 3 (33s Red A / 30s Green B)
        report "  [Cycle 2 - Phase 3] Route A Red (33s), Route B Green (30s)";
        assert (ledr(0) = '1' and ledg(1) = '1' and ledg(0) = '0' and ledr(2) = '0')
            report "FAIL: Cycle 2 Phase 3 lights invalid!" severity failure;
        assert (hex1 = SEG_3 and hex0 = SEG_3)
            report "FAIL: Cycle 2 Phase 3 entry: Route A counter expected 33 (hex1=0x30, hex0=0x30)!" severity failure;
        assert (hex3 = SEG_3 and hex2 = SEG_0)
            report "FAIL: Cycle 2 Phase 3 entry: Route B counter expected 30 (hex3=0x30, hex2=0x40)!" severity failure;

        -- Wait until transition to Phase 4 (Route B Yellow goes HIGH)
        wait until rising_edge(clk_50m) and ledr(3) = '1';
        t_phase_dur := now - t_phase_start;
        assert (t_phase_dur >= 29980 ns and t_phase_dur <= 30020 ns)
            report "FAIL: Cycle 2 Phase 3 duration not 30 us!" severity failure;
        t_phase_start := now;

        -- Boundary check at expiration of Phase 3: Route A counted to 3, Route B counted to 1
        assert (hex1 = SEG_0 and hex0 = SEG_3)
            report "FAIL: Cycle 2 Phase 3 boundary: Route A counter expected 3 (hex1=0x40, hex0=0x30)!" severity failure;
        assert (hex3 = SEG_0 and hex2 = SEG_1)
            report "FAIL: Cycle 2 Phase 3 boundary: Route B counter expected 1 (hex3=0x40, hex2=0x79)!" severity failure;

        -- Wait 1 clock cycle for synchronous timer reload
        wait until rising_edge(clk_50m);

        -- Cycle 2 - Phase 4 (3s Red A / 3s Yellow B)
        report "  [Cycle 2 - Phase 4] Route A Red (3s), Route B Yellow (3s)";
        assert (ledr(0) = '1' and ledr(3) = '1' and ledg(0) = '0' and ledg(1) = '0')
            report "FAIL: Cycle 2 Phase 4 lights invalid!" severity failure;
        assert (hex1 = SEG_0 and hex0 = SEG_3)
            report "FAIL: Cycle 2 Phase 4 entry: Route A counter expected 3 (hex1=0x40, hex0=0x30)!" severity failure;
        assert (hex3 = SEG_0 and hex2 = SEG_3)
            report "FAIL: Cycle 2 Phase 4 entry: Route B counter expected 3 (hex3=0x40, hex2=0x30)!" severity failure;

        -- Wait until transition to Phase 1 (Route A Green goes HIGH)
        wait until rising_edge(clk_50m) and ledg(0) = '1';
        t_phase_dur := now - t_phase_start;
        assert (t_phase_dur >= 2980 ns and t_phase_dur <= 3020 ns)
            report "FAIL: Cycle 2 Phase 4 duration not 3 us!" severity failure;
        t_phase_start := now;

        -- Boundary check at expiration of Phase 4: Route A counted to 1, Route B counted to 1
        assert (hex1 = SEG_0 and hex0 = SEG_1)
            report "FAIL: Cycle 2 Phase 4 boundary: Route A counter expected 1 (hex1=0x40, hex0=0x79)!" severity failure;
        assert (hex3 = SEG_0 and hex2 = SEG_1)
            report "FAIL: Cycle 2 Phase 4 boundary: Route B counter expected 1 (hex3=0x40, hex2=0x79)!" severity failure;

        -- Wait 1 clock cycle for synchronous timer reload
        wait until rising_edge(clk_50m);

        -- Confirm clean return to Phase 1 and counter reload
        assert (ledg(0) = '1' and ledr(2) = '1')
            report "FAIL: Did not return to Phase 1 after Cycle 2!" severity failure;
        assert (hex1 = SEG_2 and hex0 = SEG_5)
            report "FAIL: Cycle 2 return to Phase 1: Route A counter expected 25 (hex1=0x24, hex0=0x12)!" severity failure;
        assert (hex3 = SEG_2 and hex2 = SEG_8)
            report "FAIL: Cycle 2 return to Phase 1: Route B counter expected 28 (hex3=0x24, hex2=0x00)!" severity failure;
        report "[SCENARIO 1] PASS: 2 full consecutive normal cycles (122 us) verified successfully.";

        ------------------------------------------------------------------------
        -- SCENARIO 2: Night Mode (SW(0) = '1')
        -- Verify Yellow LEDs flash at 1 Hz, Greens/Reds OFF, 7-segs blanked ("1111111").
        -- Measure and assert exact pulse widths (500 ns HIGH, 500 ns LOW) and 50% duty cycle.
        -- Deassert SW(0) = '0' and verify return to normal operation.
        ------------------------------------------------------------------------
        report "----------------------------------------------------------------";
        report "[SCENARIO 2] Commencing Night Mode Verification (SW(0) = '1')...";
        report "----------------------------------------------------------------";
        sw(0) <= '1';
        wait for 200 ns;

        -- Verify all four 7-segment displays are blanked ("1111111")
        assert (hex0 = SEG_BLANK and hex1 = SEG_BLANK and hex2 = SEG_BLANK and hex3 = SEG_BLANK)
            report "FAIL: 7-segment displays not blanked during Night Mode!"
            severity failure;

        -- Verify Greens and Reds are strictly OFF
        assert (ledg(0) = '0' and ledg(1) = '0' and ledr(0) = '0' and ledr(2) = '0')
            report "FAIL: Greens or Reds are illuminated during Night Mode!"
            severity failure;

        -- Synchronize to a clean falling edge of yellow blink (start of a full LOW phase)
        wait until rising_edge(clk_50m) and ledr(1) = '0';
        assert (ledr(3) = '0')
            report "FAIL: Route B Yellow not synchronized with Route A Yellow at LOW entry!" severity failure;

        -- Cycle 1 Measurement: Wait for rising edge to start clean HIGH pulse
        wait until rising_edge(clk_50m) and ledr(1) = '1';
        t_blink_start := now;
        assert (ledr(3) = '1')
            report "FAIL: Route B Yellow not synchronized with Route A Yellow at HIGH entry!" severity failure;
        assert (ledg(0) = '0' and ledg(1) = '0' and ledr(0) = '0' and ledr(2) = '0')
            report "FAIL: Non-yellow LEDs active during Night Mode flash HIGH phase!" severity failure;

        -- Wait for falling edge to measure HIGH pulse duration
        wait until rising_edge(clk_50m) and ledr(1) = '0';
        t_blink_high := now - t_blink_start;
        t_blink_start := now; -- Start of LOW pulse
        assert (ledr(3) = '0')
            report "FAIL: Route B Yellow not synchronized with Route A Yellow at LOW entry!" severity failure;
        assert (ledg(0) = '0' and ledg(1) = '0' and ledr(0) = '0' and ledr(2) = '0')
            report "FAIL: Non-yellow LEDs active during Night Mode flash LOW phase!" severity failure;

        -- Wait for rising edge to measure LOW pulse duration
        wait until rising_edge(clk_50m) and ledr(1) = '1';
        t_blink_low := now - t_blink_start;
        assert (ledr(3) = '1')
            report "FAIL: Route B Yellow not synchronized with Route A Yellow on second HIGH entry!" severity failure;

        -- Assert pulse widths and 50% duty cycle for Cycle 1
        report "  [Night Mode Cycle 1] HIGH pulse = " & time'image(t_blink_high) & ", LOW pulse = " & time'image(t_blink_low);
        assert (t_blink_high = 500 ns)
            report "FAIL: Night Mode HIGH pulse width not exact 500 ns (got " & time'image(t_blink_high) & ")!"
            severity failure;
        assert (t_blink_low = 500 ns)
            report "FAIL: Night Mode LOW pulse width not exact 500 ns (got " & time'image(t_blink_low) & ")!"
            severity failure;
        assert (t_blink_high = t_blink_low)
            report "FAIL: Night Mode duty cycle is not exact 50%!"
            severity failure;
        assert ((t_blink_high + t_blink_low) = 1000 ns)
            report "FAIL: Night Mode 1 Hz total period is not 1000 ns!"
            severity failure;

        -- Cycle 2 Measurement: Verify consecutive steady-state cycle
        t_blink_start := now;
        wait until rising_edge(clk_50m) and ledr(1) = '0';
        t_blink_high := now - t_blink_start;
        t_blink_start := now;
        wait until rising_edge(clk_50m) and ledr(1) = '1';
        t_blink_low := now - t_blink_start;

        report "  [Night Mode Cycle 2] HIGH pulse = " & time'image(t_blink_high) & ", LOW pulse = " & time'image(t_blink_low);
        assert (t_blink_high = 500 ns)
            report "FAIL: Night Mode Cycle 2 HIGH pulse width not exact 500 ns!" severity failure;
        assert (t_blink_low = 500 ns)
            report "FAIL: Night Mode Cycle 2 LOW pulse width not exact 500 ns!" severity failure;
        assert (t_blink_high = t_blink_low)
            report "FAIL: Night Mode Cycle 2 duty cycle is not exact 50%!" severity failure;

        -- Deassert Night Mode
        report "  -> Deasserting Night Mode (SW(0) = '0')...";
        sw(0) <= '0';
        wait for 200 ns;

        -- Verify return to normal Phase 1 operation
        assert (ledg(0) = '1' and ledr(2) = '1' and ledg(1) = '0' and ledr(0) = '0')
            report "FAIL: Did not return cleanly to Phase 1 after deasserting Night Mode!"
            severity failure;
        assert (hex0 /= SEG_BLANK and hex1 /= SEG_BLANK)
            report "FAIL: 7-segments remained blanked after exiting Night Mode!"
            severity failure;
        assert (hex1 = SEG_2 and hex0 = SEG_5)
            report "FAIL: Route A counter not reloaded to 25 after exiting Night Mode!"
            severity failure;
        assert (hex3 = SEG_2 and hex2 = SEG_8)
            report "FAIL: Route B counter not reloaded to 28 after exiting Night Mode!"
            severity failure;
        report "[SCENARIO 2] PASS: Night Mode (1 Hz flash, 500 ns pulse / 50% duty cycle, 7-seg blanking, clean recovery) verified.";

        ------------------------------------------------------------------------
        -- SCENARIO 3: Pause / Hold Mode (SW(1) = '1')
        -- Verify counter countdown freezes and resumes smoothly without drift.
        ------------------------------------------------------------------------
        report "----------------------------------------------------------------";
        report "[SCENARIO 3] Commencing Pause / Hold Verification (SW(1) = '1')...";
        report "----------------------------------------------------------------";

        -- Let Phase 1 count down for 5 simulated seconds
        wait for 5.0 us;

        report "  -> Activating Pause (SW(1) = '1')...";
        sw(1) <= '1';
        wait for 100 ns;

        -- Capture state while paused
        frozen_hex0 := hex0;
        frozen_hex1 := hex1;
        frozen_hex2 := hex2;
        frozen_hex3 := hex3;
        frozen_ledg := ledg;
        frozen_ledr := ledr;

        -- Wait 4 simulated seconds while paused
        wait for 4.0 us;

        -- Verify that timers, lights, and displays remained completely frozen
        assert (hex0 = frozen_hex0 and hex1 = frozen_hex1 and hex2 = frozen_hex2 and hex3 = frozen_hex3)
            report "FAIL: Counter display changed while Pause (SW(1)='1') was active!"
            severity failure;
        assert (ledg = frozen_ledg and ledr = frozen_ledr)
            report "FAIL: Light outputs changed while Pause (SW(1)='1') was active!"
            severity failure;

        -- Deassert Pause and verify smooth resumption without drift
        report "  -> Deasserting Pause (SW(1) = '0')...";
        sw(1) <= '0';
        wait for 2.0 us;

        -- Confirm that countdown has resumed (hex values have decremented)
        assert (hex0 /= frozen_hex0 or hex1 /= frozen_hex1)
            report "FAIL: Counter countdown failed to resume after releasing Pause!"
            severity failure;
        report "[SCENARIO 3] PASS: Pause / Hold Mode (frozen countdown, smooth resumption) verified.";

        ------------------------------------------------------------------------
        -- SCENARIO 4: Emergency Force (KEY(1) = '0')
        -- Asserted during Phase 3 (Route B Green). Verify immediate preemption
        -- giving Green to Route A and Red to Route B.
        -- Hold Emergency corridor for 5.0 us and verify countdown state.
        -- Verify safe release, counter reload, and normal countdown resumption.
        ------------------------------------------------------------------------
        report "----------------------------------------------------------------";
        report "[SCENARIO 4] Commencing Emergency Force Verification (KEY(1) = '0')...";
        report "----------------------------------------------------------------";

        -- Fast-forward until Phase 3 is active (Route B Green, Route A Red)
        report "  -> Waiting for Phase 3 (Route B Green, Route A Red)...";
        wait until rising_edge(clk_50m) and ledg(1) = '1' and ledr(0) = '1';
        report "  -> Confirmed Phase 3 active. Route B has Green, Route A has Red.";

        -- Wait 2 us into Phase 3
        wait for 2.0 us;
        assert (ledg(1) = '1' and ledr(0) = '1' and ledg(0) = '0' and ledr(2) = '0')
            report "FAIL: Expected Phase 3 steady state before Emergency assertion!"
            severity failure;

        -- Assert Emergency Pushbutton (active-low)
        report "  -> Pressing Emergency Pushbutton (KEY(1) = '0')...";
        key(1) <= '0';
        wait for 100 ns;

        -- Verify immediate preemption: Route A gets Green, Route B gets Red
        assert (ledg(0) = '1' and ledr(2) = '1' and ledg(1) = '0' and ledr(0) = '0')
            report "FAIL: Emergency Force failed to immediately preempt Route B to Red and grant Route A Green!"
            severity failure;

        -- Verify initial countdown values loaded at emergency preemption:
        -- Route A loaded to 25 (hex1=0x24, hex0=0x12), Route B loaded to 28 (hex3=0x24, hex2=0x00)
        assert (hex1 = SEG_2 and hex0 = SEG_5)
            report "FAIL: Route A counter not initialized to 25 upon Emergency entry!"
            severity failure;
        assert (hex3 = SEG_2 and hex2 = SEG_8)
            report "FAIL: Route B counter not initialized to 28 upon Emergency entry!"
            severity failure;

        -- Hold Emergency corridor for 5 simulated seconds (5.0 us) and verify countdown state
        report "  -> Holding Emergency corridor for 5.0 us and tracking countdown state...";
        wait for 5.0 us;

        -- Verify safety corridor maintained continuously during hold
        assert (ledg(0) = '1' and ledr(2) = '1' and ledg(1) = '0' and ledr(0) = '0')
            report "FAIL: Emergency corridor violated during active hold!"
            severity failure;

        -- Verify countdown state after 5 simulated seconds:
        -- Route A: 25 - 5 = 20 (hex1=0x24, hex0=0x40)
        -- Route B: 28 - 5 = 23 (hex3=0x24, hex2=0x30)
        assert (hex1 = SEG_2 and hex0 = SEG_0)
            report "FAIL: Route A counter expected 20 after 5 us emergency hold!"
            severity failure;
        assert (hex3 = SEG_2 and hex2 = SEG_3)
            report "FAIL: Route B counter expected 23 after 5 us emergency hold!"
            severity failure;
        report "  -> Confirmed active countdown during Emergency: Route A = 20, Route B = 23.";

        -- Release Emergency Pushbutton
        report "  -> Releasing Emergency Pushbutton (KEY(1) = '1')...";
        key(1) <= '1';
        wait for 200 ns;

        -- Verify safe recovery into Phase 1 with reloaded counters
        assert (ledg(0) = '1' and ledr(2) = '1' and ledg(1) = '0' and ledr(0) = '0')
            report "FAIL: System failed to resume safely into Phase 1 after Emergency release!"
            severity failure;
        assert (hex1 = SEG_2 and hex0 = SEG_5)
            report "FAIL: Route A counter not reloaded to 25 after Emergency release!"
            severity failure;
        assert (hex3 = SEG_2 and hex2 = SEG_8)
            report "FAIL: Route B counter not reloaded to 28 after Emergency release!"
            severity failure;

        -- Let Phase 1 count down for 2.0 us to verify normal countdown progression resumed
        wait for 2.0 us;
        assert (ledg(0) = '1' and ledr(2) = '1' and ledg(1) = '0' and ledr(0) = '0')
            report "FAIL: Phase 1 lights invalid during post-emergency countdown!"
            severity failure;
        assert (hex1 = SEG_2 and hex0 = SEG_3)
            report "FAIL: Route A counter did not decrement to 23 after 2 us in Phase 1!"
            severity failure;
        assert (hex3 = SEG_2 and hex2 = SEG_6)
            report "FAIL: Route B counter did not decrement to 26 after 2 us in Phase 1!"
            severity failure;

        report "[SCENARIO 4] PASS: Emergency Force Mode (preemption, 5 us hold with countdown, safe release & reload) verified.";

        ------------------------------------------------------------------------
        -- FINAL ATTESTATION & TERMINATION
        ------------------------------------------------------------------------
        wait for 2.0 us;
        report "================================================================";
        report "  ALL 4 TEST SCENARIOS COMPLETED SUCCESSFULLY!";
        report "  ZERO SAFETY ASSERTION VIOLATIONS DETECTED.";
        report "================================================================";

        sim_done <= true;
        wait;
    end process;

end architecture sim;
