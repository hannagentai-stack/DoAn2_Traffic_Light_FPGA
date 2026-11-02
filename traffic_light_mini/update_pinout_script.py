import os, re

pinout_script = r"traffic_light_anode_chung\generate_pinout_doc.py"

with open(pinout_script, "r", encoding="utf-8") as f:
    content = f.read()

# Replace project_pins block
old_project_pins_pattern = re.compile(r'project_pins = \[(.*?)\]\n\s*for idx, \(p_name', re.DOTALL)

new_project_pins = '''project_pins = [
        # 1. Master Clock 50MHz
        ("CLOCK_50", "IN", "PIN_24", "3.3V LVTTL", "Xung vuông", "Thạch anh 50MHz tích hợp trên bo (GCLK0)."),
        
        # 2. TOP HEADER (CỤM ĐÈN GIAO THÔNG & ĐIỀU KHIỂN - TẤT CẢ NẰM HÀNG NGOÀI)
        # Đèn giao thông Làn A
        ("LEDG[0]", "OUT", "PIN_39", "3.3V LVTTL", "Active-High (1)", "Đèn XANH Làn A (Top Header - Hàng ngoài)."),
        ("LEDR[0]", "OUT", "PIN_43", "3.3V LVTTL", "Active-High (1)", "Đèn VÀNG Làn A (Top Header - Hàng ngoài)."),
        ("LEDR[1]", "OUT", "PIN_46", "3.3V LVTTL", "Active-High (1)", "Đèn ĐỎ Làn A (Top Header - Hàng ngoài)."),
        
        # Đèn giao thông Làn B
        ("LEDG[1]", "OUT", "PIN_71", "3.3V LVTTL", "Active-High (1)", "Đèn XANH Làn B (Top Header - Hàng ngoài)."),
        ("LEDR[2]", "OUT", "PIN_69", "3.3V LVTTL", "Active-High (1)", "Đèn VÀNG Làn B (Top Header - Hàng ngoài)."),
        ("LEDR[3]", "OUT", "PIN_67", "3.3V LVTTL", "Active-High (1)", "Đèn ĐỎ Làn B (Top Header - Hàng ngoài)."),
        
        # Nút nhấn ngoại vi
        ("KEY[0]", "IN", "PIN_50", "3.3V LVTTL", "Active-Low (0)", "Nút Reset toàn hệ thống (Top Header - Hàng ngoài)."),
        ("KEY[1]", "IN", "PIN_52", "3.3V LVTTL", "Active-Low (0)", "Nút Khẩn cấp Làn A (Top Header - Hàng ngoài)."),
        ("KEY[2]", "IN", "PIN_54", "3.3V LVTTL", "Active-Low (0)", "Nút Khẩn cấp Làn B (Top Header - Hàng ngoài)."),
        
        # Công tắc cần gạt 3 vị trí ON-OFF-ON
        ("SW[0]", "IN", "PIN_58", "3.3V LVTTL", "Active-Low (0)", "Chân 1 công tắc 3 nấc: Gạt nối GND là Bật Chế độ Ban đêm (Chớp vàng 1Hz)."),
        ("SW[1]", "IN", "PIN_60", "3.3V LVTTL", "Active-Low (0)", "Chân 3 công tắc 3 nấc: Gạt nối GND là Bật Tạm dừng Pause. (Giữa = Tự động)."),
        
        # 3. BOTTOM HEADER (CỤM HIỂN THỊ LED 7 ĐOẠN ANODE CHUNG)
        # LED 7 đoạn Làn A (144, 142, 138, 136, 133, 129, 143, 141, 137)
        ("HEX_A_SEG[0]", "OUT", "PIN_144", "3.3V LVTTL", "Active-High (1)", "Thanh đoạn a (Làn A) - Vào In 1B ULN2803G -> Qua trở 330Ω vào Chân 10 của LED."),
        ("HEX_A_SEG[1]", "OUT", "PIN_142", "3.3V LVTTL", "Active-High (1)", "Thanh đoạn b (Làn A) - Vào In 2B ULN2803G -> Qua trở 330Ω vào Chân 9 của LED."),
        ("HEX_A_SEG[2]", "OUT", "PIN_138", "3.3V LVTTL", "Active-High (1)", "Thanh đoạn c (Làn A) - Vào In 3B ULN2803G -> Qua trở 330Ω vào Chân 1 của LED."),
        ("HEX_A_SEG[3]", "OUT", "PIN_136", "3.3V LVTTL", "Active-High (1)", "Thanh đoạn d (Làn A) - Vào In 4B ULN2803G -> Qua trở 330Ω vào Chân 4 của LED."),
        ("HEX_A_SEG[4]", "OUT", "PIN_133", "3.3V LVTTL", "Active-High (1)", "Thanh đoạn e (Làn A) - Vào In 5B ULN2803G -> Qua trở 330Ω vào Chân 3 của LED."),
        ("HEX_A_SEG[5]", "OUT", "PIN_129", "3.3V LVTTL", "Active-High (1)", "Thanh đoạn f (Làn A) - Vào In 6B ULN2803G -> Qua trở 330Ω vào Chân 6 của LED."),
        ("HEX_A_SEG[6]", "OUT", "PIN_143", "3.3V LVTTL", "Active-High (1)", "Thanh đoạn g (Làn A) - Vào In 7B ULN2803G -> Qua trở 330Ω vào Chân 5 của LED."),
        ("HEX_A_DIG[0]", "OUT", "PIN_137", "3.3V LVTTL", "Active-High (1)", "Cấp nguồn 3.3V (Mức 1) vào Chân 7 (DIG2 Đơn vị) của LED Làn A."),
        ("HEX_A_DIG[1]", "OUT", "PIN_141", "3.3V LVTTL", "Active-High (1)", "Cấp nguồn 3.3V (Mức 1) vào Chân 8 (DIG1 Chục) của LED Làn A."),
        
        # LED 7 đoạn Làn B (127, 125, 121, 119, 113, 111, 115, 112, 110)
        ("HEX_B_SEG[0]", "OUT", "PIN_127", "3.3V LVTTL", "Active-High (1)", "Thanh đoạn a (Làn B) - Vào In 1B ULN2803G -> Qua trở 330Ω vào Chân 10 của LED."),
        ("HEX_B_SEG[1]", "OUT", "PIN_125", "3.3V LVTTL", "Active-High (1)", "Thanh đoạn b (Làn B) - Vào In 2B ULN2803G -> Qua trở 330Ω vào Chân 9 của LED."),
        ("HEX_B_SEG[2]", "OUT", "PIN_121", "3.3V LVTTL", "Active-High (1)", "Thanh đoạn c (Làn B) - Vào In 3B ULN2803G -> Qua trở 330Ω vào Chân 1 của LED."),
        ("HEX_B_SEG[3]", "OUT", "PIN_119", "3.3V LVTTL", "Active-High (1)", "Thanh đoạn d (Làn B) - Vào In 4B ULN2803G -> Qua trở 330Ω vào Chân 4 của LED."),
        ("HEX_B_SEG[4]", "OUT", "PIN_113", "3.3V LVTTL", "Active-High (1)", "Thanh đoạn e (Làn B) - Vào In 5B ULN2803G -> Qua trở 330Ω vào Chân 3 của LED."),
        ("HEX_B_SEG[5]", "OUT", "PIN_111", "3.3V LVTTL", "Active-High (1)", "Thanh đoạn f (Làn B) - Vào In 6B ULN2803G -> Qua trở 330Ω vào Chân 6 của LED."),
        ("HEX_B_SEG[6]", "OUT", "PIN_115", "3.3V LVTTL", "Active-High (1)", "Thanh đoạn g (Làn B) - Vào In 7B ULN2803G -> Qua trở 330Ω vào Chân 5 của LED."),
        ("HEX_B_DIG[0]", "OUT", "PIN_110", "3.3V LVTTL", "Active-High (1)", "Cấp nguồn 3.3V (Mức 1) vào Chân 7 (DIG2 Đơn vị) của LED Làn B."),
        ("HEX_B_DIG[1]", "OUT", "PIN_112", "3.3V LVTTL", "Active-High (1)", "Cấp nguồn 3.3V (Mức 1) vào Chân 8 (DIG1 Chục) của LED Làn B.")
    ]
    for idx, (p_name'''

content = old_project_pins_pattern.sub(new_project_pins, content)

# Replace led_wiring_data
old_led_wiring_pattern = re.compile(r'led_wiring_data = \[(.*?)\]\n\s*for idx, \(p_led_num', re.DOTALL)
new_led_wiring = '''led_wiring_data = [
        # HÀNG CHÂN DƯỚI (Chân 1 đến 5 - Đếm từ Trái sang Phải)
        ("Chân 1",  "Thanh C", "Out 3C (Chân 16)", "Trở 330Ω", "PIN_138 (In 3B)", "PIN_121 (In 3B)", "Thanh dọc dưới bên phải"),
        ("Chân 2",  "Dấu DP",  "Bỏ trống (Pin 11)", "Không cắm", "Để trống",       "Để trống",       "Dấu chấm lẻ (không dùng)"),
        ("Chân 3",  "Thanh E", "Out 5C (Chân 14)", "Trở 330Ω", "PIN_133 (In 5B)", "PIN_113 (In 5B)", "Thanh dọc dưới bên trái"),
        ("Chân 4",  "Thanh D", "Out 4C (Chân 15)", "Trở 330Ω", "PIN_136 (In 4B)", "PIN_119 (In 4B)", "Thanh ngang dưới đáy"),
        ("Chân 5",  "Thanh G", "Out 7C (Chân 12)", "Trở 330Ω", "PIN_143 (In 7B)", "PIN_115 (In 7B)", "Thanh ngang ở chính giữa"),

        # HÀNG CHÂN TRÊN (Chân 6 đến 10 - Đếm từ Phải sang Trái)
        ("Chân 6",  "Thanh F", "Out 6C (Chân 13)", "Trở 330Ω", "PIN_129 (In 6B)", "PIN_111 (In 6B)", "Thanh dọc trên bên trái"),
        ("Chân 7",  "DIG2 (Đơn vị)", "Không qua ULN", "Nối thẳng FPGA", "PIN_137", "PIN_110", "Cực Dương chung Hàng đơn vị (3.3V)"),
        ("Chân 8",  "DIG1 (Chục)",   "Không qua ULN", "Nối thẳng FPGA", "PIN_141", "PIN_112", "Cực Dương chung Hàng chục (3.3V)"),
        ("Chân 9",  "Thanh B", "Out 2C (Chân 17)", "Trở 330Ω", "PIN_142 (In 2B)", "PIN_125 (In 2B)", "Thanh dọc trên bên phải"),
        ("Chân 10", "Thanh A", "Out 1C (Chân 18)", "Trở 330Ω", "PIN_144 (In 1B)", "PIN_127 (In 1B)", "Thanh ngang trên đỉnh"),

        # CẤP NGUỒN CHO IC ULN2803G
        ("ULN Pin 9", "GND IC ULN",  "Chân 9 (GND)",  "Dây nối GND",   "GND bo FPGA", "GND bo FPGA", "Cực Âm nguồn chung (BẮT BUỘC NỐI GND)"),
        ("ULN Pin 10","COM IC ULN",  "Chân 10 (COM)", "Dây nối VCC",   "+3.3V / +5V", "+3.3V / +5V", "Chân diot dập xung (Nối lên nguồn 3.3V/5V)")
    ]
    for idx, (p_led_num'''

content = old_led_wiring_pattern.sub(new_led_wiring, content)

with open(pinout_script, "w", encoding="utf-8") as f:
    f.write(content)

print("Updated generate_pinout_doc.py successfully!")
