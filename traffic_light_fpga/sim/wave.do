# ==============================================================================
# ModelSim / QuestaSim Waveform Configuration Script
# Project : DE2-115 FPGA Traffic Light Controller
# File    : wave.do
# ==============================================================================

onerror {resume}
catch { quietly WaveActivateNextPane {} 0 }

# --- GROUP 1: CLOCKS & RESET ---
add wave -noupdate -divider {CLOCKS & RESET}
add wave -noupdate -color Yellow -format Logic /tb_traffic_light_top/clk_50m
add wave -noupdate -color Red    -format Logic /tb_traffic_light_top/key(0)
add wave -noupdate -color Cyan   -format Logic /tb_traffic_light_top/dut/tick_1hz_s
add wave -noupdate -color Orange -format Logic /tb_traffic_light_top/dut/blink_1hz_s

# --- GROUP 2: CONTROL INPUTS ---
add wave -noupdate -divider {CONTROL INPUTS}
add wave -noupdate -color Magenta -format Logic /tb_traffic_light_top/sw(0)
add wave -noupdate -color Blue    -format Logic /tb_traffic_light_top/sw(1)
add wave -noupdate -color Red     -format Logic /tb_traffic_light_top/key(1)

# --- GROUP 3: FSM STATE ---
add wave -noupdate -divider {FSM STATE}
add wave -noupdate -color Gold    -format Literal /tb_traffic_light_top/dut/u_fsm_controller/current_state
add wave -noupdate -color Orange  -format Literal /tb_traffic_light_top/dut/u_fsm_controller/next_state
add wave -noupdate -color White   -format Literal -radix binary /tb_traffic_light_top/dut/phase_sel_s
add wave -noupdate -color Cyan    -format Logic   /tb_traffic_light_top/dut/load_phase_s
add wave -noupdate -color Yellow  -format Logic   /tb_traffic_light_top/dut/timer_done_s

# --- GROUP 4: TIMERS & BCD ---
add wave -noupdate -divider {TIMERS & BCD}
add wave -noupdate -color Green -format Literal -radix unsigned /tb_traffic_light_top/dut/u_timer_counter/cnt_a
add wave -noupdate -color Cyan  -format Literal -radix unsigned /tb_traffic_light_top/dut/u_timer_counter/cnt_b
add wave -noupdate -color White -format Literal -radix hex      /tb_traffic_light_top/dut/bcd_a_tens_s
add wave -noupdate -color White -format Literal -radix hex      /tb_traffic_light_top/dut/bcd_a_units_s
add wave -noupdate -color White -format Literal -radix hex      /tb_traffic_light_top/dut/bcd_b_tens_s
add wave -noupdate -color White -format Literal -radix hex      /tb_traffic_light_top/dut/bcd_b_units_s

# --- GROUP 5: ROUTE A & B LEDS ---
add wave -noupdate -divider {ROUTE A LIGHTS}
add wave -noupdate -color Green  -format Logic /tb_traffic_light_top/ledg(0)
add wave -noupdate -color Yellow -format Logic /tb_traffic_light_top/ledr(1)
add wave -noupdate -color Red    -format Logic /tb_traffic_light_top/ledr(0)

add wave -noupdate -divider {ROUTE B LIGHTS}
add wave -noupdate -color Green  -format Logic /tb_traffic_light_top/ledg(1)
add wave -noupdate -color Yellow -format Logic /tb_traffic_light_top/ledr(3)
add wave -noupdate -color Red    -format Logic /tb_traffic_light_top/ledr(2)

# --- GROUP 6: HEX DISPLAYS ---
add wave -noupdate -divider {HEX DISPLAYS}
add wave -noupdate -color Pink -format Logic                    /tb_traffic_light_top/dut/blank_seg7_s
add wave -noupdate -color Gray -format Literal -radix hexadecimal /tb_traffic_light_top/hex1
add wave -noupdate -color Gray -format Literal -radix hexadecimal /tb_traffic_light_top/hex0
add wave -noupdate -color Gray -format Literal -radix hexadecimal /tb_traffic_light_top/hex3
add wave -noupdate -color Gray -format Literal -radix hexadecimal /tb_traffic_light_top/hex2

catch { TreeUpdate [SetDefaultTree] }
catch { configure wave -namecolwidth 260 }
catch { configure wave -valuecolwidth 100 }
catch { configure wave -justifyvalue left }
catch { configure wave -signalnamewidth 1 }
catch { configure wave -snapdistance 10 }
catch { configure wave -datasetprefix 0 }
catch { configure wave -rowmargin 4 }
catch { configure wave -childrowmargin 2 }
