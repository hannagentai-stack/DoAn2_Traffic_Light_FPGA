# Handoff Report: Review & Adversarial Critique of Milestone M2 (Verification & Simulation)

**Reviewer**: `reviewer_m2_2` (Reviewer 2, Reviewer & Adversarial Critic)  
**Date**: 2026-10-01T18:17:00Z  
**Target Milestone**: Milestone M2 (Verification & Simulation)  
**Target Artifacts**:
- `traffic_light_fpga/tb/tb_traffic_light_top.vhd`
- `traffic_light_fpga/sim/wave.do`
- `traffic_light_fpga/sim/run_sim.do`
- `.agents/teamwork/worker_m2_sim/handoff.md`  
**Verdict**: **APPROVE**  

---

## 1. Observation

### 1.1. Integrity & Authenticity Audit
A thorough inspection of `traffic_light_top.vhd`, submodules, `tb_traffic_light_top.vhd`, and `wave.do` confirms:
- **No hardcoded test results**: The testbench actively drives 50 MHz clock cycles, asserts asynchronous reset, drives stimulus lines `sw` and `key`, and continuously evaluates DUT physical pins (`ledg`, `ledr`, `hex0..hex3`).
- **No dummy or facade logic**: All RTL entities implement genuine IEEE 1164 and `numeric_std` compliant logic.
- **Genuine verification**: The testbench uses VHDL `assert ... severity failure` statements that will actively terminate execution upon any unexpected output or timing violation.
- **No fabricated verification**: Upstream simulation output transcript verbatim matches the printouts and timings configured in `tb_traffic_light_top.vhd`.

### 1.2. Verification of Continuous Safety Assertion
In `traffic_light_fpga/tb/tb_traffic_light_top.vhd`, lines 80–86:
```vhdl
    ----------------------------------------------------------------------------
    -- 3. Continuous Concurrent Safety Check
    --    Guarantees that Route A and Route B never have Green simultaneously!
    ----------------------------------------------------------------------------
    assert not (ledg(0) = '1' and ledg(1) = '1')
        report "CRITICAL SAFETY VIOLATION: Both Route A and Route B have GREEN light simultaneously!"
        severity failure;
```
- **Type**: Concurrent VHDL assertion placed in the architecture declarative/statement body.
- **Sensitivity**: Automatically sensitive to changes on `ledg(0)` and `ledg(1)` across all simulation delta cycles.
- **Severity**: `severity failure` ensures immediate simulation halt if triggered.
- **Hardware Layer Backing**: In `traffic_light_fpga/rtl/traffic_light_top.vhd` lines 147–166, the hardware interlock enforces:
  ```vhdl
  if (fsm_ga_s = '1' and fsm_gb_s = '1') then
      LEDG(0) <= '0';
      LEDG(1) <= '0';
      LEDR(0) <= '1';
      LEDR(1) <= '0';
      LEDR(2) <= '1';
      LEDR(3) <= '0';
  ```
  This mathematically guarantees that `ledg(0) = '1' and ledg(1) = '1'` cannot occur at the output pins under any condition.

### 1.3. Verification of Test Scenarios in `tb_traffic_light_top.vhd`
1. **Scenario 1: 2 Full Consecutive Normal Cycles (122 $\mu\text{s}$)** (lines 132–245):
   - Clock period = 20 ns ($50\text{ MHz}$). With `SIMULATION => true`, 1 second = 50 clock cycles = 1000 ns = 1.0 $\mu\text{s}$.
   - **Cycle 1**:
     - Phase 1 (25s Green A / 28s Red B): Checked from start (180 ns) to transition at $25190\text{ ns}$ ($\Delta t = 25010\text{ ns} \approx 25\ \mu\text{s}$). Assertion: `t_phase_dur >= 24980 ns and t_phase_dur <= 25020 ns`.
     - Phase 2 (3s Yellow A / 3s Red B): Checked to transition at $28190\text{ ns}$ ($\Delta t = 3000\text{ ns} = 3\ \mu\text{s}$). Assertion: `t_phase_dur >= 2980 ns and t_phase_dur <= 3020 ns`.
     - Phase 3 (33s Red A / 30s Green B): Checked to transition at $58190\text{ ns}$ ($\Delta t = 30000\text{ ns} = 30\ \mu\text{s}$). Assertion: `t_phase_dur >= 29980 ns and t_phase_dur <= 30020 ns`.
     - Phase 4 (3s Red A / 3s Yellow B): Checked to transition at $61190\text{ ns}$ ($\Delta t = 3000\text{ ns} = 3\ \mu\text{s}$). Assertion: `t_phase_dur >= 2980 ns and t_phase_dur <= 3020 ns`.
     - Total Cycle 1 duration = $61010\text{ ns} \approx 61\ \mu\text{s}$.
   - **Cycle 2**:
     - Repeated identical timing checks for Phase 1 ($25\ \mu\text{s}$), Phase 2 ($3\ \mu\text{s}$), Phase 3 ($30\ \mu\text{s}$), Phase 4 ($3\ \mu\text{s}$). Total Cycle 2 = $61\ \mu\text{s}$.
     - Total duration for 2 cycles = $122010\text{ ns} \approx 122\ \mu\text{s}$.
     - Confirmed clean return to Phase 1: `assert (ledg(0) = '1' and ledr(2) = '1')`.

2. **Scenario 2: Night Mode (`SW(0) = '1'`)** (lines 246–302):
   - Asserted `sw(0) <= '1'`, waited 200 ns.
   - Asserted 7-segment blanking: `hex0 = "1111111" and hex1 = "1111111" and hex2 = "1111111" and hex3 = "1111111"`.
   - Asserted all Greens and Reds OFF: `ledg(0)='0' and ledg(1)='0' and ledr(0)='0' and ledr(2)='0'`.
   - Sampled Yellow LEDs (`ledr(1)` and `ledr(3)`) across rising edges: verified synchronous HIGH phase (`ledr(1)='1' and ledr(3)='1'`) and LOW phase (`ledr(1)='0' and ledr(3)='0'`), confirming 1 Hz square wave flashing.
   - Deasserted `sw(0) <= '0'`, waited 200 ns, verified clean return to Phase 1 and unblanking of displays.

3. **Scenario 3: Pause / Hold Mode (`SW(1) = '1'`)** (lines 303–347):
   - Allowed Phase 1 to count down for 5.0 $\mu\text{s}$.
   - Asserted `sw(1) <= '1'`, captured frozen state into variables (`frozen_hex0..3`, `frozen_ledg`, `frozen_ledr`).
   - Waited 4.0 $\mu\text{s}$ (4 simulated seconds) during active pause.
   - Asserted `hex0 = frozen_hex0 and hex1 = frozen_hex1 and hex2 = frozen_hex2 and hex3 = frozen_hex3` and `ledg = frozen_ledg and ledr = frozen_ledr`.
   - Deasserted `sw(1) <= '0'`, waited 2.0 $\mu\text{s}$, confirmed resumption of countdown (`hex0 /= frozen_hex0 or hex1 /= frozen_hex1`).

4. **Scenario 4: Emergency Force Mode (`KEY(1) = '0'`)** (lines 348–394):
   - Waited for Phase 3: `wait until rising_edge(clk_50m) and ledg(1) = '1' and ledr(0) = '1'`.
   - Waited 2.0 $\mu\text{s}$ to establish steady Phase 3 operation.
   - Asserted active-low emergency button: `key(1) <= '0'`.
   - Within 100 ns, verified immediate preemption: Route A gets Green (`ledg(0)='1'`), Route B Green is revoked (`ledg(1)='0'`), Route B gets Red (`ledr(2)='1'`).
   - Maintained emergency hold for 3.0 $\mu\text{s}$, verifying steady corridor.
   - Released `key(1) <= '1'`, waited 200 ns, verified clean return to Phase 1.

### 1.4. Waveform Configuration in `traffic_light_fpga/sim/wave.do`
Line-by-line inspection of `wave.do` reveals 6 clearly defined logical groups matching specifications:
- **Group 1: CLOCKS & RESET** (lines 10–15): `clk_50m` (Yellow), `key(0)` (Red), `tick_1hz_s` (Cyan), `blink_1hz_s` (Orange).
- **Group 2: CONTROL INPUTS** (lines 17–21): `sw(0)` (Magenta), `sw(1)` (Blue), `key(1)` (Red).
- **Group 3: FSM STATE** (lines 23–29): `current_state` (Gold), `next_state` (Orange), `phase_sel_s` (White, binary radix), `load_phase_s` (Cyan), `timer_done_s` (Yellow).
- **Group 4: TIMERS & BCD** (lines 31–38): `cnt_a` (Green, unsigned radix), `cnt_b` (Cyan, unsigned radix), `bcd_a_tens_s`, `bcd_a_units_s`, `bcd_b_tens_s`, `bcd_b_units_s` (White, hex radix).
- **Group 5: ROUTE A & B LIGHTS** (lines 40–49):
  - Route A: `ledg(0)` (Green), `ledr(1)` (Yellow), `ledr(0)` (Red).
  - Route B: `ledg(1)` (Green), `ledr(3)` (Yellow), `ledr(2)` (Red).
- **Group 6: HEX DISPLAYS** (lines 51–57): `blank_seg7_s` (Pink), `hex1`, `hex0`, `hex3`, `hex2` (Gray, hexadecimal radix).

---

## 2. Logic Chain

1. **R1 / R2 Specification Conformance**:
   - ORIGINAL_REQUEST §R2 mandates testbench coverage of 2 consecutive normal cycles, Night Mode, Pause/Hold, Emergency Force, and a continuous interlock safety assertion.
   - As observed in §1.2 and §1.3, `tb_traffic_light_top.vhd` explicitly includes all five requirements with rigorous self-checking assertions and strict tolerance windows ($\pm 20\text{ ns}$ = 1 clock cycle).
2. **Timing Accuracy**:
   - In simulation mode (`SIMULATION => true`), clock frequency = 50 MHz ($T = 20\text{ ns}$), modulus = 50 clock cycles, yielding $1.0\ \mu\text{s}$ per simulated second.
   - Cycle 1 duration measured $61.01\ \mu\text{s}$ and Cycle 2 measured $61.00\ \mu\text{s}$, giving exactly $122.01\ \mu\text{s}$ for the two cycles.
   - Phase durations strictly conform to the 25s/3s/30s/3s cycle definition.
3. **Safety Guarantee**:
   - The concurrent assertion `assert not (ledg(0) = '1' and ledg(1) = '1') severity failure` runs throughout the entire simulation lifecycle.
   - In addition, the hardware interlock in `traffic_light_top.vhd` lines 147–166 independently monitors FSM lamp lines and drops both greens to '0' while raising all reds if an illegal state ever occurs.
4. **Tool Compatibility & Robustness**:
   - `wave.do` wraps GUI-only commands in `catch { ... }`, preventing script termination when executed in non-interactive batch mode (`vsim -c`).
   - `run_sim.do` dynamically resolves path context whether run from `sim/` or repository root.
5. **Conclusion Derivation**:
   - Because all 4 scenarios, safety assertions, and waveform visual groupings meet the project requirements without any detected error or violation, Milestone M2 is fully verified and ready for sign-off.

---

## 3. Adversarial Critique & Stress Analysis

### 3.1. Challenge 1: Cross-Mode Priority Inversion
- **Assumption**: The FSM priority hierarchy must prevent conflict if Emergency Force (`KEY[1] = '0'`) is triggered during Night Mode (`SW[0] = '1'`).
- **Attack Scenario**: An emergency vehicle arrives while the intersection is in Night Caution blinking mode.
- **RTL Behavior**: In `fsm_controller.vhd` lines 75–80:
  ```vhdl
  if key_emerg_n = '0' then
      next_state <= S_EMERGENCY;
  elsif sw_night = '1' then
      next_state <= S_NIGHT;
  ```
  `KEY[1]` (Emergency) is evaluated prior to `SW[0]` (Night Mode). Emergency preempts Night Mode immediately, granting Route A Green and Route B Red.
- **Verdict**: PASS. Priority ordering is optimal for civil safety.

### 3.2. Challenge 2: Pause Resumption Drift & Off-By-One Loss
- **Assumption**: Toggling Pause/Hold (`SW[1]`) must not lose or duplicate a clock tick in `timer_counter`.
- **Attack Scenario**: Asserting `pause = '1'` right at the tick edge could cause a missed decrement or counter glitch.
- **RTL Behavior**: `timer_counter.vhd` lines 104–134 decrements on `tick_1hz = '1' and pause = '0'`. When paused, the clock continue ticking but register assignments are disabled. Upon unpausing, counting resumes on the next natural `tick_1hz` pulse without asynchronous register corruption.
- **Verdict**: PASS. Fully synchronous gating prevents runt pulses and drift.

### 3.3. Challenge 3: Segment Display Blanking Integrity
- **Assumption**: In Night Mode, active-low 7-segment displays must completely de-energize to prevent ghost digits.
- **Attack Scenario**: Incomplete blanking could leave residual segments lit.
- **RTL Behavior**: `seg7_decoder.vhd` line 32 sets `seg_out <= "1111111"` unconditionally when `blank = '1'`. All four decoders (`HEX0`..`HEX3`) are connected to `blank_seg7_s`. In testbench lines 258–260, all four displays are verified to equal `"1111111"`.
- **Verdict**: PASS. Full hardware blanking verified.

---

## 4. Review Summary

### 4.1. Verdict
**APPROVE**

Milestone M2 deliverables (`tb_traffic_light_top.vhd`, `run_sim.do`, `wave.do`) meet all requirements specified in `ORIGINAL_REQUEST.md`, `PROJECT.md`, and `TEST_INFRA.md`.

### 4.2. Verified Claims
- **Scenario 1 (2 Normal Cycles)**: Verified 122 $\mu\text{s}$ duration, exact phase progressions (25s, 3s, 30s, 3s) with $\pm 20\text{ ns}$ bounds.
- **Scenario 2 (Night Mode)**: Verified 1 Hz synchronized yellow blinking, "1111111" active-low blanking across `HEX0`..`HEX3`, and clean recovery to Phase 1.
- **Scenario 3 (Pause/Hold)**: Verified freeze of countdown displays and lamps across 4 $\mu\text{s}$ pause, and resumption of decrementing.
- **Scenario 4 (Emergency Force)**: Verified immediate preemption of Phase 3 Route B Green to Route A Green within 100 ns, held for 3 $\mu\text{s}$, and safe release to Phase 1.
- **Continuous Safety Assertion**: Verified concurrent `assert not (ledg(0)='1' and ledg(1)='1')` with `severity failure`.
- **Waveform Structure**: Verified 6 functional groups with color formatting and explicit radices.

### 4.3. Findings
- None (0 Critical, 0 Major, 0 Minor). The verification suite is clean, structured, and compliant.

---

## 5. Verification Method

To independently reproduce this verification:
1. Open PowerShell in `traffic_light_fpga/sim`:
   ```powershell
   vsim -c -do "do run_sim.do; quit -f"
   ```
2. Inspect the console transcript:
   - Check compilation logs for 0 errors and 0 warnings.
   - Confirm all four scenarios log `PASS`.
   - Confirm transcript outputs: `ALL 4 TEST SCENARIOS COMPLETED SUCCESSFULLY!` and `ZERO SAFETY ASSERTION VIOLATIONS DETECTED.`
3. Invalidation Conditions:
   - Any assertion failure or unexpected termination.
   - Occurrence of `ledg(0) = '1' and ledg(1) = '1'`.
   - Phase durations drifting outside the $\pm 20\text{ ns}$ margin.
