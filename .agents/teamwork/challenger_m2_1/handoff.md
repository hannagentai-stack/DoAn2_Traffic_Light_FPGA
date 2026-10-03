# Milestone M2 Adversarial Verification Report: Challenger 1

**Verdict**: **CHALLENGE_FAILED**  
**Agent**: Challenger 1 (`challenger_m2_1`)  
**Target Milestone**: M2 (Verification & Simulation)  
**Date**: 2026-10-01T18:25:00Z  

---

## Executive Summary

As EMPIRICAL CHALLENGER, I conducted an adversarial review and stress testing of the testbench stimulus and simulation scripts for Milestone M2:
- Target files: `traffic_light_fpga/tb/tb_traffic_light_top.vhd`, `traffic_light_fpga/sim/run_sim.do`, `traffic_light_fpga/sim/wave.do`.
- Under the testbench's current stimulus, normal LED transitions and high-level scenario sequencing execute without assertion failures in ModelSim 2020.1.
- **However, critical coverage gaps exist in counter boundary validation and timing fidelity**:
  1. **Counter Boundary Blindness (MAJOR GAP)**: Across both full 61 us normal traffic cycles (122 us simulation), the testbench contains **zero assertions on `HEX0..HEX3` or counter boundary values**. It fails to check if counters reach 1 prior to transition, fails to check if reload values (Phase 2: 3/3, Phase 3: 33/30, Phase 4: 3/3) are loaded, and fails to check BCD rollover.
  2. **1-Clock Cycle Pipeline Reload Skew**: Empirical stress-testing revealed that because `timer_counter` registers `load_phase` synchronously while FSM state/lamp transitions occur combinationally on the state clock edge, the 7-segment displays show the *old* phase count for 1 clock cycle (20 ns) after the lamps change. The testbench completely masked this behavior because it never checked counter outputs at transitions.
  3. **Night Mode Blink Timing Unverified**: Night mode yellow flashing is sampled asynchronously without checking the 1 Hz frequency or 50% duty cycle (500 ns HIGH / 500 ns LOW). A waveform oscillating at 50 MHz or with 90% duty cycle would erroneously pass the testbench.
  4. **Emergency Hold & Recovery Truncation**: Emergency Force is held for only 3.0 us (< 1/8 of a normal Phase 1 duration), counter values are unmonitored during emergency, and the test terminates only 2.0 us after emergency release without verifying that Phase 1 counts down or completes.

Because the testbench stimulus fails to verify counter boundary conditions and timing specifications mandated by ORIGINAL_REQUEST R1/R2, the verdict is **CHALLENGE_FAILED**.

---

## 1. Observation

### 1.1. Codebase & Configuration Inspected
1. `traffic_light_fpga/tb/tb_traffic_light_top.vhd` (409 lines)
2. `traffic_light_fpga/sim/run_sim.do` (60 lines)
3. `traffic_light_fpga/sim/wave.do` (68 lines)
4. RTL dependencies: `traffic_light_fpga/rtl/*.vhd`

### 1.2. Direct Verbatim Code Observations

#### Observation 1: Total Absence of Counter Assertions during Normal Cycles
In `traffic_light_fpga/tb/tb_traffic_light_top.vhd`, Scenario 1 covers lines 137 to 245.
Inspecting lines 141–189 (Cycle 1):
```vhdl
141:         -- === CYCLE 1 === --
142:         -- Cycle 1 - Phase 1 (25s)
143:         t_phase_start := now;
144:         report "  [Cycle 1 - Phase 1] Route A Green (25s), Route B Red (28s)";
145:         assert (ledg(0) = '1' and ledr(2) = '1' and ledg(1) = '0' and ledr(0) = '0')
146:             report "FAIL: Cycle 1 Phase 1 lights invalid at start!" severity failure;
147:         
148:         -- Wait until transition to Phase 2 (Route A Yellow goes HIGH)
149:         wait until rising_edge(clk_50m) and ledr(1) = '1';
150:         t_phase_dur := now - t_phase_start;
151:         assert (t_phase_dur >= 24980 ns and t_phase_dur <= 25020 ns)
152:             report "FAIL: Cycle 1 Phase 1 duration not 25 us!" severity failure;
...
```
- In all 108 lines of Scenario 1 (Cycle 1 and Cycle 2), `hex0`, `hex1`, `hex2`, and `hex3` are never referenced.
- There are no assertions checking:
  - Phase 1 expiration boundary: Route A = 01, Route B = 04.
  - Phase 2 reload: Route A = 03, Route B = 03.
  - Phase 2 expiration boundary: Route A = 01, Route B = 01.
  - Phase 3 reload: Route A = 33, Route B = 30.
  - Phase 3 expiration boundary: Route A = 04, Route B = 01.
  - Phase 4 reload: Route A = 03, Route B = 03.
  - Phase 4 expiration boundary: Route A = 01, Route B = 01.
  - Phase 1 return reload: Route A = 25, Route B = 28.

#### Observation 2: Night Mode Lacks Period / Duty Cycle Verification
In `traffic_light_fpga/tb/tb_traffic_light_top.vhd` (lines 267–288):
```vhdl
267:         -- Verify Yellow LEDs toggle at 1 Hz (500 ns ON, 500 ns OFF in sim)
268:         -- Sample HIGH phase
269:         wait until rising_edge(clk_50m) and ledr(1) = '1';
270:         assert (ledr(3) = '1')
271:             report "FAIL: Route B Yellow not synchronized with Route A Yellow in Night Mode!"
272:             severity failure;
273:         assert (ledg(0) = '0' and ledg(1) = '0' and ledr(0) = '0' and ledr(2) = '0')
274:             report "FAIL: Non-yellow LEDs active during Night Mode flash HIGH phase!"
275:             severity failure;
276: 
277:         -- Sample LOW phase
278:         wait until rising_edge(clk_50m) and ledr(1) = '0';
279:         assert (ledr(3) = '0')
280:             report "FAIL: Route B Yellow did not turn OFF during Night Mode flash LOW phase!"
281:             severity failure;
282: 
283:         -- Sample HIGH phase again to confirm periodic square wave
284:         wait until rising_edge(clk_50m) and ledr(1) = '1';
285:         assert (ledr(3) = '1')
286:             report "FAIL: Night Mode flash failed second period cycle!"
287:             severity failure;
```
- No duration variables (`now - t_start`) are used to check the half-period or full-period timing.
- Because `wait until rising_edge(clk_50m) and ledr(1) = '1'` does not require a prior LOW phase, if `sw(0)` is asserted when `blink_1hz` is already '1', the process immediately evaluates line 269 on the next rising clock edge, capturing a partial pulse rather than a full pulse.

#### Observation 3: Emergency Preemption Tested during Phase 3 Green
In `traffic_light_fpga/tb/tb_traffic_light_top.vhd` (lines 357–377):
```vhdl
357:         -- Fast-forward until Phase 3 is active (Route B Green, Route A Red)
358:         report "  -> Waiting for Phase 3 (Route B Green, Route A Red)...";
359:         wait until rising_edge(clk_50m) and ledg(1) = '1' and ledr(0) = '1';
360:         report "  -> Confirmed Phase 3 active. Route B has Green, Route A has Red.";
361: 
362:         -- Wait 2 us into Phase 3
363:         wait for 2.0 us;
364:         assert (ledg(1) = '1' and ledr(0) = '1' and ledg(0) = '0' and ledr(2) = '0')
365:             report "FAIL: Expected Phase 3 steady state before Emergency assertion!"
366:             severity failure;
367: 
368:         -- Assert Emergency Pushbutton (active-low)
369:         report "  -> Pressing Emergency Pushbutton (KEY(1) = '0')...";
370:         key(1) <= '0';
371:         wait for 100 ns;
372: 
373:         -- Verify immediate preemption: Route A gets Green, Route B gets Red
374:         assert (ledg(0) = '1' and ledr(2) = '1' and ledg(1) = '0' and ledr(0) = '0')
375:             report "FAIL: Emergency Force failed to immediately preempt Route B to Red and grant Route A Green!"
376:             severity failure;
```
- The test explicitly waits for `ledg(1) = '1'` (Route B Green, Route A Red) before asserting `key(1) <= '0'`.
- The conflicting route (Route B) is indeed Green when Emergency Force is triggered.

#### Observation 4: Empirical Discovery of 1-Cycle Pipeline Reload Latency
When an empirical stress harness was constructed with BCD decoding checking `HEX0..HEX3` at `wait until rising_edge(clk_50m) and ledr(1) = '1'`:
```
# ** Note: [TEST 2] Phase 1 boundary right before expiration: A=1, B=4
#    Time: 24170 ns  Iteration: 1  Instance: /tb_adversarial_m2
# ** Note: [TEST 3] Phase 2 at ledr(1)='1': A=1, B=3 at time 25190 ns
#    Time: 25190 ns  Iteration: 1  Instance: /tb_adversarial_m2
# ** Failure: FAIL: Phase 2 reload expected A=3, B=3!
#    Time: 25190 ns  Iteration: 1  Process: /tb_adversarial_m2/line__111 File: tb_adversarial_m2.vhd
```
- At the transition clock edge (25190 ns), `ledr(1)` becomes '1', but `cnt_a` is still 1 and `cnt_b` is 3.
- Only after 1 additional clock cycle (25210 ns) do `cnt_a` and `cnt_b` reload to 3 and 3.

---

## 2. Logic Chain

1. **Premise 1 (R1 & R2 Contract)**: ORIGINAL_REQUEST §R1 and §R2 demand that `timer_counter` automatically reloads per phase, separates values into BCD tens and units for 7-segment decoders, and that the testbench performs comprehensive verification across all operational phases.
2. **Premise 2 (Observation 1)**: `tb_traffic_light_top.vhd` asserts `hex0..hex3` only at time 180 ns during initial reset. During the 122 us of normal traffic cycles, not a single assertion inspects `hex0..hex3` or counter values.
3. **Inference 1**: The testbench is blind to any counter corruption, reload failure, wrong phase duration preload, or BCD decoder error during normal traffic transitions.
4. **Premise 3 (Observation 4)**: In empirical execution, checking the counter at `ledr(1) = '1'` revealed a 1-clock-cycle pipeline latency between the combinational lamp change and the synchronous counter reload in `timer_counter.vhd`.
5. **Inference 2**: Because the testbench omitted counter checks, this pipeline behavior was never exposed or validated. A rigorous testbench should explicitly check the pre-expiration boundary (`cnt = 1`) and the post-reload value (`cnt = reload_value` after synchronous load).
6. **Premise 4 (Observation 2)**: The Night Mode check does not measure pulse durations, meaning an incorrect clock divider modulus or duty cycle would pass silently.
7. **Conclusion**: The testbench stimulus has significant blind spots in counter boundary testing and blink frequency verification. The testbench does not satisfy comprehensive verification criteria.

---

## 3. Specific Question Answers

### Q1: Are test durations sufficient to observe full phase transitions without race conditions?
- **Duration Assessment**: **YES for nominal cycles; WEAK for stress modes.**
  - The simulation runs for 200 us (`run 200 us` in `run_sim.do`).
  - Two full 61 us cycles take 122 us (completed at 122.19 us).
  - All 4 scenarios finish by 162.5 us.
  - Phase durations are strictly verified within ±20 ns tolerances (25 us, 3 us, 30 us, 3 us).
  - **Weakness**: Emergency hold is only 3 us (compared to 25 us Phase 1). Recovery wait is only 2 us (does not verify subsequent phase progression).
- **Race Condition Assessment**: **CLEAN.**
  - Stimulus input transitions (`key`, `sw`) occur at 40 ns, 100 ns, and 200 ns offsets, which are aligned to falling edges or mid-cycle points of the 20 ns master clock.
  - No setup or hold timing violations occur with respect to `clk_50m`.

### Q2: Does the testbench test boundary values of counters during transitions?
- **Finding**: **NO (CRITICAL OMISSION).**
  - The testbench contains zero assertions on `hex0..hex3` or counter boundary values during any phase transition.
  - It does not check:
    - Decrement down to 1 before transition.
    - Clamping at 1 (preventing underflow to 0 or 63).
    - Reload values upon phase entry (3, 33, 30, 25, 28).
    - Asymmetry between Route A and Route B during Phase 1 (when A=1, B=4) and Phase 3 (when B=1, A=4).

### Q3: Is Emergency Force tested while the conflicting route is actually Green?
- **Finding**: **YES.**
  - In Scenario 4 (lines 357–377), the testbench waits for Phase 3 (`ledg(1) = '1'` and `ledr(0) = '1'`), where Route B is Green and Route A is Red.
  - Emergency Force is asserted while Route B is Green.
  - Preemption is verified: Route B drops immediately to Red (`ledr(2) = '1'`), and Route A receives Green (`ledg(0) = '1'`).
  - **Limitation**: Emergency Force is not tested from Phase 2 or Phase 4 (Yellow clearance states).

### Q4: Is Night Mode tested for both blinking and blanking?
- **Finding**: **PARTIALLY (TIMING UNVERIFIED).**
  - Blanking is verified: `hex0..hex3 = "1111111"` at entry, and `hex0 /= "1111111"` at exit.
  - Blinking synchronization is verified: Yellow A and Yellow B toggle together while Green and Red remain OFF.
  - **Omission**: Blink frequency (1 Hz) and duty cycle (500 ns ON / 500 ns OFF) are never measured or asserted. Asynchronous entry leads to truncated first HIGH pulses.

---

## 4. Caveats

1. The underlying RTL design (`traffic_light_top.vhd`, `clk_divider.vhd`, `timer_counter.vhd`, `fsm_controller.vhd`) is fundamentally sound: our empirical stress harness confirmed that when properly timed (waiting 1 clock cycle for synchronous reload), all reload values, boundary values, blink periods (500 ns / 500 ns), and 30 us emergency hold operations execute correctly.
2. The 1-clock-cycle delay between lamp transition and counter reload is 20 ns in hardware (50 MHz clock), which is invisible to human observers on physical 7-segment displays. However, in rigorous RTL testbenches, this boundary behavior must be explicitly modeled and asserted.

---

## 5. Conclusion & Actionable Recommendations

**Verdict**: **CHALLENGE_FAILED**

### Required Action Items for Milestone M2 Testbench Hardening:
1. **Add Counter Boundary Checks to Scenario 1**:
   - Prior to each phase transition, assert that the expiring route's counter is at 1 (e.g. `assert hex0 = "1111001" and hex1 = "1000000"` for Route A = 01).
   - After the transition clock edge + 1 clock cycle, assert that counters reload to the correct phase initial values (Phase 2: A=03, B=03; Phase 3: A=33, B=30; Phase 4: A=03, B=03; Phase 1: A=25, B=28).
2. **Add Blink Period & Duty Cycle Timing to Scenario 2**:
   - Synchronize to a clean falling edge of yellow (`ledr(1) = '0'`), then measure `t_high` and `t_low`.
   - Assert `t_high >= 480 ns and t_high <= 520 ns` and `t_low >= 480 ns and t_low <= 520 ns`.
3. **Extend Emergency Force Validation in Scenario 4**:
   - Verify counter behavior during Emergency Force.
   - Verify that upon release of Emergency Force, Phase 1 counters reload to 25 and 28, and verify normal decrement resumption.

---

## 6. Verification Method

### Test Procedure to Independently Reproduce Findings:
1. Run the existing simulation script:
   ```powershell
   cd c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/sim
   vsim -c -do "do run_sim.do; quit -f"
   ```
2. Search `traffic_light_fpga/tb/tb_traffic_light_top.vhd` for references to `hex` between lines 137 and 245. Observe **0 occurrences**.
3. Inspect `tb_traffic_light_top.vhd` lines 267–288 and observe the lack of any timing measurement variables (`t_high`, `t_low`, `t_phase_dur`) for Night Mode blinking.
4. Add an assertion for `hex0` at line 150 of `tb_traffic_light_top.vhd` (`assert hex0 = "0110000"` for digit '3'). Observe that it fails on the immediate clock edge because the reload takes 1 clock cycle to register.
