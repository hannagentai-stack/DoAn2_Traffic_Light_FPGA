# ==============================================================================
# ModelSim / QuestaSim Automated Simulation Script
# Du an   : Thiet Ke He Thong Dieu Khien Den Giao Thong Nga Tu (Cyclone IV)
# File    : run_sim.do
# ==============================================================================

# Detect directory context (whether run from ./sim or project root)
if [file exists "../clk_divider.vhd"] {
    set rtl_dir ".."
    set tb_dir  ".."
    set sim_dir "."
} elseif [file exists "clk_divider.vhd"] {
    set rtl_dir "."
    set tb_dir  "."
    set sim_dir "sim"
} elseif [file exists "../rtl/clk_divider.vhd"] {
    set rtl_dir "../rtl"
    set tb_dir  "../tb"
    set sim_dir "."
} elseif [file exists "rtl/clk_divider.vhd"] {
    set rtl_dir "rtl"
    set tb_dir  "tb"
    set sim_dir "sim"
} else {
    set rtl_dir "."
    set tb_dir  "."
    set sim_dir "."
}

# 1. Clean and Create Work Library
if [file exists work] {
    vdel -all -lib work
}
vlib work
vmap work work

# 2. Compile RTL VHDL Files in Strict Dependency Order
puts "--> Compiling RTL VHDL sources (IEEE 1164 & numeric_std)..."
vcom -93 -work work $rtl_dir/clk_divider.vhd
vcom -93 -work work $rtl_dir/seg7_decoder.vhd
vcom -93 -work work $rtl_dir/timer_counter.vhd
vcom -93 -work work $rtl_dir/fsm_controller.vhd
vcom -93 -work work $rtl_dir/traffic_light_top.vhd

# 3. Compile Testbench
puts "--> Compiling Testbench..."
vcom -93 -work work $tb_dir/tb_traffic_light_top.vhd

# 4. Elaborate Design with Full Signal Visibility
puts "--> Elaborating design with full signal visibility..."
vsim -t 1ns -voptargs="+acc" work.tb_traffic_light_top

# Open wave window
catch { view wave }
catch { view structure }
catch { view signals }

# 5. Load Waveform Configuration
puts "--> Loading wave formatting from wave.do..."
if [file exists "$sim_dir/wave.do"] {
    do $sim_dir/wave.do
} elseif [file exists "wave.do"] {
    do wave.do
}

# 6. Run Simulation for 250 us (Covers all test scenarios)
puts "--> Running simulation for 250 us..."
run 250 us

# 7. Zoom full to view complete test results (GUI mode safe)
catch { wave zoomfull }
puts "--> Simulation complete. Check transcript for assertion results."
