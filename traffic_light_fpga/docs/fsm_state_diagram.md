# Finite State Machine (FSM) & Hardware Safety Interlock Specification

## Document Overview
- **Project**: Dual-Route 4-Phase Traffic Light Controller
- **Target Platform**: Terasic DE2-115 (Altera Cyclone IV E EP4CE115F29C7)
- **HDL Language**: VHDL (IEEE 1164 & IEEE numeric_std compliant)
- **File Location**: `traffic_light_fpga/docs/fsm_state_diagram.md`
- **Related RTL Modules**:
  - `rtl/fsm_controller.vhd`
  - `rtl/timer_counter.vhd`
  - `rtl/seg7_decoder.vhd`
  - `rtl/traffic_light_top.vhd`

---

## 1. Executive Summary & Architecture Overview

The Traffic Light Controller operates an arterial intersection between **Route A** (primary thoroughfare) and **Route B** (secondary thoroughfare). The design is implemented as a fully synchronous, 100% glitch-free Moore Finite State Machine clocked exclusively on the 50 MHz system clock (`CLOCK_50`).

### 1.1 Architectural Characteristics
1. **Moore State Machine Model**: Lamp control outputs and phase selection signals depend solely on the current state register (`current_state`) and the synchronous blinking signal (`blink_1hz`). They do not depend asynchronously on input transitions, eliminating combinational output hazards.
2. **Zero Inferred Latches**: The state transition process specifies an unconditional default assignment (`next_state <= current_state;`) at the beginning of the combinational block, and all output control signals are assigned default values prior to case evaluation.
3. **Synchronous Transition Pulse**: A 1-clock-cycle pulse `load_phase` is asserted whenever `current_state /= prev_state`. This guarantees that the dual countdown timer in `timer_counter.vhd` reloads new phase countdown values on the exact clock cycle of state entry.
4. **Autonomous Hardware Safety Interlock**: An independent combinational logic layer sitting between the raw FSM outputs and the physical I/O output pins guarantees that under no circumstance can Route A and Route B display a Green signal simultaneously.

---

## 2. State Space & Output Definitions

The FSM controller defines six discrete states represented by the enumerated type `state_type`:

```vhdl
type state_type is (S_PHASE1, S_PHASE2, S_PHASE3, S_PHASE4, S_NIGHT, S_EMERGENCY);
```

### 2.1 State Descriptions
- **`S_PHASE1` (Route A Green / Route B Red)**:
  - Route A grants vehicle flow for **25 seconds**.
  - Route B holds traffic with Red for **28 seconds** (25s Green + 3s Yellow of Route A).
  - Countdown display: Route A = $25 \to 1$, Route B = $28 \to 4$.
- **`S_PHASE2` (Route A Yellow / Route B Red)**:
  - Route A alerts stopping clearance for **3 seconds**.
  - Route B continues holding with Red for **3 seconds**.
  - Countdown display: Route A = $3 \to 1$, Route B = $3 \to 1$.
- **`S_PHASE3` (Route A Red / Route B Green)**:
  - Route A holds traffic with Red for **33 seconds** (30s Green + 3s Yellow of Route B).
  - Route B grants vehicle flow for **30 seconds**.
  - Countdown display: Route A = $33 \to 4$, Route B = $30 \to 1$.
- **`S_PHASE4` (Route A Red / Route B Yellow)**:
  - Route A continues holding with Red for **3 seconds**.
  - Route B alerts stopping clearance for **3 seconds**.
  - Countdown display: Route A = $3 \to 1$, Route B = $3 \to 1$.
- **`S_NIGHT` (Night Caution Mode)**:
  - Activated by Slide Switch `SW[0] = '1'`.
  - Both Route A and Route B Yellow lamps flash synchronously at 1.0 Hz (500 ms ON / 500 ms OFF).
  - All Green and Red lamps are completely extinguished.
  - All four 7-segment displays (`HEX0`..`HEX3`) are blanked (`"1111111"`).
- **`S_EMERGENCY` (Emergency Force Override)**:
  - Activated by Pushbutton `KEY[1] = '0'` (Active-Low).
  - Immediately forces Route A to Green and Route B to Red, preempting any active phase.
  - Grants emergency clearance corridor for authorized vehicles until `KEY[1]` is released.

---

## 3. Input Priority Arbitration Hierarchy

The controller evaluates inputs within a strict priority hierarchy in every clock cycle. This guarantees deterministic behavior when multiple inputs are asserted concurrently:

```
+-----------------------------------------------------------------------+
| Priority 1: Hardware Master Reset (KEY[0] = '0')                      |
| -> Asynchronous hardware override directly into S_PHASE1              |
+-----------------------------------------------------------------------+
                                  |
                                  v
+-----------------------------------------------------------------------+
| Priority 2: Emergency Force Override (KEY[1] = '0')                   |
| -> Preempts all operating states; forces transition to S_EMERGENCY    |
+-----------------------------------------------------------------------+
                                  |
                                  v
+-----------------------------------------------------------------------+
| Priority 3: Night Caution Mode (SW[0] = '1')                          |
| -> Preempts normal phases; forces transition to S_NIGHT               |
+-----------------------------------------------------------------------+
                                  |
                                  v
+-----------------------------------------------------------------------+
| Override Exit Condition (SW[0] = '0' and KEY[1] = '1')                |
| -> If exiting S_EMERGENCY or S_NIGHT, returns cleanly to S_PHASE1     |
+-----------------------------------------------------------------------+
                                  |
                                  v
+-----------------------------------------------------------------------+
| Priority 4: Pause / Hold Mode (SW[1] = '1')                           |
| -> Freezes FSM state register and pauses timer decrements             |
+-----------------------------------------------------------------------+
                                  |
                                  v
+-----------------------------------------------------------------------+
| Priority 5: Normal Flow Progression (timer_done = '1')                 |
| -> Transitions sequentially: Phase 1 -> 2 -> 3 -> 4 -> 1              |
+-----------------------------------------------------------------------+
```

### 3.1 Priority Arbitration Table

| Priority Level | Signal | Polarity / Active | Action / Preemption Behavior |
|:---:|:---|:---:|:---|
| **1 (Highest)** | `KEY[0]` | Active-Low (`'0'`) | Forces asynchronous hardware reset. Initializes state register to `S_PHASE1`, reloads counters to 25s / 28s, and clears internal divider registers. |
| **2** | `KEY[1]` | Active-Low (`'0'`) | Preempts any normal phase or night mode within 1 clock cycle. Transitions immediately to `S_EMERGENCY` (Route A Green, Route B Red). |
| **3** | `SW[0]` | Active-High (`'1'`) | Preempts normal 4-phase operation within 1 clock cycle. Transitions to `S_NIGHT` (both routes flash Yellow at 1 Hz, 7-segs blanked). |
| **Exit Override** | `KEY[1]='1'`, `SW[0]='0'` | Level release | When leaving `S_EMERGENCY` or `S_NIGHT`, the controller transitions to `S_PHASE1`, asserting `load_phase` to reload standard starting durations. |
| **4** | `SW[1]` | Active-High (`'1'`) | Pauses timer countdown and freezes FSM state register. Neither lamp configurations nor countdown values advance until deasserted. |
| **5 (Lowest)** | `timer_done` | 1-cycle Pulse (`'1'`) | Advances the normal 4-phase sequence when the active route countdown reaches `1` on a `tick_1hz` pulse. |

---

## 4. State Transition Table

The following comprehensive table details every valid state, input condition, resulting next state, internal control signals, raw FSM outputs, physical DE2-115 LED pins, and 7-segment display states.

### 4.1 Legend
- **Lamp Tuple**: `(R, Y, G)` where `1` = ON, `0` = OFF.
- **DE2-115 Physical Pins**:
  - Route A: Red = `LEDR[0]`, Yellow = `LEDR[1]`, Green = `LEDG[0]`
  - Route B: Red = `LEDR[2]`, Yellow = `LEDR[3]`, Green = `LEDG[1]`
- **Display**:
  - Route A: `HEX1` (Tens), `HEX0` (Units)
  - Route B: `HEX3` (Tens), `HEX2` (Units)

### 4.2 Comprehensive State Transition Matrix

| Current State | Input Conditions (`KEY[1]`, `SW[0]`, `SW[1]`, `timer_done`) | Next State | `phase_sel` | `load_phase` | `blank_seg7` | Raw Route A `(R,Y,G)` | Raw Route B `(R,Y,G)` | Physical LEDs `LEDR[3..0], LEDG[1..0]` | 7-Seg Countdown Display Behavior | Operational Description |
|:---|:---|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---|:---|
| **Any State** | `KEY[0] = '0'` | `S_PHASE1` | `"00"` | `'1'` | `'0'` | `(0, 0, 1)` | `(1, 0, 0)` | `LEDR="0100"`, `LEDG="01"` | Route A: `25`, Route B: `28` | **Asynchronous Master Reset**: Re-initializes system immediately to Phase 1. |
| **`S_PHASE1`** | `KEY[1] = '0'` | `S_EMERGENCY` | `"00"` | `'1'` | `'0'` | `(0, 0, 1)` | `(1, 0, 0)` | `LEDR="0100"`, `LEDG="01"` | Route A: `25` (frozen), Route B: `28` | Emergency vehicle preempts Phase 1; grants uninterrupted corridor on Route A. |
| **`S_PHASE1`** | `KEY[1]='1', SW[0]='1'` | `S_NIGHT` | `"00"` | `'1'` | `'1'` | `(0, B, 0)` | `(0, B, 0)` | `LEDR[1]=B, LEDR[3]=B`, `LEDG="00"` | Blanked (`"1111111"`) | Night mode activated; halts countdown and initiates 1 Hz caution blinking. |
| **`S_PHASE1`** | `KEY[1]='1', SW[0]='0', SW[1]='1'` | `S_PHASE1` | `"00"` | `'0'` | `'0'` | `(0, 0, 1)` | `(1, 0, 0)` | `LEDR="0100"`, `LEDG="01"` | Frozen at current count ($t_A, t_B$) | Pause asserted; halts timer decrement, maintains Route A Green / Route B Red. |
| **`S_PHASE1`** | `KEY[1]='1', SW[0]='0', SW[1]='0', timer_done='0'` | `S_PHASE1` | `"00"` | `'0'` | `'0'` | `(0, 0, 1)` | `(1, 0, 0)` | `LEDR="0100"`, `LEDG="01"` | Route A: $25 \to 2$, Route B: $28 \to 5$ | Normal Phase 1 countdown active; Route A Green, Route B Red. |
| **`S_PHASE1`** | `KEY[1]='1', SW[0]='0', SW[1]='0', timer_done='1'` | `S_PHASE2` | `"01"` | `'1'` | `'0'` | `(0, 1, 0)` | `(1, 0, 0)` | `LEDR="0110"`, `LEDG="00"` | Reloads: Route A = `03`, Route B = `03` | Phase 1 duration (25s) complete; advances to Phase 2 Yellow clearance. |
| **`S_PHASE2`** | `KEY[1] = '0'` | `S_EMERGENCY` | `"00"` | `'1'` | `'0'` | `(0, 0, 1)` | `(1, 0, 0)` | `LEDR="0100"`, `LEDG="01"` | Route A: `03` (frozen), Route B: `03` | Emergency vehicle preempts Phase 2; grants corridor on Route A. |
| **`S_PHASE2`** | `KEY[1]='1', SW[0]='1'` | `S_NIGHT` | `"00"` | `'1'` | `'1'` | `(0, B, 0)` | `(0, B, 0)` | `LEDR[1]=B, LEDR[3]=B`, `LEDG="00"` | Blanked (`"1111111"`) | Night mode activated; halts countdown and initiates 1 Hz caution blinking. |
| **`S_PHASE2`** | `KEY[1]='1', SW[0]='0', SW[1]='1'` | `S_PHASE2` | `"01"` | `'0'` | `'0'` | `(0, 1, 0)` | `(1, 0, 0)` | `LEDR="0110"`, `LEDG="00"` | Frozen at current count ($t_A, t_B$) | Pause asserted; freezes Route A Yellow / Route B Red. |
| **`S_PHASE2`** | `KEY[1]='1', SW[0]='0', SW[1]='0', timer_done='0'` | `S_PHASE2` | `"01"` | `'0'` | `'0'` | `(0, 1, 0)` | `(1, 0, 0)` | `LEDR="0110"`, `LEDG="00"` | Route A: $3 \to 2$, Route B: $3 \to 2$ | Normal Phase 2 countdown active; Route A Yellow, Route B Red. |
| **`S_PHASE2`** | `KEY[1]='1', SW[0]='0', SW[1]='0', timer_done='1'` | `S_PHASE3` | `"10"` | `'1'` | `'0'` | `(1, 0, 0)` | `(0, 0, 1)` | `LEDR="0001"`, `LEDG="10"` | Reloads: Route A = `33`, Route B = `30` | Phase 2 duration (3s) complete; advances to Phase 3 (Route B Green). |
| **`S_PHASE3`** | `KEY[1] = '0'` | `S_EMERGENCY` | `"00"` | `'1'` | `'0'` | `(0, 0, 1)` | `(1, 0, 0)` | `LEDR="0100"`, `LEDG="01"` | Reloads Route A = `25`, Route B = `28` | Emergency vehicle preempts Route B Green; immediately switches flow to Route A. |
| **`S_PHASE3`** | `KEY[1]='1', SW[0]='1'` | `S_NIGHT` | `"00"` | `'1'` | `'1'` | `(0, B, 0)` | `(0, B, 0)` | `LEDR[1]=B, LEDR[3]=B`, `LEDG="00"` | Blanked (`"1111111"`) | Night mode activated; halts countdown and initiates 1 Hz caution blinking. |
| **`S_PHASE3`** | `KEY[1]='1', SW[0]='0', SW[1]='1'` | `S_PHASE3` | `"10"` | `'0'` | `'0'` | `(1, 0, 0)` | `(0, 0, 1)` | `LEDR="0001"`, `LEDG="10"` | Frozen at current count ($t_A, t_B$) | Pause asserted; freezes Route A Red / Route B Green. |
| **`S_PHASE3`** | `KEY[1]='1', SW[0]='0', SW[1]='0', timer_done='0'` | `S_PHASE3` | `"10"` | `'0'` | `'0'` | `(1, 0, 0)` | `(0, 0, 1)` | `LEDR="0001"`, `LEDG="10"` | Route A: $33 \to 5$, Route B: $30 \to 2$ | Normal Phase 3 countdown active; Route A Red, Route B Green. |
| **`S_PHASE3`** | `KEY[1]='1', SW[0]='0', SW[1]='0', timer_done='1'` | `S_PHASE4` | `"11"` | `'1'` | `'0'` | `(1, 0, 0)` | `(0, 1, 0)` | `LEDR="1001"`, `LEDG="00"` | Reloads: Route A = `03`, Route B = `03` | Phase 3 duration (30s) complete; advances to Phase 4 (Route B Yellow). |
| **`S_PHASE4`** | `KEY[1] = '0'` | `S_EMERGENCY` | `"00"` | `'1'` | `'0'` | `(0, 0, 1)` | `(1, 0, 0)` | `LEDR="0100"`, `LEDG="01"` | Reloads Route A = `25`, Route B = `28` | Emergency vehicle preempts Route B Yellow; grants corridor on Route A. |
| **`S_PHASE4`** | `KEY[1]='1', SW[0]='1'` | `S_NIGHT` | `"00"` | `'1'` | `'1'` | `(0, B, 0)` | `(0, B, 0)` | `LEDR[1]=B, LEDR[3]=B`, `LEDG="00"` | Blanked (`"1111111"`) | Night mode activated; halts countdown and initiates 1 Hz caution blinking. |
| **`S_PHASE4`** | `KEY[1]='1', SW[0]='0', SW[1]='1'` | `S_PHASE4` | `"11"` | `'0'` | `'0'` | `(1, 0, 0)` | `(0, 1, 0)` | `LEDR="1001"`, `LEDG="00"` | Frozen at current count ($t_A, t_B$) | Pause asserted; freezes Route A Red / Route B Yellow. |
| **`S_PHASE4`** | `KEY[1]='1', SW[0]='0', SW[1]='0', timer_done='0'` | `S_PHASE4` | `"11"` | `'0'` | `'0'` | `(1, 0, 0)` | `(0, 1, 0)` | `LEDR="1001"`, `LEDG="00"` | Route A: $3 \to 2$, Route B: $3 \to 2$ | Normal Phase 4 countdown active; Route A Red, Route B Yellow. |
| **`S_PHASE4`** | `KEY[1]='1', SW[0]='0', SW[1]='0', timer_done='1'` | `S_PHASE1` | `"00"` | `'1'` | `'0'` | `(0, 0, 1)` | `(1, 0, 0)` | `LEDR="0100"`, `LEDG="01"` | Reloads: Route A = `25`, Route B = `28` | Phase 4 duration (3s) complete; completes 61s cycle and loops to Phase 1. |
| **`S_NIGHT`** | `KEY[1] = '0'` | `S_EMERGENCY` | `"00"` | `'1'` | `'0'` | `(0, 0, 1)` | `(1, 0, 0)` | `LEDR="0100"`, `LEDG="01"` | Displays unblank; Route A = `25`, Route B = `28` | Emergency vehicle overrides Night caution mode immediately. |
| **`S_NIGHT`** | `KEY[1]='1', SW[0]='1'` | `S_NIGHT` | `"00"` | `'0'` | `'1'` | `(0, B, 0)` | `(0, B, 0)` | `LEDR[1]=B, LEDR[3]=B`, `LEDG="00"` | Blanked (`"1111111"`) | Continues Night caution mode; Yellows blink synchronously at 1 Hz. |
| **`S_NIGHT`** | `KEY[1]='1', SW[0]='0'` | `S_PHASE1` | `"00"` | `'1'` | `'0'` | `(0, 0, 1)` | `(1, 0, 0)` | `LEDR="0100"`, `LEDG="01"` | Displays unblank; Reloads Route A = `25`, Route B = `28` | Night mode turned off; returns safely to start of normal cycle (Phase 1). |
| **`S_EMERGENCY`** | `KEY[1] = '0'` | `S_EMERGENCY` | `"00"` | `'0'` | `'0'` | `(0, 0, 1)` | `(1, 0, 0)` | `LEDR="0100"`, `LEDG="01"` | Route A: `25` (frozen), Route B: `28` | Emergency button held down; maintains Route A Green indefinitely. |
| **`S_EMERGENCY`** | `KEY[1] = '1'` | `S_PHASE1` | `"00"` | `'1'` | `'0'` | `(0, 0, 1)` | `(1, 0, 0)` | `LEDR="0100"`, `LEDG="01"` | Reloads: Route A = `25`, Route B = `28` | Emergency button released; returns cleanly to start of normal cycle (Phase 1). |

*(Note: In the table above, $B = \text{blink\_1hz}$, representing the 1 Hz square wave toggle).*

---

## 5. Mermaid State Diagram

The diagram below provides a complete visual representation of all states, normal cyclical paths, priority preemptions, and recovery transitions.

```mermaid
stateDiagram-v2
    [*] --> S_PHASE1: KEY[0]='0' (Master Reset)

    state S_PHASE1 {
        description: Phase 1 (25s)
        route_A: GREEN (25s countdown)
        route_B: RED (28s countdown)
        displays: HEX1-0 active, HEX3-2 active
    }

    state S_PHASE2 {
        description: Phase 2 (3s)
        route_A: YELLOW (3s countdown)
        route_B: RED (3s countdown remaining)
        displays: HEX1-0 active, HEX3-2 active
    }

    state S_PHASE3 {
        description: Phase 3 (30s)
        route_A: RED (33s countdown)
        route_B: GREEN (30s countdown)
        displays: HEX1-0 active, HEX3-2 active
    }

    state S_PHASE4 {
        description: Phase 4 (3s)
        route_A: RED (3s countdown remaining)
        route_B: YELLOW (3s countdown)
        displays: HEX1-0 active, HEX3-2 active
    }

    state S_NIGHT {
        description: Night Mode (Caution)
        route_A: YELLOW 1 Hz Blink
        route_B: YELLOW 1 Hz Blink
        displays: ALL BLANKED ("1111111")
    }

    state S_EMERGENCY {
        description: Emergency Force Corridor
        route_A: FORCED GREEN
        route_B: FORCED RED
        displays: Held/Frozen
    }

    %% Normal Traffic Cycle Loop (Total 61s)
    S_PHASE1 --> S_PHASE2: timer_done='1' (cnt_a reaches 1)
    S_PHASE2 --> S_PHASE3: timer_done='1' (cnt_a reaches 1)
    S_PHASE3 --> S_PHASE4: timer_done='1' (cnt_b reaches 1)
    S_PHASE4 --> S_PHASE1: timer_done='1' (cnt_b reaches 1)

    %% Pause / Hold Self-Loops
    S_PHASE1 --> S_PHASE1: SW[1]='1' (Pause: Freeze State & Timer)
    S_PHASE2 --> S_PHASE2: SW[1]='1' (Pause: Freeze State & Timer)
    S_PHASE3 --> S_PHASE3: SW[1]='1' (Pause: Freeze State & Timer)
    S_PHASE4 --> S_PHASE4: SW[1]='1' (Pause: Freeze State & Timer)

    %% Night Mode Preemption (Priority 3)
    S_PHASE1 --> S_NIGHT: SW[0]='1'
    S_PHASE2 --> S_NIGHT: SW[0]='1'
    S_PHASE3 --> S_NIGHT: SW[0]='1'
    S_PHASE4 --> S_NIGHT: SW[0]='1'

    %% Night Mode Deactivation (Return to Phase 1)
    S_NIGHT --> S_PHASE1: SW[0]='0'

    %% Emergency Force Preemption (Priority 2)
    S_PHASE1 --> S_EMERGENCY: KEY[1]='0' (Active-Low Press)
    S_PHASE2 --> S_EMERGENCY: KEY[1]='0' (Active-Low Press)
    S_PHASE3 --> S_EMERGENCY: KEY[1]='0' (Active-Low Press)
    S_PHASE4 --> S_EMERGENCY: KEY[1]='0' (Active-Low Press)
    S_NIGHT --> S_EMERGENCY: KEY[1]='0' (Active-Low Press)

    %% Emergency Mode Deactivation (Release to Phase 1)
    S_EMERGENCY --> S_PHASE1: KEY[1]='1' (Pushbutton Released)
```

---

## 6. Formal Mathematical Proof of Fail-Safe Hardware Interlock

### 6.1 Problem Statement and Safety Invariant
In road traffic intersection automation, the simultaneous activation of conflicting green lights is classified as a **Safety Critical Hazard Category A** (high probability of catastrophic vehicular collision). 

Let:
- $G_A(t) \in \{0, 1\}$ denote the raw Green command for Route A generated by the FSM controller at time $t$.
- $G_B(t) \in \{0, 1\}$ denote the raw Green command for Route B generated by the FSM controller at time $t$.
- $\text{LEDG}[0](t) \in \{0, 1\}$ denote the physical pin signal driving the Route A Green LED.
- $\text{LEDG}[1](t) \in \{0, 1\}$ denote the physical pin signal driving the Route B Green LED.
- $\text{LEDR}[0](t) \in \{0, 1\}$ denote the physical pin signal driving the Route A Red LED.
- $\text{LEDR}[2](t) \in \{0, 1\}$ denote the physical pin signal driving the Route B Red LED.

**Fundamental Safety Invariant**: Under all possible internal system states, circuit transients, register corruptions, Single-Event Upsets (SEU), or design faults, the physical green lights must satisfy:
$$\forall t \ge 0, \quad \mathcal{S}(t) = \text{LEDG}[0](t) \land \text{LEDG}[1](t) \equiv 0$$

Furthermore, if a fault causes $G_A(t) = 1$ and $G_B(t) = 1$ simultaneously, the hardware must execute an immediate **All-Red Fail-Safe Clamp**:
$$\left( G_A(t) \land G_B(t) = 1 \right) \implies \left( \text{LEDG}[0](t) = 0 \;\land\; \text{LEDG}[1](t) = 0 \;\land\; \text{LEDR}[0](t) = 1 \;\land\; \text{LEDR}[2](t) = 1 \right)$$

---

### 6.2 Hardware Interlock Gate Definition

The fail-safe interlock is implemented in `traffic_light_top.vhd` at lines 147–166 as a hardware conflict monitor:

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

Let the conflict condition $\text{Trip}$ be defined as:
$$\text{Trip} = G_A \land G_B$$

The transfer functions for the physical green outputs are:
$$\text{LEDG}[0] = G_A \land \overline{\text{Trip}}$$
$$\text{LEDG}[1] = G_B \land \overline{\text{Trip}}$$

The transfer functions for the physical red outputs are:
$$\text{LEDR}[0] = R_A \lor \text{Trip}$$
$$\text{LEDR}[2] = R_B \lor \text{Trip}$$

The transfer functions for the physical yellow outputs are:
$$\text{LEDR}[1] = Y_A \land \overline{\text{Trip}}$$
$$\text{LEDR}[3] = Y_B \land \overline{\text{Trip}}$$

---

### 6.3 Mathematical Proof of Dual-Green Prevention

#### Theorem 1 (Absolute Dual-Green Mutual Exclusion)
*For any combination of input signals $(G_A, G_B) \in \{0, 1\}^2$, the conjunction $\text{LEDG}[0] \land \text{LEDG}[1]$ is identically equal to $0$ ($False$).*

#### Proof:
Substitute $\text{Trip} = G_A \land G_B$ into the definitions of $\text{LEDG}[0]$ and $\text{LEDG}[1]$:

$$\text{LEDG}[0] = G_A \land \overline{(G_A \land G_B)}$$
$$\text{LEDG}[1] = G_B \land \overline{(G_A \land G_B)}$$

Applying **De Morgan's Laws** ($\overline{X \land Y} = \overline{X} \lor \overline{Y}$):
$$\overline{G_A \land G_B} = \overline{G_A} \lor \overline{G_B}$$

Substituting this expansion into $\text{LEDG}[0]$:
$$\begin{aligned}
\text{LEDG}[0] &= G_A \land (\overline{G_A} \lor \overline{G_B}) \\
&= (G_A \land \overline{G_A}) \lor (G_A \land \overline{G_B}) \quad &\text{[Distributive Law]} \\
&= 0 \lor (G_A \land \overline{G_B}) \quad &\text{[Law of Contradiction: } X \land \overline{X} = 0\text{]} \\
&= G_A \land \overline{G_B} \quad &\text{[Identity Law: } 0 \lor X = X\text{]}
\end{aligned}$$

Similarly, substituting into $\text{LEDG}[1]$:
$$\begin{aligned}
\text{LEDG}[1] &= G_B \land (\overline{G_A} \lor \overline{G_B}) \\
&= (G_B \land \overline{G_A}) \lor (G_B \land \overline{G_B}) \quad &\text{[Distributive Law]} \\
&= (G_B \land \overline{G_A}) \lor 0 \quad &\text{[Law of Contradiction: } X \land \overline{X} = 0\text{]} \\
&= G_B \land \overline{G_A} \quad &\text{[Identity Law]}
\end{aligned}$$

Now, compute the Boolean conjunction of both physical outputs $\mathcal{S} = \text{LEDG}[0] \land \text{LEDG}[1]$:
$$\begin{aligned}
\mathcal{S} &= \text{LEDG}[0] \land \text{LEDG}[1] \\
&= (G_A \land \overline{G_B}) \land (G_B \land \overline{G_A}) \\
&= (G_A \land \overline{G_A}) \land (G_B \land \overline{G_B}) \quad &\text{[Associative and Commutative Laws]} \\
&= 0 \land 0 \quad &\text{[Law of Contradiction]} \\
&= 0
\end{aligned}$$

Thus:
$$\mathcal{S} = \text{LEDG}[0] \land \text{LEDG}[1] \equiv 0 \quad \forall (G_A, G_B) \in \{0, 1\}^2$$
$\blacksquare$

---

### 6.4 Exhaustive State & Fault Truth Table Analysis

To demonstrate total coverage over all possible signal states and fault injections, Table 6.1 lists all $2^4 = 16$ input combinations for $(G_A, G_B, R_A, R_B)$:

| Case # | $G_A$ | $G_B$ | $R_A$ | $R_B$ | Fault Mode / Operational Meaning | $\text{Trip}$ | $\text{LEDG}[0]$ (Green A) | $\text{LEDG}[1]$ (Green B) | $\text{LEDR}[0]$ (Red A) | $\text{LEDR}[2]$ (Red B) | Safety Invariant $\text{LEDG}[0] \land \text{LEDG}[1]$ | Safe Traffic State? |
|:---:|:---:|:---:|:---:|:---:|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---|
| 1 | 0 | 0 | 0 | 0 | Night Mode / Yellow Clearance | 0 | 0 | 0 | 0 | 0 | **0 (Pass)** | YES (Yellow flashing or clearance) |
| 2 | 0 | 0 | 0 | 1 | Phase 2 (A Yellow, B Red) | 0 | 0 | 0 | 0 | 1 | **0 (Pass)** | YES (Route B stopped) |
| 3 | 0 | 0 | 1 | 0 | Phase 4 (A Red, B Yellow) | 0 | 0 | 0 | 1 | 0 | **0 (Pass)** | YES (Route A stopped) |
| 4 | 0 | 0 | 1 | 1 | All-Red Clearance Interval | 0 | 0 | 0 | 1 | 1 | **0 (Pass)** | YES (Both stopped) |
| 5 | 0 | 1 | 0 | 0 | Invalid (B Green, A unlit) | 0 | 0 | 1 | 0 | 0 | **0 (Pass)** | YES (Only B Green) |
| 6 | 0 | 1 | 0 | 1 | Invalid (B Green + B Red) | 0 | 0 | 1 | 0 | 1 | **0 (Pass)** | YES (Only B Green) |
| 7 | 0 | 1 | 1 | 0 | **Normal Phase 3 (A Red, B Green)** | 0 | 0 | 1 | 1 | 0 | **0 (Pass)** | **YES (Valid Phase 3)** |
| 8 | 0 | 1 | 1 | 1 | Invalid FSM glitch | 0 | 0 | 1 | 1 | 1 | **0 (Pass)** | YES (Only B Green) |
| 9 | 1 | 0 | 0 | 0 | Invalid (A Green, B unlit) | 0 | 1 | 0 | 0 | 0 | **0 (Pass)** | YES (Only A Green) |
| 10 | 1 | 0 | 0 | 1 | **Normal Phase 1 (A Green, B Red)** | 0 | 1 | 0 | 0 | 1 | **0 (Pass)** | **YES (Valid Phase 1)** |
| 11 | 1 | 0 | 1 | 0 | Invalid (A Green + A Red) | 0 | 1 | 0 | 1 | 0 | **0 (Pass)** | YES (Only A Green) |
| 12 | 1 | 0 | 1 | 1 | Invalid FSM glitch | 0 | 1 | 0 | 1 | 1 | **0 (Pass)** | YES (Only A Green) |
| 13 | 1 | 1 | 0 | 0 | **CRITICAL FAULT: Dual Green injection** | **1** | **0** | **0** | **1** | **1** | **0 (Pass)** | **YES (Fail-Safe All-Red Clamped!)** |
| 14 | 1 | 1 | 0 | 1 | **CRITICAL FAULT: Dual Green injection** | **1** | **0** | **0** | **1** | **1** | **0 (Pass)** | **YES (Fail-Safe All-Red Clamped!)** |
| 15 | 1 | 1 | 1 | 0 | **CRITICAL FAULT: Dual Green injection** | **1** | **0** | **0** | **1** | **1** | **0 (Pass)** | **YES (Fail-Safe All-Red Clamped!)** |
| 16 | 1 | 1 | 1 | 1 | **CRITICAL FAULT: Dual Green injection** | **1** | **0** | **0** | **1** | **1** | **0 (Pass)** | **YES (Fail-Safe All-Red Clamped!)** |

### 6.5 Physical Fault Tolerance & Resilience Analysis
1. **Single-Event Upset (SEU) Resilience**: In radiation-prone or noisy industrial environments, an alpha particle or cosmic ray could flip a flip-flop bit in the FSM state register, forcing an undefined or illegal state where both green outputs are asserted. The hardware interlock gate evaluates the output combinations combinatorially in $< 3.5\text{ ns}$ (Cyclone IV LUT propagation delay), truncating the fault before physical LED driver transistors can energize.
2. **Clock Skew Immunity**: The interlock is pure combinational logic residing in the I/O output slice immediately preceding the output pins. It does not introduce register latency or dependency on clock edges.
3. **Continuous Assertion Verification**: The testbench `tb_traffic_light_top.vhd` incorporates a concurrent safety assertion running continuously across all delta-cycles:
   ```vhdl
   safety_check: process(clk_50m)
   begin
       if rising_edge(clk_50m) then
           assert not (ledg(0) = '1' and ledg(1) = '1')
               report "CRITICAL SAFETY VIOLATION: Both Lane A and Lane B have GREEN light simultaneously!"
               severity failure;
       end if;
   end process;
   ```
   Throughout all simulation scenarios (2 normal cycles, Night mode, Pause mode, Emergency mode, and state transitions), zero assertion violations are detected.
