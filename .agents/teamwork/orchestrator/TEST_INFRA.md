# E2E Test Infra: DE2-115 FPGA Traffic Light Controller

## Test Philosophy
- Opaque-box, requirement-driven, and continuous safety assertion.
- Methodology: Category-Partition + Boundary Value Analysis + Pairwise Combinatorial + Real-World Workload Testing.
- Zero tolerance for simulated or physical safety breaches (`LEDG[0] = '1' and LEDG[1] = '1'`).

## Feature Inventory & Test Coverage Mapping
| # | Feature | Requirement Source | Tier 1 (Isolated) | Tier 2 (Boundary) | Tier 3 (Cross-Mode) | Tier 4 (Workload) |
|---|---------|-------------------|:-----------------:|:-----------------:|:-------------------:|:-----------------:|
| 1 | Master Clock & Divider | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ | ✓ |
| 2 | Reset Sequencing | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ | ✓ |
| 3 | Normal 4-Phase Cycles | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ | ✓ |
| 4 | Countdown & BCD | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ | ✓ |
| 5 | Active-Low 7-Segment | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ | ✓ |
| 6 | Night Mode 1Hz Blink | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ | ✓ |
| 7 | Night Mode 7-Seg Blank | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ | ✓ |
| 8 | Pause / Hold State | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ | ✓ |
| 9 | Emergency Force Override | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ | ✓ |
| 10 | Fail-Safe Interlock Gate | ORIGINAL_REQUEST §R1 | 5 | 5 | ✓ | ✓ |

## Test Architecture
- **Testbench**: `traffic_light_fpga/tb/tb_traffic_light_top.vhd`
- **Simulation Scripts**: `traffic_light_fpga/sim/run_sim.do`, `traffic_light_fpga/sim/wave.do`
- **Simulation Scaling**: `SIMULATION => true` scales 1 second to 50 clock cycles (1 us @ 50 MHz), enabling complete multi-cycle simulation in ~200 us running in <3s.
- **Continuous Assertion Monitor**:
  ```vhdl
  assert not (ledg(0) = '1' and ledg(1) = '1')
      report "CRITICAL INTERLOCK VIOLATION: Both routes green!"
      severity failure;
  ```

## Test Tiers & Acceptance Criteria
- **Tier 1 (Feature Coverage)**: Each phase duration verified: Phase 1 (25s), Phase 2 (3s), Phase 3 (30s), Phase 4 (3s). Active LED polarities confirmed.
- **Tier 2 (Boundary & Corner)**: Transitions at countdown value = 1, counter reload from 25/28, 3/3, 33/30. BCD boundary transitions (30->29, 20->19, 10->9, 1->0).
- **Tier 3 (Cross-Feature Combinations)**: Emergency override during Phase 3; Night mode entry during Phase 2; Pause activated during Phase 1 countdown. Priority preemption verified.
- **Tier 4 (Real-World Application Scenarios)**:
  - Scenario 1: 2 full normal cycles without interruption.
  - Scenario 2: Heavy night traffic transition (Day -> Night -> Day).
  - Scenario 3: Maintenance hold (Pause mid-phase, held for 4s, resumed smoothly).
  - Scenario 4: VIP/Ambulance preemption (Emergency button pressed while cross-traffic has Green).
