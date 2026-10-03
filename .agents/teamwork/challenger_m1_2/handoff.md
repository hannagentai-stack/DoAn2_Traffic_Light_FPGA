# Milestone M1 Adversarial Verification Report: Challenger 2

## 1. Observation

### Observation 1.1: BCD Procedure Range Handling in `timer_counter.vhd`
- **File**: `c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/rtl/timer_counter.vhd`
- **Lines 44-63**:
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
- **Line 40-41**:
```vhdl
    signal cnt_a : natural range 0 to 63 := 25;
    signal cnt_b : natural range 0 to 63 := 28;
```

### Observation 1.2: 7-Segment Active-Low Decoder Font in `seg7_decoder.vhd`
- **File**: `c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/rtl/seg7_decoder.vhd`
- **Lines 29-48**:
```vhdl
    process(bcd_in, blank)
    begin
        if blank = '1' then
            seg_out <= "1111111"; -- Blank (All OFF)
        else
            case bcd_in is
                when "0000" => seg_out <= "1000000"; -- '0' (0x40)
                when "0001" => seg_out <= "1111001"; -- '1' (0x79)
                when "0010" => seg_out <= "0100100"; -- '2' (0x24)
                when "0011" => seg_out <= "0110000"; -- '3' (0x30)
                when "0100" => seg_out <= "0011001"; -- '4' (0x19)
                when "0101" => seg_out <= "0010010"; -- '5' (0x12)
                when "0110" => seg_out <= "0000010"; -- '6' (0x02)
                when "0111" => seg_out <= "1111000"; -- '7' (0x78)
                when "1000" => seg_out <= "0000000"; -- '8' (0x00)
                when "1001" => seg_out <= "0010000"; -- '9' (0x10)
                when others => seg_out <= "1111111"; -- Blank for invalid BCD
            end case;
        end if;
    end process;
```

### Observation 1.3: Clock Divider Modulus & Enable Pulse in `clk_divider.vhd`
- **File**: `c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/rtl/clk_divider.vhd`
- **Lines 31-85**:
```vhdl
    constant FULL_COUNT_HW  : natural := 50000000;
    constant HALF_COUNT_HW  : natural := 25000000;

    constant FULL_COUNT_SIM : natural := 50;
    constant HALF_COUNT_SIM : natural := 25;
...
        elsif rising_edge(clk_50m) then
            if count_reg = FULL_COUNT - 1 then
                count_reg <= 0;
                tick_reg  <= '1';
                blink_reg <= '1';
            elsif count_reg = HALF_COUNT - 1 then
                count_reg <= count_reg + 1;
                tick_reg  <= '0';
                blink_reg <= '0';
            else
                count_reg <= count_reg + 1;
                tick_reg  <= '0';
            end if;
        end if;
```

---

## 2. Logic Chain

### 2.1. Challenge 1: BCD Conversion (`timer_counter.vhd`)
1. **Input Domain Analysis**:
   - As observed in Observation 1.1, `to_bcd` takes parameter `val : in natural range 0 to 63;`.
   - The declared input domain is the integer range $[0, 63]$ (64 possible integer inputs).
2. **Evaluation Across All 64 Values**:
   - For $val \in [0, 9]$: Branches to `else`. `tens_out` is `"0000"`, `unit_out` is $val \in [0..9]$. Valid BCD: $00$ to $09$. **PASS**.
   - For $val \in [10, 19]$: Branches to `val >= 10`. `tens_out` is `"0001"`, `unit_out` is $val - 10 \in [0..9]$. Valid BCD: $10$ to $19$. **PASS**.
   - For $val \in [20, 29]$: Branches to `val >= 20`. `tens_out` is `"0010"`, `unit_out` is $val - 20 \in [0..9]$. Valid BCD: $20$ to $29$. **PASS**.
   - For $val \in [30, 39]$: Branches to `val >= 30`. `tens_out` is `"0011"`, `unit_out` is $val - 30 \in [0..9]$. Valid BCD: $30$ to $39$. **PASS**.
   - For $val \in [40, 63]$: There are NO branches for $val \ge 40$, $val \ge 50$, or $val \ge 60$. Consequently, all values $val \ge 40$ trigger the branch `if val >= 30 then`:
     - **Tens Output Defect**: For all $val \ge 40$, `tens_out` is locked to `"0011"` (decimal 3) instead of `"0100"` (4), `"0101"` (5), or `"0110"` (6).
     - **Illegal BCD Nibble Defect ($val \in [40, 45]$)**:
       - $val = 40 \implies unit\_out = 40 - 30 = 10 = "1010"_2$ (Illegal BCD; blanks 7-seg decoder).
       - $val = 41 \implies unit\_out = 11 = "1011"_2$ (Illegal BCD).
       - $val = 42 \implies unit\_out = 12 = "1100"_2$ (Illegal BCD).
       - $val = 43 \implies unit\_out = 13 = "1101"_2$ (Illegal BCD).
       - $val = 44 \implies unit\_out = 14 = "1110"_2$ (Illegal BCD).
       - $val = 45 \implies unit\_out = 15 = "1111"_2$ (Illegal BCD).
     - **Numeric Bit Truncation Defect ($val \in [46, 63]$)**:
       - $val = 46 \implies val - 30 = 16$.
       - In IEEE `numeric_std`, `to_unsigned(16, 4)` exceeds the capacity of 4 bits ($2^4 - 1 = 15$). Standard simulators throw numeric truncation warnings (`NUMERIC_STD.TO_UNSIGNED: vector truncated`) and truncate the upper bit, evaluating $16 \pmod{16} = 0$.
       - Thus, $val = 46$ corrupts to tens = 3, units = 0 (displays "30" instead of "46").
       - $val = 63$ evaluates to $63 - 30 = 33 \equiv 1 \pmod{16}$, displaying "31" instead of "63".
3. **Conclusion for Challenge 1**: 24 out of 64 valid values ($37.5\%$ of the declared input space) fail. This is a severe defect in the arithmetic decoding layer.

### 2.2. Challenge 2: 7-Segment Active-Low Decoding (`seg7_decoder.vhd`)
1. **Active-Low Font Verification**:
   - Target DE2-115 hardware specifies Active-Low segment driving: bit 0 corresponds to segment `a`, bit 6 to segment `g` (`seg_out(6 downto 0)` = `g, f, e, d, c, b, a`).
   - Digit 0 ("0000"): `1000000` (0x40) $\implies$ segments a,b,c,d,e,f lit ('0'), g off ('1'). Matches standard font.
   - Digit 1 ("0001"): `1111001` (0x79) $\implies$ segments b,c lit, all others off. Matches standard font.
   - Digit 2 ("0010"): `0100100` (0x24) $\implies$ segments a,b,d,e,g lit, c,f off. Matches standard font.
   - Digit 3 ("0011"): `0110000` (0x30) $\implies$ segments a,b,c,d,g lit, e,f off. Matches standard font.
   - Digit 4 ("0100"): `0011001` (0x19) $\implies$ segments b,c,f,g lit, a,d,e off. Matches standard font.
   - Digit 5 ("0101"): `0010010` (0x12) $\implies$ segments a,c,d,f,g lit, b,e off. Matches standard font.
   - Digit 6 ("0110"): `0000010` (0x02) $\implies$ segments a,c,d,e,f,g lit, b off. Matches standard font.
   - Digit 7 ("0111"): `1111000` (0x78) $\implies$ segments a,b,c lit, d,e,f,g off. Matches standard font.
   - Digit 8 ("1000"): `0000000` (0x00) $\implies$ all segments lit. Matches standard font.
   - Digit 9 ("1001"): `0010000` (0x10) $\implies$ segments a,b,c,d,f,g lit, e off. Matches standard font.
2. **Invalid BCD (10-15) and Blank Handling**:
   - `when others => seg_out <= "1111111"` guarantees that any BCD code in `"1010"` to `"1111"` outputs all segments unlit (blank).
   - `if blank = '1'` unconditionally assigns `seg_out <= "1111111"`.
   - Sensitivity list `(bcd_in, blank)` is exhaustive, all branches assign `seg_out`, and no latches are inferred. **PASS**.

### 2.3. Challenge 3: Clock Divider Modulus Math & Tick Pulse Width (`clk_divider.vhd`)
1. **Modulus Math**:
   - Hardware mode (`SIMULATION = false`):
     - `FULL_COUNT_HW = 50,000,000`. Counter counts $0$ to $49,999,999$ ($50,000,000$ states).
     - At $50\text{ MHz}$ ($T = 20\text{ ns}$): $50,000,000 \times 20\text{ ns} = 1.000000\text{ s}$.
     - `HALF_COUNT_HW = 25,000,000`. Counter counts $0$ to $24,999,999$ with `blink_reg = '1'`, then toggles to `'0'` for the remaining $25,000,000$ states.
     - Half-period = $25,000,000 \times 20\text{ ns} = 500\text{ ms}$. Exact 50.0% duty cycle. **PASS**.
   - Simulation mode (`SIMULATION = true`):
     - `FULL_COUNT_SIM = 50`. Counter counts $0$ to $49$ ($50$ states).
     - Period = $50 \times 20\text{ ns} = 1000\text{ ns} = 1.0\text{ }\mu\text{s}$.
     - `HALF_COUNT_SIM = 25`. Counter toggles `blink_reg` at state 24, yielding 25 cycles HIGH and 25 cycles LOW. Exact 50.0% duty cycle. **PASS**.
2. **Tick Pulse Width (`tick_1hz`)**:
   - `tick_reg` is asserted to `'1'` only on the cycle where `count_reg = FULL_COUNT - 1`.
   - On the immediate next cycle, `count_reg` is $0$, which falls into the `else` branch, synchronously clearing `tick_reg <= '0'`.
   - Therefore, `tick_1hz` is asserted for exactly 1 clock period ($20\text{ ns}$) every 1.0 second. **PASS**.

---

## 3. Caveats
- In the existing 4 traffic phases, the maximum timer reload value is 33s (Phase 3 Route A Red). Because 33 is $\le 39$, the system does not enter the broken range $[40, 63]$ during default operation.
- However, the architectural specification and module signature explicitly define the countdown timer capacity as `natural range 0 to 63`. If any phase duration is adjusted above 39s (e.g. extending green or red duration to 45s or 60s, well within a 6-bit counter), the BCD conversion immediately fails with illegal BCD codes and truncated arithmetic. The procedure must conform to its declared input domain.

---

## 4. Conclusion & Verdict

**Verdict**: **CHALLENGE_FAILED**

### Bug Report: Incomplete Range Decoding and Arithmetic Overflows in `to_bcd`
- **Location**: `traffic_light_fpga/rtl/timer_counter.vhd`, lines 50-62.
- **Classification**: High (Arithmetic & Interface Contract Violation).
- **Description**:
  The procedure `to_bcd` specifies `val : in natural range 0 to 63;` but only checks for $val \ge 30$, omitting cases for $val \ge 40$, $val \ge 50$, and $val \ge 60$.
  For all inputs in $40 \le val \le 63$:
  1. `tens_out` incorrectly outputs `"0011"` (3) instead of 4, 5, or 6.
  2. For $40 \le val \le 45$, `unit_out` outputs non-BCD values 10 to 15 (`"1010"` to `"1111"`), triggering display blanking.
  3. For $46 \le val \le 63$, `val - 30` evaluates to $\ge 16$, exceeding 4-bit unsigned capacity, causing numeric_std truncation warnings and display corruption.
- **Required Remediation**:
  Extend `to_bcd` with explicit comparisons for 60, 50, and 40:
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

---

## 5. Verification Method

### Test Procedure to Independently Reproduce
1. In `timer_counter.vhd`, inspect line 50. Observe `if val >= 30 then ... unit_out := std_logic_vector(to_unsigned(val - 30, 4));`.
2. Evaluate `to_bcd(40, tens, units)`:
   - `tens` evaluates to `"0011"` (3). Expected: `"0100"` (4). **Mismatch!**
   - `units` evaluates to `to_unsigned(10, 4)` = `"1010"`. Expected: `"0000"` (0). **Mismatch!**
3. Evaluate `to_bcd(46, tens, units)`:
   - `units` evaluates to `to_unsigned(16, 4)`. In IEEE numeric_std, 16 requires 5 bits, triggering `NUMERIC_STD.TO_UNSIGNED: vector truncated` and returning `"0000"`. Expected: `"0110"` (6). **Mismatch!**
4. Applying the recommended remediation restores exact 1:1 BCD conversion for all 64 values from 0 to 63 without warning or truncation.
