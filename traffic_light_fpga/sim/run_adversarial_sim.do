# ==============================================================================
# ModelSim Adversarial FSM Simulation Script
# Project : DE2-115 FPGA Traffic Light Controller
# File    : run_adversarial_sim.do
# ==============================================================================

if [file exists "../clk_divider.vhd"] {
    set rtl_dir ".."
    set tb_dir  ".."
} else {
    set rtl_dir "."
    set tb_dir  "."
}

# 1. Clean and Create Work Library
if [file exists work] {
    vdel -all -lib work
}
vlib work
vmap work work

# 2. Compile RTL VHDL Files
puts "--> Compiling RTL VHDL sources..."
vcom -93 -work work $rtl_dir/clk_divider.vhd
vcom -93 -work work $rtl_dir/seg7_decoder.vhd
vcom -93 -work work $rtl_dir/timer_counter.vhd
vcom -93 -work work $rtl_dir/fsm_controller.vhd
vcom -93 -work work $rtl_dir/traffic_light_top.vhd

# 3. Compile Adversarial Testbench
puts "--> Compiling Adversarial Testbench..."
vcom -93 -work work $tb_dir/tb_adversarial_fsm.vhd

# 4. Elaborate Design
puts "--> Elaborating tb_adversarial_fsm..."
vsim -t 1ns -voptargs="+acc" work.tb_adversarial_fsm

# 5. Run Simulation
puts "--> Running Adversarial Simulation..."
run -all

puts "--> Adversarial Simulation Complete."
quit -f
