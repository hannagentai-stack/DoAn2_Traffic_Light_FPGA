# Forensic Integrity Audit Report: Milestone M2 (Verification & Simulation)

**Auditor**: `auditor_m2_1` (Forensic Integrity Auditor)  
**Roles**: critic, specialist, auditor  
**Date**: 2026-10-01T18:29:00Z  
**Target Project**: `traffic_light_fpga` (Altera Cyclone IV E EP4CE115F29C7 / Terasic DE2-115)  
**Integrity Mode**: `development` (per `ORIGINAL_REQUEST.md` line 10)  
**Verdict**: **CLEAN** (Zero Integrity Violations)

---

## 1. Observation

### 1.1. Delivered Deliverables & File Signatures
The forensic audit inspected the following deliverables and simulation artifacts:
1. `c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/tb/tb_traffic_light_top.vhd` (409 lines, 19,888 bytes)
2. `c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/sim/run_sim.do` (60 lines, 1,849 bytes)
3. `c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/sim/wave.do` (68 lines, 3,853 bytes)
4. `c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/sim/transcript` (194 lines, 10,141 bytes)
5. `c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/sim/vsim.wlf` (172,032 bytes, ModelSim binary Waveform Log File)
6. `c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/sim/work/` (ModelSim compiled library directory containing `_info`, `_lib.qdb`, `_lib1_0.qdb`, `_lib1_0.qpg`, `_lib1_0.qtl`, `_vmake`)

### 1.2. Testbench RTL Instantiation & Signal Stimulation
In `tb/tb_traffic_light_top.vhd`:
- Lines 49–63 genuinely instantiate `dut: entity work.traffic_light_top`:
  ```vhdl
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
  ```
- No facade or mock bypass: The testbench generates a continuous 50 MHz square wave clock (`clk_gen` process, lines 68–77, `CLK_PERIOD = 20 ns`) and directly controls physical active-low pushbuttons `KEY(0)` (Reset) and `KEY(1)` (Emergency), and toggle switches `SW(0)` (Night Mode) and `SW(1)` (Pause/Hold).
- The DUT outputs (`ledg(1 downto 0)`, `ledr(3 downto 0)`, `hex0` through `hex3`) are sampled dynamically and validated against expected state encodings and timing windows.

### 1.3. Safety Invariant & Assertion Authenticity
- **Continuous Concurrent Safety Check** (`tb_traffic_light_top.vhd` lines 80–86):
  ```vhdl
  assert not (ledg(0) = '1' and ledg(1) = '1')
      report "CRITICAL SAFETY VIOLATION: Both Route A and Route B have GREEN light simultaneously!"
      severity failure;
  ```
  This assertion is declared directly in the architecture body, making it a concurrent VHDL statement sensitive to any signal transition on `ledg(0)` or `ledg(1)`. If both green indicators ever assert simultaneously, the simulator aborts immediately with `severity failure`.
- **RTL Hardware Interlock Layer** (`traffic_light_top.vhd` lines 147–166):
  ```vhdl
  process(fsm_ga_s, fsm_gb_s, fsm_ya_s, fsm_yb_s, fsm_ra_s, fsm_rb_s)
  begin
      if (fsm_ga_s = '1' and fsm_gb_s = '1') then
          LEDG(0) <= '0';
          LEDG(1) <= '0';
          LEDR(0) <= '1';
          LEDR(1) <= '0';
          LEDR(2) <= '1';
          LEDR(3) <= '0';
      else
          LEDG(0) <= fsm_ga_s;
          LEDG(1) <= fsm_gb_s;
          LEDR(0) <= fsm_ra_s;
          LEDR(1) <= fsm_ya_s;
          LEDR(2) <= fsm_rb_s;
          LEDR(3) <= fsm_yb_s;
      end if;
  end process;
  ```
  The physical top-level layer provides an active hardware barrier forcing All-Red if dual-green conditions ever arise.
- **Assertion Rigor**:
  The testbench contains 25 distinct assertion statements checking:
  * Hardware reset state: Phase 1 (Route A Green, Route B Red) and initial displays 25 and 28 (`hex1="0100100"`, `hex0="0010010"`, `hex3="0100100"`, `hex2="0000000"`).
  * Phase duration timing bounds: Phase 1 ($25\ \mu\text{s} \pm 20\text{ ns}$), Phase 2 ($3\ \mu\text{s} \pm 20\text{ ns}$), Phase 3 ($30\ \mu\text{s} \pm 20\text{ ns}$), Phase 4 ($3\ \mu\text{s} \pm 20\text{ ns}$) across 2 full consecutive cycles (122 $\mu\text{s}$).
  * Night Mode: Active blanking of all four 7-segment displays (`HEX0..3 = "1111111"`), suppression of Green/Red lamps, synchronous 1 Hz Yellow blinking, and clean recovery.
  * Pause Mode: Freezing of all 4 display digits and light outputs across $4\ \mu\text{s}$, followed by resumption of countdown without skipping ticks.
  * Emergency Force: Preemption from Phase 3 into Route A Green / Route B Red in $<100\text{ ns}$, active hold for $3\ \mu\text{s}$, and safe recovery upon release.
  * Zero instances of `assert true`, dummy flags, or trivial tautologies.

### 1.4. Simulation Execution Authenticity
Inspection of `traffic_light_fpga/sim/transcript` reveals authentic execution of ModelSim - Intel FPGA Edition 2020.1:
- Compilation timestamp: `Start time: 01:14:49 on Oct 02,2026`
- Compilation of 5 RTL files (`clk_divider.vhd`, `seg7_decoder.vhd`, `timer_counter.vhd`, `fsm_controller.vhd`, `traffic_light_top.vhd`) and `tb_traffic_light_top.vhd` with `Errors: 0, Warnings: 0`.
- Elaboration command: `vsim -t 1ns -voptargs="+acc" work.tb_traffic_light_top`.
- Authentic batch-mode notifications from ModelSim's Tcl shell:
  `# configure wave not supported in batch mode`
  `# wave zoomfull not supported in batch mode`
- Generated binary waveform log file `vsim.wlf` of size 172,032 bytes.
- Generated compiled library databases in `work/` (`_info`, `_lib.qdb`, `_lib1_0.qdb`, `_lib1_0.qpg`, `_lib1_0.qtl`, `_vmake`).

---

## 2. Logic Chain

1. **Testbench Integrity**:
   - The testbench instantiates the complete structural top-level entity `traffic_light_top` without mocking or stubs.
   - All stimulus signals (`CLOCK_50`, `KEY`, `SW`) are driven programmatically through precise event sequences.
   - The testbench measures real elapsed delta time (`t_phase_dur := now - t_phase_start`) and validates that state transitions occur within strict clock-cycle windows ($\pm 20\text{ ns}$).

2. **Assertion Veracity & Interlock Safety**:
   - The safety assertion `assert not (ledg(0)='1' and ledg(1)='1')` evaluates concurrently on every simulation delta cycle.
   - Both the Moore FSM state definitions and the top-level hardware interlock layer guarantee that dual-green illumination cannot occur.
   - Every assertion checks physical hardware signals; there are no hardcoded bypasses or facade checks.

3. **Simulation Authenticity**:
   - The simulation transcript was generated by ModelSim executing batch commands against `run_sim.do`.
   - The presence of the proprietary binary waveform log (`vsim.wlf`, 172 KB) and the compiled design database (`work/`, 350+ KB) confirms genuine tool invocation.
   - The batch execution messages (`configure wave not supported in batch mode`) confirm authentic interaction with ModelSim's Tcl interpreter.

4. **Forensic Integrity Mode Compliance**:
   - `ORIGINAL_REQUEST.md` specifies `Integrity mode: development`.
   - Phase 1 (Mode-Agnostic) check results:
     * Hardcoded test results: **None** (PASS).
     * Facade implementations: **None** (PASS).
     * Pre-populated result artifacts: **None** (PASS).
     * Delegated execution to pre-built external binaries: **None** (PASS).
   - Under Development Mode, the deliverable is 100% compliant with all integrity standards.

---

## 3. Caveats

1. **Simulation Generic Acceleration**:
   - The testbench accelerates execution by setting generic `SIMULATION => true`, reducing the 50 MHz division modulus from 50,000,000 to 50 clock cycles ($1\ \mu\text{s}$ per simulated second). This is the standard VHDL practice requested in `ORIGINAL_REQUEST.md §R1` and `§R2`. For hardware synthesis on the physical DE2-115 kit, `SIMULATION` defaults to `false` (producing real-world 1 Hz seconds).
2. **Physical Board Synthesis**:
   - Physical FPGA pin assignments (`PIN_Y2`, `PIN_M23`, etc.), 3.3-V LVTTL I/O standards, and timing closure at 50 MHz are the scope of Milestone M3 (`syn/`).

---

## 4. Conclusion

**Verdict: CLEAN**

Milestone M2 (Verification & Simulation) exhibits full integrity:
1. `tb/tb_traffic_light_top.vhd` is a genuine, comprehensive, self-checking testbench that exercises all 4 operational scenarios plus reset initialization and continuous safety interlock monitoring.
2. Assertions are rigorous, dynamic, and free of trivial or hardcoded bypasses.
3. The simulation was genuinely executed using ModelSim 2020.1, producing verified transcript logs, compiled library databases, and binary waveform artifacts with zero errors and zero warnings.

No integrity violations were detected. Milestone M2 is cleared.

---

## 5. Verification Method

To independently verify the simulation artifacts and testbench execution:

1. Open a terminal in `traffic_light_fpga/sim`:
   ```powershell
   vsim -c -do "do run_sim.do; quit -f"
   ```
2. Verify that the transcript log outputs:
   - Compilation of all 5 RTL sources and testbench with `Errors: 0, Warnings: 0`.
   - `[SCENARIO 1] PASS: 2 full consecutive normal cycles (122 us) verified successfully.`
   - `[SCENARIO 2] PASS: Night Mode (1 Hz flash, 7-seg blanking, clean recovery) verified.`
   - `[SCENARIO 3] PASS: Pause / Hold Mode (frozen countdown, smooth resumption) verified.`
   - `[SCENARIO 4] PASS: Emergency Force Mode (immediate preemption, safe release) verified.`
   - `ALL 4 TEST SCENARIOS COMPLETED SUCCESSFULLY!`
   - `ZERO SAFETY ASSERTION VIOLATIONS DETECTED.`
3. Inspect `sim/vsim.wlf` and `sim/work/` to confirm generation of waveform data and library binaries.
4. Invalidation conditions:
   - Any compiler error or warning.
   - Any assertion failure.
   - Any simultaneous illumination of `LEDG(0)` and `LEDG(1)`.
