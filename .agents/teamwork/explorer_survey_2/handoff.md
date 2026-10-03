# Handoff Report: RTL Architecture & FSM Design Specification

**Agent**: explorer_survey_2 (RTL Architecture & FSM Explorer)  
**Date**: 2026-10-01T17:39:00Z  
**Target Project**: `traffic_light_fpga` (Altera Cyclone IV E EP4CE115F29C7 / Terasic DE2-115)  
**Integrity Mode**: development  

---

## 1. Observation

Direct observations from authoritative user request (`c:/Users/handa/OneDrive/Documents/Projects/DoAn2/.agents/teamwork/ORIGINAL_REQUEST.md`):

1. **RTL Standard & Synchronous Design Constraints (Lines 14–15)**:
   > "Toàn bộ mã nguồn RTL VHDL tuân thủ chuẩn IEEE 1164 và numeric_std (nghiêm cấm `std_logic_arith` và `std_logic_unsigned`), thiết kế logic đồng bộ 100%, triệt tiêu hoàn toàn Inferred Latches."
2. **Clock Divider Requirements (Line 16)**:
   > "`clk_divider.vhd`: Chia tần số từ `CLOCK_50` (50 MHz, chân `Y2`) xuống 1 Hz và tạo xung nhấp nháy 1 Hz. Có generic `SIMULATION : boolean := false` để chia chu kỳ ngắn khi chạy mô phỏng."
3. **Timer / Counter Requirements (Line 17)**:
   > "`timer_counter.vhd`: Bộ đếm lùi thời gian đồng bộ cho 2 tuyến, tự động reload thời gian đếm tương ứng với từng pha của FSM, tách giá trị đếm thành 2 số BCD 4-bit (`tens`, `units`) cấp cho bộ giải mã 7 đoạn."
4. **FSM Controller & Operational Modes (Lines 18–26)**:
   > "- Phase 1: Tuyến A Xanh (25s), Tuyến B Đỏ (28s).  
   > - Phase 2: Tuyến A Vàng (3s), Tuyến B Đỏ (3s còn lại).  
   > - Phase 3: Tuyến A Đỏ (33s), Tuyến B Xanh (30s).  
   > - Phase 4: Tuyến A Đỏ (3s còn lại), Tuyến B Vàng (3s).  
   > - Night Mode (`SW[0] = '1'`): Cả 2 tuyến nhấp nháy đèn Vàng ở tần số 1 Hz.  
   > - Pause/Hold (`SW[1] = '1'`): Giữ nguyên trạng thái và dừng bộ đếm lùi.  
   > - Emergency Force (`KEY[1]` active-low): Kích hoạt chuyển ngay sang luồng ưu tiên khẩn cấp.  
   > - Interlock Safety: Khóa logic đảm bảo tuyệt đối không xuất tín hiệu Xanh cho cả 2 tuyến cùng lúc trong bất kỳ trạng thái nào."
5. **Seven-Segment Decoder Requirements (Line 27)**:
   > "`seg7_decoder.vhd`: Giải mã BCD (0-9) sang LED 7 đoạn Cathode chung (Active-Low: '0' sáng, '1' tắt), tự động tắt (blank) toàn bộ LED 7 đoạn khi ở Night Mode."
6. **Top-Level Integration & Hardware Pin Mappings (Lines 28, 40–46)**:
   > "`traffic_light_top.vhd`: Top-level module kết nối các module con, ánh xạ đúng tên port chuẩn DE2-115 (`CLOCK_50`, `KEY`, `SW`, `LEDR`, `LEDG`, `HEX0`..`HEX3`)."  
   > "`CLOCK_50` -> PIN_Y2"  
   > "`KEY[0]` -> PIN_M23, `KEY[1]` -> PIN_M21"  
   > "`SW[0]` -> PIN_AB28, `SW[1]` -> PIN_AC28"  
   > "`LEDR[0..3]` và `LEDG[0..1]`"  
   > "`HEX0`, `HEX1`, `HEX2`, `HEX3` (mỗi HEX 7 bit `[0..6]`)."  
   > Interlock assertion condition: "`LEDG[0] = '1' and LEDG[1] = '1'`".

---

## 2. Logic Chain

From the observed requirements, we establish the following rigorous engineering deductions:

1. **Clock Distribution & Glitch-Free Architecture**:
   - Driving register clock pins directly with divided clocks creates ripple clocking, high clock skew, and timing closure failure on FPGAs.
   - Therefore, the entire system must operate in a single synchronous clock domain on `CLOCK_50` (50.0 MHz).
   - `clk_divider.vhd` must NOT output a gated clock; instead, it outputs:
     - `tick_1hz`: A single-cycle synchronous clock enable pulse (asserted for exactly one `CLOCK_50` period every 1 second).
     - `blink_1hz`: A 50% duty cycle square wave (500 ms HIGH, 500 ms LOW) for blinking Yellow LEDs in Night Mode.
   - In simulation (`SIMULATION => true`), the divider modulus is scaled down (e.g. 50 clock cycles instead of 50,000,000 cycles) to enable rapid automated simulation without multi-million cycle delays.

2. **Phase Timing & Dual Synchronous Countdown Arithmetic**:
   - Total traffic cycle duration:
     $$\text{Cycle Duration} = T_{\text{Phase 1}} (25\text{s}) + T_{\text{Phase 2}} (3\text{s}) + T_{\text{Phase 3}} (30\text{s}) + T_{\text{Phase 4}} (3\text{s}) = 61\text{s}$$
   - Route A timeline:
     - Phase 1 (25s): Green ($t = 25 \dots 1$)
     - Phase 2 (3s): Yellow ($t = 3 \dots 1$)
     - Phase 3 (30s): Red ($t = 33 \dots 4$)
     - Phase 4 (3s): Red continued ($t = 3 \dots 1$)
     - Total Red time for Route A: $30\text{s} + 3\text{s} = 33\text{s}$.
   - Route B timeline:
     - Phase 1 (25s): Red ($t = 28 \dots 4$)
     - Phase 2 (3s): Red continued ($t = 3 \dots 1$)
     - Total Red time for Route B: $25\text{s} + 3\text{s} = 28\text{s}$.
     - Phase 3 (30s): Green ($t = 30 \dots 1$)
     - Phase 4 (3s): Yellow ($t = 3 \dots 1$)
   - Countdown Reload Strategy:
     - On Phase 1 entry: Counter A loads `25`, Counter B loads `28`.
     - On Phase 2 entry: Counter A loads `3`, Counter B loads `3` (self-correcting reload preventing cumulative drift).
     - On Phase 3 entry: Counter A loads `33`, Counter B loads `30`.
     - On Phase 4 entry: Counter A loads `3`, Counter B loads `3`.
   - On each `tick_1hz` when `pause = '0'`, active counters decrement synchronously by 1.
   - When the active phase duration expires (at counter reaching `1` on `tick_1hz`), `timer_done` is pulsed high for 1 clock cycle to trigger the FSM next-state transition.

3. **BCD Separation**:
   - Maximum countdown value is 33.
   - BCD separation can be implemented combinatorially without resource-heavy division or remainder operators using explicit range comparison and subtraction:
     - If $val \ge 30$: Tens = `"0011"`, Units = $val - 30$.
     - If $val \ge 20$: Tens = `"0010"`, Units = $val - 20$.
     - If $val \ge 10$: Tens = `"0001"`, Units = $val - 10$.
     - Else: Tens = `"0000"`, Units = $val$.
   - This translates to simple 4-input LUT logic with zero timing delay and 100% deterministic synthesis.

4. **FSM Moore Architecture & Priority Preemption**:
   - States:
     - `S_PHASE1`: Route A Green, Route B Red
     - `S_PHASE2`: Route A Yellow, Route B Red
     - `S_PHASE3`: Route A Red, Route B Green
     - `S_PHASE4`: Route A Red, Route B Yellow
     - `S_EMERGENCY`: Emergency corridor (Route A Green, Route B Red)
     - `S_NIGHT`: Night caution (Route A Yellow blink, Route B Yellow blink, 7-seg blank)
   - Input Priority Hierarchy:
     1. Asynchronous Reset (`KEY[0] = '0'`): Forces immediate reset to `S_PHASE1`.
     2. Emergency Force (`KEY[1] = '0'`): Overrides all states; transitions to `S_EMERGENCY`.
     3. Night Mode (`SW[0] = '1'`): Transitions to `S_NIGHT`.
     4. Pause/Hold (`SW[1] = '1'`): Disables state transitions and freezes counter decrements.
     5. Normal Progression: Transitions to next sequential phase on `timer_done = '1'`.

5. **Hardware Interlock Safety Barrier (Conflict Monitor)**:
   - Observation 6 requires: `assert not (LEDG[0] = '1' and LEDG[1] = '1')`.
   - To guarantee physical safety even in the event of SEU (single-event upset), undefined states, or register corruption, an independent hardware interlock layer is placed at the final output boundary:
     - If $(\text{Green}_A = \text{'1'} \land \text{Green}_B = \text{'1'})$, the interlock overrides BOTH Greens to `'0'` and forces BOTH Reds to `'1'` (Fail-Safe All-Red).
     - Under normal operation: Signals pass through directly.
   - This provides mathematical certainty that `LEDG[0] = '1' and LEDG[1] = '1'` is physically unreachable.

6. **Active-Low 7-Segment Decoding**:
   - DE2-115 7-segment displays are active-low (cathode-common driver / common anode digit: bit = '0' lights the segment).
   - Segments are ordered `seg[6 downto 0]` matching `g, f, e, d, c, b, a`.
   - Blanking output: `"1111111"` (all segments turned off).
   - In Night Mode, the `blank` signal is asserted, forcing all 4 displays (`HEX0`..`HEX3`) to `"1111111"`.

---

## 3. Caveats

1. **Physical LED Colors on DE2-115**:
   - The DE2-115 board possesses 18 Red LEDs (`LEDR[17..0]`) and 9 Green LEDs (`LEDG[8..0]`), but no discrete Yellow LEDs.
   - As explicitly mapped in ORIGINAL_REQUEST.md:
     - Route A: Red = `LEDR[0]`, Yellow = `LEDR[1]`, Green = `LEDG[0]`
     - Route B: Red = `LEDR[2]`, Yellow = `LEDR[3]`, Green = `LEDG[1]`
2. **Switch & Key Debouncing**:
   - On the DE2-115 board, `KEY` pushbuttons are active-low debounced by hardware Schmitt triggers. In simulation and at 50 MHz clocking with 1 Hz tick enables, direct synchronous sampling of `KEY` and `SW` inputs is robust.
3. **Simulation vs Hardware Generic**:
   - The generic `SIMULATION : boolean := false` must be preserved on both `clk_divider` and `traffic_light_top` so top-level synthesis defaults to 50,000,000 cycles, while testbenches override it to `true` (50 cycles).

---

## 4. Conclusion & Module Interface Specifications

### 4.1. Structural Decomposition & Data Flow

```
                      +-------------------------------------------------------------+
                      |                      traffic_light_top                      |
                      |                                                             |
                      |  CLOCK_50, KEY(1..0), SW(1..0)                              |
                      +-------------------+-----------------------------------------+
                                          |
                      +-------------------v-------------------+
                      |              clk_divider              |
                      |  CLOCK_50 -> tick_1hz (1-cycle pulse) |
                      |           -> blink_1hz (50% toggle)   |
                      +---------+-------------------+---------+
                                |                   |
                 +--------------+                   +-------------+
                 | tick_1hz                                       | blink_1hz
                 v                                                v
      +--------------------+   phase_sel, load_phase   +--------------------+
      |                    |<--------------------------|                    |
      |   timer_counter    |        timer_done         |   fsm_controller   |
      |                    |-------------------------->|                    |
      +---------+----------+                           +---------+----------+
                |                                                |
                | BCD (Tens & Units for A and B)                 | Raw Lamp Controls
                v                                                v
      +--------------------+                           +--------------------+
      | 4x seg7_decoder    |                           | Interlock Hardware |
      | (HEX0, 1, 2, 3)    |                           | Safety Lock Gate   |
      +---------+----------+                           +---------+----------+
                |                                                |
                v                                                v
         HEX3..HEX0 Pins                                  LEDR(3..0), LEDG(1..0)
```

---

### 4.2. Exact Module Contracts & Entity Declarations

#### Module 1: `clk_divider.vhd`
- **File**: `traffic_light_fpga/rtl/clk_divider.vhd`
- **Standards**: IEEE 1164, numeric_std

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clk_divider is
    generic (
        SIMULATION : boolean := false
    );
    port (
        clk_50m   : in  std_logic;
        reset_n   : in  std_logic;
        tick_1hz  : out std_logic;
        blink_1hz : out std_logic
    );
end entity clk_divider;

architecture rtl of clk_divider is
    -- 50 MHz to 1 Hz: 50,000,000 cycles for 1 second
    constant FULL_COUNT_HW  : natural := 50000000;
    constant HALF_COUNT_HW  : natural := 25000000;
    
    -- Simulation mode: 50 cycles for 1 second (scaled 1,000,000x)
    constant FULL_COUNT_SIM : natural := 50;
    constant HALF_COUNT_SIM : natural := 25;
    
    function get_full_count(sim : boolean) return natural is
    begin
        if sim then return FULL_COUNT_SIM;
        else return FULL_COUNT_HW; end if;
    end function;
    
    function get_half_count(sim : boolean) return natural is
    begin
        if sim then return HALF_COUNT_SIM;
        else return HALF_COUNT_HW; end if;
    end function;
    
    constant FULL_COUNT : natural := get_full_count(SIMULATION);
    constant HALF_COUNT : natural := get_half_count(SIMULATION);
    
    signal count_reg : natural range 0 to FULL_COUNT - 1 := 0;
    signal blink_reg : std_logic := '0';
    signal tick_reg  : std_logic := '0';
begin
    process(clk_50m, reset_n)
    begin
        if reset_n = '0' then
            count_reg <= 0;
            blink_reg <= '0';
            tick_reg  <= '0';
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
    end process;
    
    tick_1hz  <= tick_reg;
    blink_1hz <= blink_reg;
end architecture rtl;
```

---

#### Module 2: `timer_counter.vhd`
- **File**: `traffic_light_fpga/rtl/timer_counter.vhd`
- **Standards**: IEEE 1164, numeric_std

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer_counter is
    port (
        clk_50m      : in  std_logic;
        reset_n      : in  std_logic;
        tick_1hz     : in  std_logic;
        pause        : in  std_logic;
        load_phase   : in  std_logic;
        phase_sel    : in  std_logic_vector(1 downto 0);
        timer_done   : out std_logic;
        bcd_a_tens   : out std_logic_vector(3 downto 0);
        bcd_a_units  : out std_logic_vector(3 downto 0);
        bcd_b_tens   : out std_logic_vector(3 downto 0);
        bcd_b_units  : out std_logic_vector(3 downto 0)
    );
end entity timer_counter;

architecture rtl of timer_counter is
    signal cnt_a : natural range 0 to 63 := 25;
    signal cnt_b : natural range 0 to 63 := 28;
    
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
    
    signal done_reg : std_logic := '0';
begin
    process(clk_50m, reset_n)
    begin
        if reset_n = '0' then
            cnt_a    <= 25;
            cnt_b    <= 28;
            done_reg <= '0';
        elsif rising_edge(clk_50m) then
            done_reg <= '0';
            
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
                        cnt_a <= 0;
                        cnt_b <= 0;
                end case;
            elsif tick_1hz = '1' and pause = '0' then
                -- Determine timeout for current active phase
                case phase_sel is
                    when "00" => -- Phase 1 expires when cnt_a reaches 1
                        if cnt_a = 1 then
                            done_reg <= '1';
                        end if;
                    when "01" => -- Phase 2 expires when cnt_a reaches 1
                        if cnt_a = 1 then
                            done_reg <= '1';
                        end if;
                    when "10" => -- Phase 3 expires when cnt_b reaches 1
                        if cnt_b = 1 then
                            done_reg <= '1';
                        end if;
                    when "11" => -- Phase 4 expires when cnt_b reaches 1
                        if cnt_b = 1 then
                            done_reg <= '1';
                        end if;
                    when others =>
                        null;
                end case;
                
                -- Decrement counters
                if cnt_a > 1 then
                    cnt_a <= cnt_a - 1;
                end if;
                if cnt_b > 1 then
                    cnt_b <= cnt_b - 1;
                end if;
            end if;
        end if;
    end process;
    
    timer_done <= done_reg;
    
    -- Combinational BCD output decoding
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

end architecture rtl;
```

---

#### Module 3: `fsm_controller.vhd`
- **File**: `traffic_light_fpga/rtl/fsm_controller.vhd`
- **Standards**: IEEE 1164, numeric_std
- **State Encodings**:
  - `S_PHASE1`: Phase 1 (Route A Green 25s, Route B Red 28s)
  - `S_PHASE2`: Phase 2 (Route A Yellow 3s, Route B Red 3s)
  - `S_PHASE3`: Phase 3 (Route A Red 33s, Route B Green 30s)
  - `S_PHASE4`: Phase 4 (Route A Red 3s, Route B Yellow 3s)
  - `S_NIGHT`: Night Caution Mode (Both Yellow blink @ 1 Hz, 7-seg blanked)
  - `S_EMERGENCY`: Emergency Override Mode (Route A Green, Route B Red)

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fsm_controller is
    port (
        clk_50m      : in  std_logic;
        reset_n      : in  std_logic;
        blink_1hz    : in  std_logic;
        timer_done   : in  std_logic;
        sw_night     : in  std_logic;
        sw_pause     : in  std_logic;
        key_emerg_n  : in  std_logic;
        phase_sel    : out std_logic_vector(1 downto 0);
        load_phase   : out std_logic;
        blank_seg7   : out std_logic;
        fsm_ra       : out std_logic;
        fsm_ya       : out std_logic;
        fsm_ga       : out std_logic;
        fsm_rb       : out std_logic;
        fsm_yb       : out std_logic;
        fsm_gb       : out std_logic
    );
end entity fsm_controller;

architecture rtl of fsm_controller is
    type state_type is (S_PHASE1, S_PHASE2, S_PHASE3, S_PHASE4, S_NIGHT, S_EMERGENCY);
    signal current_state, next_state : state_type := S_PHASE1;
    signal prev_state : state_type := S_PHASE4;
begin

    -- Synchronous State Register & Reload Pulse Generation
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

    -- Next State Combinational Logic with Strict Priority
    process(current_state, key_emerg_n, sw_night, sw_pause, timer_done)
    begin
        next_state <= current_state; -- Default: latch prevention
        
        -- Priority 1: Emergency Force (KEY[1] Active-Low)
        if key_emerg_n = '0' then
            next_state <= S_EMERGENCY;
        -- Priority 2: Night Mode (SW[0] Active-High)
        elsif sw_night = '1' then
            next_state <= S_NIGHT;
        -- Priority 3: Pause/Hold (SW[1] Active-High)
        elsif sw_pause = '1' then
            next_state <= current_state; -- Freeze state
        else
            -- Normal State Flow
            case current_state is
                when S_PHASE1 =>
                    if timer_done = '1' then
                        next_state <= S_PHASE2;
                    end if;
                when S_PHASE2 =>
                    if timer_done = '1' then
                        next_state <= S_PHASE3;
                    end if;
                when S_PHASE3 =>
                    if timer_done = '1' then
                        next_state <= S_PHASE4;
                    end if;
                when S_PHASE4 =>
                    if timer_done = '1' then
                        next_state <= S_PHASE1;
                    end if;
                when S_EMERGENCY =>
                    if key_emerg_n = '1' then
                        next_state <= S_PHASE1;
                    end if;
                when S_NIGHT =>
                    if sw_night = '0' then
                        next_state <= S_PHASE1;
                    end if;
                when others =>
                    next_state <= S_PHASE1;
            end case;
        end if;
    end process;

    -- Moore Output Logic
    process(current_state, blink_1hz)
    begin
        -- Default assignments to prevent latches
        phase_sel  <= "00";
        blank_seg7 <= '0';
        fsm_ra     <= '0';
        fsm_ya     <= '0';
        fsm_ga     <= '0';
        fsm_rb     <= '0';
        fsm_yb     <= '0';
        fsm_gb     <= '0';

        case current_state is
            when S_PHASE1 =>
                phase_sel <= "00";
                fsm_ga    <= '1';
                fsm_rb    <= '1';

            when S_PHASE2 =>
                phase_sel <= "01";
                fsm_ya    <= '1';
                fsm_rb    <= '1';

            when S_PHASE3 =>
                phase_sel <= "10";
                fsm_ra    <= '1';
                fsm_gb    <= '1';

            when S_PHASE4 =>
                phase_sel <= "11";
                fsm_ra    <= '1';
                fsm_yb    <= '1';

            when S_NIGHT =>
                phase_sel  <= "00";
                blank_seg7 <= '1';
                fsm_ya     <= blink_1hz;
                fsm_yb     <= blink_1hz;

            when S_EMERGENCY =>
                phase_sel <= "00";
                fsm_ga    <= '1';
                fsm_rb    <= '1';

            when others =>
                phase_sel <= "00";
                fsm_ra    <= '1';
                fsm_rb    <= '1';
        end case;
    end process;

end architecture rtl;
```

---

#### Module 4: `seg7_decoder.vhd`
- **File**: `traffic_light_fpga/rtl/seg7_decoder.vhd`
- **Standards**: IEEE 1164, numeric_std
- **Polarity**: Active-Low ('0' ON, '1' OFF)

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity seg7_decoder is
    port (
        bcd_in  : in  std_logic_vector(3 downto 0);
        blank   : in  std_logic;
        seg_out : out std_logic_vector(6 downto 0)
    );
end entity seg7_decoder;

architecture rtl of seg7_decoder is
begin
    process(bcd_in, blank)
    begin
        if blank = '1' then
            seg_out <= "1111111"; -- All OFF (Blank)
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
end architecture rtl;
```

---

#### Module 5: `traffic_light_top.vhd`
- **File**: `traffic_light_fpga/rtl/traffic_light_top.vhd`
- **Standards**: IEEE 1164, numeric_std
- **Includes**: Fail-Safe Interlock Safety Hardware Lock

```vhdl
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity traffic_light_top is
    generic (
        SIMULATION : boolean := false
    );
    port (
        CLOCK_50 : in  std_logic;
        KEY      : in  std_logic_vector(1 downto 0); -- KEY(0): Reset_n, KEY(1): Emergency_n
        SW       : in  std_logic_vector(1 downto 0); -- SW(0): NightMode, SW(1): Pause
        LEDR     : out std_logic_vector(3 downto 0); -- [0]=Red A, [1]=Yellow A, [2]=Red B, [3]=Yellow B
        LEDG     : out std_logic_vector(1 downto 0); -- [0]=Green A, [1]=Green B
        HEX0     : out std_logic_vector(6 downto 0); -- Route A Units
        HEX1     : out std_logic_vector(6 downto 0); -- Route A Tens
        HEX2     : out std_logic_vector(6 downto 0); -- Route B Units
        HEX3     : out std_logic_vector(6 downto 0)  -- Route B Tens
    );
end entity traffic_light_top;

architecture structural of traffic_light_top is

    signal tick_1hz_s   : std_logic;
    signal blink_1hz_s  : std_logic;
    signal timer_done_s : std_logic;
    signal phase_sel_s  : std_logic_vector(1 downto 0);
    signal load_phase_s : std_logic;
    signal blank_seg7_s : std_logic;
    
    signal bcd_a_tens_s  : std_logic_vector(3 downto 0);
    signal bcd_a_units_s : std_logic_vector(3 downto 0);
    signal bcd_b_tens_s  : std_logic_vector(3 downto 0);
    signal bcd_b_units_s : std_logic_vector(3 downto 0);
    
    -- Raw FSM signals prior to hardware safety interlock
    signal fsm_ra_s, fsm_ya_s, fsm_ga_s : std_logic;
    signal fsm_rb_s, fsm_yb_s, fsm_gb_s : std_logic;

begin

    -- 1. Clock Divider Instance
    u_clk_divider: entity work.clk_divider
        generic map (
            SIMULATION => SIMULATION
        )
        port map (
            clk_50m   => CLOCK_50,
            reset_n   => KEY(0),
            tick_1hz  => tick_1hz_s,
            blink_1hz => blink_1hz_s
        );

    -- 2. FSM Controller Instance
    u_fsm_controller: entity work.fsm_controller
        port map (
            clk_50m     => CLOCK_50,
            reset_n     => KEY(0),
            blink_1hz   => blink_1hz_s,
            timer_done  => timer_done_s,
            sw_night    => SW(0),
            sw_pause    => SW(1),
            key_emerg_n => KEY(1),
            phase_sel   => phase_sel_s,
            load_phase  => load_phase_s,
            blank_seg7  => blank_seg7_s,
            fsm_ra      => fsm_ra_s,
            fsm_ya      => fsm_ya_s,
            fsm_ga      => fsm_ga_s,
            fsm_rb      => fsm_rb_s,
            fsm_yb      => fsm_yb_s,
            fsm_gb      => fsm_gb_s
        );

    -- 3. Timer Counter Instance
    u_timer_counter: entity work.timer_counter
        port map (
            clk_50m     => CLOCK_50,
            reset_n     => KEY(0),
            tick_1hz    => tick_1hz_s,
            pause       => SW(1),
            load_phase  => load_phase_s,
            phase_sel   => phase_sel_s,
            timer_done  => timer_done_s,
            bcd_a_tens  => bcd_a_tens_s,
            bcd_a_units => bcd_a_units_s,
            bcd_b_tens  => bcd_b_tens_s,
            bcd_b_units => bcd_b_units_s
        );

    -- 4. 7-Segment Decoders Instances
    u_hex0: entity work.seg7_decoder
        port map (bcd_in => bcd_a_units_s, blank => blank_seg7_s, seg_out => HEX0);

    u_hex1: entity work.seg7_decoder
        port map (bcd_in => bcd_a_tens_s, blank => blank_seg7_s, seg_out => HEX1);

    u_hex2: entity work.seg7_decoder
        port map (bcd_in => bcd_b_units_s, blank => blank_seg7_s, seg_out => HEX2);

    u_hex3: entity work.seg7_decoder
        port map (bcd_in => bcd_b_tens_s, blank => blank_seg7_s, seg_out => HEX3);

    -- 5. Interlock Safety Logic (Hardware Conflict Monitor)
    -- Absolute guarantee: LEDG(0) = '1' and LEDG(1) = '1' is mathematically prevented.
    -- If a dual-green fault condition ever arises, both routes are forced to RED (All-Red Fail-Safe).
    process(fsm_ga_s, fsm_gb_s, fsm_ya_s, fsm_yb_s, fsm_ra_s, fsm_rb_s)
    begin
        if (fsm_ga_s = '1' and fsm_gb_s = '1') then
            -- Interlock tripped! Enforce safe All-Red condition
            LEDG(0) <= '0';
            LEDG(1) <= '0';
            LEDR(0) <= '1'; -- Red A
            LEDR(1) <= '0';
            LEDR(2) <= '1'; -- Red B
            LEDR(3) <= '0';
        else
            -- Normal passthrough
            LEDG(0) <= fsm_ga_s;
            LEDG(1) <= fsm_gb_s;
            LEDR(0) <= fsm_ra_s;
            LEDR(1) <= fsm_ya_s;
            LEDR(2) <= fsm_rb_s;
            LEDR(3) <= fsm_yb_s;
        end if;
    end process;

end architecture structural;
```

---

## 5. Verification Method

To independently verify the RTL architecture specifications:

1. **Syntax & Standard Compliance**:
   - Verify every file contains strictly `ieee.std_logic_1164.all` and `ieee.numeric_std.all`.
   - Grep search to guarantee zero occurrences of `std_logic_arith` or `std_logic_unsigned`:
     ```powershell
     grep -rn "std_logic_arith" traffic_light_fpga/rtl/
     grep -rn "std_logic_unsigned" traffic_light_fpga/rtl/
     ```
2. **Inferred Latch & Timing Closure Verification**:
   - Inspect Quartus Synthesis Report (`.map.rpt`) for:
     `Number of Inferred Latches: 0`
   - Run Quartus TimeQuest Timing Analyzer (`.sta.rpt`) to confirm slack $> 0.0$ ns at 50 MHz (`CLOCK_50`, period = 20.000 ns).
3. **Simulation Invalidation Conditions**:
   - The design is invalid if:
     - Any simulated state produces `LEDG(0) = '1' and LEDG(1) = '1'`.
     - `HEX0`..`HEX3` displays any segment other than `"1111111"` while `SW[0] = '1'` (Night Mode).
     - Phase 1 duration departs from 25s, Phase 2 departs from 3s, Phase 3 departs from 30s, or Phase 4 departs from 3s.
     - Counter value jumps or skips during countdown.
