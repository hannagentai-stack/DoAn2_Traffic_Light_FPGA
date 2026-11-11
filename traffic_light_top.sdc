# ==============================================================================
# Synopsys Design Constraints (.sdc) for TimeQuest Timing Analyzer
# Project       : ZCJ Cyclone IV EP4CE6E22C8N FPGA Traffic Light Controller
# Target Device : Altera Cyclone IV E EP4CE6E22C8N
# Top Entity    : traffic_light_top
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Primary Clock Definition
#    50.000 MHz Oscillator on PIN_24 (Period = 20.000 ns, 50% Duty Cycle)
# ------------------------------------------------------------------------------
create_clock -name CLOCK_50 -period 20.000 [get_ports CLOCK_50]

# ------------------------------------------------------------------------------
# 2. Clock Uncertainty Derivation
# ------------------------------------------------------------------------------
derive_clock_uncertainty

# ------------------------------------------------------------------------------
# 3. Asynchronous Input / Output False Paths
# ------------------------------------------------------------------------------
# Asynchronous Human Control Inputs
set_false_path -from [get_ports {KEY[*]}]
set_false_path -from [get_ports {SW[*]}]

# Static Visual Indicators & Displays
set_false_path -to [get_ports {LEDR[*]}]
set_false_path -to [get_ports {LEDG[*]}]
set_false_path -to [get_ports {HEX_A_SEG[*]}]
set_false_path -to [get_ports {HEX_A_DIG[*]}]
set_false_path -to [get_ports {HEX_B_SEG[*]}]
set_false_path -to [get_ports {HEX_B_DIG[*]}]
