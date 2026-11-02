"""
--------------------------------------------------------------------------------
DỰ ÁN: THIẾT KẾ HỆ THỐNG ĐIỀU KHIỂN ĐÈN GIAO THÔNG NGÃ TƯ TRÊN FPGA CYCLONE IV
SCRIPT: generate_bom_doc.py
MỤC ĐÍCH:
  Xuất báo cáo Danh sách Linh kiện & Dự toán Mua sắm (BOM - Bill of Materials)
  định dạng Microsoft Word (.docx) chuyên nghiệp, có dấu Tiếng Việt 100%:
  - Bảng linh kiện chi tiết cho LED 7 đoạn Cathode chung (5621BH / 3621BH).
  - Sử dụng 1 con IC ULN2003 (DIP-16) duy nhất gánh 4 chân DIG Cathode.
  - BỎ HOÀN TOÀN 4 con Transistor PNP và điện trở 1k, mạch cực kỳ tinh gọn.
  - Sơ đồ chân chuẩn 10 chân của LED 7 đoạn đôi và hướng dẫn cắm test / hàn PCB.
--------------------------------------------------------------------------------
"""

import os
from docx import Document
from docx.shared import Pt, Inches, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.oxml import parse_xml, OxmlElement
from docx.oxml.ns import nsdecls, qn

COLOR_PRIMARY = RGBColor(27, 54, 93)       # Deep Navy #1B365D
COLOR_SECONDARY = RGBColor(14, 116, 144)   # Deep Teal #0E7490
COLOR_TEXT_MAIN = RGBColor(30, 41, 59)     # Dark Slate #1E293B
COLOR_MUTED = RGBColor(100, 116, 139)      # Muted Gray #64748B

def set_cell_background(cell, fill_hex):
    shd = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>')
    cell._tc.get_or_add_tcPr().append(shd)

def set_cell_margins(cell, top=80, bottom=80, left=100, right=100):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = OxmlElement('w:tcMar')
    for m, val in [('top', top), ('bottom', bottom), ('left', left), ('right', right)]:
        node = OxmlElement(f'w:{m}')
        node.set(qn('w:w'), str(val))
        node.set(qn('w:type'), 'dxa')
        tcMar.append(node)
    tcPr.append(tcMar)

def add_callout(doc, text, title="LƯU Ý QUAN TRỌNG:", border_color="1B365D", bg_color="F1F5F9"):
    table = doc.add_table(rows=1, cols=1)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    table.rows[0].cells[0].width = Inches(6.5)
    
    cell = table.rows[0].cells[0]
    set_cell_background(cell, bg_color)
    set_cell_margins(cell, 120, 120, 150, 150)
    
    tcPr = cell._tc.get_or_add_tcPr()
    borders = parse_xml(
        f'<w:tcBorders {nsdecls("w")}>'
        f'  <w:left w:val="single" w:sz="24" w:space="0" w:color="{border_color}"/>'
        f'  <w:top w:val="none"/>'
        f'  <w:right w:val="none"/>'
        f'  <w:bottom w:val="none"/>'
        f'</w:tcBorders>'
    )
    tcPr.append(borders)
    
    p = cell.paragraphs[0]
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(2)
    r_title = p.add_run(title + " ")
    r_title.font.name = 'Segoe UI'
    r_title.font.bold = True
    r_title.font.size = Pt(9.5)
    r_title.font.color.rgb = COLOR_PRIMARY
    
    r_txt = p.add_run(text)
    r_txt.font.name = 'Segoe UI'
    r_txt.font.size = Pt(9.0)
    r_txt.font.color.rgb = COLOR_TEXT_MAIN

def build_bom_document(file_path):
    doc = Document()
    
    for sec in doc.sections:
        sec.top_margin = Inches(0.75)
        sec.bottom_margin = Inches(0.75)
        sec.left_margin = Inches(0.75)
        sec.right_margin = Inches(0.75)
        
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
    r_title = p_title.add_run("BẢNG TỔNG HỢP LINH KIỆN & DỰ TOÁN MUA SẮM (BOM)")
    r_title.font.name = 'Segoe UI'
    r_title.font.size = Pt(17)
    r_title.font.bold = True
    r_title.font.color.rgb = COLOR_PRIMARY
    
    p_sub = doc.add_paragraph()
    p_sub.paragraph_format.space_before = Pt(0)
    p_sub.paragraph_format.space_after = Pt(14)
    p_sub.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r_sub = p_sub.add_run("Đồ án: Hệ Thống Điều Khiển Đèn Giao Thông Ngã Tư (Cyclone IV EP4CE6E22C8N)")
    r_sub.font.name = 'Segoe UI'
    r_sub.font.size = Pt(11)
    r_sub.font.italic = True
    r_sub.font.color.rgb = COLOR_SECONDARY
    
    doc.add_paragraph()
    
    # --------------------------------------------------------------------------
    # MỤC 1: BẢNG DANH SÁCH LINH KIỆN CẦN MUA (BOM)
    # --------------------------------------------------------------------------
    h1 = doc.add_heading(level=1)
    h1.paragraph_format.space_before = Pt(12)
    h1.paragraph_format.space_after = Pt(4)
    r = h1.add_run("1. Bảng Thống Kê Chi Tiết Linh Kiện Cần Mua (Phương Án Cathode Chung Tinh Gọn)")
    r.font.name = 'Segoe UI'
    r.font.bold = True
    r.font.size = Pt(13)
    r.font.color.rgb = COLOR_PRIMARY
    
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(6)
    p.add_run(
        "Hệ thống sử dụng LED 7 đoạn đôi Cathode chung (Cực Âm chung) kết hợp cùng 1 con IC ULN2003 duy nhất "
        "để gánh 4 chân DIG xuống GND. Phương án này LOẠI BỎ HOÀN TOÀN các Transistor PNP và trở kích chân B, giúp mạch "
        "cực kỳ tinh gọn, dễ cắm trên Breadboard và chi phí mua sắm tiết kiệm nhất:"
    )
    
    tbl_bom = doc.add_table(rows=1, cols=7)
    tbl_bom.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl_bom.autofit = False
    
    col_w = [Inches(0.5), Inches(1.8), Inches(1.5), Inches(0.7), Inches(0.8), Inches(1.8), Inches(0.9)]
    for idx, width in enumerate(col_w):
        tbl_bom.rows[0].cells[idx].width = width
        
    headers = ["STT", "Tên Linh Kiện", "Mã / Thông Số Kỹ Thuật", "Cần", "Nên Mua", "Công Dụng & Vị Trí Trong Mạch", "Đơn Giá Ước Tính"]
    for idx, h_text in enumerate(headers):
        c = tbl_bom.rows[0].cells[idx]
        c.text = h_text
        c.paragraphs[0].runs[0].font.name = 'Segoe UI'
        c.paragraphs[0].runs[0].font.bold = True
        c.paragraphs[0].runs[0].font.size = Pt(8.8)
        c.paragraphs[0].runs[0].font.color.rgb = RGBColor(255, 255, 255)
        set_cell_background(c, "1B365D")
        set_cell_margins(c, 100, 100, 100, 100)
        
    bom_data = [
        # Nhóm hiển thị
        ("1", "LED 7 đoạn 2 số 0.56\" Cathode chung", "5621BH / 3621BH / 5622BH (10 chân)", "2 con", "3 con", "Đồng hồ đếm lùi 2 chữ số (1 con Làn A, 1 con Làn B). Chú ý mã có chữ cái B là Cathode chung", "8.000 đ"),
        ("2", "LED đơn 5mm Màu ĐỎ (Red)", "Siêu sáng / Đục 5mm", "2 con", "5 con", "Đèn ĐỎ Làn A (PIN_42) và Làn B (PIN_46)", "500 đ"),
        ("3", "LED đơn 5mm Màu VÀNG (Yellow)", "Siêu sáng / Đục 5mm", "2 con", "5 con", "Đèn VÀNG Làn A (PIN_39) và Làn B (PIN_44)", "500 đ"),
        ("4", "LED đơn 5mm Màu XANH LÁ (Green)", "Siêu sáng / Đục 5mm", "2 con", "5 con", "Đèn XANH Làn A (PIN_38) và Làn B (PIN_43)", "500 đ"),
        
        # Nhóm bán dẫn & đệm công suất (CHỈ 1 IC DUY NHẤT)
        ("5", "IC Đệm dòng 7 kênh Darlington", "ULN2003 / ULN2003AN (DIP-16)", "1 con", "2 con", "Gánh toàn bộ dòng xả 50mA - 70mA về GND cho 4 chân DIG (DIG1_A, DIG2_A, DIG1_B, DIG2_B), bảo vệ FPGA an toàn mát 100%", "3.500 đ"),
        ("6", "Đế cắm IC 16 chân", "DIP-16 IC Socket", "1 cái", "2 - 3 cái", "Hàn lên PCB hoặc cắm lên Breadboard để cắm rút IC ULN2003 tránh nhiệt mỏ hàn", "500 đ"),
        
        # Nhóm điện trở (KHÔNG CẦN TRỞ 1K VÌ ĐÃ BỎ TRANSISTOR)
        ("7", "Điện trở 330 Ω (hoặc 220 Ω)", "1/4W (Trở cắm 5 vạch màu)", "20 con", "1 gói (50 con)", "Hạn dòng bảo vệ cho 6 đèn LED giao thông và 14 thanh LED 7 đoạn a..g", "3.000 đ/gói"),
        
        # Nhóm điều khiển
        ("8", "Nút nhấn nhả 4 chân (Tactile switch)", "6x6x5mm", "3 nút", "5 nút", "Nút Reset (PIN_49), Khẩn cấp Làn A (PIN_50), Khẩn cấp Làn B (PIN_51)", "500 đ"),
        ("9", "Công tắc gạt 3 chân SPDT", "Mini Slide Switch SS12D00", "2 cái", "4 cái", "Công tắc Chế độ ban đêm (PIN_52), Tạm dừng Pause (PIN_53)", "1.000 đ"),
        
        # Nhóm phụ kiện test
        ("10", "Breadboard MB-102 (Bo cắm test)", "830 lỗ (165 x 55 mm)", "1 bo", "1 - 2 bo", "Cắm linh kiện chạy thử nghiệm trước khi hàn mạch in PCB", "25.000 đ"),
        ("11", "Dây cắm Breadboard Đực - Cái", "Male to Female 20cm", "1 tép", "1 tép (40 sợi)", "Nối từ hàng cọc kim của bo FPGA sang Breadboard", "15.000 đ"),
        ("12", "Dây cắm Breadboard Đực - Đực", "Male to Male 10cm / 20cm", "1 tép", "1 tép (40 sợi)", "Cầu dây nối các linh kiện trên mặt Breadboard", "15.000 đ"),
        ("13", "Rào Cái 2.54mm 2 hàng (Nữ)", "Female Header 2x20 pin", "2 thanh", "4 thanh", "Hàn lên bo mạch PCB để cắm bo mạch FPGA Cyclone IV lên", "3.000 đ")
    ]
    
    for idx, row_data in enumerate(bom_data):
        bg = "F8FAFC" if idx % 2 == 1 else "FFFFFF"
        row = tbl_bom.add_row()
        for c_idx, text in enumerate(row_data):
            cell = row.cells[c_idx]
            cell.width = col_w[c_idx]
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            p = cell.paragraphs[0]
            p.paragraph_format.space_before = Pt(2)
            p.paragraph_format.space_after = Pt(2)
            r = p.add_run(text)
            r.font.name = 'Segoe UI'
            r.font.size = Pt(8.5)
            if c_idx == 1:
                r.font.bold = True
                r.font.color.rgb = COLOR_PRIMARY
            elif c_idx in (0, 3, 4, 6):
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                if c_idx == 4:
                    r.font.bold = True
                    r.font.color.rgb = RGBColor(185, 28, 28)
            set_cell_background(cell, bg)
            set_cell_margins(cell, 60, 60, 80, 80)
            
    doc.add_paragraph()
    
    # Tổng chi phí Callout
    add_callout(
        doc,
        "Tổng dự toán toàn bộ linh kiện cần mua chỉ dao động từ 65.000 đ đến 80.000 đ (đã bao gồm cả bo cắm test "
        "Breadboard và 2 bộ dây cắm 80 sợi). Việc chuyển sang Cathode chung đã giúp bạn tiết kiệm chi phí, không phải mua "
        "4 con Transistor PNP S8550 và bớt được 1 con IC ULN2003!",
        title="DỰ TOÁN CHI PHÍ LINH KIỆN TIẾT KIỆM:",
        border_color="0E7490",
        bg_color="F0F9FF"
    )
    
    doc.add_paragraph()
    
    # --------------------------------------------------------------------------
    # MỤC 2: NGUYÊN LÝ & KẾT NỐI IC ĐỆM DÒNG ULN2003 CHO CATHODE CHUNG
    # --------------------------------------------------------------------------
    h1 = doc.add_heading(level=1)
    h1.paragraph_format.space_before = Pt(14)
    h1.paragraph_format.space_after = Pt(4)
    r = h1.add_run("2. Hướng Dẫn Kết Nối 1 IC ULN2003 Duy Nhất Cho 4 Chân DIG Cathode")
    r.font.name = 'Segoe UI'
    r.font.bold = True
    r.font.size = Pt(13)
    r.font.color.rgb = COLOR_PRIMARY
    
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(6)
    p.add_run(
        "Với LED Cathode chung (Cực Âm chung), 14 thanh đoạn a..g được FPGA cấp điện áp 3.3V qua điện trở 330 Ω "
        "(mỗi thanh chỉ tiêu thụ khoảng 5mA, chân I/O FPGA phát trực tiếp rất nhẹ nhàng). Toàn bộ dòng xả của cả 7 thanh khi sáng cùng lúc (50mA - 70mA) "
        "sẽ dồn về 4 chân DIG Cathode. Do đó, 1 con IC ULN2003 duy nhất đảm nhiệm kéo 4 chân DIG này xuống GND an toàn tuyệt đối:"
    )
    
    tbl_uln = doc.add_table(rows=1, cols=4)
    tbl_uln.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl_uln.autofit = False
    
    col_w_uln = [Inches(1.2), Inches(1.5), Inches(1.8), Inches(2.5)]
    for idx, width in enumerate(col_w_uln):
        tbl_uln.rows[0].cells[idx].width = width
        
    hdr_uln = tbl_uln.rows[0].cells
    hdr_uln[0].text = "Chân ULN2003"
    hdr_uln[1].text = "Tên Chân"
    hdr_uln[2].text = "Kết Nối Phía FPGA"
    hdr_uln[3].text = "Kết Nối Phía LED 7 Đoạn"
    for c in hdr_uln:
        c.paragraphs[0].runs[0].font.name = 'Segoe UI'
        c.paragraphs[0].runs[0].font.bold = True
        c.paragraphs[0].runs[0].font.size = Pt(9.0)
        c.paragraphs[0].runs[0].font.color.rgb = RGBColor(255, 255, 255)
        set_cell_background(c, "1E293B")
        set_cell_margins(c, 80, 80, 100, 100)
        
    uln_data = [
        ("Chân 1", "1B (Input 1)", "Nối FPGA PIN_121 (HEX_A_DIG(0))", "Điều khiển DIG2 (Đơn vị) Làn A"),
        ("Chân 16", "1C (Output 1)", "Không nối FPGA", "Nối trực tiếp vào Chân 7 (DIG2 Đơn vị) của LED Làn A"),
        ("Chân 2", "2B (Input 2)", "Nối FPGA PIN_124 (HEX_A_DIG(1))", "Điều khiển DIG1 (Chục) Làn A"),
        ("Chân 15", "2C (Output 2)", "Không nối FPGA", "Nối trực tiếp vào Chân 8 (DIG1 Chục) của LED Làn A"),
        ("Chân 3", "3B (Input 3)", "Nối FPGA PIN_135 (HEX_B_DIG(0))", "Điều khiển DIG2 (Đơn vị) Làn B"),
        ("Chân 14", "3C (Output 3)", "Không nối FPGA", "Nối trực tiếp vào Chân 7 (DIG2 Đơn vị) của LED Làn B"),
        ("Chân 4", "4B (Input 4)", "Nối FPGA PIN_136 (HEX_B_DIG(1))", "Điều khiển DIG1 (Chục) Làn B"),
        ("Chân 13", "4C (Output 4)", "Không nối FPGA", "Nối trực tiếp vào Chân 8 (DIG1 Chục) của LED Làn B"),
        ("Chân 5, 6, 7 & 12, 11, 10", "5B..7B & 5C..7C", "Để trống (Không dùng)", "3 kênh dự phòng"),
        ("Chân 8", "E (Emitter / GND)", "Nối GND chung của bo FPGA", "Nối Mass GND chung toàn bộ mạch"),
        ("Chân 9", "COM (Cathode Clamp)", "Nối nguồn 3.3V hoặc 5V", "Triệt tiêu xung điện áp ngược")
    ]
    
    for idx, (p_uln, n_uln, f_uln, l_uln) in enumerate(uln_data):
        bg = "F1F5F9" if idx % 2 == 1 else "FFFFFF"
        row = tbl_uln.add_row()
        for c_idx, text in enumerate([p_uln, n_uln, f_uln, l_uln]):
            cell = row.cells[c_idx]
            cell.width = col_w_uln[c_idx]
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            p = cell.paragraphs[0]
            p.paragraph_format.space_before = Pt(2)
            p.paragraph_format.space_after = Pt(2)
            r = p.add_run(text)
            r.font.name = 'Segoe UI'
            r.font.size = Pt(8.8)
            if c_idx == 0:
                r.font.bold = True
                r.font.color.rgb = RGBColor(185, 28, 28)
            elif c_idx == 1:
                r.font.bold = True
                r.font.color.rgb = COLOR_PRIMARY
            set_cell_background(cell, bg)
            set_cell_margins(cell, 60, 60, 80, 80)
            
    doc.add_paragraph()
    
    # --------------------------------------------------------------------------
    # MỤC 3: SƠ ĐỒ KẾT NỐI CHÂN CON LED 7 ĐOẠN 10 CHÂN CATHODE CHUNG
    # --------------------------------------------------------------------------
    h1 = doc.add_heading(level=1)
    h1.paragraph_format.space_before = Pt(14)
    h1.paragraph_format.space_after = Pt(4)
    r = h1.add_run("3. Sơ Đồ Chân Thực Tế LED 7 Đoạn Đôi 10 Chân Cathode Chung (5621BH / 3621BH)")
    r.font.name = 'Segoe UI'
    r.font.bold = True
    r.font.size = Pt(13)
    r.font.color.rgb = COLOR_PRIMARY
    
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(6)
    p.add_run(
        "Sơ đồ 10 chân của LED 7 đoạn đôi Cathode chung hoàn toàn giống hệt vị trí vật lý của loại Anode chung "
        "(chỉ khác tính chất cực: a..g là Anode nhận 3.3V qua trở 330 Ω, DIG1/DIG2 là Cathode kéo về GND qua ULN2003):\n"
        "- Hàng chân DƯỚI (tính từ Trái qua Phải: 1 đến 5): Chân 1 (C), 2 (DP), 3 (E), 4 (D), 5 (G).\n"
        "- Hàng chân TRÊN (tính từ Phải qua Trái: 10 về 6): Chân 10 (A), 9 (B), 8 (DIG1 Chục), 7 (DIG2 Đơn vị), 6 (F)."
    )
    
    tbl_pin_direct = doc.add_table(rows=1, cols=6)
    tbl_pin_direct.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl_pin_direct.autofit = False
    
    col_w_pd = [Inches(1.0), Inches(1.1), Inches(1.3), Inches(1.2), Inches(1.2), Inches(1.6)]
    for idx, width in enumerate(col_w_pd):
        tbl_pin_direct.rows[0].cells[idx].width = width
        
    hdr_pd = tbl_pin_direct.rows[0].cells
    hdr_pd[0].text = "Chân LED"
    hdr_pd[1].text = "Tên Đoạn"
    hdr_pd[2].text = "Linh Kiện Mắc Kèm"
    hdr_pd[3].text = "FPGA Làn A"
    hdr_pd[4].text = "FPGA Làn B"
    hdr_pd[5].text = "Chức Năng & Vị Trí Nét"
    for c in hdr_pd:
        c.paragraphs[0].runs[0].font.name = 'Segoe UI'
        c.paragraphs[0].runs[0].font.bold = True
        c.paragraphs[0].runs[0].font.size = Pt(9.0)
        c.paragraphs[0].runs[0].font.color.rgb = RGBColor(255, 255, 255)
        set_cell_background(c, "0E7490")
        set_cell_margins(c, 80, 80, 100, 100)
        
    pin_direct_data = [
        ("Chân 10", "Thanh A", "Trở 330Ω", "PIN_110", "PIN_125", "Thanh ngang trên đỉnh"),
        ("Chân 9",  "Thanh B", "Trở 330Ω", "PIN_111", "PIN_126", "Thanh dọc trên bên phải"),
        ("Chân 1",  "Thanh C", "Trở 330Ω", "PIN_112", "PIN_127", "Thanh dọc dưới bên phải"),
        ("Chân 4",  "Thanh D", "Trở 330Ω", "PIN_113", "PIN_128", "Thanh ngang dưới đáy"),
        ("Chân 3",  "Thanh E", "Trở 330Ω", "PIN_115", "PIN_129", "Thanh dọc dưới bên trái (né PIN_114)"),
        ("Chân 6",  "Thanh F", "Trở 330Ω", "PIN_119", "PIN_132", "Thanh dọc trên bên trái"),
        ("Chân 5",  "Thanh G", "Trở 330Ω", "PIN_120", "PIN_133", "Thanh ngang ở chính giữa"),
        ("Chân 2",  "Dấu DP",  "Không cắm", "Để trống", "Để trống", "Dấu chấm lẻ (không dùng)"),
        ("Chân 8",  "DIG1 (Chục)",   "ULN2003 Out (2C/4C)", "Qua ULN2003", "Qua ULN2003", "Cực Âm chung Số bên Trái (Hàng chục)"),
        ("Chân 7",  "DIG2 (Đơn vị)", "ULN2003 Out (1C/3C)", "Qua ULN2003", "Qua ULN2003", "Cực Âm chung Số bên Phải (Đơn vị)")
    ]
    
    for idx, (p_num, s_name, c_comp, f_a, f_b, n_seg) in enumerate(pin_direct_data):
        bg = "F0F9FF" if idx % 2 == 1 else "FFFFFF"
        row = tbl_pin_direct.add_row()
        for c_idx, text in enumerate([p_num, s_name, c_comp, f_a, f_b, n_seg]):
            cell = row.cells[c_idx]
            cell.width = col_w_pd[c_idx]
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            p = cell.paragraphs[0]
            p.paragraph_format.space_before = Pt(2)
            p.paragraph_format.space_after = Pt(2)
            r = p.add_run(text)
            r.font.name = 'Segoe UI'
            r.font.size = Pt(8.8)
            if c_idx == 0:
                r.font.bold = True
                r.font.color.rgb = RGBColor(185, 28, 28)
            elif c_idx in (3, 4):
                r.font.bold = True
                r.font.color.rgb = COLOR_PRIMARY
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            elif c_idx == 1:
                r.font.bold = True
                r.font.color.rgb = COLOR_SECONDARY
            set_cell_background(cell, bg)
            set_cell_margins(cell, 60, 60, 80, 80)
            
    doc.add_paragraph()
    
    # --------------------------------------------------------------------------
    # MỤC 4: PHÂN BỔ TỔNG CỘNG 29 CHÂN I/O CỦA HỆ THỐNG
    # --------------------------------------------------------------------------
    h1 = doc.add_heading(level=1)
    h1.paragraph_format.space_before = Pt(14)
    h1.paragraph_format.space_after = Pt(4)
    r = h1.add_run("4. Bảng Tổng Hợp 29 Chân Tín Hiệu I/O Hệ Thống")
    r.font.name = 'Segoe UI'
    r.font.bold = True
    r.font.size = Pt(13)
    r.font.color.rgb = COLOR_PRIMARY
    
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(6)
    p.add_run(
        "Toàn bộ 29 tín hiệu của hệ thống vẫn được phân bổ đều đặn trên 2 hàng rào cắm (Rào Trên và Rào Dưới) "
        "theo nguyên tắc Zero-Crossing giúp layout mạch in PCB không bị đan chéo đường dây:"
    )
    
    tbl_io = doc.add_table(rows=1, cols=4)
    tbl_io.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl_io.autofit = False
    
    col_w_io = [Inches(1.8), Inches(1.0), Inches(2.0), Inches(2.2)]
    for idx, width in enumerate(col_w_io):
        tbl_io.rows[0].cells[idx].width = width
        
    hdr_io = tbl_io.rows[0].cells
    hdr_io[0].text = "Nhóm Chức Năng"
    hdr_io[1].text = "Số Chân"
    hdr_io[2].text = "Danh Sách Chân FPGA"
    hdr_io[3].text = "Vị Trí Hàng Rào Cắm"
    for c in hdr_io:
        c.paragraphs[0].runs[0].font.name = 'Segoe UI'
        c.paragraphs[0].runs[0].font.bold = True
        c.paragraphs[0].runs[0].font.size = Pt(9.0)
        c.paragraphs[0].runs[0].font.color.rgb = RGBColor(255, 255, 255)
        set_cell_background(c, "1B365D")
        set_cell_margins(c, 80, 80, 100, 100)
        
    io_data = [
        ("Đèn Giao Thông Làn A (Xanh, Vàng, Đỏ)", "3 chân", "PIN_38, PIN_39, PIN_42", "Rào Cắm Trên (Top Header)"),
        ("Đèn Giao Thông Làn B (Xanh, Vàng, Đỏ)", "3 chân", "PIN_43, PIN_44, PIN_46", "Rào Cắm Trên (Top Header)"),
        ("Nút Nhấn Điều Khiển (Reset, Khẩn cấp A, B)", "3 chân", "PIN_49, PIN_50, PIN_51", "Rào Cắm Trên (Top Header)"),
        ("Công Tắc Gạt (Ban đêm, Tạm dừng Pause)", "2 chân", "PIN_52, PIN_53", "Rào Cắm Trên (Top Header)"),
        ("LED 7 Đoạn Làn A (7 đoạn a..g + 2 digit)", "9 chân", "PIN_110..120 và PIN_121, 124", "Rào Cắm Dưới (Bottom Header)"),
        ("LED 7 Đoạn Làn B (7 đoạn a..g + 2 digit)", "9 chân", "PIN_125..133 và PIN_135, 136", "Rào Cắm Dưới (Bottom Header)"),
        ("Tổng Cộng Tín Hiệu I/O Ngoại Vi", "29 chân", "11 chân Rào Trên + 18 chân Rào Dưới", "Rào Trái để trống 100%")
    ]
    
    for idx, (grp, count, pins, pos) in enumerate(io_data):
        bg = "FEF3C7" if idx == 6 else ("F8FAFC" if idx % 2 == 1 else "FFFFFF")
        row = tbl_io.add_row()
        for c_idx, text in enumerate([grp, count, pins, pos]):
            cell = row.cells[c_idx]
            cell.width = col_w_io[c_idx]
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            p = cell.paragraphs[0]
            p.paragraph_format.space_before = Pt(2)
            p.paragraph_format.space_after = Pt(2)
            r = p.add_run(text)
            r.font.name = 'Segoe UI'
            r.font.size = Pt(8.8)
            if idx == 6:
                r.font.bold = True
                r.font.color.rgb = RGBColor(180, 83, 9)
            elif c_idx == 0:
                r.font.bold = True
                r.font.color.rgb = COLOR_PRIMARY
            elif c_idx == 1:
                p.alignment = WD_ALIGN_PARAGRAPH.CENTER
                r.font.bold = True
            set_cell_background(cell, bg)
            set_cell_margins(cell, 60, 60, 80, 80)
            
    doc.save(file_path)
    print(f"Generated BOM document: {file_path}")

if __name__ == "__main__":
    out_dir = r"c:\Users\handa\OneDrive\Documents\Projects\DoAn2\traffic_light_mini"
    target_path = os.path.join(out_dir, "Danh_Sach_Linh_Kien_Do_An_Traffic_Light.docx")
    build_bom_document(target_path)
