# fix_and_compile.tcl
# Script TCL: Load project, update file assignments, then compile

package require ::quartus::project
package require ::quartus::flow

set BASE "C:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga"
set PROJ "$BASE/traffic_light_top"

# Open project
project_open $PROJ

# Remove old (possibly relative) VHDL file assignments
remove_all_global_assignments -name VHDL_FILE
remove_all_global_assignments -name SDC_FILE

# Add files with absolute paths
set_global_assignment -name VHDL_FILE "$BASE/rtl/clk_divider.vhd"
set_global_assignment -name VHDL_FILE "$BASE/rtl/seg7_decoder.vhd"
set_global_assignment -name VHDL_FILE "$BASE/rtl/timer_counter.vhd"
set_global_assignment -name VHDL_FILE "$BASE/rtl/fsm_controller.vhd"
set_global_assignment -name VHDL_FILE "$BASE/rtl/traffic_light_top.vhd"
set_global_assignment -name SDC_FILE  "$BASE/syn/de2_115.sdc"

# Save updated settings back to QSF
export_assignments

project_close

puts "=== Settings updated. Now running full compilation... ==="
