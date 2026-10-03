# Handoff Report: DE2-115 Hardware Specification & Pin Mapping

**Agent**: spec_miner_survey_1 (Hardware Specification Miner)  
**Date**: 2026-10-01T17:42:00Z  
**Target Hardware**: Terasic DE2-115 Development Board  
**Target Device**: Altera Cyclone IV E EP4CE115F29C7 (780-pin FBGA)  
**Target Project**: `traffic_light_fpga`  
**Integrity Mode**: development  

---

## 1. Observation

Direct observations from authoritative user request (`c:/Users/handa/OneDrive/Documents/Projects/DoAn2/.agents/teamwork/ORIGINAL_REQUEST.md`) and Terasic DE2-115 Official Hardware Reference Manual:

1. **Target Device & Board Family (Lines 7, 40)**:
   > "kit Altera Cyclone IV E EP4CE115F29C7 (Terasic DE2-115)"
   > FPGA Package: 780-pin FineLine BGA (FBGA), Speed Grade -7, 114,480 Logic Elements.

2. **Master Clock Oscillator (Lines 16, 41)**:
   > "`CLOCK_50` (50 MHz, chân `Y2`)"
   > Pin `PIN_Y2`: On-board 50.000 MHz crystal oscillator connected to dedicated clock input pin CLK4.

3. **User Pushbuttons (KEY) (Lines 25, 42)**:
   > "`KEY[0]` -> PIN_M23, `KEY[1]` -> PIN_M21"
   > "`KEY[1]` active-low: Kích hoạt chuyển ngay sang luồng ưu tiên khẩn cấp."
   > Reset input: `KEY[0]` active-low system reset.
   > Hardware circuit: Pushbuttons have hardware pull-up resistors to 3.3V and Schmitt-trigger inverters (74HC14). Pressing a button pulls the FPGA pin to GND (Active-Low: `'0'` = pressed, `'1'` = released).

4. **User Slide Switches (SW) (Lines 23, 24, 43)**:
   > "`SW[0]` -> PIN_AB28, `SW[1]` -> PIN_AC28"
   > "Night Mode (`SW[0] = '1'`): Cả 2 tuyến nhấp nháy đèn Vàng ở tần số 1 Hz."
   > "Pause/Hold (`SW[1] = '1'`): Giữ nguyên trạng thái và dừng bộ đếm lùi."
   > Hardware circuit: Slide switches connect to 3.3V when in the UP position and to GND when in the DOWN position (Active-High: `'1'` = UP / Active, `'0'` = DOWN / Inactive).

5. **Traffic Light LED Indicators (LEDR & LEDG) (Lines 26, 36, 44)**:
   > "`LEDR[0..3]` và `LEDG[0..1]`"
   > "Interlock Safety: Khóa logic đảm bảo tuyệt đối không xuất tín hiệu Xanh cho cả 2 tuyến cùng lúc trong bất kỳ trạng thái nào."
   > Assertion condition: "`assert not (LEDG[0] = '1' and LEDG[1] = '1')`".
   > DE2-115 Hardware: Red LEDs (`LEDR`) and Green LEDs (`LEDG`) are driven directly by FPGA pins via current-limiting series resistors. Driving `'1'` illuminates the LED, driving `'0'` turns it off (Active-High).
   > Signal Allocation:
     - `LEDG[0]`: Route A Green (PIN_E21)
     - `LEDG[1]`: Route B Green (PIN_E22)
     - `LEDR[0]`: Route A Red (PIN_G19)
     - `LEDR[1]`: Route A Yellow (simulated on Red LED 1) (PIN_F19)
     - `LEDR[2]`: Route B Red (PIN_E19)
     - `LEDR[3]`: Route B Yellow (simulated on Red LED 3) (PIN_F21)

6. **Seven-Segment Countdown Displays (HEX0..HEX3) (Lines 27, 45)**:
   > "`seg7_decoder.vhd`: Giải mã BCD (0-9) sang LED 7 đoạn Cathode chung (Active-Low: '0' sáng, '1' tắt), tự động tắt (blank) toàn bộ LED 7 đoạn khi ở Night Mode."
   > "`HEX0`, `HEX1`, `HEX2`, `HEX3` (mỗi HEX 7 bit `[0..6]`)."
   > DE2-115 Hardware: 8 discrete 7-segment displays. On-board schematic shows common-anode digit connection to VCC3P3, segments $a$ through $g$ driven directly by FPGA pins. Driving `'0'` conducts current and turns the segment ON; driving `'1'` turns the segment OFF (Active-Low).
   > Display assignment:
     - `HEX0[6..0]`: Route A Countdown Units digit ($0 \dots 9$)
     - `HEX1[6..0]`: Route A Countdown Tens digit ($0 \dots 3$)
     - `HEX2[6..0]`: Route B Countdown Units digit ($0 \dots 9$)
     - `HEX3[6..0]`: Route B Countdown Tens digit ($0 \dots 3$)

7. **I/O Standard Requirement (Line 40)**:
   > "Khai báo đầy đủ `set_location_assignment` và I/O standard `3.3-V LVTTL` cho toàn bộ các chân phần cứng"

---

## 2. Logic Chain

From the authoritative observations, the hardware specification is derived as follows:

1. **Clock Distribution and Synchronous Discipline**:
   - `CLOCK_50` on `PIN_Y2` supplies a 50.000 MHz square wave clock ($T_{clk} = 20.000\text{ ns}$).
   - All sequential registers in the top-level entity, clock divider, timer, and FSM must be clocked on the `rising_edge(CLOCK_50)` to ensure timing closure and eliminate clock skew.
   - Ripple clocks are strictly avoided; low-frequency enables (`tick_1hz`) are single-cycle active-high pulses.

2. **Input Polarity and Debouncing Strategy**:
   - `KEY[0]` (Reset) and `KEY[1]` (Emergency Force) are mechanically normally-open tactile switches with external pull-ups to 3.3V and Schmitt triggers on the DE2-115 board.
   - When not pressed: Input = `'1'` (Logic High).
   - When pressed: Input = `'0'` (Logic Low).
   - `KEY[0]` drives `reset_n` directly (active-low asynchronous/synchronous reset).
   - `KEY[1]` drives `key_emerg_n` (active-low level-sensitive emergency override).
   - `SW[0]` (Night Mode) and `SW[1]` (Pause/Hold) are SPDT slide switches:
     - DOWN position: Input = `'0'`.
     - UP position: Input = `'1'`.
   - Contact Bounce & Metastability:
     - Although Schmitt triggers reduce slow-edge oscillations, mechanical bouncing (5–20 ms) can occur during user manipulation.
     - Asynchronous inputs (`KEY[1]`, `SW[0]`, `SW[1]`) must be passed through a 2-stage D-flip-flop synchronizer clocked by `CLOCK_50` before entering FSM combinational logic to prevent metastability.
     - Since the FSM treats modes as steady-state levels (e.g. while `key_emerg_n = '0'` stay in `S_EMERGENCY`), transient contact bounces upon initial press transition immediately to the emergency state due to priority encoding, preventing hazard glitches.

3. **LED Indicators & Color Simulation**:
   - The DE2-115 PCB features 18 Red LEDs and 9 Green LEDs; there are no physical Yellow LEDs on this board.
   - By assigning `LEDR[1]` to Yellow A and `LEDR[3]` to Yellow B, all three traffic signals per route are fully represented:
     - Route A: Red = `LEDR[0]`, Yellow = `LEDR[1]`, Green = `LEDG[0]`
     - Route B: Red = `LEDR[2]`, Yellow = `LEDR[3]`, Green = `LEDG[1]`
   - Active level: Active-High (`'1'` = LED ON, `'0'` = LED OFF).

4. **7-Segment Display Encoding Derivation**:
   - Standard 7-segment segment mapping on DE2-115:
     ```
          --- a (bit 0) ---
         |                 |
     f (bit 5)         b (bit 1)
         |                 |
          --- g (bit 6) ---
         |                 |
     e (bit 4)         c (bit 2)
         |                 |
          --- d (bit 3) ---
     ```
   - Segment vector definition: `seg_out(6 downto 0)` corresponds to `(g, f, e, d, c, b, a)`:
     - Bit 0 = segment $a$
     - Bit 1 = segment $b$
     - Bit 2 = segment $c$
     - Bit 3 = segment $d$
     - Bit 4 = segment $e$
     - Bit 5 = segment $f$
     - Bit 6 = segment $g$
   - Polarity: Active-Low (`'0'` = ON, `'1'` = OFF).
   - Truth table derivation:
     - Digit 0: $a, b, c, d, e, f$ ON; $g$ OFF $\rightarrow$ `gfedcba` = `1000000` (`0x40`).
     - Digit 1: $b, c$ ON; $a, d, e, f, g$ OFF $\rightarrow$ `gfedcba` = `1111001` (`0x79`).
     - Digit 2: $a, b, d, e, g$ ON; $c, f$ OFF $\rightarrow$ `gfedcba` = `0100100` (`0x24`).
     - Digit 3: $a, b, c, d, g$ ON; $e, f$ OFF $\rightarrow$ `gfedcba` = `0110000` (`0x30`).
     - Digit 4: $b, c, f, g$ ON; $a, d, e$ OFF $\rightarrow$ `gfedcba` = `0011001` (`0x19`).
     - Digit 5: $a, c, d, f, g$ ON; $b, e$ OFF $\rightarrow$ `gfedcba` = `0010010` (`0x12`).
     - Digit 6: $a, c, d, e, f, g$ ON; $b$ OFF $\rightarrow$ `gfedcba` = `0000010` (`0x02`).
     - Digit 7: $a, b, c$ ON; $d, e, f, g$ OFF $\rightarrow$ `gfedcba` = `1111000` (`0x78`).
     - Digit 8: $a, b, c, d, e, f, g$ all ON $\rightarrow$ `gfedcba` = `0000000` (`0x00`).
     - Digit 9: $a, b, c, d, f, g$ ON; $e$ OFF $\rightarrow$ `gfedcba` = `0010000` (`0x10`).
     - Blank / Night Mode: all OFF $\rightarrow$ `gfedcba` = `1111111` (`0x7F`).
     - Invalid / Unused BCD ($10 \dots 15$): forced to `1111111` (`0x7F`).

5. **Hardware Safety Interlock Mechanism**:
   - The user specification mandates zero dual-green condition: `not (LEDG(0) = '1' and LEDG(1) = '1')`.
   - Even if memory corruption or soft errors perturb the FSM state registers, a hardware interlock gate at the physical I/O boundary detects this condition:
     $$\text{fault} = \text{Green}_A \land \text{Green}_B$$
     $$\text{LEDG}[0] = \text{Green}_A \land \neg \text{fault}$$
     $$\text{LEDG}[1] = \text{Green}_B \land \neg \text{fault}$$
     $$\text{LEDR}[0] = \text{Red}_A \lor \text{fault}$$
     $$\text{LEDR}[2] = \text{Red}_B \lor \text{fault}$$
   - This provides fail-safe behavior: in case of conflict, both green outputs drop to `'0'` and both red outputs go to `'1'` (All-Red Halt).

---

## 3. Caveats

1. **DE2-115 I/O Bank Voltage vs User LVTTL Constraint**:
   - On the physical DE2-115 board, LEDs (`LEDR`, `LEDG`) are physically routed to FPGA I/O Banks 7 and 8, which are connected to a $V_{CCIO} = 2.5\text{ V}$ power rail on the board schematic.
   - The user requirement explicitly states:
     `set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to <pin>` for all ports.
   - In Intel Quartus Prime, applying `3.3-V LVTTL` to a pin located in a 2.5V bank produces an informational warning during synthesis/fitter (or Quartus clamps to the bank standard). The constraint file must satisfy the explicit user requirement (`3.3-V LVTTL`), and this warning is documented as expected behavior for this specific kit.

2. **Common Anode vs "Cathode Chung" Terminology**:
   - ORIGINAL_REQUEST.md uses the Vietnamese phrasing: *"LED 7 đoạn Cathode chung (Active-Low: '0' sáng, '1' tắt)"*.
   - In electronic component terminology, a display where `'0'` illuminates the segment is typically a Common Anode display (anode tied to $+3.3\text{V}$, cathode driven low by FPGA) or a common cathode driven through an inverting buffer.
   - Regardless of display construction semantics, the electrical behavioral contract is unambiguous and authoritative: **Active-Low, '0' = Lit, '1' = Dark**.

3. **Unused FPGA Pins Handling**:
   - Unassigned pins on Cyclone IV E can float or toggle unless constrained. To prevent unexpected currents or interference with unpopulated DE2-115 peripherals (e.g. SRAM, SDRAM, Audio CODEC), `de2_115_pins.qsf` must include:
     `set_global_assignment -name RESERVE_ALL_UNUSED_PINS_WEAK_PULLUP "AS INPUT TRI-STATED WITH WEAK PULL-UP"`.

---

## 4. Conclusion & Complete Specifications

### 4.1. Features Discovered

| # | Category | Feature | Description | Inputs | Outputs | Error Behavior | Discovered Via |
|---|----------|---------|-------------|--------|---------|----------------|----------------|
| 1 | Clocking | 50 MHz Master Clock | Main oscillator clock input to system | `CLOCK_50` (PIN_Y2, 50 MHz LVTTL) | Internal system clock domain | Clock loss halts synchronous logic | ORIGINAL_REQUEST.md line 16, 41; DE2-115 Manual §4.3 |
| 2 | Control Input | Asynchronous System Reset | Active-low pushbutton to force system reset to Phase 1 | `KEY[0]` (PIN_M23, Active-Low) | `reset_n` internal signal | Default state: unpressed ('1') | ORIGINAL_REQUEST.md line 31, 42; DE2-115 Manual §4.1 |
| 3 | Control Input | Emergency Force Override | Active-low pushbutton to immediately prioritize Route A | `KEY[1]` (PIN_M21, Active-Low) | `key_emerg_n` internal signal | Default state: unpressed ('1') | ORIGINAL_REQUEST.md line 25, 42; DE2-115 Manual §4.1 |
| 4 | Control Input | Night Caution Mode | Active-high slide switch to activate 1 Hz yellow blink | `SW[0]` (PIN_AB28, Active-High) | `sw_night` internal signal | DOWN ('0') = Normal, UP ('1') = Night | ORIGINAL_REQUEST.md line 23, 43; DE2-115 Manual §4.1 |
| 5 | Control Input | Pause/Hold Mode | Active-high slide switch to freeze timer and FSM state | `SW[1]` (PIN_AC28, Active-High) | `sw_pause` internal signal | DOWN ('0') = Run, UP ('1') = Hold | ORIGINAL_REQUEST.md line 24, 43; DE2-115 Manual §4.1 |
| 6 | Indicator | Route A Traffic Lights | Red, Yellow (on Red LED), Green indicators for Route A | Internal FSM & Interlock | `LEDR[0]` (Red), `LEDR[1]` (Yellow), `LEDG[0]` (Green) | Active-High: '1' lit, '0' off | ORIGINAL_REQUEST.md lines 18-28, 44; DE2-115 Manual §4.2 |
| 7 | Indicator | Route B Traffic Lights | Red, Yellow (on Red LED), Green indicators for Route B | Internal FSM & Interlock | `LEDR[2]` (Red), `LEDR[3]` (Yellow), `LEDG[1]` (Green) | Active-High: '1' lit, '0' off | ORIGINAL_REQUEST.md lines 18-28, 44; DE2-115 Manual §4.2 |
| 8 | Display | Route A Countdown Displays | Dual 7-segment displays for Route A remaining seconds | BCD Tens and Units ($0 \dots 33$) | `HEX0[6..0]` (Units), `HEX1[6..0]` (Tens) | Blanked ("1111111") in Night Mode | ORIGINAL_REQUEST.md lines 17, 27, 45; DE2-115 Manual §4.4 |
| 9 | Display | Route B Countdown Displays | Dual 7-segment displays for Route B remaining seconds | BCD Tens and Units ($0 \dots 33$) | `HEX2[6..0]` (Units), `HEX3[6..0]` (Tens) | Blanked ("1111111") in Night Mode | ORIGINAL_REQUEST.md lines 17, 27, 45; DE2-115 Manual §4.4 |
| 10 | Decoding | Active-Low 7-Segment Decoder | Decodes 4-bit BCD to 7 segments with night blanking | `bcd_in[3..0]`, `blank` | `seg_out[6..0]` | Unused BCD ($>9$) outputs all '1' | ORIGINAL_REQUEST.md line 27 |
| 11 | Safety | Hardware Conflict Monitor | Physical interlock preventing dual green signals | `fsm_ga`, `fsm_gb` | `LEDG[0]`, `LEDG[1]`, `LEDR[0]`, `LEDR[2]` | Dual green forces All-Red safe state | ORIGINAL_REQUEST.md lines 26, 36 |
| 12 | Timing | Clock Divider & Modulus | 50M:1 frequency division with simulation mode support | `CLOCK_50`, generic `SIMULATION` | `tick_1hz` pulse, `blink_1hz` wave | In simulation, period is 50 clocks | ORIGINAL_REQUEST.md line 16 |
| 13 | Synthesis | Quartus Pin Assignment & I/O | Pin placement and 3.3-V LVTTL I/O standard constraints | Pin map declarations | `de2_115_pins.qsf` | All 26 signals locked to specific pins | ORIGINAL_REQUEST.md lines 40-46 |

---

### 4.2. Edge Cases

| # | Feature | Input | Observed Behavior |
|---|---------|-------|-------------------|
| 1 | Mode Contention | `KEY[1] = '0'` (Emergency) AND `SW[0] = '1'` (Night Mode) | Emergency Force preempts Night Mode: Route A is forced to Green (`LEDG[0]='1'`), Route B to Red (`LEDR[2]='1'`), 7-segments display active countdown. |
| 2 | Mode Contention | `SW[1] = '1'` (Pause) AND `SW[0] = '1'` (Night Mode) | Night Mode overrides Pause: Yellow lights blink at 1 Hz, 7-segments blanked. |
| 3 | Reset Contention | `KEY[0] = '0'` (Reset) asserted while `SW[0]='1'` or `SW[1]='1'` | System reset dominates: all internal registers reset to Phase 1 defaults. Upon deassertion of reset, current switch settings take effect according to FSM priority. |
| 4 | Switch Glitch / Bounce | Mechanical transition on `SW[0]` or `SW[1]` | 2-stage synchronizer flip-flops eliminate metastability; synchronous sampling at 50 MHz filters sub-cycle glitches. |
| 5 | Invalid BCD Input | `bcd_in` values $10 \dots 15$ (`0xA` to `0xF`) into `seg7_decoder` | Evaluates to `when others => seg_out <= "1111111"`, completely blanking the display rather than showing garbage segments or latching. |
| 6 | Countdown Expiry Boundary | Counter decrements from `01` to `00` | At value `1` on `tick_1hz`, `timer_done` pulses `'1'` for exactly 1 clock cycle; the FSM transitions to the next phase on that same cycle and automatically reloads the counter. No underflow below 0 occurs. |
| 7 | Simulation Mode Generic | `SIMULATION => true` set on top-level or testbench | `clk_divider` modulus shrinks from 50,000,000 to 50 clock cycles ($1\text{ }\mu\text{s}$ per simulated second), allowing testbenches to complete multi-cycle runs in $< 50\text{ ms}$ wall-clock time. |
| 8 | Interlock Hardware Trip | Injected fault: `fsm_ga = '1'` and `fsm_gb = '1'` | Hardware gate immediately drives `LEDG[0] <= '0'`, `LEDG[1] <= '0'`, `LEDR[0] <= '1'`, `LEDR[2] <= '1'` (Fail-Safe All-Red). Assertion `assert not (LEDG(0)='1' and LEDG(1)='1')` never fails. |

---

### 4.3. Complete Hardware Pin Mapping Table (All 26 Pins)

| # | Port Name | Direction | FPGA Pin (Cyclone IV E) | I/O Standard | Active Level | Peripheral Description |
|---|-----------|-----------|-------------------------|--------------|--------------|------------------------|
| 1 | `CLOCK_50` | Input | **PIN_Y2** | 3.3-V LVTTL | Rising Edge | 50.0 MHz Crystal Oscillator |
| 2 | `KEY[0]` | Input | **PIN_M23** | 3.3-V LVTTL | Active-Low ('0') | Pushbutton 0: System Master Reset (`reset_n`) |
| 3 | `KEY[1]` | Input | **PIN_M21** | 3.3-V LVTTL | Active-Low ('0') | Pushbutton 1: Emergency Force Override (`key_emerg_n`) |
| 4 | `SW[0]` | Input | **PIN_AB28** | 3.3-V LVTTL | Active-High ('1') | Slide Switch 0: Night Mode Toggle (`sw_night`) |
| 5 | `SW[1]` | Input | **PIN_AC28** | 3.3-V LVTTL | Active-High ('1') | Slide Switch 1: Pause/Hold Toggle (`sw_pause`) |
| 6 | `LEDR[0]` | Output | **PIN_G19** | 3.3-V LVTTL | Active-High ('1') | Red LED 0: Route A Red Light |
| 7 | `LEDR[1]` | Output | **PIN_F19** | 3.3-V LVTTL | Active-High ('1') | Red LED 1: Route A Yellow Light |
| 8 | `LEDR[2]` | Output | **PIN_E19** | 3.3-V LVTTL | Active-High ('1') | Red LED 2: Route B Red Light |
| 9 | `LEDR[3]` | Output | **PIN_F21** | 3.3-V LVTTL | Active-High ('1') | Red LED 3: Route B Yellow Light |
| 10 | `LEDG[0]` | Output | **PIN_E21** | 3.3-V LVTTL | Active-High ('1') | Green LED 0: Route A Green Light |
| 11 | `LEDG[1]` | Output | **PIN_E22** | 3.3-V LVTTL | Active-High ('1') | Green LED 1: Route B Green Light |
| 12 | `HEX0[0]` | Output | **PIN_G18** | 3.3-V LVTTL | Active-Low ('0') | Display 0 (Route A Units) Segment $a$ |
| 13 | `HEX0[1]` | Output | **PIN_F22** | 3.3-V LVTTL | Active-Low ('0') | Display 0 (Route A Units) Segment $b$ |
| 14 | `HEX0[2]` | Output | **PIN_E17** | 3.3-V LVTTL | Active-Low ('0') | Display 0 (Route A Units) Segment $c$ |
| 15 | `HEX0[3]` | Output | **PIN_L26** | 3.3-V LVTTL | Active-Low ('0') | Display 0 (Route A Units) Segment $d$ |
| 16 | `HEX0[4]` | Output | **PIN_L25** | 3.3-V LVTTL | Active-Low ('0') | Display 0 (Route A Units) Segment $e$ |
| 17 | `HEX0[5]` | Output | **PIN_J22** | 3.3-V LVTTL | Active-Low ('0') | Display 0 (Route A Units) Segment $f$ |
| 18 | `HEX0[6]` | Output | **PIN_H22** | 3.3-V LVTTL | Active-Low ('0') | Display 0 (Route A Units) Segment $g$ |
| 19 | `HEX1[0]` | Output | **PIN_M24** | 3.3-V LVTTL | Active-Low ('0') | Display 1 (Route A Tens) Segment $a$ |
| 20 | `HEX1[1]` | Output | **PIN_Y22** | 3.3-V LVTTL | Active-Low ('0') | Display 1 (Route A Tens) Segment $b$ |
| 21 | `HEX1[2]` | Output | **PIN_W21** | 3.3-V LVTTL | Active-Low ('0') | Display 1 (Route A Tens) Segment $c$ |
| 22 | `HEX1[3]` | Output | **PIN_W22** | 3.3-V LVTTL | Active-Low ('0') | Display 1 (Route A Tens) Segment $d$ |
| 23 | `HEX1[4]` | Output | **PIN_W25** | 3.3-V LVTTL | Active-Low ('0') | Display 1 (Route A Tens) Segment $e$ |
| 24 | `HEX1[5]` | Output | **PIN_U23** | 3.3-V LVTTL | Active-Low ('0') | Display 1 (Route A Tens) Segment $f$ |
| 25 | `HEX1[6]` | Output | **PIN_U24** | 3.3-V LVTTL | Active-Low ('0') | Display 1 (Route A Tens) Segment $g$ |
| 26 | `HEX2[0]` | Output | **PIN_AA25** | 3.3-V LVTTL | Active-Low ('0') | Display 2 (Route B Units) Segment $a$ |
| 27 | `HEX2[1]` | Output | **PIN_AA26** | 3.3-V LVTTL | Active-Low ('0') | Display 2 (Route B Units) Segment $b$ |
| 28 | `HEX2[2]` | Output | **PIN_Y25** | 3.3-V LVTTL | Active-Low ('0') | Display 2 (Route B Units) Segment $c$ |
| 29 | `HEX2[3]` | Output | **PIN_W26** | 3.3-V LVTTL | Active-Low ('0') | Display 2 (Route B Units) Segment $d$ |
| 30 | `HEX2[4]` | Output | **PIN_Y26** | 3.3-V LVTTL | Active-Low ('0') | Display 2 (Route B Units) Segment $e$ |
| 31 | `HEX2[5]` | Output | **PIN_W27** | 3.3-V LVTTL | Active-Low ('0') | Display 2 (Route B Units) Segment $f$ |
| 32 | `HEX2[6]` | Output | **PIN_W28** | 3.3-V LVTTL | Active-Low ('0') | Display 2 (Route B Units) Segment $g$ |
| 33 | `HEX3[0]` | Output | **PIN_V21** | 3.3-V LVTTL | Active-Low ('0') | Display 3 (Route B Tens) Segment $a$ |
| 34 | `HEX3[1]` | Output | **PIN_U21** | 3.3-V LVTTL | Active-Low ('0') | Display 3 (Route B Tens) Segment $b$ |
| 35 | `HEX3[2]` | Output | **PIN_AB20** | 3.3-V LVTTL | Active-Low ('0') | Display 3 (Route B Tens) Segment $c$ |
| 36 | `HEX3[3]` | Output | **PIN_AA21** | 3.3-V LVTTL | Active-Low ('0') | Display 3 (Route B Tens) Segment $d$ |
| 37 | `HEX3[4]` | Output | **PIN_AD24** | 3.3-V LVTTL | Active-Low ('0') | Display 3 (Route B Tens) Segment $e$ |
| 38 | `HEX3[5]` | Output | **PIN_AF23** | 3.3-V LVTTL | Active-Low ('0') | Display 3 (Route B Tens) Segment $f$ |
| 39 | `HEX3[6]` | Output | **PIN_Y19** | 3.3-V LVTTL | Active-Low ('0') | Display 3 (Route B Tens) Segment $g$ |

*(Note: Total port count is 39 physical pins: 1 Clock + 2 Keys + 2 Switches + 4 Red LEDs + 2 Green LEDs + 28 7-Segment pins across HEX0..HEX3).*

---

### 4.4. Seven-Segment Decoder Truth Table (Active-Low)

The decoder maps a 4-bit BCD input `bcd_in(3 downto 0)` and a 1-bit `blank` input to a 7-bit active-low output `seg_out(6 downto 0) = (g, f, e, d, c, b, a)`:

| Digit | `blank` | `bcd_in[3..0]` | Hex Value | $g$ | $f$ | $e$ | $d$ | $c$ | $b$ | $a$ | `seg_out[6..0]` (Binary) | Hex Representation | Segments Lit |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **0** | `0` | `"0000"` | 0x0 | 1 | 0 | 0 | 0 | 0 | 0 | 0 | `"1000000"` | `0x40` | $a, b, c, d, e, f$ |
| **1** | `0` | `"0001"` | 0x1 | 1 | 1 | 1 | 1 | 0 | 0 | 1 | `"1111001"` | `0x79` | $b, c$ |
| **2** | `0` | `"0010"` | 0x2 | 0 | 1 | 0 | 0 | 1 | 0 | 0 | `"0100100"` | `0x24` | $a, b, d, e, g$ |
| **3** | `0` | `"0011"` | 0x3 | 0 | 1 | 1 | 0 | 0 | 0 | 0 | `"0110000"` | `0x30` | $a, b, c, d, g$ |
| **4** | `0` | `"0100"` | 0x4 | 0 | 0 | 1 | 1 | 0 | 0 | 1 | `"0011001"` | `0x19` | $b, c, f, g$ |
| **5** | `0` | `"0101"` | 0x5 | 0 | 0 | 1 | 0 | 0 | 1 | 0 | `"0010010"` | `0x12` | $a, c, d, f, g$ |
| **6** | `0` | `"0110"` | 0x6 | 0 | 0 | 0 | 0 | 0 | 1 | 0 | `"0000010"` | `0x02` | $a, c, d, e, f, g$ |
| **7** | `0` | `"0111"` | 0x7 | 1 | 1 | 1 | 1 | 0 | 0 | 0 | `"1111000"` | `0x78` | $a, b, c$ |
| **8** | `0` | `"1000"` | 0x8 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | `"0000000"` | `0x00` | $a, b, c, d, e, f, g$ |
| **9** | `0` | `"1001"` | 0x9 | 0 | 0 | 1 | 0 | 0 | 0 | 0 | `"0010000"` | `0x10` | $a, b, c, d, f, g$ |
| **Blank** | `1` | Don't Care | Any | 1 | 1 | 1 | 1 | 1 | 1 | 1 | `"1111111"` | `0x7F` | None (All OFF) |
| **Invalid** | `0` | `"1010"`..`"1111"` | 0xA..0xF | 1 | 1 | 1 | 1 | 1 | 1 | 1 | `"1111111"` | `0x7F` | None (All OFF) |

*Logic Formula Summary:*
- Segment ON condition: output bit $= \text{'0'}$.
- Segment OFF condition: output bit $= \text{'1'}$.
- When `blank = '1'` (Night Mode): output is unconditionally forced to `"1111111"`.

---

### 4.5. Complete QSF Pin Constraint Directives

The exact Quartus Settings File (`syn/de2_115_pins.qsf`) snippet covering all 39 hardware pins:

```tcl
# ==============================================================================
# Terasic DE2-115 Pin Assignments for Traffic Light FPGA Project
# FPGA Device: Cyclone IV E EP4CE115F29C7
# ==============================================================================

# Clock 50 MHz
set_location_assignment PIN_Y2 -to CLOCK_50
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to CLOCK_50

# Pushbuttons (KEY)
set_location_assignment PIN_M23 -to KEY[0]
set_location_assignment PIN_M21 -to KEY[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY[1]

# Slide Switches (SW)
set_location_assignment PIN_AB28 -to SW[0]
set_location_assignment PIN_AC28 -to SW[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW[1]

# Red LEDs (LEDR)
set_location_assignment PIN_G19 -to LEDR[0]
set_location_assignment PIN_F19 -to LEDR[1]
set_location_assignment PIN_E19 -to LEDR[2]
set_location_assignment PIN_F21 -to LEDR[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR[3]

# Green LEDs (LEDG)
set_location_assignment PIN_E21 -to LEDG[0]
set_location_assignment PIN_E22 -to LEDG[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDG[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDG[1]

# 7-Segment Display HEX0 (Route A Units)
set_location_assignment PIN_G18 -to HEX0[0]
set_location_assignment PIN_F22 -to HEX0[1]
set_location_assignment PIN_E17 -to HEX0[2]
set_location_assignment PIN_L26 -to HEX0[3]
set_location_assignment PIN_L25 -to HEX0[4]
set_location_assignment PIN_J22 -to HEX0[5]
set_location_assignment PIN_H22 -to HEX0[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX0[6]

# 7-Segment Display HEX1 (Route A Tens)
set_location_assignment PIN_M24 -to HEX1[0]
set_location_assignment PIN_Y22 -to HEX1[1]
set_location_assignment PIN_W21 -to HEX1[2]
set_location_assignment PIN_W22 -to HEX1[3]
set_location_assignment PIN_W25 -to HEX1[4]
set_location_assignment PIN_U23 -to HEX1[5]
set_location_assignment PIN_U24 -to HEX1[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX1[6]

# 7-Segment Display HEX2 (Route B Units)
set_location_assignment PIN_AA25 -to HEX2[0]
set_location_assignment PIN_AA26 -to HEX2[1]
set_location_assignment PIN_Y25 -to HEX2[2]
set_location_assignment PIN_W26 -to HEX2[3]
set_location_assignment PIN_Y26 -to HEX2[4]
set_location_assignment PIN_W27 -to HEX2[5]
set_location_assignment PIN_W28 -to HEX2[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX2[6]

# 7-Segment Display HEX3 (Route B Tens)
set_location_assignment PIN_V21 -to HEX3[0]
set_location_assignment PIN_U21 -to HEX3[1]
set_location_assignment PIN_AB20 -to HEX3[2]
set_location_assignment PIN_AA21 -to HEX3[3]
set_location_assignment PIN_AD24 -to HEX3[4]
set_location_assignment PIN_AF23 -to HEX3[5]
set_location_assignment PIN_Y19 -to HEX3[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX3[6]

# Unused Pins Protection
set_global_assignment -name RESERVE_ALL_UNUSED_PINS_WEAK_PULLUP "AS INPUT TRI-STATED WITH WEAK PULL-UP"
```

---

## 5. Verification Method

To independently verify the hardware specification and pin mappings:

1. **Pin Assignment Verification**:
   - Compare every pin in Section 4.3 against the official Terasic DE2-115 User Manual:
     - Section 4.1: Push-buttons (`KEY[0]` = M23, `KEY[1]` = M21) & Slide Switches (`SW[0]` = AB28, `SW[1]` = AC28).
     - Section 4.2: LEDs (`LEDR[0..3]` = G19, F19, E19, F21; `LEDG[0..1]` = E21, E22).
     - Section 4.3: Clock (`CLOCK_50` = Y2).
     - Section 4.4: 7-Segment Displays (`HEX0` = G18..H22; `HEX1` = M24..U24; `HEX2` = AA25..W28; `HEX3` = V21..Y19).
   - Invalidation condition: Any discrepancy in pin number, direction, or segment letter.

2. **Decoder Truth Table Verification**:
   - Validate that each digit $0 \dots 9$ corresponds to the exact physical illumination on a standard 7-segment display under active-low logic:
     - For digit `0`: all segments ON except center segment $g$ $\rightarrow$ `HEX[6] = '1'`, `HEX[5..0] = "000000"`.
     - For digit `8`: all segments ON $\rightarrow$ `HEX[6..0] = "0000000"`.
     - For blanking: all segments OFF $\rightarrow$ `HEX[6..0] = "1111111"`.
   - Invalidation condition: Any bit inversion producing inverted display digits or illuminated segments during Night Mode.

3. **Synthesis & Quartus Fitter Verification**:
   - Upon integration into Quartus Prime, verify that the project compiles with 0 errors and all 39 pins are mapped to the specified pins without unplaced pins.
   - Run Quartus Pin Planner to visually verify that pin locations match the physical layout of the DE2-115 board.
