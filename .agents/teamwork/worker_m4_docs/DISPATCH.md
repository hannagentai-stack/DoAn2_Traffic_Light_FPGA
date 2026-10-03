## 2026-10-01T18:19:58Z

You are the Technical Documentation Worker (worker_m4_docs).
Your working directory is: c:/Users/handa/OneDrive/Documents/Projects/DoAn2/.agents/teamwork/worker_m4_docs

You MUST read the authoritative user request at:
c:/Users/handa/OneDrive/Documents/Projects/DoAn2/.agents/teamwork/ORIGINAL_REQUEST.md

You must also read:
- c:/Users/handa/OneDrive/Documents/Projects/DoAn2/.agents/teamwork/orchestrator/PROJECT.md
- c:/Users/handa/OneDrive/Documents/Projects/DoAn2/.agents/teamwork/explorer_survey_2/handoff.md
- c:/Users/handa/OneDrive/Documents/Projects/DoAn2/.agents/teamwork/explorer_survey_3/handoff.md

FILE WRITE OWNERSHIP:
You exclusively own and must implement:
1. c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/docs/fsm_state_diagram.md
2. c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/docs/timing_specifications.md

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Tasks:
1. Implement `traffic_light_fpga/docs/fsm_state_diagram.md`:
   - Detailed State Transition Table covering all states (S_PHASE1, S_PHASE2, S_PHASE3, S_PHASE4, S_NIGHT, S_EMERGENCY), input conditions, next states, output lamp values, and 7-segment display behavior.
   - Mermaid state diagram showing all transitions, overrides, and conditions.
   - Formal mathematical proof of the hardware fail-safe interlock gate guaranteeing dual-green prevention under all circuit states.
2. Implement `traffic_light_fpga/docs/timing_specifications.md`:
   - Clock tree and frequency division math: 50 MHz input, 1 Hz tick pulse (50,000,000 cycles HW vs 50 cycles SIM), 1 Hz blink toggle (500 ms ON / 500 ms OFF).
   - Phase timing schedule and dual countdown timeline (61s cycle).
   - Step-by-step deployment guide for Intel Quartus Prime:
     * Step 1: Create Quartus Prime Project (Cyclone IV E EP4CE115F29C7).
     * Step 2: Add RTL source files.
     * Step 3: Run Analysis & Elaboration and verify RTL Viewer.
     * Step 4: Import and verify QSF pin constraints and SDC timing constraints.
     * Step 5: Compile design (Synthesis & Fitter) and check Compilation Report.
     * Step 6: Program hardware via USB-Blaster cable (.sof file programming).

Deliver report to: c:/Users/handa/OneDrive/Documents/Projects/DoAn2/.agents/teamwork/worker_m4_docs/handoff.md
Update progress.md before finishing.
When done, message caller.
