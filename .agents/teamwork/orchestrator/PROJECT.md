# Project: DE2-115 FPGA Traffic Light Controller (`traffic_light_fpga`)

## 1. Architecture

### System Block Diagram
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

### Core Architecture Principles
1. **Single Synchronous Clock Domain**: All sequential logic clocked on `rising_edge(CLOCK_50)` (50.0 MHz). Gated/ripple clocks strictly forbidden. `tick_1hz` is a single-cycle synchronous clock enable pulse.
2. **IEEE 1164 & numeric_std**: Strictly pure standard packages. `std_logic_arith` and `std_logic_unsigned` strictly prohibited.
3. **Zero Inferred Latches**: 100% synchronous registers; all combinational processes have unconditional default assignments.
4. **Hardware Interlock Safety Barrier**: Physical logic gate ensures Route A Green and Route B Green are mutually exclusive under all circumstances:
   - $\text{Trip} = \text{Green}_A \land \text{Green}_B$
   - $\text{LEDG}[0] = \text{Green}_A \land \neg \text{Trip}$
   - $\text{LEDG}[1] = \text{Green}_B \land \neg \text{Trip}$
   - $\text{LEDR}[0] = \text{Red}_A \lor \text{Trip}$
   - $\text{LEDR}[2] = \text{Red}_B \lor \text{Trip}$
5. **Simulation Mode Generic**: Generic `SIMULATION : boolean := false` scales 1-second modulus from 50,000,000 cycles to 50 cycles for ultrafast verification.

---

## 2. Feature Inventory

| # | Feature | Description | Milestone | Source | Status |
|---|---------|-------------|-----------|--------|--------|
| 1 | 50 MHz Master Clock | `CLOCK_50` on PIN_Y2, single synchronous clock domain | M1 | ORIGINAL_REQUEST §R1 | DONE |
| 2 | Asynchronous Reset | `KEY[0]` active-low system reset into Phase 1 | M1 | ORIGINAL_REQUEST §R1 | DONE |
| 3 | Emergency Force Override | `KEY[1]` active-low immediate Route A Green corridor | M1 | ORIGINAL_REQUEST §R1 | DONE |
| 4 | Night Caution Mode | `SW[0]` active-high 1 Hz Yellow blinking on both routes | M1 | ORIGINAL_REQUEST §R1 | DONE |
| 5 | Pause/Hold Mode | `SW[1]` active-high freezing counter and FSM state | M1 | ORIGINAL_REQUEST §R1 | DONE |
| 6 | 4-Phase Moore Traffic FSM | Phase 1 (25s/28s), Phase 2 (3s/3s), Phase 3 (33s/30s), Phase 4 (3s/3s) | M1 | ORIGINAL_REQUEST §R1 | DONE |
| 7 | Dual Countdown Timer | Synchronous decrements, per-phase reload, range 1..33 | M1 | ORIGINAL_REQUEST §R1 | DONE |
| 8 | Combinational BCD Split | Tens and Units 4-bit BCD separation for Route A & B without division (0..63) | M1 | ORIGINAL_REQUEST §R1 | DONE |
| 9 | Active-Low 7-Segment Decoder | Digits 0-9 decoding, blanking ("1111111") on Night Mode & invalid BCD | M1 | ORIGINAL_REQUEST §R1 | DONE |
| 10 | Hardware Interlock Gate | Fail-safe All-Red override if dual green condition ever occurs | M1 | ORIGINAL_REQUEST §R1 | DONE |
| 11 | Top-Level DE2-115 Port Map | Entity `traffic_light_top` connecting all submodules to DE2-115 pins | M1 | ORIGINAL_REQUEST §R1 | DONE |
| 12 | Testbench 50 MHz Clock & Reset | Accelerated clock generator & clean reset stimulus sequence | M2 | ORIGINAL_REQUEST §R2 | DONE |
| 13 | Testbench Scenario 1 (Normal Cycles) | 2 consecutive complete 61s traffic cycles (122 us sim) | M2 | ORIGINAL_REQUEST §R2 | DONE |
| 14 | Testbench Scenario 2 (Night Mode) | Verification of 1 Hz yellow blinking & 7-seg blanking | M2 | ORIGINAL_REQUEST §R2 | DONE |
| 15 | Testbench Scenario 3 (Pause/Hold) | Verification of frozen countdown and resuming without error | M2 | ORIGINAL_REQUEST §R2 | DONE |
| 16 | Testbench Scenario 4 (Emergency Force) | Verification of immediate preemption to Route A Green | M2 | ORIGINAL_REQUEST §R2 | DONE |
| 17 | Continuous Safety Assertion | Concurrent `assert not (LEDG(0)='1' and LEDG(1)='1')` | M2 | ORIGINAL_REQUEST §R2 | DONE |
| 18 | ModelSim Automation Scripts | `run_sim.do` compilation & execution; `wave.do` 6 grouped waves | M2 | ORIGINAL_REQUEST §R2 | DONE |
| 19 | Pin Assignment & I/O Standard | `de2_115_pins.qsf` locking 39 pins to 3.3-V LVTTL on Cyclone IV E | M3 | ORIGINAL_REQUEST §R3 | DONE |
| 20 | Timing Constraints | `de2_115.sdc` 50 MHz clock definition & false path constraints | M3 | ORIGINAL_REQUEST §R3 | DONE |
| 21 | Synthesis & Timing Audit | Verifying 0 inferred latches and 50 MHz timing closure ($T_{slack} > 0$) | M3 | ORIGINAL_REQUEST §R3 | DONE |
| 22 | FSM State Documentation | `fsm_state_diagram.md`: State table, priority tree, Mermaid diagram | M4 | ORIGINAL_REQUEST §R4 | DONE |
| 23 | Timing & Deployment Guide | `timing_specifications.md`: Clock trees, phase math, Quartus tutorial | M4 | ORIGINAL_REQUEST §R4 | DONE |
| 24 | E2E Final Acceptance & Coverage | 100% test pass across all tiers and adversarial stress hardening | M5 | Acceptance Criteria | DONE |

---

## 3. Milestones

| # | Name | Scope | Dependencies | Status | Output Artifacts |
|---|------|-------|-------------|--------|------------------|
| M1 | RTL Architecture & Design | `clk_divider.vhd`, `timer_counter.vhd`, `fsm_controller.vhd`, `seg7_decoder.vhd`, `traffic_light_top.vhd` in `traffic_light_fpga/rtl/` | None | **DONE** | 5 VHDL modules, 0 latches, verified in ModelSim |
| M2 | Verification & Simulation | `tb_traffic_light_top.vhd` in `traffic_light_fpga/tb/`, `run_sim.do` and `wave.do` in `traffic_light_fpga/sim/` | M1 | **DONE** | Hardened self-checking testbench, 100% pass in ModelSim |
| M3 | Synthesis Constraints & Pin Mapping | `de2_115_pins.qsf`, `de2_115.sdc`, and synthesis verification report in `traffic_light_fpga/syn/` | M1 | **DONE** | 39 pins locked, 3.3-V LVTTL, +14.486 ns slack in Quartus Prime Lite 20.1 |
| M4 | Documentation & Deployment Guide | `fsm_state_diagram.md` and `timing_specifications.md` in `traffic_light_fpga/docs/` | M1 | **DONE** | 25-row FSM table, Mermaid diagram, hardware fail-safe proof, Quartus tutorial |
| M5 | Final E2E Verification & Adversarial Hardening | Phase 1: 100% pass on all test scenarios. Phase 2: Adversarial edge-case audit. | M1, M2, M3, M4 | **DONE** | 100% passing test logs, CLEAN forensic audit, sign-off |

---

## 4. Code Layout

```
traffic_light_fpga/
├── rtl/
│   ├── clk_divider.vhd
│   ├── timer_counter.vhd
│   ├── fsm_controller.vhd
│   ├── seg7_decoder.vhd
│   └── traffic_light_top.vhd
├── tb/
│   └── tb_traffic_light_top.vhd
├── sim/
│   ├── run_sim.do
│   └── wave.do
├── syn/
│   ├── de2_115_pins.qsf
│   ├── de2_115.sdc
│   └── synthesis_report.md
└── docs/
    ├── fsm_state_diagram.md
    └── timing_specifications.md
```
