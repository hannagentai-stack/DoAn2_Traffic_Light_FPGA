# Handoff Report: Adversarial Verification of Milestone M2 (Verification & Simulation)

**Agent**: `challenger_m2_2` (Empirical Challenger 2)  
**Date**: 2026-10-01T18:25:00Z  
**Verdict**: **APPROVE**  
**Target Project**: `traffic_light_fpga` (Altera Cyclone IV E EP4CE115F29C7 / Terasic DE2-115)  

---

## 1. Observation

### 1.1. Inspected Deliverables & File Paths
The following M2 artifacts were audited:
- Testbench: `c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/tb/tb_traffic_light_top.vhd` (409 lines)
- Simulation Run Script: `c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/sim/run_sim.do` (60 lines)
- Waveform Configuration: `c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/sim/wave.do` (68 lines)
- ModelSim Transcript Log: `c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/sim/transcript` (194 lines)
- ModelSim Wave Log File: `c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/sim/vsim.wlf` (172,032 bytes)

### 1.2. Simulation Execution Transcript Analysis
Direct inspection of `traffic_light_fpga/sim/transcript` revealed:
1. **RTL & TB Compilation Order & Status**:
   - `../rtl/clk_divider.vhd`: Line 16 -> `Errors: 0, Warnings: 0`
   - `../rtl/seg7_decoder.vhd`: Line 27 -> `Errors: 0, Warnings: 0`
   - `../rtl/timer_counter.vhd`: Line 38 -> `Errors: 0, Warnings: 0`
   - `../rtl/fsm_controller.vhd`: Line 49 -> `Errors: 0, Warnings: 0`
   - `../rtl/traffic_light_top.vhd`: Line 64 -> `Errors: 0, Warnings: 0`
   - `../tb/tb_traffic_light_top.vhd`: Line 76 -> `Errors: 0, Warnings: 0`
2. **Elaboration**:
   - Command: `vsim -t 1ns -voptargs="+acc" work.tb_traffic_light_top` (Line 77)
   - Bound entities: `tb_traffic_light_top(sim)`, `traffic_light_top(structural)`, `clk_divider(rtl)`, `fsm_controller(rtl)`, `timer_counter(rtl)`, `seg7_decoder(rtl)`.
3. **Execution Milestones & Assertion Results**:
   - Initial Reset (Time: 180 ns): Line 115 -> `[INIT] PASS: Reset successfully initialized system to Phase 1 (25s Green A / 28s Red B).`
   - Scenario 1 (Time: 122190 ns): Line 141 -> `[SCENARIO 1] PASS: 2 full consecutive normal cycles (122 us) verified successfully.`
   - Scenario 2 (Time: 123350 ns): Line 151 -> `[SCENARIO 2] PASS: Night Mode (1 Hz flash, 7-seg blanking, clean recovery) verified.`
   - Scenario 3 (Time: 134450 ns): Line 163 -> `[SCENARIO 3] PASS: Pause / Hold Mode (frozen countdown, smooth resumption) verified.`
   - Scenario 4 (Time: 160490 ns): Line 179 -> `[SCENARIO 4] PASS: Emergency Force Mode (immediate preemption, safe release) verified.`
   - Final Summary (Time: 162490 ns): Lines 183-185 ->
     ```text
     ** Note:   ALL 4 TEST SCENARIOS COMPLETED SUCCESSFULLY!
     ** Note:   ZERO SAFETY ASSERTION VIOLATIONS DETECTED.
     ```
   - Run Termination (Line 193): `quit -f`, `End time: 01:14:51`, `Errors: 0, Warnings: 0`.

### 1.3. Waveform Script & Hierarchical Path Audit
Cross-referencing `wave.do` against `tb_traffic_light_top.vhd` and submodule signals in `traffic_light_top.vhd`:
- Group 1 (Clocks & Reset):
  * `/tb_traffic_light_top/clk_50m` -> Exists in TB line 32.
  * `/tb_traffic_light_top/key(0)` -> Exists in TB line 33.
  * `/tb_traffic_light_top/dut/tick_1hz_s` -> Exists in top line 42.
  * `/tb_traffic_light_top/dut/blink_1hz_s` -> Exists in top line 43.
- Group 2 (Control Inputs):
  * `/tb_traffic_light_top/sw(0)`, `/tb_traffic_light_top/sw(1)`, `/tb_traffic_light_top/key(1)` -> Exist in TB lines 33-34.
- Group 3 (FSM State):
  * `/tb_traffic_light_top/dut/u_fsm_controller/current_state` -> Exists in `fsm_controller.vhd` line 48.
  * `/tb_traffic_light_top/dut/u_fsm_controller/next_state` -> Exists in `fsm_controller.vhd` line 49.
  * `/tb_traffic_light_top/dut/phase_sel_s`, `/tb_traffic_light_top/dut/load_phase_s`, `/tb_traffic_light_top/dut/timer_done_s` -> Exist in top lines 44-46.
- Group 4 (Timers & BCD):
  * `/tb_traffic_light_top/dut/u_timer_counter/cnt_a`, `cnt_b` -> Exist in `timer_counter.vhd` lines 40-41.
  * `/tb_traffic_light_top/dut/bcd_a_tens_s`, `bcd_a_units_s`, `bcd_b_tens_s`, `bcd_b_units_s` -> Exist in top lines 49-52.
- Group 5 (Route A & B LEDs):
  * `/tb_traffic_light_top/ledg(0)`, `/tb_traffic_light_top/ledr(1)`, `/tb_traffic_light_top/ledr(0)` -> Route A outputs.
  * `/tb_traffic_light_top/ledg(1)`, `/tb_traffic_light_top/ledr(3)`, `/tb_traffic_light_top/ledr(2)` -> Route B outputs.
- Group 6 (HEX Displays):
  * `/tb_traffic_light_top/dut/blank_seg7_s`, `/tb_traffic_light_top/hex1`, `hex0`, `hex3`, `hex2` -> Display outputs.
- Batch Protection:
  * Lines 7, 8, 59-67 in `wave.do` wrap GUI configurations (`TreeUpdate`, `configure wave`) in `catch { ... }` or `onerror {resume}`, preventing command abortion in batch mode (`-c`).

---

## 2. Logic Chain

1. **Verification of Zero Errors & Zero Warnings**:
   - Each of the 5 RTL files and the testbench compiled with `Errors: 0, Warnings: 0`.
   - The simulation run concluded with `Errors: 0, Warnings: 0`.
   - No unexpected compiler notices or unhandled warnings were emitted.

2. **Verification of Zero Assertion Failures**:
   - The testbench contains 25 distinct assertion statements checking:
     * Post-reset state (Phase 1, Route A Green, Route B Red, displays initialized to 25 and 28).
     * Exact phase durations for 2 consecutive cycles within +/- 20 ns tolerance.
     * Night mode 7-segment blanking ("1111111"), suppression of Green/Red lights, and 1 Hz Yellow toggling.
     * Pause mode display and output freeze over a 4 us interval, followed by smooth resumption without skipping ticks.
     * Emergency Force immediate preemption from Phase 3 (dropping Route B Green immediately to Red and granting Route A Green) and safe restoration to Phase 1.
     * Continuous concurrent invariant check: `assert not (ledg(0) = '1' and ledg(1) = '1') severity failure;` evaluating continuously across all delta cycles.
   - All 4 test scenarios passed sequentially and cleanly without triggering any assertion failures or warnings.

3. **Verification of Wave Script Integrity**:
   - All 28 signal references in `wave.do` match the instantiated module ports, internal registers, and wire names.
   - Signal radices (binary, hex, unsigned) and color encodings are appropriately assigned.
   - GUI commands are protected with `catch`, ensuring robust execution in both batch (`vsim -c`) and interactive GUI (`vsim`) modes.

---

## 3. Caveats

- **Simulation Mode Generic**: The testbench executes with generic `SIMULATION => true`, scaling 1 second to 50 clock cycles (1 us) to enable full regression testing in ~162 us. For physical FPGA synthesis, `SIMULATION` defaults to `false` (50,000,000 cycles = 1s).
- **Physical Board Testing**: Pin assignments, I/O standards (3.3-V LVTTL), and timing closure at 50 MHz on the Cyclone IV EP4CE115F29C7 kit belong to Milestone M3 (`syn/`).

---

## 4. Conclusion

**Verdict: APPROVE**

The deliverables for Milestone M2 (Verification & Simulation) meet and exceed all requirements specified in `ORIGINAL_REQUEST.md` (§R2) and `PROJECT.md`:
1. `tb/tb_traffic_light_top.vhd` thoroughly tests all functional modes, boundary durations, and continuous interlock safety with 0 assertion failures.
2. `sim/run_sim.do` cleanly automates compile, elaboration, and simulation with 0 errors and 0 warnings.
3. `sim/wave.do` provides structured signal groups with valid hierarchical paths and robust GUI/batch error handling.

Milestone M2 is fully verified and ready for sign-off.

---

## 5. Verification Method

To independently reproduce this verification:

1. In PowerShell, navigate to `c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/sim`:
   ```powershell
   vsim -c -do "do run_sim.do; quit -f"
   ```
2. Verify the transcript log confirms:
   - `Errors: 0, Warnings: 0` for all compilation steps.
   - `[SCENARIO 1] PASS: 2 full consecutive normal cycles (122 us) verified successfully.`
   - `[SCENARIO 2] PASS: Night Mode (1 Hz flash, 7-seg blanking, clean recovery) verified.`
   - `[SCENARIO 3] PASS: Pause / Hold Mode (frozen countdown, smooth resumption) verified.`
   - `[SCENARIO 4] PASS: Emergency Force Mode (immediate preemption, safe release) verified.`
   - `ALL 4 TEST SCENARIOS COMPLETED SUCCESSFULLY!`
   - `ZERO SAFETY ASSERTION VIOLATIONS DETECTED.`
   - `Errors: 0, Warnings: 0` at simulation termination.
3. Invalidation conditions:
   - Any compiler error or warning during compilation.
   - Any assertion failure during simulation.
   - Any syntax error or missing signal error in `wave.do`.
