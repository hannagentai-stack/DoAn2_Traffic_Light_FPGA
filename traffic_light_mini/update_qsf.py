import os

qsf_path = r"traffic_light_anode_chung\traffic_light_top.qsf"
with open(qsf_path, "r", encoding="utf-8") as f:
    lines = f.readlines()

filtered_lines = [l for l in lines if not any(k in l for k in [
    'CLOCK_50', 'LEDR', 'LEDG', 'KEY', 'SW', 'HEX_A_SEG', 'HEX_A_DIG', 'HEX_B_SEG', 'HEX_B_DIG'
])]

new_assignments = """
# ==============================================================================
# PIN ASSIGNMENTS - CUSTOM USER CONFIGURATION
# ==============================================================================
# Clock 50MHz
set_location_assignment PIN_24 -to CLOCK_50
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to CLOCK_50

# Traffic LEDs Lane A
set_location_assignment PIN_39 -to LEDG[0]
set_location_assignment PIN_43 -to LEDR[0]
set_location_assignment PIN_46 -to LEDR[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDG[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR[1]

# Traffic LEDs Lane B
set_location_assignment PIN_71 -to LEDG[1]
set_location_assignment PIN_69 -to LEDR[2]
set_location_assignment PIN_67 -to LEDR[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDG[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LEDR[3]

# Inputs (Buttons & Switches)
set_location_assignment PIN_50 -to KEY[0]
set_location_assignment PIN_52 -to KEY[1]
set_location_assignment PIN_54 -to KEY[2]
set_location_assignment PIN_58 -to SW[0]
set_location_assignment PIN_60 -to SW[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to KEY[*]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to KEY[*]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW[*]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to SW[*]

# 7-Segment Lane A (144, 142, 138, 136, 133, 129, 143, 141, 137)
set_location_assignment PIN_144 -to HEX_A_SEG[0]
set_location_assignment PIN_142 -to HEX_A_SEG[1]
set_location_assignment PIN_138 -to HEX_A_SEG[2]
set_location_assignment PIN_136 -to HEX_A_SEG[3]
set_location_assignment PIN_133 -to HEX_A_SEG[4]
set_location_assignment PIN_129 -to HEX_A_SEG[5]
set_location_assignment PIN_143 -to HEX_A_SEG[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX_A_SEG[*]

set_location_assignment PIN_137 -to HEX_A_DIG[0]
set_location_assignment PIN_141 -to HEX_A_DIG[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX_A_DIG[*]

# 7-Segment Lane B (127, 125, 121, 119, 113, 111, 115, 112, 110)
set_location_assignment PIN_127 -to HEX_B_SEG[0]
set_location_assignment PIN_125 -to HEX_B_SEG[1]
set_location_assignment PIN_121 -to HEX_B_SEG[2]
set_location_assignment PIN_119 -to HEX_B_SEG[3]
set_location_assignment PIN_113 -to HEX_B_SEG[4]
set_location_assignment PIN_111 -to HEX_B_SEG[5]
set_location_assignment PIN_115 -to HEX_B_SEG[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX_B_SEG[*]

set_location_assignment PIN_110 -to HEX_B_DIG[0]
set_location_assignment PIN_112 -to HEX_B_DIG[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HEX_B_DIG[*]
"""

with open(qsf_path, "w", encoding="utf-8") as f:
    f.writelines(filtered_lines)
    f.write(new_assignments)

print("Updated QSF with new pinout successfully!")
