"""
--------------------------------------------------------------------------------
DỰ ÁN: THIẾT KẾ HỆ THỐNG ĐIỀU KHIỂN ĐÈN GIAO THÔNG NGÃ TƯ TRÊN FPGA CYCLONE IV
PHIÊN BẢN: ANODE CHUNG (COMMON ANODE - 5621AH / 3621AH)
SCRIPT: generate_pinout_doc.py
MỤC ĐÍCH:
  Tạo tài liệu Bảng Tra Cứu & Danh Sách Gán Chân I/O Phần Cứng FPGA
  định dạng Word (.docx) chuyên nghiệp, 100% Tiếng Việt có dấu chuẩn xác
  cho phiên bản LED 7 đoạn Anode chung.
--------------------------------------------------------------------------------
"""

import os
import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tc = cell._tc
    tcPr = tc.get_or_add_tcPr()
    tcMar = OxmlElement('w:tcMar')
    for m, val in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
        node = OxmlElement(f'w:{m}')
        node.set(qn('w:w'), str(val))
        node.set(qn('w:type'), 'dxa')
        tcMar.append(node)
    tcPr.append(tcMar)

def set_cell_background(cell, hex_color):
    tc = cell._tc
    tcPr = tc.get_or_add_tcPr()
    shd = OxmlElement('w:shd')
    shd.set(qn('w:val'), 'clear')
    shd.set(qn('w:color'), 'auto')
    shd.set(qn('w:fill'), hex_color)
    tcPr.append(shd)

def add_callout(doc, text, title="LƯU Ý QUAN TRỌNG:", border_color="1B365D", bg_color="F1F5F9"):
    tbl = doc.add_table(rows=1, cols=1)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    cell = tbl.cell(0, 0)
    set_cell_background(cell, bg_color)
    set_cell_margins(cell, top=140, bottom=140, left=200, right=180)
    
    tc = cell._tc
    tcPr = tc.get_or_add_tcPr()
    tcBorders = OxmlElement('w:tcBorders')
    
    left = OxmlElement('w:left')
    left.set(qn('w:val'), 'single')
    left.set(qn('w:sz'), '36') # 4.5 pt
    left.set(qn('w:space'), '0')
    left.set(qn('w:color'), border_color)
    tcBorders.append(left)
    
    for b_name in ['top', 'bottom', 'right']:
        b = OxmlElement(f'w:{b_name}')
        b.set(qn('w:val'), 'none')
        tcBorders.append(b)
    tcPr.append(tcBorders)
    
    p = cell.paragraphs[0]
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(3)
    r_title = p.add_run(title + " ")
    r_title.bold = True
    r_title.font.name = 'Segoe UI'
    r_title.font.size = Pt(10.5)
    r_title.font.color.rgb = RGBColor(27, 54, 93)
    
    r_text = p.add_run(text)
    r_text.font.name = 'Segoe UI'
    r_text.font.size = Pt(10)
    r_text.font.color.rgb = RGBColor(51, 65, 85)

def build_pinout_document(file_path):
    doc = docx.Document()
    
    # Căn lề trang 2cm
    for section in doc.sections:
        section.top_margin = Inches(0.8)
        section.bottom_margin = Inches(0.8)
        section.left_margin = Inches(0.8)
        section.right_margin = Inches(0.8)
        
    COLOR_PRIMARY = RGBColor(27, 54, 93)     # #1B365D Deep Navy
    COLOR_SECONDARY = RGBColor(14, 116, 144) # #0E7490 Cyan / Teal
    COLOR_TEXT = RGBColor(30, 41, 59)        # #1E293B Dark Slate
    
    # Tiêu đề tài liệu
    p_pre = doc.add_paragraph()
    p_pre.paragraph_format.space_after = Pt(2)
    p_pre.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_pre = p_pre.add_run("TRƯỜNG ĐẠI HỌC - KHOA ĐIỆN - ĐIỆN TỬ / BỘ MÔN KỸ THUẬT MÁY TÍNH")
    r_pre.font.name = 'Segoe UI'
    r_pre.font.size = Pt(9.5)
    r_pre.font.bold = True
    r_pre.font.color.rgb = RGBColor(100, 116, 139)
    
    p_title = doc.add_paragraph()
    p_title.paragraph_format.space_before = Pt(4)
    p_title.paragraph_format.space_after = Pt(4)
    p_title.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_title = p_title.add_run("BẢNG TRA CỨU & DANH SÁCH GÁN CHÂN I/O PHẦN CỨNG FPGA")
    r_title.font.name = 'Segoe UI'
    r_title.font.size = Pt(17)
    r_title.font.bold = True
    r_title.font.color.rgb = COLOR_PRIMARY
    
    p_sub = doc.add_paragraph()
    p_sub.paragraph_format.space_before = Pt(0)
    p_sub.paragraph_format.space_after = Pt(14)
    p_sub.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_sub = p_sub.add_run("Phiên bản: ANODE CHUNG (Common Anode - 5621AH) - Kit Cyclone IV EP4CE6E22C8N & DE2-115")
    r_sub.font.name = 'Segoe UI'
    r_sub.font.size = Pt(11)
    r_sub.font.italic = True
    r_sub.font.color.rgb = COLOR_SECONDARY
    
    doc.add_paragraph()
    
    # --------------------------------------------------------------------------
    # MỤC 1: THÔNG SỐ VÀ CẤU HÌNH PHẦN CỨNG
    # --------------------------------------------------------------------------
    h1 = doc.add_heading(level=1)
    h1.paragraph_format.space_before = Pt(12)
    h1.paragraph_format.space_after = Pt(4)
    r = h1.add_run("1. Thông Số Kỹ Thuật Bo Mạch FPGA Mục Tiêu")
    r.font.name = 'Segoe UI'
    r.font.bold = True
    r.font.size = Pt(13.5)
    r.font.color.rgb = COLOR_PRIMARY
    
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(6)
    p.paragraph_format.line_spacing = 1.15
    p.add_run(
        "Dự án được thiết kế, tổng hợp và nạp thực tế trên bo mạch lõi FPGA giá rẻ phổ biến Altera / Intel "
        "Cyclone IV E EP4CE6E22C8N (kit lõi đen / Mini Core Board) và tương thích hoàn toàn về kiến trúc với "
        "dòng bo thí nghiệm Terasic DE2-115 (EP4CE115F29C7). Dưới đây là thông số phần cứng cốt lõi:"
    )
    
    tbl_specs = doc.add_table(rows=1, cols=3)
    tbl_specs.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl_specs.autofit = False
    
    col_widths = [Inches(1.8), Inches(2.6), Inches(2.6)]
    for row in tbl_specs.rows:
        for idx, width in enumerate(col_widths):
            row.cells[idx].width = width
            
    hdr_cells = tbl_specs.rows[0].cells
    hdr_cells[0].text = "Thành Phần Phần Cứng"
    hdr_cells[1].text = "Thông Số / Mã Chip"
    hdr_cells[2].text = "Đặc Điểm Kỹ Thuật"
    for c in hdr_cells:
        c.paragraphs[0].runs[0].font.name = 'Segoe UI'
        c.paragraphs[0].runs[0].font.bold = True
        c.paragraphs[0].runs[0].font.size = Pt(9.5)
        c.paragraphs[0].runs[0].font.color.rgb = RGBColor(255, 255, 255)
        set_cell_background(c, "1B365D")
        set_cell_margins(c, 100, 100, 140, 140)
        
    specs_data = [
        ("Chip FPGA Chính", "Altera / Intel Cyclone IV E EP4CE6E22C8N", "Đóng gói QFP-144 chân, 6.272 Logic Elements, 392 Kbits RAM, 2 khối PLL."),
        ("Nguồn Cấp Hệ Thống", "5V DC qua cổng Type-C hoặc Header", "Hạ áp bởi IC AMS1117 ra 3.3V (VCCIO cho các I/O Banks) và 1.2V (VCCINT cho lõi FPGA)."),
        ("Xung Nhịp Master Clock", "50.000 MHz (Thạch anh tích hợp)", "Nối vào chân PIN_24 (CLK0). Chu kỳ T = 20 ns, độ lệch pha ổn định < 0.1%."),
        ("Xung Nhịp Phụ (nếu có)", "27.000 MHz (Thạch anh thứ 2)", "Nối vào chân PIN_90 / PIN_91 (dùng cho các ứng dụng Video/VGA nếu cần)."),
        ("Bộ Nhớ Flash Nạp Code", "EPCS4N / EPCS16 (SPI Flash)", "Nối qua bus Active Serial (AS). Lưu file .jic để mạch chạy vĩnh viễn không mất code khi mất điện."),
        ("Giao Tiếp Nạp JTAG", "Chuẩn Header 10-pin 2.54mm", "Kết nối cáp USB-Blaster (TCK=16, TMS=18, TDO=20, TDI=17) nạp file .sof trực tiếp vào RAM."),
        ("Giao Tiếp UART / Serial", "Chip USB-UART CH340 / Type-C", "Nối sẵn vào chân PIN_10 (TXD) và PIN_23 (RXD), truyền dữ liệu lên máy tính PC.")
    ]
    
    for idx, (comp, param, desc) in enumerate(specs_data):
        bg = "F8FAFC" if idx % 2 == 1 else "FFFFFF"
        row = tbl_specs.add_row()
        for c_idx, text in enumerate([comp, param, desc]):
            cell = row.cells[c_idx]
            cell.width = col_widths[c_idx]
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            p = cell.paragraphs[0]
            p.paragraph_format.space_before = Pt(2)
            p.paragraph_format.space_after = Pt(2)
            r = p.add_run(text)
            r.font.name = 'Segoe UI'
            r.font.size = Pt(9.2)
            if c_idx == 0:
                r.font.bold = True
                r.font.color.rgb = COLOR_PRIMARY
            else:
                r.font.color.rgb = COLOR_TEXT
            set_cell_background(cell, bg)
            set_cell_margins(cell, 90, 90, 130, 130)
            
    doc.add_paragraph()
    
    # --------------------------------------------------------------------------
    # MỤC 2: DANH SÁCH CHÂN ONBOARD ĐÃ KIỂM CHỨNG THỰC TẾ
    # --------------------------------------------------------------------------
    h1 = doc.add_heading(level=1)
    h1.paragraph_format.space_before = Pt(14)
    h1.paragraph_format.space_after = Pt(4)
    r = h1.add_run("2. Danh Sách Các Chân Cứng ONBOARD (Kiểm Chứng 100% Trên Bo)")
    r.font.name = 'Segoe UI'
    r.font.bold = True
    r.font.size = Pt(13.5)
    r.font.color.rgb = COLOR_PRIMARY
    
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(6)
    p.add_run(
        "Đây là danh sách toàn bộ các chân I/O đã được hàn cố định vào linh kiện trên bo mạch "
        "Cyclone IV EP4CE6E22C8N. Khi thiết kế mạch ngoài, cần nắm rõ để tránh xung đột phần cứng:"
    )
    
    tbl_onboard = doc.add_table(rows=1, cols=4)
    tbl_onboard.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl_onboard.autofit = False
    
    col_w2 = [Inches(1.2), Inches(1.8), Inches(1.5), Inches(2.5)]
    for idx, width in enumerate(col_w2):
        tbl_onboard.rows[0].cells[idx].width = width
        
    hdr2 = tbl_onboard.rows[0].cells
    hdr2[0].text = "Chân FPGA"
    hdr2[1].text = "Linh Kiện Onboard"
    hdr2[2].text = "Chuẩn / Mức Logic"
    hdr2[3].text = "Ghi Chú & Kiểm Chứng Thực Tế"
    for c in hdr2:
        c.paragraphs[0].runs[0].font.name = 'Segoe UI'
        c.paragraphs[0].runs[0].font.bold = True
        c.paragraphs[0].runs[0].font.size = Pt(9.5)
        c.paragraphs[0].runs[0].font.color.rgb = RGBColor(255, 255, 255)
        set_cell_background(c, "0E7490")
        set_cell_margins(c, 100, 100, 140, 140)
        
    onboard_data = [
        ("PIN_24", "Thạch anh 50 MHz", "3.3V LVTTL", "In chữ '50M 24/25' trên PCB. Chân Clock toàn cục GCLK0. (PIN_25 là kênh dự phòng GCLK1)."),
        ("PIN_1", "LED 1 Onboard (D1)", "Active-Low (0 = Sáng)", "In số '1' cạnh JTAG. Đã kiểm chứng sáng chớp tắt thành công."),
        ("PIN_2", "LED 2 Onboard (D2)", "Active-Low (0 = Sáng)", "In số '2' cạnh JTAG. Đã kiểm chứng sáng chớp tắt thành công."),
        ("PIN_3", "LED 3 Onboard (D3)", "Active-Low (0 = Sáng)", "In số '3' cạnh JTAG. Đã kiểm chứng sáng chớp tắt thành công."),
        ("PIN_7", "LED 4 Onboard (D4)", "Active-Low (0 = Sáng)", "In số '7' cạnh JTAG. Đã kiểm chứng sáng chớp tắt thành công."),
        ("PIN_11", "LED 5 Onboard (D5)", "Active-Low (0 = Sáng)", "In số '11' cạnh JTAG. Đã kiểm chứng sáng chớp tắt thành công."),
        ("PIN_88", "Nút Nhấn Reset", "Active-Low (0 = Nhấn)", "Nút bấm Reset hệ thống. Nối trở kéo lên 10k lên 3.3V trên bo."),
        ("PIN_73", "Nút Nhấn KEY 1", "Active-Low (0 = Nhấn)", "In số '73' trên PCB cạnh hàng phím. Có thể dùng làm nút khẩn cấp A."),
        ("PIN_80", "Nút Nhấn KEY 2", "Active-Low (0 = Nhấn)", "In số '80' trên PCB cạnh hàng phím. Có thể dùng làm nút khẩn cấp B."),
        ("PIN_89", "Nút Nhấn KEY 3", "Active-Low (0 = Nhấn)", "In số '89' trên PCB. Có thể dùng làm công tắc chuyển chế độ."),
        ("PIN_114", "Nút Nhấn KEY 4", "Active-Low (0 = Nhấn)", "In số '114' trên PCB. Nút nhấn người dùng đa năng."),
        ("PIN_23", "UART RX (Từ CH340)", "3.3V LVTTL", "Nhận tín hiệu Serial từ máy tính qua cáp Type-C. KHÔNG ĐƯỢC DÙNG LÀM CLOCK!"),
        ("PIN_10", "UART TX (Đến CH340)", "3.3V LVTTL", "Truyền tín hiệu Serial từ FPGA lên máy tính qua cáp Type-C."),
        ("PIN_74", "Flash EPCS4N DATA0", "3.3V LVTTL", "Chân dữ liệu vào Flash SPI nạp vĩnh viễn."),
        ("PIN_75", "Flash EPCS4N DCLK", "3.3V LVTTL", "Chân xung nhịp SPI cho Flash."),
        ("PIN_84", "Flash EPCS4N ASDI", "3.3V LVTTL", "Chân dữ liệu ra Flash SPI."),
        ("PIN_87", "Flash EPCS4N nCS", "3.3V LVTTL", "Chân chọn chip Flash Active-Low.")
    ]
    
    for idx, (p_num, dev, std, note) in enumerate(onboard_data):
        bg = "F0F9FF" if idx % 2 == 1 else "FFFFFF"
        row = tbl_onboard.add_row()
        for c_idx, text in enumerate([p_num, dev, std, note]):
            cell = row.cells[c_idx]
            cell.width = col_w2[c_idx]
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            p = cell.paragraphs[0]
            p.paragraph_format.space_before = Pt(2)
            p.paragraph_format.space_after = Pt(2)
            r = p.add_run(text)
            r.font.name = 'Segoe UI'
            r.font.size = Pt(9.2)
            if c_idx == 0:
                r.font.bold = True
                r.font.color.rgb = RGBColor(185, 28, 28)
            elif c_idx == 1:
                r.font.bold = True
                r.font.color.rgb = COLOR_PRIMARY
            else:
                r.font.color.rgb = COLOR_TEXT
            set_cell_background(cell, bg)
            set_cell_margins(cell, 80, 80, 120, 120)
            
    doc.add_paragraph()
    
    add_callout(
        doc,
        "Cực kỳ lưu ý rằng chân PIN_23 trên bo này được nối cố định với chip nạp UART CH340 (chân RX nhận dữ liệu từ USB), "
        "KHÔNG PHẢI là chân Clock 50MHz như một số bo kit Altera cũ khác. Chân thạch anh 50MHz chuẩn trên bo này "
        "bắt buộc phải là PIN_24 (CLK0)!",
        title="CẢNH BÁO QUAN TRỌNG VỀ XUNG CLOCK:"
    )
    
    doc.add_paragraph()
    
    # --------------------------------------------------------------------------
    # MỤC 3: BẢNG GÁN CHÂN CHO DỰ ÁN ĐÈN GIAO THÔNG (TRAFFIC_LIGHT_TOP)
    # --------------------------------------------------------------------------
    h1 = doc.add_heading(level=1)
    h1.paragraph_format.space_before = Pt(14)
    h1.paragraph_format.space_after = Pt(4)
    r = h1.add_run("3. Bảng Gán Chân Chi Tiết Cho Dự Án Đèn Giao Thông (Top-Level Anode Chung)")
    r.font.name = 'Segoe UI'
    r.font.bold = True
    r.font.size = Pt(13.5)
    r.font.color.rgb = COLOR_PRIMARY
    
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(6)
    p.add_run(
        "Bảng dưới đây quy định toàn bộ 29 tín hiệu ngõ vào / ngõ ra của thiết kế Top-Level "
        "(traffic_light_top.vhd) cho LED 7 đoạn Anode chung, kèm theo chân FPGA và vị trí cắm trên các hàng rào GPIO Header:"
    )
    
    tbl_project = doc.add_table(rows=1, cols=6)
    tbl_project.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl_project.autofit = False
    
    col_w3 = [Inches(1.2), Inches(0.6), Inches(1.0), Inches(1.1), Inches(1.1), Inches(2.0)]
    for idx, width in enumerate(col_w3):
        tbl_project.rows[0].cells[idx].width = width
        
    hdr3 = tbl_project.rows[0].cells
    hdr3[0].text = "Tên Tín Hiệu (Port)"
    hdr3[1].text = "Hướng"
    hdr3[2].text = "Chân FPGA"
    hdr3[3].text = "Chuẩn Logic"
    hdr3[4].text = "Mức Kích Hoạt"
    hdr3[5].text = "Chức Năng & Vị Trí Kết Nối"
    for c in hdr3:
        c.paragraphs[0].runs[0].font.name = 'Segoe UI'
        c.paragraphs[0].runs[0].font.bold = True
        c.paragraphs[0].runs[0].font.size = Pt(9.2)
        c.paragraphs[0].runs[0].font.color.rgb = RGBColor(255, 255, 255)
        set_cell_background(c, "1B365D")
        set_cell_margins(c, 100, 100, 120, 120)
        
    project_pins = [
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
    for idx, (p_name, direct, p_num, std, active, desc) in enumerate(project_pins):
        bg = "F8FAFC" if idx % 2 == 1 else "FFFFFF"
        row = tbl_project.add_row()
        for c_idx, text in enumerate([p_name, direct, p_num, std, active, desc]):
            cell = row.cells[c_idx]
            cell.width = col_w3[c_idx]
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            p = cell.paragraphs[0]
            p.paragraph_format.space_before = Pt(2)
            p.paragraph_format.space_after = Pt(2)
            r = p.add_run(text)
            r.font.name = 'Segoe UI'
            r.font.size = Pt(8.8)
            if c_idx == 0:
                r.font.bold = True
                r.font.color.rgb = COLOR_PRIMARY
            elif c_idx == 2:
                r.font.bold = True
                r.font.color.rgb = RGBColor(185, 28, 28)
            elif c_idx == 1:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                r.font.bold = True
                r.font.color.rgb = RGBColor(14, 116, 144)
            else:
                r.font.color.rgb = COLOR_TEXT
            set_cell_background(cell, bg)
            set_cell_margins(cell, 70, 70, 100, 100)
            
    doc.add_paragraph()

    # --------------------------------------------------------------------------
    # MỤC 3.1: BẢNG NỐI DÂY CHI TIẾT CON LED 7 ĐOẠN ĐÔI 10 CHÂN (ANODE CHUNG)
    # --------------------------------------------------------------------------
    h2 = doc.add_heading(level=2)
    h2.paragraph_format.space_before = Pt(10)
    h2.paragraph_format.space_after = Pt(4)
    r2 = h2.add_run("3.1. Bảng Hướng Dẫn Nối Dây Thực Tế Con LED 7 Đoạn Đôi 10 Chân Anode Chung Sang FPGA")
    r2.font.name = 'Segoe UI'
    r2.font.bold = True
    r2.font.size = Pt(12)
    r2.font.color.rgb = COLOR_SECONDARY

    p_led = doc.add_paragraph()
    p_led.paragraph_format.space_after = Pt(6)
    p_led.add_run(
        "Đây là bảng tra cứu trực tiếp theo thứ tự chân 1 đến 10 trên con LED 7 đoạn 2 chữ số Anode chung (5621AH / 3621AH, 10 chân) "
        "khi ghép nối với IC đệm dòng ULN2803G (DIP-18) để bảo vệ FPGA 100%:\n\n"
        "SƠ ĐỒ BỐ TRÍ CHÂN THỰC TẾ (NHÌN TỪ MẶT TRƯỚC LED):\n"
        "       10    9    8    7    6\n"
        "    +--------------------------+\n"
        "    |   A    B   D1   D2    F  |  <-- HÀNG CHÂN TRÊN\n"
        "    |                          |\n"
        "    |  [DIG 1]        [DIG 2]  |\n"
        "    |  (Hàng chục)    (Đơn vị) |\n"
        "    |                          |\n"
        "    |   C   DP    E    D    G  |  <-- HÀNG CHÂN DƯỚI\n"
        "    +--------------------------+\n"
        "        1    2    3    4    5\n\n"
        "- IC ULN2803G đệm dòng cho 7 thanh đoạn: Chân FPGA phát mức '1' vào Input ULN2803G -> Output của ULN2803G kéo chân Cathode của thanh LED xuống GND -> LED SÁNG!\n"
        "- 2 chân DIG1 (Chân 8) và DIG2 (Chân 7) là cực Dương chung (Anode), nối TRỰC TIẾP vào chân FPGA tương ứng (FPGA phát mức 1 cấp nguồn 3.3V)."
    )

    tbl_led_direct = doc.add_table(rows=1, cols=7)
    tbl_led_direct.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl_led_direct.autofit = False

    col_w_led = [Inches(0.9), Inches(1.1), Inches(1.4), Inches(1.2), Inches(1.1), Inches(1.1), Inches(1.5)]
    for idx, width in enumerate(col_w_led):
        tbl_led_direct.rows[0].cells[idx].width = width

    hdr_led = tbl_led_direct.rows[0].cells
    hdr_led[0].text = "Chân LED"
    hdr_led[1].text = "Tên Đoạn"
    hdr_led[2].text = "Nối Vào ULN2803G"
    hdr_led[3].text = "Linh Kiện Kèm"
    hdr_led[4].text = "FPGA Làn A"
    hdr_led[5].text = "FPGA Làn B"
    hdr_led[6].text = "Chức Năng & Vị Trí"
    for c in hdr_led:
        c.paragraphs[0].runs[0].font.name = 'Segoe UI'
        c.paragraphs[0].runs[0].font.bold = True
        c.paragraphs[0].runs[0].font.size = Pt(8.8)
        c.paragraphs[0].runs[0].font.color.rgb = RGBColor(255, 255, 255)
        set_cell_background(c, "0E7490")
        set_cell_margins(c, 100, 100, 100, 100)

    led_wiring_data = [
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
    for idx, (p_led_num, seg_name, uln_pin, comp, fpga_a, fpga_b, note_seg) in enumerate(led_wiring_data):
        bg = "F0F9FF" if idx % 2 == 1 else "FFFFFF"
        row = tbl_led_direct.add_row()
        for c_idx, text in enumerate([p_led_num, seg_name, uln_pin, comp, fpga_a, fpga_b, note_seg]):
            cell = row.cells[c_idx]
            cell.width = col_w_led[c_idx]
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            p = cell.paragraphs[0]
            p.paragraph_format.space_before = Pt(2)
            p.paragraph_format.space_after = Pt(2)
            r = p.add_run(text)
            r.font.name = 'Segoe UI'
            r.font.size = Pt(8.5)
            if c_idx == 0:
                r.font.bold = True
                r.font.color.rgb = RGBColor(185, 28, 28)
            elif c_idx in (4, 5):
                r.font.bold = True
                r.font.color.rgb = COLOR_PRIMARY
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            elif c_idx == 1:
                r.font.bold = True
                r.font.color.rgb = COLOR_SECONDARY
            elif c_idx == 2:
                r.font.bold = True
                r.font.color.rgb = RGBColor(14, 116, 144)
            else:
                r.font.color.rgb = COLOR_TEXT
            set_cell_background(cell, bg)
            set_cell_margins(cell, 60, 60, 80, 80)

    doc.add_paragraph()
    
    # --------------------------------------------------------------------------
    # MỤC 3.2: HƯỚNG DẪN CẮM DÂY TRÊN BREADBOARD (BOARD TEST) VỚI IC UL2803G
    # --------------------------------------------------------------------------
    h2_bb = doc.add_heading(level=2)
    h2_bb.paragraph_format.space_before = Pt(10)
    h2_bb.paragraph_format.space_after = Pt(4)
    r2_bb = h2_bb.add_run("3.2. Hướng Dẫn Chi Tiết Các Bước Cắm Dây Trên Breadboard (Board Test) Với IC UL2803G")
    r2_bb.font.name = 'Segoe UI'
    r2_bb.font.bold = True
    r2_bb.font.size = Pt(12)
    r2_bb.font.color.rgb = COLOR_SECONDARY

    p_bb = doc.add_paragraph()
    p_bb.paragraph_format.space_after = Pt(6)
    p_bb.add_run(
        "Để cắm test mạch chạy mượt mà, không bị rối dây và đảm bảo an toàn tuyệt đối cho Kit FPGA Cyclone IV, "
        "bạn thực hiện cắm linh kiện trên Breadboard theo 4 bước chuẩn hóa sau:\n\n"
        "BƯỚC 1: ĐẶT IC UL2803G VÀ CẤP NGUỒN\n"
        "- Cắm 2 con IC UL2803G (DIP-18) nằm ngang vắt qua rãnh giữa của Breadboard (IC1 cho Làn A, IC2 cho Làn B). "
        "Lưu ý khuyết tròn (chấm chỉ vị trí chân 1) quay sang phía bên tay trái.\n"
        "- Chân 9 của cả 2 IC: Nối dây về thanh Bus GND (-) trên Breadboard, sau đó nối về chân GND của bo FPGA.\n"
        "- Chân 10 của cả 2 IC: Nối dây về thanh Bus VCC (+) trên Breadboard, sau đó nối về chân 3.3V của bo FPGA.\n\n"
        "BƯỚC 2: NỐI CHÂN TÍN HIỆU TỪ FPGA VÀO INPUT UL2803G (Hàng chân dưới của IC: Chân 1 đến 7)\n"
        "- Làn A: Nối 7 dây Đực-Đực từ FPGA vào Chân 1..7 của IC1:\n"
        "  + PIN_110 -> Chân 1 (1B)  |  PIN_111 -> Chân 2 (2B)  |  PIN_112 -> Chân 3 (3B)\n"
        "  + PIN_113 -> Chân 4 (4B)  |  PIN_115 -> Chân 5 (5B)  |  PIN_119 -> Chân 6 (6B)  |  PIN_120 -> Chân 7 (7B)\n"
        "- Làn B: Nối 7 dây Đực-Đực từ FPGA vào Chân 1..7 của IC2:\n"
        "  + PIN_125 -> Chân 1 (1B)  |  PIN_126 -> Chân 2 (2B)  |  PIN_127 -> Chân 3 (3B)\n"
        "  + PIN_128 -> Chân 4 (4B)  |  PIN_129 -> Chân 5 (5B)  |  PIN_132 -> Chân 6 (6B)  |  PIN_133 -> Chân 7 (7B)\n\n"
        "BƯỚC 3: NỐI OUTPUT UL2803G QUA ĐIỆN TRỞ 330Ω VÀO CÁC ĐOẠN a..g CỦA LED 7 ĐOẠN (Hàng chân trên: Chân 18 về 12)\n"
        "- Chân 18 (1C) -> Trở 330Ω -> Chân 10 của LED (Đoạn A)\n"
        "- Chân 17 (2C) -> Trở 330Ω -> Chân 9 của LED (Đoạn B)\n"
        "- Chân 16 (3C) -> Trở 330Ω -> Chân 1 của LED (Đoạn C)\n"
        "- Chân 15 (4C) -> Trở 330Ω -> Chân 4 của LED (Đoạn D)\n"
        "- Chân 14 (5C) -> Trở 330Ω -> Chân 3 của LED (Đoạn E)\n"
        "- Chân 13 (6C) -> Trở 330Ω -> Chân 6 của LED (Đoạn F)\n"
        "- Chân 12 (7C) -> Trở 330Ω -> Chân 5 của LED (Đoạn G)\n"
        "- Chân 11 (8C) & Chân 2 của LED (DP): Bỏ trống không dùng.\n\n"
        "BƯỚC 4: NỐI CHÂN ĐIỀU KHIỂN VỊ TRÍ DIG1, DIG2 (CỰC DƯƠNG CHUNG)\n"
        "- Làn A: Nối thẳng PIN_124 vào Chân 8 của LED (DIG1 - Chục); Nối thẳng PIN_121 vào Chân 7 của LED (DIG2 - Đơn vị).\n"
        "- Làn B: Nối thẳng PIN_136 vào Chân 8 của LED (DIG1 - Chục); Nối thẳng PIN_135 vào Chân 7 của LED (DIG2 - Đơn vị).\n"
        "(Cách nối này không cần thêm transistor nào, cắm gọn gàng và chạy ngay lập tức)."
    )

    doc.add_paragraph()
    add_callout(
        doc,
        "Các tín hiệu đã được phân bổ tối ưu theo nguyên tắc 'Zero-Crossing PCB Routing' (Không đan chéo đường mạch):\n"
        "1. Hàng Rào Trên (Top Header): Dành riêng cho cụm Đèn giao thông và Điều khiển (PIN_38 đến PIN_53).\n"
        "2. Hàng Rào Dưới (Bottom Header): Dành riêng cho 2 cụm LED 7 đoạn quét động Làn A & B (PIN_110 đến PIN_136).\n"
        "3. Hàng Rào Trái (Left Header): Để trống 100%, không vướng vào cổng USB-C hay các nút bấm onboard.\n"
        "Khi thiết kế Schematic và Layout trên Altium/KiCad/Proteus, các bus tín hiệu sẽ đi thẳng tắp ra linh kiện mà không cần đảo lớp hoặc dùng nhiều via xuyên lớp.",
        title="TỐI ƯU CHO THIẾT KẾ LAYOUT MẠCH IN PCB:",
        border_color="0E7490",
        bg_color="F0F9FF"
    )
    
    doc.add_paragraph()
    
    # --------------------------------------------------------------------------
    # MỤC 4: DANH MỤC TOÀN BỘ CHÂN GPIO TRÊN BO (TRA CỨU RỘNG)
    # --------------------------------------------------------------------------
    h1 = doc.add_heading(level=1)
    h1.paragraph_format.space_before = Pt(14)
    h1.paragraph_format.space_after = Pt(4)
    r = h1.add_run("4. Danh Mục Toàn Bộ Các Chân GPIO Khả Dụng Trên Các Hàng Rào Cắm")
    r.font.name = 'Segoe UI'
    r.font.bold = True
    r.font.size = Pt(13.5)
    r.font.color.rgb = COLOR_PRIMARY
    
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(6)
    p.add_run(
        "Ngoài các chân đã sử dụng ở trên, bo mạch còn rất nhiều chân GPIO tự do mở rộng trên các hàng rào cắm. "
        "Người dùng có thể tự do chọn lựa các chân này để kết nối thêm cảm biến, còi báo động hoặc màn hình LCD:"
    )
    
    tbl_gpio = doc.add_table(rows=1, cols=3)
    tbl_gpio.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl_gpio.autofit = False
    
    col_w4 = [Inches(1.8), Inches(2.7), Inches(2.5)]
    for idx, width in enumerate(col_w4):
        tbl_gpio.rows[0].cells[idx].width = width
        
    hdr4 = tbl_gpio.rows[0].cells
    hdr4[0].text = "Nhóm Vùng Chân"
    hdr4[1].text = "Danh Sách Chân FPGA (PIN_xx)"
    hdr4[2].text = "Đặc Tính & Khuyến Nghị"
    for c in hdr4:
        c.paragraphs[0].runs[0].font.name = 'Segoe UI'
        c.paragraphs[0].runs[0].font.bold = True
        c.paragraphs[0].runs[0].font.size = Pt(9.5)
        c.paragraphs[0].runs[0].font.color.rgb = RGBColor(255, 255, 255)
        set_cell_background(c, "1E293B")
        set_cell_margins(c, 100, 100, 140, 140)
        
    gpio_groups = [
        ("Hàng Rào Trên (Top Header) - Đang dùng", "PIN_38, 39, 42, 43, 44, 46, 49, 50, 51, 52, 53", "Dùng cho 6 LED Giao thông (A, B) và 5 nút/công tắc điều khiển. Nhóm gọn gàng."),
        ("Hàng Rào Trên (Top Header) - Còn trống", "PIN_54, PIN_55, PIN_58, PIN_59", "Các chân GPIO dự phòng tiếp theo trên rào trên, có thể nối thêm còi buzzer, đèn người đi bộ."),
        ("Hàng Rào Dưới (Bottom Header) - Đang dùng", "PIN_110, 111, 112, 113, 115, 119, 120, 121, 124, 125, 126, 127, 128, 129, 132, 133, 135, 136", "Dùng toàn bộ cho 2 cụm LED 7 đoạn quét động Làn A & Làn B (18 chân liên tiếp cực gọn)."),
        ("Hàng Rào Dưới (Bottom Header) - Còn trống", "PIN_137, PIN_138, PIN_141, PIN_142, PIN_143, PIN_144", "Các chân dự phòng phía dưới bên phải, có thể dùng để giao tiếp thêm cảm biến siêu âm."),
        ("Hàng Rào Trái (Left Header) - Để trống", "PIN_28, PIN_30, PIN_31, PIN_32, PIN_33, PIN_34", "Để trống 100% để tránh vướng vào cổng USB-C và hàng nút nhấn onboard."),
        ("Chân Nguồn trên Rào", "VCC3V3 (3.3V), VCC5V (5V), GND (0V)", "Mỗi hàng rào đều có các chân GND và Nguồn để cấp cho module ngoài.")
    ]
    
    for idx, (grp, pins, note) in enumerate(gpio_groups):
        bg = "F1F5F9" if idx % 2 == 1 else "FFFFFF"
        row = tbl_gpio.add_row()
        for c_idx, text in enumerate([grp, pins, note]):
            cell = row.cells[c_idx]
            cell.width = col_w4[c_idx]
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            p = cell.paragraphs[0]
            p.paragraph_format.space_before = Pt(2)
            p.paragraph_format.space_after = Pt(2)
            r = p.add_run(text)
            r.font.name = 'Segoe UI'
            r.font.size = Pt(9.0)
            if c_idx == 0:
                r.font.bold = True
                r.font.color.rgb = COLOR_PRIMARY
            elif c_idx == 1:
                r.font.bold = True
                r.font.color.rgb = COLOR_SECONDARY
            else:
                r.font.color.rgb = COLOR_TEXT
            set_cell_background(cell, bg)
            set_cell_margins(cell, 80, 80, 120, 120)
            
    doc.add_paragraph()
    
    # --------------------------------------------------------------------------
    # MỤC 5: CÁC CHÂN CẤM / HẠN CHẾ SỬ DỤNG
    # --------------------------------------------------------------------------
    h1 = doc.add_heading(level=1)
    h1.paragraph_format.space_before = Pt(14)
    h1.paragraph_format.space_after = Pt(4)
    r = h1.add_run("5. Danh Sách Các Chân CẤM HOẶC HẠN CHẾ Sử Dụng")
    r.font.name = 'Segoe UI'
    r.font.bold = True
    r.font.size = Pt(13.5)
    r.font.color.rgb = RGBColor(185, 28, 28)
    
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(6)
    p.add_run(
        "Để tránh gây chập cháy phần cứng, mất kết nối JTAG hoặc hỏng chip FPGA, "
        "tuyệt đối KHÔNG được gán các tín hiệu người dùng vào các chân chuyên dụng dưới đây:"
    )
    
    tbl_prohibit = doc.add_table(rows=1, cols=3)
    tbl_prohibit.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl_prohibit.autofit = False
    
    col_w5 = [Inches(1.5), Inches(2.2), Inches(3.3)]
    for idx, width in enumerate(col_w5):
        tbl_prohibit.rows[0].cells[idx].width = width
        
    hdr5 = tbl_prohibit.rows[0].cells
    hdr5[0].text = "Nhóm Chức Năng"
    hdr5[1].text = "Chân FPGA"
    hdr5[2].text = "Lý Do Cấm / Cảnh Báo Rủi Ro"
    for c in hdr5:
        c.paragraphs[0].runs[0].font.name = 'Segoe UI'
        c.paragraphs[0].runs[0].font.bold = True
        c.paragraphs[0].runs[0].font.size = Pt(9.5)
        c.paragraphs[0].runs[0].font.color.rgb = RGBColor(255, 255, 255)
        set_cell_background(c, "991B1B")
        set_cell_margins(c, 100, 100, 140, 140)
        
    prohibit_data = [
        ("Giao Tiếp JTAG", "PIN_16 (TCK), PIN_18 (TMS), PIN_20 (TDO), PIN_17 (TDI)", "Phục vụ nạp chương trình từ máy tính. Nếu dùng làm I/O thường sẽ mất kết nối USB-Blaster và không thể nạp được chip."),
        ("Cấu Hình Hệ Thống", "PIN_12 (nCONFIG), PIN_13 (nSTATUS), PIN_14 (CONF_DONE), PIN_15 (nCE)", "Các chân điều khiển chu trình Boot của FPGA từ Flash. Nếu nối ngoại vi sẽ làm chip bị treo không khởi động."),
        ("Chế Độ Cấu Hình MSEL", "MSEL[2..0] (Chân cấu hình phần cứng)", "Quy định chế độ nạp (AS hay JTAG), đã được nối sẵn trở trên bo mạch."),
        ("Nguồn Lõi (VCCINT)", "PIN_29, 45, 62, 82, 102, 118, 134...", "Nguồn điện áp 1.2V cấp cho lõi logic bên trong FPGA. CẤM NỐI VÀO I/O!"),
        ("Nguồn I/O (VCCIO)", "PIN_26, 40, 56, 78, 93, 107, 122, 140...", "Nguồn điện áp 3.3V cấp cho các khối đệm I/O. CẤM NỐI VÀO I/O!"),
        ("Chân Mát (GND)", "PIN_35, 47, 61, 79, 92, 108, 123, 139...", "Nối đất toàn mạch (Ground). Tuyệt đối không gán logic.")
    ]
    
    for idx, (grp, pins, reason) in enumerate(prohibit_data):
        bg = "FEF2F2" if idx % 2 == 1 else "FFFFFF"
        row = tbl_prohibit.add_row()
        for c_idx, text in enumerate([grp, pins, reason]):
            cell = row.cells[c_idx]
            cell.width = col_w5[c_idx]
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            p = cell.paragraphs[0]
            p.paragraph_format.space_before = Pt(2)
            p.paragraph_format.space_after = Pt(2)
            r = p.add_run(text)
            r.font.name = 'Segoe UI'
            r.font.size = Pt(9.0)
            if c_idx == 0:
                r.font.bold = True
                r.font.color.rgb = RGBColor(185, 28, 28)
            elif c_idx == 1:
                r.font.bold = True
                r.font.color.rgb = COLOR_TEXT
            else:
                r.font.color.rgb = COLOR_TEXT
            set_cell_background(cell, bg)
            set_cell_margins(cell, 80, 80, 120, 120)
            
    doc.add_paragraph()
    
    # --------------------------------------------------------------------------
    # MỤC 6: PHỤ LỤC - BẢNG CHÂN CHO KIT DE2-115 (EP4CE115F29C7)
    # --------------------------------------------------------------------------
    h1 = doc.add_heading(level=1)
    h1.paragraph_format.space_before = Pt(14)
    h1.paragraph_format.space_after = Pt(4)
    r = h1.add_run("6. Phụ Lục: Bảng Gán Chân Cho Kit DE2-115 (EP4CE115F29C7)")
    r.font.name = 'Segoe UI'
    r.font.bold = True
    r.font.size = Pt(13.5)
    r.font.color.rgb = COLOR_PRIMARY
    
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(6)
    p.add_run(
        "Bảng chân này dùng khi bạn cần đem đồ án lên phòng thực hành của trường để chạy trên kit "
        "Terasic DE2-115 (bo kit Altera Cyclone IV lớn hơn với 115.000 LEs và đầy đủ LED, Switch, 7 đoạn sẵn có):"
    )
    
    tbl_de2 = doc.add_table(rows=1, cols=4)
    tbl_de2.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl_de2.autofit = False
    
    col_w6 = [Inches(1.8), Inches(1.5), Inches(1.4), Inches(2.3)]
    for idx, width in enumerate(col_w6):
        tbl_de2.rows[0].cells[idx].width = width
        
    hdr6 = tbl_de2.rows[0].cells
    hdr6[0].text = "Tín Hiệu (Port)"
    hdr6[1].text = "Chân DE2-115"
    hdr6[2].text = "Điện Áp I/O"
    hdr6[3].text = "Linh Kiện Tích Hợp Sẵn Trên Kit"
    for c in hdr6:
        c.paragraphs[0].runs[0].font.name = 'Segoe UI'
        c.paragraphs[0].runs[0].font.bold = True
        c.paragraphs[0].runs[0].font.size = Pt(9.5)
        c.paragraphs[0].runs[0].font.color.rgb = RGBColor(255, 255, 255)
        set_cell_background(c, "334155")
        set_cell_margins(c, 100, 100, 140, 140)
        
    de2_pins = [
        ("CLOCK_50", "PIN_Y2", "3.3V LVTTL", "Thạch anh 50MHz tích hợp trên DE2-115."),
        ("KEY[0]", "PIN_M23", "2.5 V", "Nút bấm KEY0 trên bo (Master Reset)."),
        ("KEY[1]", "PIN_M21", "2.5 V", "Nút bấm KEY1 trên bo (Khẩn cấp Làn A)."),
        ("KEY[2]", "PIN_N21", "2.5 V", "Nút bấm KEY2 trên bo (Khẩn cấp Làn B)."),
        ("SW[0]", "PIN_AB28", "2.5 V", "Công tắc gạt SW0 trên bo (Chế độ Ban đêm)."),
        ("SW[1]", "PIN_AC28", "2.5 V", "Công tắc gạt SW1 trên bo (Chế độ Tạm dừng Pause)."),
        ("LEDR[0] (Vàng A)", "PIN_G19", "2.5 V", "Đèn LED đỏ/vàng LEDR0 trên bo."),
        ("LEDR[1] (Đỏ A)", "PIN_F19", "2.5 V", "Đèn LED đỏ LEDR1 trên bo."),
        ("LEDG[0] (Xanh A)", "PIN_E21", "2.5 V", "Đèn LED xanh lá LEDG0 trên bo."),
        ("LEDR[2] (Vàng B)", "PIN_E19", "2.5 V", "Đèn LED đỏ/vàng LEDR2 trên bo."),
        ("LEDR[3] (Đỏ B)", "PIN_F21", "2.5 V", "Đèn LED đỏ LEDR3 trên bo."),
        ("LEDG[1] (Xanh B)", "PIN_E22", "2.5 V", "Đèn LED xanh lá LEDG1 trên bo."),
        ("HEX0[0..6] (Đơn vị A)", "G18, F22, E17, L26, L25, J22, H22", "2.5 V", "LED 7 đoạn HEX0 sẵn trên bo (Active-Low)."),
        ("HEX1[0..6] (Chục A)", "M24, Y22, W21, W22, W25, U23, U24", "2.5 V", "LED 7 đoạn HEX1 sẵn trên bo (Active-Low)."),
        ("HEX2[0..6] (Đơn vị B)", "AA25, AA26, Y25, W26, Y27, W27, W28", "2.5 V", "LED 7 đoạn HEX2 sẵn trên bo (Active-Low)."),
        ("HEX3[0..6] (Chục B)", "V21, U21, AB20, AA21, AD24, AF23, Q25", "2.5 V", "LED 7 đoạn HEX3 sẵn trên bo (Active-Low).")
    ]
    
    for idx, (p_name, pin_de2, volt, dev) in enumerate(de2_pins):
        bg = "F8FAFC" if idx % 2 == 1 else "FFFFFF"
        row = tbl_de2.add_row()
        for c_idx, text in enumerate([p_name, pin_de2, volt, dev]):
            cell = row.cells[c_idx]
            cell.width = col_w6[c_idx]
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            p = cell.paragraphs[0]
            p.paragraph_format.space_before = Pt(2)
            p.paragraph_format.space_after = Pt(2)
            r = p.add_run(text)
            r.font.name = 'Segoe UI'
            r.font.size = Pt(9.0)
            if c_idx == 0:
                r.font.bold = True
                r.font.color.rgb = COLOR_PRIMARY
            elif c_idx == 1:
                r.font.bold = True
                r.font.color.rgb = COLOR_SECONDARY
            else:
                r.font.color.rgb = COLOR_TEXT
            set_cell_background(cell, bg)
            set_cell_margins(cell, 80, 80, 120, 120)
            
    doc.add_paragraph()
    
    # --------------------------------------------------------------------------
    # MỤC 7: MÃ LỆNH TCL ĐỂ CHÈN VÀO FILE .QSF
    # --------------------------------------------------------------------------
    h1 = doc.add_heading(level=1)
    h1.paragraph_format.space_before = Pt(14)
    h1.paragraph_format.space_after = Pt(4)
    r = h1.add_run("7. Đoạn Mã Lệnh TCL Gán Chân Mẫu Để Chèn Vào File .QSF (Quartus)")
    r.font.name = 'Segoe UI'
    r.font.bold = True
    r.font.size = Pt(13.5)
    r.font.color.rgb = COLOR_PRIMARY
    
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(6)
    p.add_run(
        "Nếu bạn muốn áp dụng ngay bảng gán chân này cho bo Cyclone IV EP4CE6E22C8N, "
        "chỉ cần sao chép toàn bộ đoạn mã dưới đây và dán vào cuối file traffic_light_top.qsf:"
    )
    
    qsf_code = (
        "# ==============================================================================\n"
        "# GÁN CHÂN PHẦN CỨNG 100% GPIO NGOÀI TỐI ƯU VẼ PCB (ZERO-CROSSING)\n"
        "# Kit Altera / Intel Cyclone IV E EP4CE6E22C8N (Điện áp chuẩn: 3.3-V LVTTL)\n"
        "# ==============================================================================\n"
        "# 1. MASTER CLOCK 50 MHZ (ONBOARD ACTIVE CRYSTAL OSCILLATOR)\n"
        "set_location_assignment PIN_24 -to CLOCK_50\n"
        "set_instance_assignment -name IO_STANDARD \"3.3-V LVTTL\" -to CLOCK_50\n\n"
        "# 2. TOP HEADER: TOÀN BỘ ĐÈN GIAO THÔNG & ĐIỀU KHIỂN (LIÊN TIẾP TỪ PIN_38 ĐẾN 53)\n"
        "# --- 6 Đèn giao thông (Active-High: '1' là sáng đèn) ---\n"
        "# Làn A: Xanh, Vàng, Đỏ\n"
        "set_location_assignment PIN_38 -to LEDG[0]\n"
        "set_location_assignment PIN_39 -to LEDR[0]\n"
        "set_location_assignment PIN_42 -to LEDR[1]\n"
        "set_instance_assignment -name IO_STANDARD \"3.3-V LVTTL\" -to LEDG[0]\n"
        "set_instance_assignment -name IO_STANDARD \"3.3-V LVTTL\" -to LEDR[0]\n"
        "set_instance_assignment -name IO_STANDARD \"3.3-V LVTTL\" -to LEDR[1]\n\n"
        "# Làn B: Xanh, Vàng, Đỏ\n"
        "set_location_assignment PIN_43 -to LEDG[1]\n"
        "set_location_assignment PIN_44 -to LEDR[2]\n"
        "set_location_assignment PIN_46 -to LEDR[3]\n"
        "set_instance_assignment -name IO_STANDARD \"3.3-V LVTTL\" -to LEDG[1]\n"
        "set_instance_assignment -name IO_STANDARD \"3.3-V LVTTL\" -to LEDR[2]\n"
        "set_instance_assignment -name IO_STANDARD \"3.3-V LVTTL\" -to LEDR[3]\n\n"
        "# --- 3 Nút nhấn điều khiển ngoài (Active-Low: '0' là bấm) ---\n"
        "# KEY0: Reset hệ thống | KEY1: Khẩn cấp Làn A | KEY2: Khẩn cấp Làn B\n"
        "set_location_assignment PIN_49 -to KEY[0]\n"
        "set_location_assignment PIN_50 -to KEY[1]\n"
        "set_location_assignment PIN_51 -to KEY[2]\n"
        "set_instance_assignment -name IO_STANDARD \"3.3-V LVTTL\" -to KEY[0]\n"
        "set_instance_assignment -name IO_STANDARD \"3.3-V LVTTL\" -to KEY[1]\n"
        "set_instance_assignment -name IO_STANDARD \"3.3-V LVTTL\" -to KEY[2]\n"
        "set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to KEY[*]\n\n"
        "# --- 2 Công tắc gạt chế độ ngoài (Active-Low kèm trở kéo lên nội 3.3V) ---\n"
        "# SW0: Chế độ Ban đêm (Chớp vàng 1Hz) | SW1: Tạm dừng Pause bộ đếm\n"
        "set_location_assignment PIN_52 -to SW[0]\n"
        "set_location_assignment PIN_53 -to SW[1]\n"
        "set_instance_assignment -name IO_STANDARD \"3.3-V LVTTL\" -to SW[0]\n"
        "set_instance_assignment -name IO_STANDARD \"3.3-V LVTTL\" -to SW[1]\n"
        "set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to SW[*]\n\n"
        "# 3. BOTTOM HEADER: TOÀN BỘ HIỂN THỊ LED 7 ĐOẠN ANODE CHUNG (PIN_110 ĐẾN 136)\n"
        "# --- LED 7 đoạn quét động Làn A (Active-Low: '0' là sáng thanh đoạn) ---\n"
        "set_location_assignment PIN_110 -to HEX_A_SEG[0]\n"
        "set_location_assignment PIN_111 -to HEX_A_SEG[1]\n"
        "set_location_assignment PIN_112 -to HEX_A_SEG[2]\n"
        "set_location_assignment PIN_113 -to HEX_A_SEG[3]\n"
        "set_location_assignment PIN_115 -to HEX_A_SEG[4]\n"
        "set_location_assignment PIN_119 -to HEX_A_SEG[5]\n"
        "set_location_assignment PIN_120 -to HEX_A_SEG[6]\n"
        "set_instance_assignment -name IO_STANDARD \"3.3-V LVTTL\" -to HEX_A_SEG[*]\n\n"
        "# Chân chọn vị trí LED Làn A: DIG0=Đơn vị, DIG1=Hàng chục (Mức 1 cấp 3.3V)\n"
        "set_location_assignment PIN_121 -to HEX_A_DIG[0]\n"
        "set_location_assignment PIN_124 -to HEX_A_DIG[1]\n"
        "set_instance_assignment -name IO_STANDARD \"3.3-V LVTTL\" -to HEX_A_DIG[*]\n\n"
        "# --- LED 7 đoạn quét động Làn B (Active-Low: '0' là sáng thanh đoạn) ---\n"
        "set_location_assignment PIN_125 -to HEX_B_SEG[0]\n"
        "set_location_assignment PIN_126 -to HEX_B_SEG[1]\n"
        "set_location_assignment PIN_127 -to HEX_B_SEG[2]\n"
        "set_location_assignment PIN_128 -to HEX_B_SEG[3]\n"
        "set_location_assignment PIN_129 -to HEX_B_SEG[4]\n"
        "set_location_assignment PIN_132 -to HEX_B_SEG[5]\n"
        "set_location_assignment PIN_133 -to HEX_B_SEG[6]\n"
        "set_instance_assignment -name IO_STANDARD \"3.3-V LVTTL\" -to HEX_B_SEG[*]\n\n"
        "# Chân chọn vị trí LED Làn B: DIG0=Đơn vị, DIG1=Hàng chục (Mức 1 cấp 3.3V)\n"
        "set_location_assignment PIN_135 -to HEX_B_DIG[0]\n"
        "set_location_assignment PIN_136 -to HEX_B_DIG[1]\n"
        "set_instance_assignment -name IO_STANDARD \"3.3-V LVTTL\" -to HEX_B_DIG[*]\n"
    )
    
    tbl_code = doc.add_table(rows=1, cols=1)
    tbl_code.alignment = WD_TABLE_ALIGNMENT.CENTER
    c = tbl_code.cell(0, 0)
    set_cell_background(c, "1E293B")
    set_cell_margins(c, 140, 140, 180, 180)
    p = c.paragraphs[0]
    p.paragraph_format.space_before = Pt(2)
    p.paragraph_format.space_after = Pt(2)
    r = p.add_run(qsf_code)
    r.font.name = 'Consolas'
    r.font.size = Pt(8.8)
    r.font.color.rgb = RGBColor(241, 245, 249)
    
    try:
        doc.save(file_path)
        print(f"Generated successfully: {file_path}")
    except PermissionError:
        alt_path = file_path.replace(".docx", "_CapNhat.docx")
        doc.save(alt_path)
        print(f"File dang mo trong Word, da luu ban cap nhat moi tai: {alt_path}")

if __name__ == "__main__":
    out_dir = r"c:\Users\handa\OneDrive\Documents\Projects\DoAn2\traffic_light_mini\traffic_light_anode_chung"
    target_path = os.path.join(out_dir, "Danh_Sach_Chan_IO_FPGA_Cyclone_IV_Anode_Chung.docx")
    build_pinout_document(target_path)
