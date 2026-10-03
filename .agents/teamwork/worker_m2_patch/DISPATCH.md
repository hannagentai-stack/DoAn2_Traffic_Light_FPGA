## 2026-10-01T18:19:58Z
You are the Testbench Hardening Worker (worker_m2_patch).
Your working directory is: c:/Users/handa/OneDrive/Documents/Projects/DoAn2/.agents/teamwork/worker_m2_patch

You MUST read the authoritative user request at:
c:/Users/handa/OneDrive/Documents/Projects/DoAn2/.agents/teamwork/ORIGINAL_REQUEST.md

You must also read:
- c:/Users/handa/OneDrive/Documents/Projects/DoAn2/.agents/teamwork/orchestrator/PROJECT.md
- c:/Users/handa/OneDrive/Documents/Projects/DoAn2/.agents/teamwork/challenger_m2_1/handoff.md
- c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/tb/tb_traffic_light_top.vhd

FILE WRITE OWNERSHIP:
You exclusively own and modify:
c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/tb/tb_traffic_light_top.vhd

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Tasks:
1. Harden `traffic_light_fpga/tb/tb_traffic_light_top.vhd`:
   - In Scenario 1 (Normal Cycles): Add cycle-accurate assertions verifying 7-segment / counter values at phase entry and boundaries:
     * Phase 1 entry: Route A is 25 (hex1=0x24, hex0=0x12), Route B is 28 (hex3=0x24, hex2=0x00).
     * Phase 2 entry: Route A is 3 (hex1=0x40, hex0=0x30), Route B is 3 (hex3=0x40, hex2=0x30).
     * Phase 3 entry: Route A is 33 (hex1=0x30, hex0=0x30), Route B is 30 (hex3=0x30, hex2=0x40).
     * Phase 4 entry: Route A is 3 (hex1=0x40, hex0=0x30), Route B is 3 (hex3=0x40, hex2=0x30).
   - In Scenario 2 (Night Mode): Measure and assert the 1 Hz blink frequency: measure the pulse width of `ledr(1)`/`ledr(3)` (500 ns HIGH, 500 ns LOW in simulation) and assert exact 50% duty cycle.
   - In Scenario 4 (Emergency Mode): Extend emergency hold duration to 5 us and verify countdown state.
2. Run simulation in ModelSim:
   Execute `vsim -c -do "do run_sim.do; quit -f"` in `traffic_light_fpga/sim/` via run_command.
3. Confirm that all assertions pass with 0 errors and 0 warnings.
4. Deliver report to: c:/Users/handa/OneDrive/Documents/Projects/DoAn2/.agents/teamwork/worker_m2_patch/handoff.md
Update progress.md before finishing.
When done, message caller.
