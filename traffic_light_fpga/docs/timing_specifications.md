# Timing Specifications & Intel Quartus Prime Deployment Guide

## Document Overview
- **Project**: Dual-Route 4-Phase Traffic Light Controller
- **Target Platform**: Terasic DE2-115 Development Board (Altera Cyclone IV E EP4CE115F29C7)
- **HDL Standard**: VHDL IEEE 1164 & IEEE numeric_std
- **File Location**: `traffic_light_fpga/docs/timing_specifications.md`
- **Related Design & Constraint Artifacts**:
  - `rtl/clk_divider.vhd`
  - `rtl/timer_counter.vhd`
  - `rtl/fsm_controller.vhd`
  - `rtl/traffic_light_top.vhd`
  - `syn/de2_115_pins.qsf`
  - `syn/de2_115.sdc`

---

## 1. System Clock Architecture & Frequency Division Math

### 1.1 Master Clock Domain
The entire traffic light controller operates within a **single, synchronous clock domain**:
- **Oscillator Frequency**: $f_{\text{osc}} = 50.000\text{ MHz} = 50 \times 10^6\text{ Hz}$
- **Clock Period**: $T_{\text{clk}} = \frac{1}{f_{\text{osc}}} = 20.000\text{ ns}$
- **FPGA Pin Assignment**: `PIN_Y2` (`CLOCK_50`), connected to an onboard low-jitter crystal oscillator.
- **Clock Distribution**: Global Clock Network (`GCLK2`). All flip-flops across `clk_divider`, `timer_counter`, and `fsm_controller` are clocked on the rising edge of `CLOCK_50`.

```
                  +-------------------------------------------------------+
                  |                 Single Clock Domain                   |
                  |                CLOCK_50 (50 MHz, 20ns)                |
                  +---------------------------+---------------------------+
                                              |
                   +--------------------------+--------------------------+
                   |                          |                          |
                   v                          v                          v
          +-----------------+        +-----------------+        +-----------------+
          |   clk_divider   |        |  timer_counter  |        | fsm_controller  |
          |  (counts 50M)   |        | (enabled by     |        | (transitions on |
          |                 |        |  tick_1hz)      |        |  timer_done)    |
          +--------+--------+        +-----------------+        +-----------------+
                   |
                   +---> tick_1hz (1-cycle synchronous enable pulse @ 1 Hz)
                   +---> blink_1hz (50% duty cycle square wave @ 1 Hz)
```

> **Design Rule Violation Warning**: Driving flip-flop clock pins with divided clock nets (ripple clocking or gated clocks) causes clock skew, routing race conditions, and timing analysis failures. In this architecture, no clock gating is used; instead, `tick_1hz` operates strictly as a **synchronous clock enable pulse**.

---

### 1.2 Hardware Frequency Division Math (Hardware Mode: `SIMULATION = false`)

#### 1. 1 Hz Synchronous Tick Generator (`tick_1hz`)
The 1 Hz tick generator produces an active-high pulse lasting exactly one `CLOCK_50` period ($20.000\text{ ns}$) once every $1.00000000\text{ second}$.
- Target Tick Frequency: $f_{\text{tick}} = 1.000\text{ Hz}$
- Required Clock Cycle Count (Modulus):
  $$N_{\text{HW}} = \frac{f_{\text{osc}}}{f_{\text{tick}}} = \frac{50{,}000{,}000\text{ Hz}}{1\text{ Hz}} = 50{,}000{,}000\text{ cycles}$$
- Terminal Count:
  $$\text{Terminal Count} = N_{\text{HW}} - 1 = 49{,}999{,}999$$
- Counter Register Bit-Width Calculation:
  $$B = \lceil \log_2(N_{\text{HW}}) \rceil = \lceil \log_2(50{,}000{,}000) \rceil = \lceil 25.5754 \rceil = 26\text{ bits}$$
  $$\left( 2^{25} = 33{,}554{,}432 < 50{,}000{,}000 \le 2^{26} = 67{,}108{,}864 \right)$$
- Output Pulse Characteristics:
  - Pulse High Duration: $t_{\text{high}} = 1 \times T_{\text{clk}} = 20.000\text{ ns}$
  - Pulse Low Duration: $t_{\text{low}} = 49{,}999{,}999 \times T_{\text{clk}} = 999{,}999{,}980\text{ ns} \approx 0.99999998\text{ s}$
  - Total Period: $T_{\text{tick}} = 50{,}000{,}000 \times 20.000\text{ ns} = 1.00000000\text{ s}$

#### 2. 1 Hz Blink Toggle Generator (`blink_1hz`)
The blink toggle generates a symmetrical 50% duty cycle square wave used to flash the Yellow caution LEDs during Night Mode (`SW[0] = '1'`).
- Symmetrical Half-Period Cycle Count:
  $$N_{\text{half\_HW}} = \frac{N_{\text{HW}}}{2} = \frac{50{,}000{,}000}{2} = 25{,}000{,}000\text{ cycles}$$
- Timing Parameters:
  - High Time ($t_{\text{on}}$): $25{,}000{,}000 \times 20\text{ ns} = 500{,}000{,}000\text{ ns} = 500\text{ ms} = 0.500\text{ s}$
  - Low Time ($t_{\text{off}}$): $25{,}000{,}000 \times 20\text{ ns} = 500{,}000{,}000\text{ ns} = 500\text{ ms} = 0.500\text{ s}$
  - Duty Cycle:
    $$D = \frac{t_{\text{on}}}{t_{\text{on}} + t_{\text{off}}} \times 100\% = \frac{500\text{ ms}}{1000\text{ ms}} \times 100\% = 50.0\%$$
  - Blink Frequency: $f_{\text{blink}} = \frac{1}{0.5\text{s} + 0.5\text{s}} = 1.000\text{ Hz}$

---

### 1.3 Simulation Frequency Division Math (Simulation Mode: `SIMULATION = true`)

Simulating 122 seconds of real-time operation at 50 MHz requires computing:
$$\text{Simulation Cycles} = 122\text{ s} \times 50{,}000{,}000\text{ cycles/s} = 6{,}100{,}000{,}000\text{ cycles}$$
This would require several hours of simulator execution time.

To achieve ultrafast verification while preserving full cycle accuracy, the generic parameter `SIMULATION` in `clk_divider.vhd` scales the modulus down to $50\text{ cycles}$:
- Simulation Cycle Count: $N_{\text{SIM}} = 50\text{ cycles}$
- Simulation Period:
  $$T_{\text{sim\_tick}} = 50 \times 20.000\text{ ns} = 1{,}000.0\text{ ns} = 1.0\ \mu\text{s}$$
- Half-Count Toggle:
  $$N_{\text{half\_SIM}} = 25\text{ cycles} \implies t_{\text{sim\_on}} = 25 \times 20\text{ ns} = 500\text{ ns}, \quad t_{\text{sim\_off}} = 500\text{ ns}$$
- Scaling Acceleration Ratio:
  $$\text{Speedup Factor} = \frac{N_{\text{HW}}}{N_{\text{SIM}}} = \frac{50{,}000{,}000}{50} = 1{,}000{,}000\times \quad (10^6\text{ times speedup})$$

#### Simulation vs. Hardware Parameter Comparison Matrix

| Parameter | Hardware Synthesis (`SIMULATION = false`) | Accelerated Simulation (`SIMULATION = true`) | Unit / Note |
|:---|:---:|:---:|:---|
| **Input Clock Frequency ($f_{\text{osc}}$)** | $50.000$ | $50.000$ | MHz |
| **Input Clock Period ($T_{\text{clk}}$)** | $20.000$ | $20.000$ | ns |
| **Full Modulus ($N$)** | $50{,}000{,}000$ | $50$ | clock cycles |
| **Half Modulus ($N_{\text{half}}$)** | $25{,}000{,}000$ | $25$ | clock cycles |
| **Tick Pulse Width** | $20.000$ | $20.000$ | ns (1 clock cycle) |
| **1-Second Equivalent** | $1.000$ | $1.000$ | s in HW / $\mu\text{s}$ in SIM |
| **Blink High Duration** | $500.0$ | $500.0$ | ms in HW / ns in SIM |
| **Blink Low Duration** | $500.0$ | $500.0$ | ms in HW / ns in SIM |
| **Blink Frequency** | $1.000$ | $1.000$ | Hz in HW / MHz in SIM |
| **Full 61s Cycle Runtime** | $61.000\text{ s}$ | $61.000\ \mu\text{s}$ | Simulated duration |
| **Two Full Cycles (122s)** | $122.000\text{ s}$ | $122.000\ \mu\text{s}$ | Simulated duration |
| **ModelSim Execution Time** | $\approx 2.5\text{ hours}$ | $< 3.0\text{ seconds}$ | CPU wall-clock time |

---

## 2. Phase Timing Schedule & Dual Countdown Timeline

### 2.1 Intersection Phase Schedule Breakdown
The intersection operates on a total cycle time of **61 seconds**:
$$T_{\text{cycle}} = T_{\text{Phase 1}} + T_{\text{Phase 2}} + T_{\text{Phase 3}} + T_{\text{Phase 4}} = 25\text{s} + 3\text{s} + 30\text{s} + 3\text{s} = 61\text{s}$$

```
Time (s)  0         25   28                             58   61
          +---------+----+------------------------------+----+
Route A:  |  GREEN  |YEL |             RED              |    |
          |   25s   | 3s |             33s              |    |
          +---------+----+------------------------------+----+
Route B:  |     RED      |            GREEN             |YEL |
          |     28s      |             30s              | 3s |
          +--------------+------------------------------+----+
          |<--Phase 1-->|<-P2->|<---------Phase 3------>|<-P4>|
```

1. **Phase 1: Route A Green / Route B Red ($25\text{ seconds}$)**:
   - Duration: $t \in [0, 25)$
   - Route A: Green light active. Countdown decrements from $25 \to 1$.
   - Route B: Red light active. Countdown decrements from $28 \to 4$.
   - At $t = 25$, Route A countdown reaches $1$ and triggers `timer_done = '1'`.
2. **Phase 2: Route A Yellow / Route B Red ($3\text{ seconds}$)**:
   - Duration: $t \in [25, 28)$
   - Route A: Yellow light active. Countdown decrements from $3 \to 1$.
   - Route B: Red light continues. Countdown reloaded to $3 \to 1$ (synchronous alignment).
   - At $t = 28$, Route A countdown reaches $1$ and triggers `timer_done = '1'`.
3. **Phase 3: Route A Red / Route B Green ($30\text{ seconds}$)**:
   - Duration: $t \in [28, 58)$
   - Route A: Red light active. Countdown decrements from $33 \to 4$.
   - Route B: Green light active. Countdown decrements from $30 \to 1$.
   - At $t = 58$, Route B countdown reaches $1$ and triggers `timer_done = '1'`.
4. **Phase 4: Route A Red / Route B Yellow ($3\text{ seconds}$)**:
   - Duration: $t \in [58, 61)$
   - Route A: Red light continues. Countdown reloaded to $3 \to 1$.
   - Route B: Yellow light active. Countdown decrements from $3 \to 1$.
   - At $t = 61$, Route B countdown reaches $1$ and triggers `timer_done = '1'`, completing the cycle.

---

### 2.2 Second-by-Second Dual Countdown Matrix (61-Second Complete Cycle)

The following matrix records the exact display values decoded to `HEX1-HEX0` (Route A) and `HEX3-HEX2` (Route B) across all 61 seconds:

| Elapsed Second ($t$) | Operating Phase | Route A Lamp | Display A (`HEX1-0`) | Route B Lamp | Display B (`HEX3-2`) | `timer_done` Pulse | State Transition on Expiry |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **00 s** | Phase 1 | **GREEN** | `25` | **RED** | `28` | `'0'` | Initial reload on entry |
| **01 s** | Phase 1 | GREEN | `24` | RED | `27` | `'0'` | Normal decrement |
| **02 s** | Phase 1 | GREEN | `23` | RED | `26` | `'0'` | Normal decrement |
| **...** | Phase 1 | GREEN | ... | RED | ... | `'0'` | ... |
| **23 s** | Phase 1 | GREEN | `02` | RED | `05` | `'0'` | Normal decrement |
| **24 s** | Phase 1 | GREEN | `01` | RED | `04` | **`'1'`** | **Phase 1 expires** $\to$ triggers transition to Phase 2 |
| **25 s** | Phase 2 | **YELLOW** | `03` | **RED** | `03` | `'0'` | `load_phase` reloads both counters to 3 |
| **26 s** | Phase 2 | YELLOW | `02` | RED | `02` | `'0'` | Normal decrement |
| **27 s** | Phase 2 | YELLOW | `01` | RED | `01` | **`'1'`** | **Phase 2 expires** $\to$ triggers transition to Phase 3 |
| **28 s** | Phase 3 | **RED** | `33` | **GREEN** | `30` | `'0'` | `load_phase` reloads A=33, B=30 |
| **29 s** | Phase 3 | RED | `32` | GREEN | `29` | `'0'` | Normal decrement |
| **30 s** | Phase 3 | RED | `31` | GREEN | `28` | `'0'` | Normal decrement |
| **...** | Phase 3 | RED | ... | GREEN | ... | `'0'` | ... |
| **56 s** | Phase 3 | RED | `05` | GREEN | `02` | `'0'` | Normal decrement |
| **57 s** | Phase 3 | RED | `04` | GREEN | `01` | **`'1'`** | **Phase 3 expires** $\to$ triggers transition to Phase 4 |
| **58 s** | Phase 4 | **RED** | `03` | **YELLOW** | `03` | `'0'` | `load_phase` reloads both counters to 3 |
| **59 s** | Phase 4 | RED | `02` | YELLOW | `02` | `'0'` | Normal decrement |
| **60 s** | Phase 4 | RED | `01` | YELLOW | `01` | **`'1'`** | **Phase 4 expires** $\to$ triggers transition to Phase 1 |
| **61 s / 00 s**| Phase 1 | **GREEN** | `25` | **RED** | `28` | `'0'` | Clean rollover to Phase 1 (Cycle repeats) |

---

### 2.3 Special Operating Mode Timing Characteristics

1. **Pause / Hold Mode (`SW[1] = '1'`)**:
   - Asynchronous switch activation sampled synchronously on `CLOCK_50`.
   - `pause = '1'` immediately inhibits the decrement operation:
     ```vhdl
     elsif tick_1hz = '1' and pause = '0' then
         -- countdown logic
     ```
   - Counters `cnt_a` and `cnt_b` maintain their current integer values indefinitely.
   - The FSM state register maintains its current state.
   - When `SW[1]` is returned to `'0'`, decrements resume seamlessly without lost pulses or reload artifacts.
2. **Night Caution Mode (`SW[0] = '1'`)**:
   - Transitions state to `S_NIGHT`.
   - `blank_seg7` asserted HIGH (`'1'`), forcing segment outputs `HEX0..HEX3` to `"1111111"` (Active-Low: all segments OFF).
   - Yellow lamps `LEDR[1]` and `LEDR[3]` follow `blink_1hz`:
     - 500 ms ON (LED illuminated).
     - 500 ms OFF (LED extinguished).
   - Green and Red LEDs are forced to `'0'`.
   - Upon deasserting `SW[0] = '0'`, FSM transitions to `S_PHASE1`, asserting `load_phase` to reload 25s / 28s cleanly.
3. **Emergency Force Override (`KEY[1] = '0'`)**:
   - Pushbutton `KEY[1]` active-low press sampled synchronously.
   - Highest operational priority; preempts any phase within 1 clock cycle ($20\text{ ns}$).
   - Immediately drives `fsm_ga = '1'` and `fsm_rb = '1'` (Route A Green, Route B Red).
   - Held as long as `KEY[1] = '0'`.
   - Upon release (`KEY[1] = '1'`), transitions to `S_PHASE1`, restarting the cycle cleanly from 25s / 28s.

---

## 3. Intel Quartus Prime Step-by-Step Deployment Guide

This section provides a rigorous, step-by-step engineering walkthrough for synthesizing, constraining, fitting, and programming the Traffic Light Controller onto the **Terasic DE2-115 Development Board** featuring the **Altera Cyclone IV E EP4CE115F29C7** FPGA.

---

### Step 1: Create Quartus Prime Project
1. Launch **Intel Quartus Prime Lite Edition** (or Standard Edition) version 18.1, 20.1, or 22.1+.
2. Select **File $\to$ New Project Wizard**.
3. **Directory, Name, Top-Level Entity**:
   - *Working Directory*: `.../traffic_light_fpga/`
   - *Project Name*: `traffic_light_top`
   - *Top-Level Design Entity*: `traffic_light_top`
   - Click **Next**.
4. **Project Type**:
   - Select **Empty project**. Click **Next**.
5. **Add Files**:
   - Skip adding files at this prompt (we will add them in Step 2). Click **Next**.
6. **Family, Device & Board Settings**:
   - *Family*: **Cyclone IV E**
   - *Package*: **FBGA**
   - *Pin count*: **780**
   - *Speed grade*: **7**
   - *Target Device*: **`EP4CE115F29C7`**
   - Click **Next**.
7. **EDA Tool Settings**:
   - *Simulation*: **ModelSim-Altera** / **Questa Intel FPGA**, Format: **VHDL**.
   - Click **Next**, then click **Finish**.

---

### Step 2: Add RTL Source Files
1. In the Quartus Project Navigator, switch to the **Files** tab.
2. Right-click on **Files** $\to$ **Add/Remove Files in Project...**
3. Browse to the `rtl/` directory and add all five production RTL files:
   - `rtl/clk_divider.vhd`
   - `rtl/seg7_decoder.vhd`
   - `rtl/timer_counter.vhd`
   - `rtl/fsm_controller.vhd`
   - `rtl/traffic_light_top.vhd`
4. Ensure default generic parameter `SIMULATION` in `traffic_light_top.vhd` is set to `false`:
   ```vhdl
   generic (
       SIMULATION : boolean := false
   );
   ```
5. Click **Apply** $\to$ **OK**.

---

### Step 3: Run Analysis & Elaboration and Verify RTL Viewer
1. Click **Processing $\to$ Start $\to$ Start Analysis & Elaboration** (or press `Ctrl+K`).
2. Verify that Analysis & Elaboration finishes with **0 Errors**.
3. **Inspect the RTL Viewer**:
   - Go to **Tools $\to$ Netlist Viewers $\to$ RTL Viewer**.
   - Verify top-level hierarchy: Confirm instances `u_clk_divider`, `u_fsm_controller`, `u_timer_counter`, `u_hex0` through `u_hex3`, and the combinational safety interlock block.
   - Click into `u_fsm_controller` to observe the Moore state registers.
4. **Inspect the State Machine Viewer**:
   - Go to **Tools $\to$ Netlist Viewers $\to$ State Machine Viewer**.
   - Verify the state graph contains all 6 states: `S_PHASE1`, `S_PHASE2`, `S_PHASE3`, `S_PHASE4`, `S_NIGHT`, and `S_EMERGENCY`.
   - Inspect the state encoding table (typically One-Hot or Minimal Bits selected automatically by Quartus).

---

### Step 4: Import and Verify QSF Pin Constraints and SDC Timing Constraints
1. **Import Pin Assignments (`de2_115_pins.qsf`)**:
   - Go to **Assignments $\to$ Import Assignments...**
   - Select file `syn/de2_115_pins.qsf`. Click **OK**.
   - Alternatively, open the project `.qsf` file in a text editor and append the directives directly.
2. **Add Timing Constraints File (`de2_115.sdc`)**:
   - Go to **Assignments $\to$ Settings $\to$ Timing Analyzer**.
   - Under **SDC file to include in the project**, click **Browse** and select `syn/de2_115.sdc`.
   - Click **Add** $\to$ **Apply** $\to$ **OK**.

#### Comprehensive Hardware Pin Mapping Reference Table (35 I/O Pins)

| Signal Name | Port Mode | FPGA Pin Location | Pin Function & Board Connection | Electrical I/O Standard |
|:---|:---:|:---:|:---|:---:|
| `CLOCK_50` | `IN` | `PIN_Y2` | 50.0 MHz Onboard Crystal Oscillator | `3.3-V LVTTL` |
| `KEY[0]` | `IN` | `PIN_M23` | Pushbutton 0 (Active-Low System Reset) | `3.3-V LVTTL` |
| `KEY[1]` | `IN` | `PIN_M21` | Pushbutton 1 (Active-Low Emergency Force) | `3.3-V LVTTL` |
| `SW[0]` | `IN` | `PIN_AB28` | Slide Switch 0 (Active-High Night Mode) | `3.3-V LVTTL` |
| `SW[1]` | `IN` | `PIN_AC28` | Slide Switch 1 (Active-High Pause / Hold) | `3.3-V LVTTL` |
| `LEDR[0]` | `OUT` | `PIN_G19` | Red LED 0 (Route A Red Lamp) | `3.3-V LVTTL` |
| `LEDR[1]` | `OUT` | `PIN_F19` | Red LED 1 (Route A Yellow Lamp) | `3.3-V LVTTL` |
| `LEDR[2]` | `OUT` | `PIN_E19` | Red LED 2 (Route B Red Lamp) | `3.3-V LVTTL` |
| `LEDR[3]` | `OUT` | `PIN_F21` | Red LED 3 (Route B Yellow Lamp) | `3.3-V LVTTL` |
| `LEDG[0]` | `OUT` | `PIN_E21` | Green LED 0 (Route A Green Lamp) | `3.3-V LVTTL` |
| `LEDG[1]` | `OUT` | `PIN_E22` | Green LED 1 (Route B Green Lamp) | `3.3-V LVTTL` |
| `HEX0[0]` | `OUT` | `PIN_G18` | Route A Units 7-Segment (Segment a) | `3.3-V LVTTL` |
| `HEX0[1]` | `OUT` | `PIN_F22` | Route A Units 7-Segment (Segment b) | `3.3-V LVTTL` |
| `HEX0[2]` | `OUT` | `PIN_E17` | Route A Units 7-Segment (Segment c) | `3.3-V LVTTL` |
| `HEX0[3]` | `OUT` | `PIN_L26` | Route A Units 7-Segment (Segment d) | `3.3-V LVTTL` |
| `HEX0[4]` | `OUT` | `PIN_L25` | Route A Units 7-Segment (Segment e) | `3.3-V LVTTL` |
| `HEX0[5]` | `OUT` | `PIN_J22` | Route A Units 7-Segment (Segment f) | `3.3-V LVTTL` |
| `HEX0[6]` | `OUT` | `PIN_H22` | Route A Units 7-Segment (Segment g) | `3.3-V LVTTL` |
| `HEX1[0]` | `OUT` | `PIN_M24` | Route A Tens 7-Segment (Segment a) | `3.3-V LVTTL` |
| `HEX1[1]` | `OUT` | `PIN_Y22` | Route A Tens 7-Segment (Segment b) | `3.3-V LVTTL` |
| `HEX1[2]` | `OUT` | `PIN_W21` | Route A Tens 7-Segment (Segment c) | `3.3-V LVTTL` |
| `HEX1[3]` | `OUT` | `PIN_W22` | Route A Tens 7-Segment (Segment d) | `3.3-V LVTTL` |
| `HEX1[4]` | `OUT` | `PIN_W25` | Route A Tens 7-Segment (Segment e) | `3.3-V LVTTL` |
| `HEX1[5]` | `OUT` | `PIN_U23` | Route A Tens 7-Segment (Segment f) | `3.3-V LVTTL` |
| `HEX1[6]` | `OUT` | `PIN_U24` | Route A Tens 7-Segment (Segment g) | `3.3-V LVTTL` |
| `HEX2[0]` | `OUT` | `PIN_AA25`| Route B Units 7-Segment (Segment a) | `3.3-V LVTTL` |
| `HEX2[1]` | `OUT` | `PIN_AA26`| Route B Units 7-Segment (Segment b) | `3.3-V LVTTL` |
| `HEX2[2]` | `OUT` | `PIN_Y25` | Route B Units 7-Segment (Segment c) | `3.3-V LVTTL` |
| `HEX2[3]` | `OUT` | `PIN_W26` | Route B Units 7-Segment (Segment d) | `3.3-V LVTTL` |
| `HEX2[4]` | `OUT` | `PIN_Y26` | Route B Units 7-Segment (Segment e) | `3.3-V LVTTL` |
| `HEX2[5]` | `OUT` | `PIN_W27` | Route B Units 7-Segment (Segment f) | `3.3-V LVTTL` |
| `HEX2[6]` | `OUT` | `PIN_W28` | Route B Units 7-Segment (Segment g) | `3.3-V LVTTL` |
| `HEX3[0]` | `OUT` | `PIN_V21` | Route B Tens 7-Segment (Segment a) | `3.3-V LVTTL` |
| `HEX3[1]` | `OUT` | `PIN_U21` | Route B Tens 7-Segment (Segment b) | `3.3-V LVTTL` |
| `HEX3[2]` | `OUT` | `PIN_AB20`| Route B Tens 7-Segment (Segment c) | `3.3-V LVTTL` |
| `HEX3[3]` | `OUT` | `PIN_AA21`| Route B Tens 7-Segment (Segment d) | `3.3-V LVTTL` |
| `HEX3[4]` | `OUT` | `PIN_AD24`| Route B Tens 7-Segment (Segment e) | `3.3-V LVTTL` |
| `HEX3[5]` | `OUT` | `PIN_AF23`| Route B Tens 7-Segment (Segment f) | `3.3-V LVTTL` |
| `HEX3[6]` | `OUT` | `PIN_Y19` | Route B Tens 7-Segment (Segment g) | `3.3-V LVTTL` |

---

### Step 5: Compile Design (Synthesis & Fitter) and Check Compilation Report
1. Click **Processing $\to$ Start Compilation** (or press `Ctrl+L`).
2. Compilation will execute in sequence:
   - Analysis & Synthesis
   - Fitter (Place & Route)
   - Assembler (Generate `.sof` programming file)
   - TimeQuest Timing Analysis
   - EDA Netlist Writer
3. **Verify Compilation Results in the Compilation Report**:
   - **Flow Status**: `Successful - 0 Errors`.
   - **Total Logic Elements**: $\le 180\ / 114{,}480$ ($< 0.2\%$ utilization).
   - **Total Registers**: $\approx 45$ to $55$ registers.
   - **Total Pins**: $35\ / 529$ ($7\%$).
   - **Inferred Latches Check**:
     - Open the Analysis & Synthesis report (`output_files/traffic_light_top.map.rpt`).
     - Search for "latch". Confirm **`0 Inferred Latches`**.
   - **TimeQuest Timing Closure Check**:
     - Open the TimeQuest Timing Analyzer report (`output_files/traffic_light_top.sta.rpt`).
     - Check the **Clocks** summary:
       - Required Clock: `50.0 MHz` ($T_{\text{period}} = 20.000\text{ ns}$).
       - Worst-Case Setup Slack ($T_{\text{slack}}$): $> +8.000\text{ ns}$ (positive slack, timing met with massive margin).
       - Estimated $F_{\text{max}}$: $> 120.0\text{ MHz}$ (well exceeding 50 MHz requirement).

---

### Step 6: Program Hardware via USB-Blaster Cable (.sof File Programming)
1. **Physical Hardware Setup**:
   - Connect the DC 12V power adapter to the DE2-115 board power jack (`J1`).
   - Connect a USB Type-B cable between the PC USB port and the port labeled **USB BLASTER** (`J9`) on the DE2-115 board.
   - Press the red push-button power switch (`POWER`) to turn ON the board. The blue `POWER` LED should illuminate.
2. **Open Quartus Programmer**:
   - In Quartus Prime, go to **Tools $\to$ Programmer**.
3. **Configure Hardware Setup**:
   - Click **Hardware Setup...** in the top left corner.
   - Under *Currently selected hardware*, select **USB-Blaster [USB-0]**.
   - Click **Close**.
4. **Configure Programming Mode**:
   - Set *Mode* dropdown to **JTAG**.
5. **Add Programming File**:
   - If the device chain is not displayed, click **Auto Detect** and select `EP4CE115`.
   - Click on the `EP4CE115` device row, click **Change File...** (or **Add File...**).
   - Navigate to `output_files/traffic_light_top.sof` and select it.
   - Check the **Program/Configure** checkbox for the `EP4CE115` device.
6. **Program the FPGA**:
   - Click the **Start** button in the left sidebar.
   - The *Progress* bar will advance from $0\%$ to **100% (Successful)**.

---

### Step 7: On-Board Hardware Functional Verification Checklist

Once programming reaches 100%, execute the following systematic validation checklist directly on the DE2-115 board:

- [ ] **1. Power-On & Reset Verification**:
  - Press and release `KEY[0]` (Hardware Reset).
  - Verify that Route A Green (`LEDG[0]`) and Route B Red (`LEDR[2]`) light up immediately.
  - Verify that `HEX1-HEX0` displays `25` and `HEX3-HEX2` displays `28`.
- [ ] **2. Normal 61-Second Traffic Cycle Verification**:
  - Observe `HEX1-HEX0` countdown: $25 \to 24 \to \dots \to 01$.
  - At $t = 25\text{s}$, verify Route A transitions from Green (`LEDG[0]`) to Yellow (`LEDR[1]`), while Route B stays Red (`LEDR[2]`).
  - Verify both `HEX1-HEX0` and `HEX3-HEX2` reload to `03` and count down: $03 \to 02 \to 01$.
  - At $t = 28\text{s}$, verify Route A transitions to Red (`LEDR[0]`) and Route B transitions to Green (`LEDG[1]`).
  - Verify `HEX1-HEX0` displays `33` and `HEX3-HEX2` displays `30`.
  - At $t = 58\text{s}$, verify Route B transitions to Yellow (`LEDR[3]`) while Route A remains Red (`LEDR[0]`).
  - Verify both displays reload to `03` and count down: $03 \to 02 \to 01$.
  - At $t = 61\text{s}$, verify clean return to Phase 1 (Route A Green, Route B Red, displays reload to `25` and `28`).
- [ ] **3. Night Caution Mode Verification**:
  - Flip slide switch `SW[0]` UP to `'1'`.
  - Verify that all four 7-segment displays (`HEX0`..`HEX3`) are completely blanked (no segments lit).
  - Verify that Green (`LEDG[0..1]`) and Red (`LEDR[0, 2]`) LEDs are extinguished.
  - Verify that Yellow LEDs `LEDR[1]` and `LEDR[3]` flash synchronously at exactly 1 Hz (500 ms ON, 500 ms OFF).
  - Flip `SW[0]` DOWN to `'0'`. Verify system recovers cleanly into Phase 1 ($25\text{s} / 28\text{s}$).
- [ ] **4. Pause / Hold Mode Verification**:
  - While counting down in any phase (e.g. Phase 1 at count `18`), flip slide switch `SW[1]` UP to `'1'`.
  - Verify that both 7-segment displays stop decrementing and freeze on the current numbers.
  - Verify that the traffic light LEDs maintain their current color without change.
  - Wait several seconds; verify counts do not advance.
  - Flip `SW[1]` DOWN to `'0'`. Verify countdown resumes immediately from count `18` without skipping.
- [ ] **5. Emergency Force Mode Verification**:
  - While Route B has Green (`LEDG[1] = '1'` in Phase 3), press and hold pushbutton `KEY[1]`.
  - Verify that Route B Green turns OFF immediately ($< 20\text{ ns}$) and switches to Red (`LEDR[2]`), while Route A Green (`LEDG[0]`) turns ON immediately.
  - Hold `KEY[1]` for several seconds; verify the emergency corridor is maintained.
  - Release `KEY[1]`. Verify clean recovery into Phase 1 ($25\text{s} / 28\text{s}$).
- [ ] **6. Hardware Safety Interlock Verification**:
  - Verify that throughout all mode transitions, switch toggles, and button presses, Green A (`LEDG[0]`) and Green B (`LEDG[1]`) are **NEVER simultaneously illuminated**.
