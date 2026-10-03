# ==============================================================================
# Synopsys Design Constraints (.sdc) for TimeQuest Timing Analyzer
# Project       : DE2-115 FPGA Traffic Light Controller
# Target Device : Altera Cyclone IV E EP4CE115F29C7
# Top Entity    : traffic_light_top
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Primary Clock Definition
#    50.000 MHz Oscillator on PIN_Y2 (Period = 20.000 ns, 50% Duty Cycle)
# ------------------------------------------------------------------------------
create_clock -name CLOCK_50 -period 20.000 [get_ports CLOCK_50]

# ------------------------------------------------------------------------------
# 2. Clock Uncertainty Derivation
#    Automatically calculates setup and hold uncertainty due to PLL and clock network jitter
# ------------------------------------------------------------------------------
derive_clock_uncertainty

# ------------------------------------------------------------------------------
# 3. Asynchronous Input / Output False Paths
#    External mechanical inputs (KEY, SW) and human-visual outputs (LEDR, LEDG, HEX0..HEX3)
#    are asynchronous to the high-speed system clock and are not timing-critical.
# ------------------------------------------------------------------------------

# Asynchronous Human Control Inputs
set_false_path -from [get_ports {KEY[*]}]
set_false_path -from [get_ports {SW[*]}]

# Static Visual Indicators & Displays
set_false_path -to [get_ports {LEDR[*]}]
set_false_path -to [get_ports {LEDG[*]}]
set_false_path -to [get_ports {HEX0[*]}]
set_false_path -to [get_ports {HEX1[*]}]
set_false_path -to [get_ports {HEX2[*]}]
set_false_path -to [get_ports {HEX3[*]}]
