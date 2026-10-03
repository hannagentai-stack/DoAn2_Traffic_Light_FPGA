## 2026-10-01T17:41:28Z
You are the RTL Implementation Worker (worker_m1_rtl).
Your working directory is: c:/Users/handa/OneDrive/Documents/Projects/DoAn2/.agents/teamwork/worker_m1_rtl

You MUST read the authoritative user request at:
c:/Users/handa/OneDrive/Documents/Projects/DoAn2/.agents/teamwork/ORIGINAL_REQUEST.md

You must also read the architecture design documents:
- c:/Users/handa/OneDrive/Documents/Projects/DoAn2/.agents/teamwork/orchestrator/PROJECT.md
- c:/Users/handa/OneDrive/Documents/Projects/DoAn2/.agents/teamwork/explorer_survey_2/handoff.md
- c:/Users/handa/OneDrive/Documents/Projects/DoAn2/.agents/teamwork/spec_miner_survey_1/handoff.md

FILE WRITE OWNERSHIP:
You exclusively own and must implement the following 5 files in c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/rtl/:
1. clk_divider.vhd
2. timer_counter.vhd
3. fsm_controller.vhd
4. seg7_decoder.vhd
5. traffic_light_top.vhd

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Detailed Implementation Requirements:
1. Strict IEEE 1164 and numeric_std only (NO std_logic_arith, NO std_logic_unsigned).
2. 100% synchronous logic clocked on rising_edge(CLOCK_50). Zero inferred latches (unconditional defaults in combinational processes).
3. clk_divider.vhd:
   - generic SIMULATION : boolean := false
   - When SIMULATION=false: 50,000,000 cycles for 1s. When SIMULATION=true: 50 cycles for 1s.
   - Outputs: tick_1hz (1-cycle synchronous pulse), blink_1hz (50% toggle wave).
4. timer_counter.vhd:
   - Synchronous countdown for Route A and Route B.
   - On load_phase='1': Phase 1 loads A=25, B=28; Phase 2 loads A=3, B=3; Phase 3 loads A=33, B=30; Phase 4 loads A=3, B=3.
   - On tick_1hz='1' and pause='0': decrements counters down to 1.
   - Pulses timer_done='1' for 1 cycle when current phase counter reaches 1.
   - Pure combinational BCD separation into bcd_a_tens, bcd_a_units, bcd_b_tens, bcd_b_units using range comparison (no division operators).
5. fsm_controller.vhd:
   - Moore FSM with states: S_PHASE1, S_PHASE2, S_PHASE3, S_PHASE4, S_NIGHT, S_EMERGENCY.
   - Priority preemption: Reset (KEY[0]='0') > Emergency (KEY[1]='0') > Night Mode (SW[0]='1') > Pause (SW[1]='1') > Normal cycle.
   - Generates load_phase pulse on state transition.
   - In S_NIGHT: asserts blank_seg7='1', drives fsm_ya and fsm_yb with blink_1hz.
6. seg7_decoder.vhd:
   - Active-Low cathode chung ('0' lit, '1' off).
   - Segments [6..0] = (g, f, e, d, c, b, a).
   - Truth table: 0(1000000/0x40), 1(1111001/0x79), 2(0100100/0x24), 3(0110000/0x30), 4(0011001/0x19), 5(0010010/0x12), 6(0000010/0x02), 7(1111000/0x78), 8(0000000/0x00), 9(0010000/0x10).
   - Blanking on blank='1' or invalid BCD: "1111111" (0x7F).
7. traffic_light_top.vhd:
   - Top-level entity mapping ports: CLOCK_50, KEY(1..0), SW(1..0), LEDR(3..0), LEDG(1..0), HEX0(6..0)..HEX3(6..0).
   - Generic SIMULATION : boolean := false.
   - Fail-Safe Hardware Interlock Layer:
     If fsm_ga='1' and fsm_gb='1', both LEDG outputs are forced to '0' and both LEDR(0)/LEDR(2) are forced to '1' (All-Red).
8. Verification:
   - Compile or syntax-check files (run ghdl or syntax check scripts via powershell if available).
   - Check that no std_logic_arith/unsigned exists.
   - Check that all process sensitivity lists and default assignments prevent any inferred latches.
