# Forensic Audit Report: Milestone M1 (RTL Architecture & Design)

**Auditor Agent**: auditor_m1_1  
**Target Milestone**: Milestone 1 (RTL Architecture & Design)  
**Target Scope**: `c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/rtl/`  
**Profile**: General Project (VHDL FPGA RTL)  
**Date**: 2026-10-01T17:58:00Z  
**Verdict**: **CLEAN**

---

## 1. Executive Summary & Binary Verdict

| Criterion | Standard / Requirement | Finding | Status |
|:---|:---|:---|:---:|
| **Standard Package Compliance** | Strictly IEEE 1164 & numeric_std (Forbidden: `std_logic_arith`, `std_logic_unsigned`) | 0 occurrences across all 5 files | **PASS** |
| **Logic Authenticity** | Genuine implementation, 0 dummy/mock logic, 0 facade modules | 100% genuine sequential & combinational RTL | **PASS** |
| **Inferred Latch Prevention** | 100% synchronous registers, complete combinational assignments with unconditional defaults | 0 latches inferred | **PASS** |
| **Fail-Safe Interlock Integrity** | Physical hardware logic barrier preventing dual-green state | Genuine All-Red force gate at pin boundary | **PASS** |
| **DE2-115 Port Mapping** | Matches Altera DE2-115 pin specifications | Exact mapping to `CLOCK_50`, `KEY`, `SW`, `LEDR`, `LEDG`, `HEX0..HEX3` | **PASS** |

**FINAL VERDICT**: **CLEAN** (No integrity violations detected).

---

## 2. 5-Component Forensic Audit Report

### 2.1. Observation

1. **Inspection of RTL Files**:
   - Exactly 5 source files exist in `traffic_light_fpga/rtl/`:
     - `clk_divider.vhd` (91 lines)
     - `timer_counter.vhd` (144 lines)
     - `fsm_controller.vhd` (172 lines)
     - `seg7_decoder.vhd` (51 lines)
     - `traffic_light_top.vhd` (169 lines)

2. **Package Import Evidence**:
   - Exact query: `grep_search("use ieee\..*")`:
     - `traffic_light_top.vhd:19-20`:
       ```vhdl
       19: use ieee.std_logic_1164.all;
       20: use ieee.numeric_std.all;
       ```
     - `seg7_decoder.vhd:15-16`:
       ```vhdl
       15: use ieee.std_logic_1164.all;
       16: use ieee.numeric_std.all;
       ```
     - `timer_counter.vhd:19-20`:
       ```vhdl
       19: use ieee.std_logic_1164.all;
       20: use ieee.numeric_std.all;
       ```
     - `fsm_controller.vhd:21-22`:
       ```vhdl
       21: use ieee.std_logic_1164.all;
       22: use ieee.numeric_std.all;
       ```
     - `clk_divider.vhd:14-15`:
       ```vhdl
       14: use ieee.std_logic_1164.all;
       15: use ieee.numeric_std.all;
       ```
   - Searches for deprecated packages:
     - `grep_search("std_logic_arith")`: 0 results.
     - `grep_search("std_logic_unsigned")`: 0 results.
     - `grep_search("std_logic_signed")`: 0 results.

3. **Inferred Latch and Sensitivity List Analysis**:
   - `clk_divider.vhd`: Process (lines 65-85) sensitive to `(clk_50m, reset_n)`. All registers (`count_reg`, `blink_reg`, `tick_reg`) clocked on `rising_edge(clk_50m)` with asynchronous `reset_n = '0'`. No combinational process.
   - `timer_counter.vhd`:
     - Sequential process (lines 68-127) sensitive to `(clk_50m, reset_n)`. All registers (`cnt_a`, `cnt_b`, `done_reg`) clocked on `rising_edge(clk_50m)`.
     - Combinational process (lines 132-141) sensitive to `(cnt_a, cnt_b)`. Unconditionally executes `to_bcd` on both `cnt_a` and `cnt_b`, assigning `bcd_a_tens`, `bcd_a_units`, `bcd_b_tens`, `bcd_b_units` in all paths.
   - `fsm_controller.vhd`:
     - Sequential process (lines 55-64) sensitive to `(clk_50m, reset_n)`.
     - Combinational next-state process (lines 70-117) sensitive to `(current_state, key_emerg_n, sw_night, sw_pause, timer_done)`. Line 72 defines unconditional default: `next_state <= current_state;`.
     - Combinational output process (lines 120-169) sensitive to `(current_state, blink_1hz)`. Lines 123-130 provide unconditional default assignments for all 8 outputs:
       ```vhdl
       phase_sel  <= "00";
       blank_seg7 <= '0';
       fsm_ra     <= '0';
       fsm_ya     <= '0';
       fsm_ga     <= '0';
       fsm_rb     <= '0';
       fsm_yb     <= '0';
       fsm_gb     <= '0';
       ```
   - `seg7_decoder.vhd`: Combinational process (lines 29-48) sensitive to `(bcd_in, blank)`. All 16 BCD combinations (0-9 and `others`) and `blank = '1'` assign `seg_out`.
   - `traffic_light_top.vhd`: Combinational interlock process (lines 147-166) sensitive to `(fsm_ga_s, fsm_gb_s, fsm_ya_s, fsm_yb_s, fsm_ra_s, fsm_rb_s)`. Both `if` and `else` branches assign all 6 output signals (`LEDG(0..1)`, `LEDR(0..3)`).

4. **Hardware Interlock Safety Barrier Verification**:
   - `traffic_light_top.vhd` lines 147-166:
     ```vhdl
     process(fsm_ga_s, fsm_gb_s, fsm_ya_s, fsm_yb_s, fsm_ra_s, fsm_rb_s)
     begin
         if (fsm_ga_s = '1' and fsm_gb_s = '1') then
             -- Interlock tripped: Force safe All-Red condition
             LEDG(0) <= '0';
             LEDG(1) <= '0';
             LEDR(0) <= '1'; -- Red A
             LEDR(1) <= '0';
             LEDR(2) <= '1'; -- Red B
             LEDR(3) <= '0';
         else
             -- Normal transparent passthrough
             LEDG(0) <= fsm_ga_s;
             LEDG(1) <= fsm_gb_s;
             LEDR(0) <= fsm_ra_s;
             LEDR(1) <= fsm_ya_s;
             LEDR(2) <= fsm_rb_s;
             LEDR(3) <= fsm_yb_s;
         end if;
     end process;
     ```
   - Proves mathematically that `LEDG(0) = '1' and LEDG(1) = '1'` cannot occur at the output pins under any circumstance.

5. **Absence of Pre-populated Artifacts & Mock Code**:
   - `find_by_name` across `traffic_light_fpga/` shows only the 5 RTL files and no pre-existing logs, fake wave files, or dummy test outputs.

---

### 2.2. Logic Chain

1. **Absence of Prohibited Patterns**:
   - Since no pre-populated logs or test results exist, there are no fabricated verification outputs (Pattern 3).
   - Since each module contains complete logic (parameterized divider, dual countdown arithmetic, Moore FSM, 7-segment lookup, and interlock gate), there are no facade implementations (Pattern 2) or hardcoded test results (Pattern 1).
   - Since the entire design is written in standard VHDL directly addressing the DE2-115 specifications, no external pre-built black-box IP core was improperly substituted (Pattern 5).

2. **Standard Compliance Chain**:
   - Every file explicitly and exclusively imports `ieee.std_logic_1164.all` and `ieee.numeric_std.all`.
   - All arithmetic operations (`count_reg + 1`, `cnt_a - 1`, `to_unsigned`, etc.) rely solely on `ieee.numeric_std`.
   - Zero occurrences of `std_logic_arith` and `std_logic_unsigned` eliminates potential operator overloading ambiguities and synthesis warnings.

3. **Latch-Free Guarantee**:
   - Every combinational process has an exhaustive sensitivity list including every signal read inside the process.
   - Every combinational process defines either unconditional default assignments or covers all possible branches of `case`/`if-else`.
   - Every sequential process is gated by `rising_edge(clk_50m)` with asynchronous active-low reset.
   - Therefore, zero latches are inferred.

4. **Functional Soundness**:
   - Countdown timing matches requirements: Phase 1 (25s Green A / 28s Red B), Phase 2 (3s Yellow A / 3s Red B remaining), Phase 3 (33s Red A / 30s Green B), Phase 4 (3s Red A remaining / 3s Yellow B).
   - Priority hierarchy in FSM: Emergency (`KEY[1]='0'`) > Night Mode (`SW[0]='1'`) > Pause (`SW[1]='1'`) > Normal Cycle.
   - Fail-safe interlock layer intercepts any simultaneous dual-green condition directly at the physical output boundary.

---

### 2.3. Caveats

1. **Simulation vs. Hardware Clock Scaling**:
   - Generic `SIMULATION` in `clk_divider` and `traffic_light_top` scales 1-second modulus between 50 clock cycles (simulation) and 50,000,000 clock cycles (hardware synthesis). The top-level default is `SIMULATION : boolean := false`. The testbench in Milestone M2 must pass `SIMULATION => true` for rapid simulation.
2. **Pushbutton Debouncing**:
   - Inputs `KEY(1 downto 0)` are active-low pushbuttons. The DE2-115 board incorporates hardware RC/Schmitt trigger filtering on KEY pins. For RTL simulation and standard synthesis, edge sampling directly on `CLOCK_50` is sound.

---

### 2.4. Conclusion

The Milestone M1 RTL implementation in `traffic_light_fpga/rtl/` is **AUTHENTIC, COMPLIANT, FULLY IMPLEMENTED, AND LATCH-FREE**.
No integrity violations, dummy implementations, or hardcoded shortcuts exist.

**Verdict**: **CLEAN**

---

### 2.5. Verification Method

To independently verify this audit:
1. **Package Scan**:
   ```powershell
   grep -rn "std_logic_arith" traffic_light_fpga/rtl/
   grep -rn "std_logic_unsigned" traffic_light_fpga/rtl/
   ```
   *Expected*: 0 matches.
2. **Library Confirmation**:
   ```powershell
   grep -rn "use ieee" traffic_light_fpga/rtl/
   ```
   *Expected*: Exactly 2 lines per file (`ieee.std_logic_1164.all` and `ieee.numeric_std.all`).
3. **Interlock Verification**:
   Inspect `traffic_light_fpga/rtl/traffic_light_top.vhd` lines 147-166. Note the All-Red override when `(fsm_ga_s = '1' and fsm_gb_s = '1')`.
