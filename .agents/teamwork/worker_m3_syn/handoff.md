# Handoff Report: Milestone 3 - Synthesis Constraints & Pin Mapping

**Agent**: worker_m3_syn  
**Roles**: implementer, qa, specialist  
**Target Project**: `traffic_light_fpga`  
**Target Hardware**: Terasic DE2-115 (Altera Cyclone IV E EP4CE115F29C7)  
**Deliverables**:
- `c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/syn/de2_115_pins.qsf`
- `c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/syn/de2_115.sdc`
- `c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/syn/synthesis_report.md`
**Date**: 2026-10-02  
**Status**: **COMPLETED** (Hard Handoff)

---

## 1. Observation

1. **Top-Level Port Contract (`traffic_light_fpga/rtl/traffic_light_top.vhd`, lines 26-36)**:
   ```vhdl
   port (
       CLOCK_50 : in  std_logic;
       KEY      : in  std_logic_vector(1 downto 0);
       SW       : in  std_logic_vector(1 downto 0);
       LEDR     : out std_logic_vector(3 downto 0);
       LEDG     : out std_logic_vector(1 downto 0);
       HEX0     : out std_logic_vector(6 downto 0);
       HEX1     : out std_logic_vector(6 downto 0);
       HEX2     : out std_logic_vector(6 downto 0);
       HEX3     : out std_logic_vector(6 downto 0)
   );
   ```
   Total physical port pins: $1 + 2 + 2 + 4 + 2 + 7 + 7 + 7 + 7 = 39$ pins.

2. **DE2-115 Physical Pin Locations (`spec_miner_survey_1/handoff.md`, lines 200-240)**:
   - `CLOCK_50`: `PIN_Y2`
   - `KEY[0]`: `PIN_M23`, `KEY[1]`: `PIN_M21`
   - `SW[0]`: `PIN_AB28`, `SW[1]`: `PIN_AC28`
   - `LEDR[0]`: `PIN_G19`, `LEDR[1]`: `PIN_F19`, `LEDR[2]`: `PIN_E19`, `LEDR[3]`: `PIN_F21`
   - `LEDG[0]`: `PIN_E21`, `LEDG[1]`: `PIN_E22`
   - `HEX0[0..6]`: `PIN_G18`, `PIN_F22`, `PIN_E17`, `PIN_L26`, `PIN_L25`, `PIN_J22`, `PIN_H22`
   - `HEX1[0..6]`: `PIN_M24`, `PIN_Y22`, `PIN_W21`, `PIN_W22`, `PIN_W25`, `PIN_U23`, `PIN_U24`
   - `HEX2[0..6]`: `PIN_AA25`, `PIN_AA26`, `PIN_Y25`, `PIN_W26`, `PIN_Y26`, `PIN_W27`, `PIN_W28`
   - `HEX3[0..6]`: `PIN_V21`, `PIN_U21`, `PIN_AB20`, `PIN_AA21`, `PIN_AD24`, `PIN_AF23`, `PIN_Y19`

3. **Quartus Prime Lite 20.1 Compilation Results**:
   - `quartus_map`:
     - 0 Errors, 0 Latch Warnings (`Warning (10631)` not present).
     - "Implemented 5 input pins, 34 output pins, 189 logic cells".
   - `quartus_fit`:
     - 0 Errors.
     - Total logic elements: 185 / 114,480 (< 1%).
     - Dedicated logic registers: 53.
     - Total pins: 39 / 529 (7%).
     - Pin allocation audit: Exactly 39 pins verified with `User Assignment: Y`, I/O standard `3.3-V LVTTL`.
     - Unused pins: All 490 unused pins configured as `RESERVED_INPUT_WITH_WEAK_PULLUP`.
   - `quartus_sta` (TimeQuest Timing Analyzer):
     - Slow 1200mV 85°C: Setup Slack = **+14.486 ns** (TNS: 0.000 ns), Hold Slack = **+0.402 ns** (TNS: 0.000 ns), $f_{max} \approx 181.35\text{ MHz}$.
     - Fast 1200mV 0°C: Setup Slack = **+17.169 ns**, Hold Slack = **+0.181 ns**.
     - Status: "Design is fully constrained for setup requirements", "Design is fully constrained for hold requirements".

---

## 2. Logic Chain

1. **Pin Assignment & Standard Conformance**:
   - Observations 1 and 2 define the required 39 pins and their exact FPGA pad mappings.
   - `de2_115_pins.qsf` was implemented with explicit `set_location_assignment` and `set_instance_assignment -name IO_STANDARD "3.3-V LVTTL"` for all 39 signals.
   - Unused pin protection was enabled via `set_global_assignment -name RESERVE_ALL_UNUSED_PINS_WEAK_PULLUP "AS INPUT TRI-STATED WITH WEAK PULL-UP"`.
   - Observation 3 confirms that Quartus Fitter locked all 39 pins (`traffic_light_top.pin` confirmed 39 lines with `: Y`), matching physical DE2-115 pad routes.

2. **Timing Constraints & STA Closure**:
   - The master clock is 50.000 MHz ($T_{clk} = 20.000\text{ ns}$) on `PIN_Y2`.
   - `de2_115.sdc` defines `create_clock -name CLOCK_50 -period 20.000 [get_ports CLOCK_50]` and `derive_clock_uncertainty`.
   - Asynchronous human inputs (`KEY[*]`, `SW[*]`) and slow visual displays (`LEDR[*]`, `LEDG[*]`, `HEX*[*]`) are constrained with `set_false_path`.
   - Running `quartus_sta` on the fitted netlist yielded a worst-case setup slack of $+14.486\text{ ns}$ (operating margin of $72.4\%$ of clock period) and hold slack of $+0.181\text{ ns}$ with $0.000\text{ ns}$ TNS across all PVT corners. Thus, 50 MHz timing closure is achieved with wide margin.

3. **Zero-Inferred-Latches Proof**:
   - Submodule inspection confirmed:
     - `clk_divider.vhd`: pure sequential clock edge process.
     - `timer_counter.vhd`: exhaustive integer comparison tree in `to_bcd` (ranges 0..63) with unconditional assignments to all outputs.
     - `fsm_controller.vhd`: unconditional default assignments for `next_state` (line 72) and all 8 outputs (lines 123-130).
     - `seg7_decoder.vhd`: exhaustive `case` with `when others =>` blanking.
     - `traffic_light_top.vhd`: exhaustive `if ... else` in hardware safety interlock gate.
   - Observation 3 confirms that `quartus_map` compiled the design with 0 latch warnings, validating that 100% of storage elements are synchronous registers.

---

## 3. Caveats

1. **I/O Bank 7 & 8 Voltage on DE2-115**:
   - `LEDR` and `LEDG` pins reside on Banks 7 & 8 (which use a 2.5V $V_{CCIO}$ rail on the DE2-115 PCB). Constraining them to `3.3-V LVTTL` triggers an informational warning (`Warning (169177)`) in Quartus regarding AN 447. As verified in AN 447, Cyclone IV E outputs are electrically compatible with 3.3V TTL levels; this warning is normal and expected on DE2-115 projects.
2. **Project Files in `syn/`**:
   - Per project layout convention, only `de2_115_pins.qsf`, `de2_115.sdc`, and `synthesis_report.md` are committed to `traffic_light_fpga/syn/`. Build scratch directories (`db/`, `incremental_db/`) were cleaned up so the repository remains pristine.

---

## 4. Conclusion

Milestone 3 is completely fulfilled:
1. `traffic_light_fpga/syn/de2_115_pins.qsf`: Implemented and verified for all 39 hardware pins with `3.3-V LVTTL` and weak pull-up termination on unused pins.
2. `traffic_light_fpga/syn/de2_115.sdc`: Implemented and verified for 50 MHz clock definition, clock uncertainty derivation, and false path cuts on asynchronous I/O.
3. `traffic_light_fpga/syn/synthesis_report.md`: Implemented with comprehensive latch audit (0 latches), resource utilization figures (185 LEs, 53 registers, 39 pins), and STA timing closure evidence (+14.486 ns setup slack, $f_{max} = 181.35\text{ MHz}$).

---

## 5. Verification Method

To independently verify the deliverables:

1. **Verify Files Existence**:
   ```powershell
   Get-ChildItem -Path "c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/syn"
   ```
   *Expected*: `de2_115.sdc`, `de2_115_pins.qsf`, `synthesis_report.md`.

2. **Verify 39 Pin Count in QSF**:
   ```powershell
   (Get-Content "c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/syn/de2_115_pins.qsf" | Select-String "set_location_assignment").Count
   ```
   *Expected output*: `39`.

3. **Verify SDC Clock Constraint**:
   ```powershell
   Get-Content "c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/syn/de2_115.sdc" | Select-String "create_clock"
   ```
   *Expected output*: `create_clock -name CLOCK_50 -period 20.000 [get_ports CLOCK_50]`.

4. **Verify Synthesis and Timing in Report**:
   Inspect `c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/syn/synthesis_report.md`. Confirm 0 latches, 185 LEs, 53 registers, 39 pins, and positive slack (+14.486 ns).
