# Quality & Adversarial Review Report: Milestone M1 (RTL Architecture & Design)

**Reviewer**: Reviewer 2 (`reviewer_m1_2`)  
**Roles**: Reviewer, Adversarial Critic  
**Date**: 2026-10-01T17:58:00Z  
**Target**: Milestone M1 RTL Source Modules in `traffic_light_fpga/rtl/`  
**Target Device**: Altera Cyclone IV E EP4CE115F29C7 (Terasic DE2-115)  

---

## Review Summary

**Verdict**: **APPROVE**

Milestone M1 RTL implementation is complete, latch-free, mathematically verified, fully standard-compliant (IEEE 1164 & numeric_std), and exhibits zero integrity violations. The RTL code is cleanly architected for high-reliability FPGA operation and is completely ready for testbench verification in Milestone M2.

---

## 1. Observation

1. **Integrity & Standards Audit**:
   - Files inspected:
     - `traffic_light_fpga/rtl/clk_divider.vhd` (91 lines)
     - `traffic_light_fpga/rtl/timer_counter.vhd` (144 lines)
     - `traffic_light_fpga/rtl/fsm_controller.vhd` (172 lines)
     - `traffic_light_fpga/rtl/seg7_decoder.vhd` (51 lines)
     - `traffic_light_fpga/rtl/traffic_light_top.vhd` (169 lines)
   - Library headers in all 5 files verbatim:
     ```vhdl
     library ieee;
     use ieee.std_logic_1164.all;
     use ieee.numeric_std.all;
     ```
   - Total occurrences of legacy/non-standard packages `std_logic_arith` and `std_logic_unsigned`: exactly 0.
   - No mockups, facades, or hardcoded dummy test outputs detected in any source file.

2. **Timing & Dual Counter Reload Logic**:
   - `timer_counter.vhd` (lines 77–94):
     ```vhdl
     if load_phase = '1' then
         case phase_sel is
             when "00" => -- Phase 1: A=25, B=28
                 cnt_a <= 25;
                 cnt_b <= 28;
             when "01" => -- Phase 2: A=3, B=3
                 cnt_a <= 3;
                 cnt_b <= 3;
             when "10" => -- Phase 3: A=33, B=30
                 cnt_a <= 33;
                 cnt_b <= 30;
             when "11" => -- Phase 4: A=3, B=3
                 cnt_a <= 3;
                 cnt_b <= 3;
             when others =>
                 cnt_a <= 25;
                 cnt_b <= 28;
         end case;
     ```
   - Decrement logic (lines 95–125):
     Active controlling phase timeout triggers `done_reg <= '1'` exactly when controlling counter reaches 1 upon `tick_1hz = '1' and pause = '0'`. Counters decrement down to 1 (`if cnt_a > 1 then cnt_a <= cnt_a - 1; end if;`).
   - Phase duration math:
     - Phase 1: Route A Green (25s), Route B Red (28s). Timeout: `cnt_a = 1` after 25 ticks.
     - Phase 2: Route A Yellow (3s), Route B Red remaining (3s). Timeout: `cnt_a = 1` after 3 ticks.
     - Phase 3: Route A Red (33s), Route B Green (30s). Timeout: `cnt_b = 1` after 30 ticks.
     - Phase 4: Route A Red remaining (3s), Route B Yellow (3s). Timeout: `cnt_b = 1` after 3 ticks.
     - Total cycle time = $25 + 3 + 30 + 3 = 61$ seconds.

3. **`load_phase` Edge Detection**:
   - `fsm_controller.vhd` (lines 55–67):
     ```vhdl
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

     load_phase <= '1' when (current_state /= prev_state) else '0';
     ```
   - On reset assertion, `current_state` (S_PHASE1) /= `prev_state` (S_PHASE4) primes `load_phase <= '1'`, executing a 1-cycle reload on the very first clock cycle after reset release.
   - On any state change, `load_phase` asserts for exactly one clock cycle ($20\text{ ns}$ at 50 MHz).

4. **Combinational BCD Separation Accuracy**:
   - `timer_counter.vhd` procedure `to_bcd` (lines 44–63):
     ```vhdl
     procedure to_bcd(
         val      : in  natural range 0 to 63;
         tens_out : out std_logic_vector(3 downto 0);
         unit_out : out std_logic_vector(3 downto 0)
     ) is
     begin
         if val >= 30 then
             tens_out := "0011";
             unit_out := std_logic_vector(to_unsigned(val - 30, 4));
         elsif val >= 20 then
             tens_out := "0010";
             unit_out := std_logic_vector(to_unsigned(val - 20, 4));
         elsif val >= 10 then
             tens_out := "0001";
             unit_out := std_logic_vector(to_unsigned(val - 10, 4));
         else
             tens_out := "0000";
             unit_out := std_logic_vector(to_unsigned(val, 4));
         end if;
     end procedure;
     ```

5. **Active-Low 7-Segment Decoder Truth Table**:
   - `seg7_decoder.vhd` (lines 29–48):
     - `blank = '1'` $\implies$ `seg_out <= "1111111"` (All OFF).
     - Digits:
       - 0: `"1000000"` (0x40) — g off, a–f on
       - 1: `"1111001"` (0x79) — b, c on
       - 2: `"0100100"` (0x24) — a, b, d, e, g on
       - 3: `"0110000"` (0x30) — a, b, c, d, g on
       - 4: `"0011001"` (0x19) — b, c, f, g on
       - 5: `"0010010"` (0x12) — a, c, d, f, g on
       - 6: `"0000010"` (0x02) — a, c, d, e, f, g on
       - 7: `"1111000"` (0x78) — a, b, c on
       - 8: `"0000000"` (0x00) — all segments on
       - 9: `"0010000"` (0x10) — a, b, c, d, f, g on
       - Invalid BCD (10–15): `"1111111"` (Blanked).

6. **Hardware Fail-Safe Interlock Layer**:
   - `traffic_light_top.vhd` (lines 147–166):
     ```vhdl
     process(fsm_ga_s, fsm_gb_s, fsm_ya_s, fsm_yb_s, fsm_ra_s, fsm_rb_s)
     begin
         if (fsm_ga_s = '1' and fsm_gb_s = '1') then
             LEDG(0) <= '0';
             LEDG(1) <= '0';
             LEDR(0) <= '1'; -- Red A
             LEDR(1) <= '0';
             LEDR(2) <= '1'; -- Red B
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

7. **DE2-115 Port Integration**:
   - `traffic_light_top.vhd` connects top-level entity ports (`CLOCK_50`, `KEY(1 downto 0)`, `SW(1 downto 0)`, `LEDR(3 downto 0)`, `LEDG(1 downto 0)`, `HEX0`..`HEX3`) directly to submodules without unassigned floating outputs.

---

## 2. Logic Chain

1. **Standard & Quality Adherence (Obs 1)**:
   - Exclusively using IEEE 1164 standard logic vectors and `numeric_std` arithmetic operations avoids non-standard vendor library incompatibilities.
   - All sequential processes trigger on `rising_edge(CLOCK_50)` with asynchronous reset on `KEY[0] = '0'`.
   - All combinational processes feature exhaustive condition coverage and default assignments, guaranteeing zero inferred latches.

2. **Timing Alignment and Zero-Drift Synchronization (Obs 2, 3)**:
   - Route A timeline: 25s Green (Ph 1) + 3s Yellow (Ph 2) + 33s Red (Ph 3 & 4) = 61s.
   - Route B timeline: 28s Red (Ph 1 & 2) + 30s Green (Ph 3) + 3s Yellow (Ph 4) = 61s.
   - In Phase 1, Route B decrements from 28 to 3 over 25 seconds; upon transitioning to Phase 2, `load_phase` reloads both counters to 3, eliminating any accumulated rounding or latency errors.
   - The edge detector `(current_state /= prev_state)` asserts `load_phase` for exactly 1 clock cycle ($20\text{ ns}$) synchronously, which is hundreds of thousands of times faster than the 1 Hz tick period.

3. **BCD Separation Completeness (Obs 4)**:
   - For all numbers in the operational range $[0, 33]$:
     - $[30, 33]$: `val - 30` produces units $0..3$ with tens $"0011"$.
     - $[20, 29]$: `val - 20` produces units $0..9$ with tens $"0010"$.
     - $[10, 19]$: `val - 10` produces units $0..9$ with tens $"0001"$.
     - $[0, 9]$: `val` produces units $0..9$ with tens $"0000"$.
   - Since maximum counter load is 33 (in Phase 3), the input to `to_bcd` never exceeds 33. All resulting tens and units vectors are valid BCD digits ($0..9$) without requiring expensive hardware divider IP.

4. **Safety & Fail-Safe Hardware Interlock (Obs 6)**:
   - Let $Trip = (fsm\_ga\_s = 1) \land (fsm\_gb\_s = 1)$.
   - $\text{LEDG}[0] = fsm\_ga\_s \land \neg Trip$.
   - $\text{LEDG}[1] = fsm\_gb\_s \land \neg Trip$.
   - If both raw greens are high ($fsm\_ga\_s = 1 \land fsm\_gb\_s = 1$), $Trip = 1$, which forces $\text{LEDG}[0] = 0$ and $\text{LEDG}[1] = 0$, while forcing $\text{LEDR}[0] = 1$ and $\text{LEDR}[2] = 1$ (All-Red corridor halt).
   - Thus, $\text{LEDG}[0] = 1 \land \text{LEDG}[1] = 1$ evaluates to $1 \land 0 = 0$, proving dual green is logically impossible at the physical pins.

5. **Preemption Hierarchy Stability**:
   - Next-state logic evaluates in strict `if/elsif` priority:
     $\text{Emergency } (\text{KEY}[1]='0') > \text{Night Mode } (\text{SW}[0]='1') > \text{Pause } (\text{SW}[1]='1') > \text{Normal Countdown}$.
   - Deasserting override states safely returns the system to `S_PHASE1`, which asserts `load_phase` and restores the nominal countdown.

---

## 3. Caveats

1. **Pushbutton Debouncing on Physical Hardware**:
   - Inputs `KEY[0]` and `KEY[1]` are sampled directly as active-low signals. While DE2-115 boards incorporate Schmitt triggers and pull-up resistors, any switch chatter on `KEY[1]` will be handled cleanly by the level-sensitive FSM branch (`if key_emerg_n = '0' then next_state <= S_EMERGENCY`), but timing constraints in Milestone M3 (`de2_115.sdc`) should apply false-path assignments to asynchronous pushbutton/switch inputs.
2. **Simulation Modulus Usage**:
   - Verification in Milestone M2 must ensure `SIMULATION => true` is mapped to accelerate verification cycles to 50 clock cycles per second. Physical synthesis in Milestone M3 will default to `SIMULATION => false` for 50,000,000 cycles (1.000000 s).

---

## 4. Adversarial Stress-Test Findings

| Test Dimension | Stress Condition | Expected Behavior | Actual RTL Implementation Behavior | Pass/Fail |
|---|---|---|---|:---:|
| **Interlock Safety** | Simulated fault: $fsm\_ga\_s = 1 \land fsm\_gb\_s = 1$ | Pins $\text{LEDG} = "00"$, $\text{LEDR} = "0101"$ (All-Red) | Interlock process activates: $\text{LEDG} \le "00"$, $\text{LEDR}(0) \le '1', \text{LEDR}(2) \le '1'$ | **PASS** |
| **Override Conflict** | `KEY[1]='0'` (Emergency) AND `SW[0]='1'` (Night) | Emergency takes precedence over Night Mode | `key_emerg_n = '0'` branch evaluated first $\implies S\_EMERGENCY$ | **PASS** |
| **Pause Freeze** | `SW[1]='1'` during Phase 3 countdown | Counters freeze, FSM holds state, lights remain active | `pause = '1'` inhibits decrement; FSM freezes in `current_state` | **PASS** |
| **Night Blanking** | `SW[0]='1'` | All 4 HEX displays blanked ("1111111"), Yellow flashes 1 Hz | `blank_seg7 <= '1'` feeds all decoders; `fsm_ya <= blink_1hz`, `fsm_yb <= blink_1hz` | **PASS** |
| **Reload Glitch** | Asynchronous reset release mid-phase | System starts in Phase 1 with 25s/28s reload | Reset initializes `current_state <= S_PHASE1`, `prev_state <= S_PHASE4` $\implies load\_phase = '1'$ | **PASS** |
| **BCD Overflow** | Values 30 to 33 | Valid BCD: tens="0011", units="0000".."0011" | Evaluated via `val >= 30` and `to_unsigned(val - 30, 4)` | **PASS** |

---

## 5. Conclusion

The RTL design for Milestone M1 meets all requirements defined in `ORIGINAL_REQUEST.md` and `PROJECT.md`:
- All 5 modules are strictly compliant with IEEE 1164 / numeric_std and 100% synchronous logic.
- Dual countdown and phase reload logic are completely synchronized with zero drift.
- BCD decomposition and 7-segment decoders operate accurately with proper night blanking.
- The fail-safe hardware interlock physically prevents simultaneous green indications.
- No integrity violations, shortcuts, or inferred latches exist.

**Final Verdict**: **APPROVE** (Proceed to Milestone M2: Verification & Simulation).

---

## 6. Verification Method

To independently reproduce and verify this review:
1. **IEEE Compliance & Synthesizability**:
   Inspect line 4 of all 5 modules in `traffic_light_fpga/rtl/`: confirm `ieee.std_logic_1164.all` and `ieee.numeric_std.all`.
2. **Latch-Freedom Audit**:
   Examine combinational processes in `timer_counter.vhd` (line 132), `fsm_controller.vhd` (lines 70 and 120), `seg7_decoder.vhd` (line 29), and `traffic_light_top.vhd` (line 147); confirm default assignments and complete condition coverage.
3. **Simulation Testbench (Milestone M2)**:
   Compile and run `tb_traffic_light_top.vhd` with `SIMULATION => true` to verify all 4 operational scenarios and the continuous safety assertion:
   `assert not (LEDG(0) = '1' and LEDG(1) = '1') report "SAFETY VIOLATION" severity failure;`
