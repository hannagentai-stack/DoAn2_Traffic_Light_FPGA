## 2026-10-01T18:05:37Z

You are the Verification & Simulation Worker (worker_m2_sim).
Your working directory is: c:/Users/handa/OneDrive/Documents/Projects/DoAn2/.agents/teamwork/worker_m2_sim

You MUST read the authoritative user request at:
c:/Users/handa/OneDrive/Documents/Projects/DoAn2/.agents/teamwork/ORIGINAL_REQUEST.md

You must also read:
- c:/Users/handa/OneDrive/Documents/Projects/DoAn2/.agents/teamwork/orchestrator/PROJECT.md
- c:/Users/handa/OneDrive/Documents/Projects/DoAn2/.agents/teamwork/orchestrator/TEST_INFRA.md
- c:/Users/handa/OneDrive/Documents/Projects/DoAn2/.agents/teamwork/explorer_survey_3/handoff.md
- RTL sources in c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/rtl/

FILE WRITE OWNERSHIP:
You exclusively own and must implement:
1. c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/tb/tb_traffic_light_top.vhd
2. c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/sim/run_sim.do
3. c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/sim/wave.do

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Detailed Implementation Requirements:
1. `tb/tb_traffic_light_top.vhd`:
   - Self-checking testbench instantiating `traffic_light_top` with generic `SIMULATION => true`.
   - 50 MHz clock generation (`clk_50m`, period 20 ns) and active-low reset on `KEY(0)`.
   - Continuous concurrent safety check:
     `assert not (ledg(0) = '1' and ledg(1) = '1') report "CRITICAL SAFETY VIOLATION: Both Route A and Route B have GREEN light simultaneously!" severity failure;`
   - Scenario 1: 2 consecutive normal cycles (122 us). Verify Phase 1 (25s Green A / 28s Red B), Phase 2 (3s Yellow A / 3s Red B), Phase 3 (33s Red A / 30s Green B), Phase 4 (3s Red A / 3s Yellow B).
   - Scenario 2: Night Mode (`SW(0) = '1'`). Verify Yellow LEDs flash at 1 Hz, greens/reds OFF, 7-segs blanked (`"1111111"`). Deassert `SW(0) = '0'`.
   - Scenario 3: Pause/Hold (`SW(1) = '1'`). Verify counter countdown freezes and resumes smoothly without drift.
   - Scenario 4: Emergency Force (`KEY(1) = '0'`). Asserted during Phase 3 (Route B Green). Verify immediate preemption giving Green to Route A and Red to Route B.
2. `sim/run_sim.do`:
   - Complete ModelSim / QuestaSim automation: create clean work library, compile 5 RTL files in dependency order, compile testbench, elaborate with `vsim -t 1ns -voptargs="+acc" work.tb_traffic_light_top`, load `wave.do`, run simulation for 200 us.
3. `sim/wave.do`:
   - Color-coded signals across 6 dividers: Clocks/Reset, Control Inputs, FSM State, Timers/BCD, Route A/B LEDs, HEX Displays.
4. Execution:
   - Run simulation via command line (e.g. ModelSim batch execution `vsim -c -do "do run_sim.do; quit -f"` or `vcom` and `vsim` commands).
   - Verify that all assertions pass and output shows "ALL 4 TEST SCENARIOS COMPLETED SUCCESSFULLY!".
   - Include full simulation execution output transcript in handoff report.

Deliverable:
Write report to: c:/Users/handa/OneDrive/Documents/Projects/DoAn2/.agents/teamwork/worker_m2_sim/handoff.md
Update progress.md before finishing.
When done, message caller.
