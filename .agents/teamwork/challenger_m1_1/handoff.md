# Adversarial Verification Report: Milestone M1 (RTL Architecture & Design)

**Verdict**: **APPROVE**  
**Agent**: Challenger 1 (`challenger_m1_1`)  
**Target Milestone**: M1 (RTL Architecture & Design)  
**Date**: 2026-10-01T17:54:00Z  

---

## 1. Observation

### 1.1. Codebase & Files Examined
The complete M1 RTL design in `traffic_light_fpga/rtl/` was inspected verbatim:
1. `clk_divider.vhd` (91 lines)
2. `timer_counter.vhd` (144 lines)
3. `fsm_controller.vhd` (172 lines)
4. `seg7_decoder.vhd` (51 lines)
5. `traffic_light_top.vhd` (169 lines)

### 1.2. Direct Verbatim Code Observations

#### Observation 1: FSM Priority Hierarchy & Preemption Logic
In `fsm_controller.vhd` (lines 54-117):
```vhdl
    -- Synchronous State Register and State Change Tracker
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

    -- Generate a clean 1-cycle load_phase pulse on state transition
    load_phase <= '1' when (current_state /= prev_state) else '0';

    -- Next-State Combinational Logic with Strict Priority Encoding
    process(current_state, key_emerg_n, sw_night, sw_pause, timer_done)
    begin
        next_state <= current_state; -- Default: prevent inferred latches

        -- Priority 1: Emergency Force (KEY[1] Active-Low)
        if key_emerg_n = '0' then
            next_state <= S_EMERGENCY;

        -- Priority 2: Night Mode (SW[0] Active-High)
        elsif sw_night = '1' then
            next_state <= S_NIGHT;

        -- Exit condition from override states when triggers are deasserted
        elsif current_state = S_EMERGENCY or current_state = S_NIGHT then
            next_state <= S_PHASE1;

        -- Priority 3: Pause/Hold (SW[1] Active-High)
        elsif sw_pause = '1' then
            next_state <= current_state; -- Freeze current phase

        -- Priority 4: Normal Traffic Flow Progression
        else
            case current_state is
                when S_PHASE1 =>
                    if timer_done = '1' then
                        next_state <= S_PHASE2;
                    end if;
```

#### Observation 2: Fail-Safe Hardware Interlock Layer
In `traffic_light_top.vhd` (lines 147-166):
```vhdl
    -- 5. Fail-Safe Hardware Interlock Layer (Conflict Monitor)
    -- Guarantee: LEDG(0) = '1' and LEDG(1) = '1' is mathematically prevented at the pins.
    -- If a dual-green fault condition ever arises, both routes are forced to RED (All-Red Fail-Safe).
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

#### Observation 3: Timer Countdown, Expiration & Reload Logic
In `timer_counter.vhd` (lines 68-130):
```vhdl
    -- Synchronous Countdown and Phase Load Process
    process(clk_50m, reset_n)
    begin
        if reset_n = '0' then
            cnt_a    <= 25;
            cnt_b    <= 28;
            done_reg <= '0';
        elsif rising_edge(clk_50m) then
            done_reg <= '0'; -- Default: 1-cycle pulse duration

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
                        cnt_a <= 25;
                        cnt_b <= 28;
                end case;
            elsif tick_1hz = '1' and pause = '0' then
                -- Timeout detection for the active controlling route in current phase
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

                -- Decrement counters synchronously down to 1
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
```

---

## 2. Logic Chain

### 2.1. Challenge 1: FSM Priority Contention

#### Scenario A: Emergency (`KEY[1]='0'`) and Night Mode (`SW[0]='1'`) simultaneously active
1. In `fsm_controller.vhd`, lines 74-81 implement an `if ... elsif` conditional tree:
   - Line 75: `if key_emerg_n = '0' then next_state <= S_EMERGENCY;`
   - Line 79: `elsif sw_night = '1' then next_state <= S_NIGHT;`
2. Because `key_emerg_n = '0'` is evaluated first at the top of the chain, the `elsif sw_night = '1'` branch is unreachable while `KEY[1]='0'`.
3. Thus, Emergency has absolute priority over Night Mode. Route A receives Green (`fsm_ga = '1'`) and Route B receives Red (`fsm_rb = '1'`).
4. When `KEY[1]` is released (`key_emerg_n = '1'`) while `SW[0]='1'`, the top branch becomes false, and `elsif sw_night = '1'` immediately takes effect on the next clock cycle, transitioning the FSM directly into `S_NIGHT`.
5. When both are cleared, line 83 (`elsif current_state = S_EMERGENCY or current_state = S_NIGHT then next_state <= S_PHASE1;`) executes, safely transitioning to Phase 1.
6. **Verdict**: Zero race condition, zero deadlock. Hierarchy is strictly deterministic.

#### Scenario B: Pause (`SW[1]='1'`) during Night Mode or Emergency
1. In `fsm_controller.vhd`, `sw_pause = '1'` is evaluated at line 87 (Priority 3), which is strictly lower in priority than Emergency (Priority 1, line 75) and Night Mode (Priority 2, line 79).
2. During `S_EMERGENCY`:
   - `next_state` is driven to `S_EMERGENCY` regardless of `sw_pause`.
   - `timer_counter.vhd` stops decrementing because `pause = '1'`, but the FSM in `S_EMERGENCY` does not monitor `timer_done`.
   - When Emergency is released (`KEY[1]='1'`), line 83 evaluates before line 87, forcing the transition `next_state <= S_PHASE1`. Once in Phase 1, `sw_pause = '1'` takes effect and holds the system at Phase 1.
3. During `S_NIGHT`:
   - `sw_night = '1'` overrides `sw_pause = '1'`.
   - Caution lamps continue blinking at 1 Hz (`fsm_ya <= blink_1hz; fsm_yb <= blink_1hz;`) because `blink_1hz` originates from the free-running `clk_divider.vhd`, which does not receive the `pause` signal.
   - 7-segment displays remain blanked (`blank_seg7 <= '1'`).
4. **Verdict**: Pause cannot disable Emergency corridor nor can it halt safety caution blinking in Night Mode.

#### Scenario C: Reset (`KEY[0]='0'`) pressed during any mode
1. `KEY[0]` is mapped to asynchronous reset `reset_n` on all sequential registers (`clk_divider`, `timer_counter`, `fsm_controller`).
2. Upon `reset_n = '0'`:
   - `clk_divider`: `count_reg <= 0`, `blink_reg <= '1'`, `tick_reg <= '0'`.
   - `timer_counter`: `cnt_a <= 25`, `cnt_b <= 28`, `done_reg <= '0'`.
   - `fsm_controller`: `current_state <= S_PHASE1`, `prev_state <= S_PHASE4`.
3. Because `current_state` (`S_PHASE1`) $\neq$ `prev_state` (`S_PHASE4`), `load_phase` evaluates to `'1'` immediately out of reset.
4. When `KEY[0]` is released, on the first active rising clock edge, `cnt_a` and `cnt_b` are synchronously re-confirmed at 25 and 28, and `prev_state` syncs to `S_PHASE1`, dropping `load_phase` to `'0'`.
5. **Verdict**: Asynchronous reset immediately and unconditionally restores the initial Phase 1 configuration from any state or mode.

---

### 2.2. Challenge 2: Hardware Interlock Safety Proof

#### Mathematical Proof of Dual Green Mutual Exclusion:
Let $G_A = \text{fsm\_ga\_s}$ and $G_B = \text{fsm\_gb\_s}$.
The interlock process in `traffic_light_top.vhd` defines:
$$\text{LEDG}(0) = G_A \land \neg(G_A \land G_B) = G_A \land (\neg G_A \lor \neg G_B) = G_A \land \neg G_B$$
$$\text{LEDG}(1) = G_B \land \neg(G_A \land G_B) = G_B \land (\neg G_A \lor \neg G_B) = G_B \land \neg G_A$$

Now compute the logical conjunction of both green outputs:
$$\text{LEDG}(0) \land \text{LEDG}(1) = (G_A \land \neg G_B) \land (G_B \land \neg G_A) = (G_A \land \neg G_A) \land (G_B \land \neg G_B) = 0 \land 0 \equiv 0$$

#### Exhaustive Truth Table:
| $G_A$ | $G_B$ | Condition $(G_A \land G_B)$ | $\text{LEDG}(0)$ | $\text{LEDG}(1)$ | $\text{LEDR}(0)$ (Red A) | $\text{LEDR}(2)$ (Red B) | Status |
|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---|
| 0 | 0 | 0 (False) | 0 | 0 | Raw $R_A$ | Raw $R_B$ | Safe |
| 0 | 1 | 0 (False) | 0 | 1 | Raw $R_A$ | Raw $R_B$ | Safe (Route B Green) |
| 1 | 0 | 0 (False) | 1 | 0 | Raw $R_A$ | Raw $R_B$ | Safe (Route A Green) |
| 1 | 1 | 1 (True)  | **0** | **0** | **1** (Forced) | **1** (Forced) | **Interlock Tripped: All-Red Fail-Safe** |

#### Physical Glitch and Timing Analysis:
- On Cyclone IV E FPGA architecture, each of $\text{LEDG}(0)$ and $\text{LEDG}(1)$ maps to a dedicated 4-LUT.
- The ON-set for $\text{LEDG}(0)$ is $\{G_A=1, G_B=0\}$.
- The ON-set for $\text{LEDG}(1)$ is $\{G_A=0, G_B=1\}$.
- Because the intersection of their ON-sets is identically null ($\text{ON}_0 \cap \text{ON}_1 = \emptyset$), no physical input combination—static, dynamic, or glitch-induced—can cause both outputs to evaluate high simultaneously.
- Furthermore, in the event of any state corruption or SEU resulting in $(G_A=1, G_B=1)$, the hardware interlock forces both Green outputs low and asserts both Red lamps (`LEDR[0]='1'`, `LEDR[2]='1'`), enforcing a fail-safe All-Red corridor.
- **Verdict**: Proven 100% fail-safe.

---

### 2.3. Challenge 3: State Transition Timing & Counter Reload Latency

#### Question 3A: Does `timer_done` trigger exactly when counter reaches 1?
1. Consider Phase 2 (3s duration, initialized to $A=3, B=3$):
   - $t=0$: Counter loaded with 3.
   - $t=1$ s (Tick 1): Before clock edge, `cnt_a = 3`. Condition `cnt_a = 1` is false. `cnt_a` decrements to 2.
   - $t=2$ s (Tick 2): Before clock edge, `cnt_a = 2`. Condition `cnt_a = 1` is false. `cnt_a` decrements to 1. **(Counter has reached 1)**. `done_reg` remains `'0'`.
   - $t=3$ s (Tick 3): Before clock edge, `cnt_a = 1`. Condition `cnt_a = 1` evaluates to **TRUE**. `done_reg <= '1'`.
2. Analysis:
   - Does `done_reg` trigger on Tick 2 (when counter transitions into 1)? **NO.**
   - It triggers on Tick 3 (after counter has been displayed as 1 for 1 full second).
   - This behavior is **architecturally required** for accurate countdown displays:
     - Value '3' displayed for 1.0 s (from $t=0$ to $t=1$)
     - Value '2' displayed for 1.0 s (from $t=1$ to $t=2$)
     - Value '1' displayed for 1.0 s (from $t=2$ to $t=3$)
     - Total elapsed phase duration = exactly 3.0 s!
   - If `timer_done` had triggered on Tick 2 when reaching 1, the phase duration would be cut short by 1 full second (2s instead of 3s; 24s instead of 25s; 29s instead of 30s), and drivers would never see '1'.
   - Furthermore, lines 119-124 clamp the counter at 1 (`if cnt_a > 1 then cnt_a <= cnt_a - 1; end if;`), preventing underflow or display of 0.

#### Question 3B: Does `load_phase` reload the new counter values on the exact cycle of state transition?
1. Let clock cycle $T$ be the cycle where `timer_done = '1'` is presented to `fsm_controller`.
2. Cycle $T+1$ (Rising edge of `CLOCK_50`):
   - `fsm_controller` registers: `current_state <= next_state` (e.g. `S_PHASE2`).
   - `prev_state` registers the old state (`S_PHASE1`).
   - Line 67 evaluates combinationally: `load_phase <= '1' when (current_state /= prev_state) else '0';`.
   - `load_phase` transitions to `'1'` at cycle $T+1$.
3. Cycle $T+2$ (Next rising edge of `CLOCK_50`, 20 ns later):
   - In `timer_counter.vhd`, the sequential process registers the new phase counts (`cnt_a <= 3; cnt_b <= 3;`) because `load_phase` was `'1'` before the edge.
   - In `fsm_controller.vhd`, `prev_state` registers `current_state` (`S_PHASE2`), causing `load_phase` to fall back to `'0'`.
4. Detailed Finding:
   - The counter reload takes effect at cycle $T+2$, which is **1 clock cycle (20 ns) after** `current_state` transitions at cycle $T+1$.
   - During the single 20 ns clock cycle of $T+1$, `current_state` is in the new phase while the counter registers still hold the clamped value '1'.
   - Impact assessment:
     - 20 ns is $2 \times 10^{-8}$ s—completely invisible to human vision and seven-segment displays.
     - `tick_1hz` is inactive (`'0'`) during this cycle; the next tick will not occur for 50,000,000 cycles (or 50 cycles in simulation).
     - `timer_done` has already deasserted to `'0'` at cycle $T+1$.
     - Therefore, there is zero risk of false re-triggering, race conditions, or display flickering.

---

## 3. Caveats

- **Gate-Level Post-Fit Timing**: This analysis verifies RTL architecture and behavioral logic. Post-synthesis timing closure ($T_{\text{slack}} > 0$ at 50 MHz) and exact pin delay models are validated during Milestone M3 on the Cyclone IV E netlist.
- **Physical Pushbutton Debouncing**: Pushbutton `KEY[1]` is sampled directly by `clk_50m`. If a physical key bounces on hardware release, the state alternates between `S_EMERGENCY` and `S_PHASE1`. Because both states command Route A Green and Route B Red, no conflicting lamp signals are ever generated during bounce.

---

## 4. Conclusion

- **Verdict**: **APPROVE**
- The RTL implementation across all 5 modules in `traffic_light_fpga/rtl/` is completely robust, strictly adheres to IEEE 1164 and numeric_std, contains 0 inferred latches, enforces exact deterministic priority hierarchies, guarantees hardware fail-safe mutual exclusion of green indications under all conditions, and executes phase countdowns with exact integer second accuracy.

---

## 5. Verification Method

To independently verify these findings:
1. **Inspection**:
   - Inspect `traffic_light_top.vhd` lines 147-166 to verify the All-Red conflict monitor gate.
   - Inspect `fsm_controller.vhd` lines 74-117 to verify priority encoding.
   - Inspect `timer_counter.vhd` lines 95-125 to verify counter clamping at 1 and `timer_done` trigger on counter = 1.
2. **Simulation Command (upon Milestone M2 testbench delivery)**:
   - In ModelSim: `vsim -do traffic_light_fpga/sim/run_sim.do`
   - Observe waveforms for:
     - `KEY(1)='0'` and `SW(0)='1'` simultaneously asserted -> verify FSM enters `S_EMERGENCY`.
     - `LEDG(0)='1' and LEDG(1)='1'` -> verify continuous assertion never fails.
     - Phase durations: Phase 1 = 25 ticks, Phase 2 = 3 ticks, Phase 3 = 30 ticks, Phase 4 = 3 ticks.
