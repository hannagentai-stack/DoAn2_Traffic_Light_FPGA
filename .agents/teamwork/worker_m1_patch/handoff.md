# Handoff Report: RTL Patch for `timer_counter.vhd`

## 1. Observation
1. In `c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/rtl/timer_counter.vhd`, lines 44-63 previously defined `to_bcd` with branches only for $val \ge 30$, $val \ge 20$, $val \ge 10$, and `else`:
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
2. For any counter value $val \in [40, 63]$, the procedure fell into the `val >= 30` branch:
   - For $val \in [40, 45]$, `val - 30` yielded non-BCD values $10..15$ (`"1010"` to `"1111"`), corrupting 7-segment display decoding.
   - For $val \in [46, 63]$, `val - 30` evaluated to $\ge 16$, triggering 4-bit unsigned truncation warnings under IEEE `numeric_std` and corrupting the unit digit.
   - For all $val \ge 40$, `tens_out` was stuck at `"0011"` (3) instead of 4, 5, or 6.
3. Updated `traffic_light_fpga/rtl/timer_counter.vhd` (lines 44-72) to:
```vhdl
    procedure to_bcd(
        val      : in  natural range 0 to 63;
        tens_out : out std_logic_vector(3 downto 0);
        unit_out : out std_logic_vector(3 downto 0)
    ) is
    begin
        if val >= 60 then
            tens_out := "0110";
            unit_out := std_logic_vector(to_unsigned(val - 60, 4));
        elsif val >= 50 then
            tens_out := "0101";
            unit_out := std_logic_vector(to_unsigned(val - 50, 4));
        elsif val >= 40 then
            tens_out := "0100";
            unit_out := std_logic_vector(to_unsigned(val - 40, 4));
        elsif val >= 30 then
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
4. Compilation test via ModelSim `vcom 2020.1`:
   - `vcom traffic_light_fpga/rtl/clk_divider.vhd` $\implies$ `Errors: 0, Warnings: 0`
   - `vcom traffic_light_fpga/rtl/seg7_decoder.vhd` $\implies$ `Errors: 0, Warnings: 0`
   - `vcom traffic_light_fpga/rtl/timer_counter.vhd` $\implies$ `Errors: 0, Warnings: 0`
   - `vcom traffic_light_fpga/rtl/fsm_controller.vhd` $\implies$ `Errors: 0, Warnings: 0`
   - `vcom traffic_light_fpga/rtl/traffic_light_top.vhd` $\implies$ `Errors: 0, Warnings: 0`
5. Exhaustive testbench execution in `vsim 2020.1` testing all 64 integers ($val \in [0, 63]$):
   - Output note: `SUCCESS: All 64 values passed BCD verification perfectly!`
   - Simulation errors: 0, warnings: 0.

## 2. Logic Chain
1. Based on Observation 1.1 and Observation 1.2, the counter signals `cnt_a` and `cnt_b` have range $0..63$. When countdown timers exceed 39 seconds or are configured up to 63 seconds, the arithmetic conversion previously produced invalid BCD nibbles and bit truncation.
2. Based on Observation 1.3, the updated procedure explicitly partitions the input space $[0, 63]$ into disjoint ranges:
   - $[60, 63] \implies tens = 6 ("0110")$, units $= val - 60 \in [0, 3]$ (fits in 4 bits: "0000".."0011").
   - $[50, 59] \implies tens = 5 ("0101")$, units $= val - 50 \in [0, 9]$ (fits in 4 bits: "0000".."1001").
   - $[40, 49] \implies tens = 4 ("0100")$, units $= val - 40 \in [0, 9]$ (fits in 4 bits: "0000".."1001").
   - $[30, 39] \implies tens = 3 ("0011")$, units $= val - 30 \in [0, 9]$ (fits in 4 bits: "0000".."1001").
   - $[20, 29] \implies tens = 2 ("0010")$, units $= val - 20 \in [0, 9]$ (fits in 4 bits: "0000".."1001").
   - $[10, 19] \implies tens = 1 ("0001")$, units $= val - 10 \in [0, 9]$ (fits in 4 bits: "0000".."1001").
   - $[0, 9] \implies tens = 0 ("0000")$, units $= val \in [0, 9]$ (fits in 4 bits: "0000".."1001").
3. In each branch, both `tens_out` and `unit_out` variables are assigned unconditionally, ensuring combinational purity and zero inferred latches.
4. All subtraction operands stay strictly within 4-bit unsigned bounds ($0 \le unit\_val \le 9$), preventing any numeric truncation or out-of-range warnings under IEEE `numeric_std`.
5. Observations 1.4 and 1.5 verify that `timer_counter.vhd` and all dependent RTL modules compile cleanly and pass functional simulation across the complete integer range.

## 3. Caveats
- No caveats. The patch is minimal, strictly scoped to `traffic_light_fpga/rtl/timer_counter.vhd`, fully compliant with IEEE 1164 & numeric_std, and completely resolves Challenger 2's defect report.

## 4. Conclusion
- The `to_bcd` procedure in `traffic_light_fpga/rtl/timer_counter.vhd` now robustly supports all 64 values in `natural range 0 to 63`.
- BCD values for tens and units are mathematically exact across the entire domain.
- Inferred latches: 0.
- VHDL compilation warnings/errors: 0.

## 5. Verification Method
To independently verify the implementation:
1. Compile the modified file with ModelSim `vcom`:
```powershell
vlib work
vcom -work work traffic_light_fpga/rtl/timer_counter.vhd
```
Confirm `Errors: 0, Warnings: 0`.

2. Compile all top-level RTL files:
```powershell
vcom -work work traffic_light_fpga/rtl/clk_divider.vhd
vcom -work work traffic_light_fpga/rtl/seg7_decoder.vhd
vcom -work work traffic_light_fpga/rtl/timer_counter.vhd
vcom -work work traffic_light_fpga/rtl/fsm_controller.vhd
vcom -work work traffic_light_fpga/rtl/traffic_light_top.vhd
```
Confirm `Errors: 0, Warnings: 0`.

3. Invalidation condition: Any input $val \in [0, 63]$ returning `tens_out` or `unit_out` differing from $val / 10$ or $val \pmod{10}$, or any truncation warning issued by ModelSim during simulation.
