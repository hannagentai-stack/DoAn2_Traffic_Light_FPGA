# Milestone M1 Recheck Verification Report: RTL Challenger

## 1. Observation

### Observation 1.1: Patched `to_bcd` Procedure in `timer_counter.vhd`
- **File**: `c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/rtl/timer_counter.vhd`
- **Lines 44-72**:
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

### Observation 1.2: Combinational Calling Process in `timer_counter.vhd`
- **File**: `c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/rtl/timer_counter.vhd`
- **Lines 141-150**:
```vhdl
    -- Combinational BCD Output Separation (Range Comparisons, No Division)
    process(cnt_a, cnt_b)
        variable t_a, u_a, t_b, u_b : std_logic_vector(3 downto 0);
    begin
        to_bcd(cnt_a, t_a, u_a);
        to_bcd(cnt_b, t_b, u_b);
        bcd_a_tens  <= t_a;
        bcd_a_units <= u_a;
        bcd_b_tens  <= t_b;
        bcd_b_units <= u_b;
    end process;
```

### Observation 1.3: Synchronous Sequential Countdown Process in `timer_counter.vhd`
- **File**: `c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/rtl/timer_counter.vhd`
- **Lines 77-85**:
```vhdl
    process(clk_50m, reset_n)
    begin
        if reset_n = '0' then
            cnt_a    <= 25;
            cnt_b    <= 28;
            done_reg <= '0';
        elsif rising_edge(clk_50m) then
            done_reg <= '0'; -- Default: 1-cycle pulse duration
```

### Observation 1.4: Packages & Entity Declaration
- **File**: `c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga/rtl/timer_counter.vhd`
- **Lines 18-20**:
```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
```
- No obsolete Synopsys packages (`std_logic_arith` / `std_logic_unsigned`) are included.

---

## 2. Logic Chain

### 2.1. Verification of Conversion for All 64 Values in Range 0..63
Referencing Observation 1.1:
1. The declared domain is `natural range 0 to 63` ($N = 64$ distinct integer values).
2. The conditional logic defines 7 mutually exclusive and collectively exhaustive sub-ranges:
   - **Range $[60, 63]$ (4 values: 60, 61, 62, 63)**:
     - Branch `if val >= 60`:
     - `tens_out := "0110"` (decimal 6). Exact tens digit $\lfloor val/10 \rfloor = 6$.
     - `unit_out := to_unsigned(val - 60, 4)`. For $val \in [60, 63]$, $val - 60 \in \{0, 1, 2, 3\}$. Binary: `"0000"`, `"0001"`, `"0010"`, `"0011"`. Exact units digit $val \pmod{10}$.
     - Correct: $60 \to 6, 0$; $61 \to 6, 1$; $62 \to 6, 2$; $63 \to 6, 3$.
   - **Range $[50, 59]$ (10 values: 50..59)**:
     - Branch `elsif val >= 50`:
     - `tens_out := "0101"` (decimal 5). Exact tens digit $\lfloor val/10 \rfloor = 5$.
     - `unit_out := to_unsigned(val - 50, 4)`. For $val \in [50, 59]$, $val - 50 \in [0, 9]$. Fits in 4 bits (`"0000"` to `"1001"`). Exact units digit $val \pmod{10}$.
     - Correct: $50..59 \to (5, 0)..(5, 9)$.
   - **Range $[40, 49]$ (10 values: 40..49)**:
     - Branch `elsif val >= 40`:
     - `tens_out := "0100"` (decimal 4). Exact tens digit $\lfloor val/10 \rfloor = 4$.
     - `unit_out := to_unsigned(val - 40, 4)`. For $val \in [40, 49]$, $val - 40 \in [0, 9]$. Fits in 4 bits (`"0000"` to `"1001"`). Exact units digit $val \pmod{10}$.
     - Correct: $40..49 \to (4, 0)..(4, 9)$. (Previously, Challenger 2 identified that values $40..49$ were misidentified as tens=3 and non-BCD/truncated units).
   - **Range $[30, 39]$ (10 values: 30..39)**:
     - Branch `elsif val >= 30`:
     - `tens_out := "0011"` (decimal 3), `unit_out := to_unsigned(val - 30, 4)` ($0..9$).
     - Correct: $30..39 \to (3, 0)..(3, 9)$.
   - **Range $[20, 29]$ (10 values: 20..29)**:
     - Branch `elsif val >= 20`:
     - `tens_out := "0010"` (decimal 2), `unit_out := to_unsigned(val - 20, 4)` ($0..9$).
     - Correct: $20..29 \to (2, 0)..(2, 9)$.
   - **Range $[10, 19]$ (10 values: 10..19)**:
     - Branch `elsif val >= 10`:
     - `tens_out := "0001"` (decimal 1), `unit_out := to_unsigned(val - 10, 4)` ($0..9$).
     - Correct: $10..19 \to (1, 0)..(1, 9)$.
   - **Range $[0, 9]$ (10 values: 0..9)**:
     - Branch `else`:
     - `tens_out := "0000"` (decimal 0), `unit_out := to_unsigned(val, 4)` ($0..9$).
     - Correct: $0..9 \to (0, 0)..(0, 9)$.
3. Partition union: $[0, 9] \cup [10, 19] \cup [20, 29] \cup [30, 39] \cup [40, 49] \cup [50, 59] \cup [60, 63] = [0, 63]$.
4. Sum of cardinalities: $10 + 10 + 10 + 10 + 10 + 10 + 4 = 64$.
5. **Conclusion**: Every value in $[0, 63]$ is mapped to its exact BCD tens and units representation.

### 2.2. Truncations, Numeric Warnings, and Branch Completeness
Referencing Observation 1.1:
1. Maximum argument to `to_unsigned(..., 4)`:
   - For $[60, 63]$: $\max(val - 60) = 3$.
   - For $[50, 59]$: $\max(val - 50) = 9$.
   - For $[40, 49]$: $\max(val - 40) = 9$.
   - For $[30, 39]$: $\max(val - 30) = 9$.
   - For $[20, 29]$: $\max(val - 20) = 9$.
   - For $[10, 19]$: $\max(val - 10) = 9$.
   - For $[0, 9]$: $\max(val) = 9$.
2. The global maximum integer passed to `to_unsigned(x, 4)` is $9$.
3. A 4-bit unsigned vector accommodates numbers in $0 \le x \le 15$. Because $9 < 15$, vector truncation is mathematically impossible.
4. All arguments are non-negative due to prior branch conditions.
5. Therefore, IEEE `numeric_std` will NEVER throw `NUMERIC_STD.TO_UNSIGNED: vector truncated` or range errors.
6. The `else` clause catches all remaining cases; hence there are no unhandled branches.

### 2.3. Synchronous Logic Integrity & Inferred Latches
Referencing Observations 1.2 and 1.3:
1. **Clocking & Registers**:
   - `timer_counter` registers `cnt_a`, `cnt_b`, and `done_reg` are updated exclusively on `rising_edge(clk_50m)` or asynchronous `reset_n = '0'`.
   - Single clock domain, 100% synchronous design.
2. **Combinational Output Evaluation**:
   - The process `process(cnt_a, cnt_b)` is purely combinational.
   - Inside `to_bcd`, every branch explicitly assigns both `tens_out` and `unit_out`.
   - The caller process assigns all four outputs (`bcd_a_tens`, `bcd_a_units`, `bcd_b_tens`, `bcd_b_units`) unconditionally on every trigger.
   - Sensitivity list `(cnt_a, cnt_b)` includes all signals read within the process.
   - Number of inferred latches: Exactly 0.

---

## 3. Caveats
- No caveats. The patch is minimal, cleanly architected, uses no hardware division operators, complies with IEEE 1164/numeric_std, and completely resolves Challenger 2's defect report across all 64 possible counter values.

---

## 4. Conclusion & Verdict

**Verdict**: **APPROVE**

- The `to_bcd` procedure in `timer_counter.vhd` has been verified exhaustively for all 64 integer values ($0 \le val \le 63$).
- Tens and units outputs match $val / 10$ and $val \pmod{10}$ with 100% precision.
- No vector truncation warnings or illegal BCD nibbles can occur.
- Combinational logic is 100% latch-free, and sequential countdown logic is 100% synchronous.
- Challenger 2's defect report is completely resolved.

---

## 5. Verification Method

### Independent Verification Procedure:
1. **Source Code Inspection**:
   - File: `traffic_light_fpga/rtl/timer_counter.vhd`, lines 50-71.
   - Verify that branches for $\ge 60$, $\ge 50$, and $\ge 40$ are present in descending order before $\ge 30, \ge 20, \ge 10$, and `else`.
2. **Boundary Value Equivalence Check**:
   - Test $val = 39$: Falls into `val >= 30` $\to$ tens = `"0011"` (3), units = $39 - 30 = 9$ (`"1001"`).
   - Test $val = 40$: Falls into `val >= 40` $\to$ tens = `"0100"` (4), units = $40 - 40 = 0$ (`"0000"`).
   - Test $val = 46$: Falls into `val >= 40` $\to$ tens = `"0100"` (4), units = $46 - 40 = 6$ (`"0110"`). (Previously truncated 16 to 0).
   - Test $val = 50$: Falls into `val >= 50` $\to$ tens = `"0101"` (5), units = $50 - 50 = 0$ (`"0000"`).
   - Test $val = 60$: Falls into `val >= 60` $\to$ tens = `"0110"` (6), units = $60 - 60 = 0$ (`"0000"`).
   - Test $val = 63$: Falls into `val >= 60` $\to$ tens = `"0110"` (6), units = $63 - 60 = 3$ (`"0011"`). (Previously truncated 33 to 1).
3. **Invalidation Condition**:
   - Any value $val \in [0, 63]$ generating `tens_out` $\ne \lfloor val / 10 \rfloor$ or `unit_out` $\ne val \pmod{10}$, or any simulator numeric truncation warning. (None found; test coverage is 100%).
