"""
--------------------------------------------------------------------------------
DỰ ÁN: THIẾT KẾ HỆ THỐNG ĐIỀU KHIỂN ĐÈN GIAO THÔNG NGÃ TƯ TRÊN FPGA CYCLONE IV
PHIÊN BẢN: ANODE CHUNG (COMMON ANODE - 5621AH / 3621AH)
SCRIPT: generate_bom_doc.py
MỤC ĐÍCH:
  Xuất báo cáo Danh sách Linh kiện & Dự toán Mua sắm (BOM - Bill of Materials)
  định dạng Microsoft Word (.docx) chuyên nghiệp, 100% Tiếng Việt có dấu chuẩn xác
  cho phiên bản LED 7 đoạn Anode chung.
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
    r_sub = p_sub.add_run("Phiên bản: ANODE CHUNG (Common Anode - 5621AH) - Kit FPGA Cyclone IV EP4CE6E22C8N")
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
    r = h1.add_run("1. Bảng Thống Kê Chi Tiết Linh Kiện Cần Mua (Phiên Bản Anode Chung)")
    r.font.name = 'Segoe UI'
    r.font.bold = True
    r.font.size = Pt(13)
    r.font.color.rgb = COLOR_PRIMARY
    
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(6)
    p.add_run(
        "Hệ thống sử dụng LED 7 đoạn đôi ANODE CHUNG (Cực Dương chung - mã đuôi AH). "
        "Bảng dưới đây thống kê toàn bộ linh kiện cần thiết cho cả 2 phương án: cắm test nhanh trực tiếp trên Breadboard "
        "hoặc làm mạch in PCB hoàn chỉnh:"
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
        ("1", "LED 7 đoạn 2 số 0.56\" Anode chung", "5621AH / 3621AH / 5622AH (10 chân)", "2 con", "3 con", "Đồng hồ đếm lùi 2 chữ số (1 con Làn A, 1 con Làn B). Mã có chữ cái A là Anode chung", "8.000 đ"),
        ("2", "LED đơn 5mm Màu ĐỎ (Red)", "Siêu sáng / Đục 5mm", "2 con", "5 con", "Đèn ĐỎ Làn A (PIN_46) và Làn B (PIN_54)", "500 đ"),
        ("3", "LED đơn 5mm Màu VÀNG (Yellow)", "Siêu sáng / Đục 5mm", "2 con", "5 con", "Đèn VÀNG Làn A (PIN_43) và Làn B (PIN_52)", "500 đ"),
        ("4", "LED đơn 5mm Màu XANH LÁ (Green)", "Siêu sáng / Đục 5mm", "2 con", "5 con", "Đèn XANH Làn A (PIN_39) và Làn B (PIN_50)", "500 đ"),
        
        # Nhóm bán dẫn & đệm công suất
        ("5", "IC Đệm dòng 8 kênh Darlington", "ULN2803A / ULN2803G (DIP-18)", "2 con", "3 con", "Đệm kéo 14 thanh đoạn a..g xuống GND (1 con Làn A, 1 con Làn B), bảo vệ tuyệt đối cổng I/O FPGA", "4.000 đ"),
        ("6", "Đế cắm IC 18 chân", "DIP-18 IC Socket", "2 cái", "4 cái", "Hàn lên PCB hoặc cắm lên Breadboard để cắm rút IC ULN2803A", "500 đ"),
        
        # Nhóm điện trở
        ("7", "Điện trở 330 Ω (hoặc 220 Ω)", "1/4W (Trở cắm 5 vạch màu)", "20 con", "1 gói (50 con)", "Hạn dòng bảo vệ cho 6 đèn LED giao thông và 14 thanh LED 7 đoạn a..g", "3.000 đ/gói"),
        ("8", "Điện trở 10k Ω (Kéo lên dự phòng)", "1/4W", "5 con", "10 con", "Trở kéo lên dự phòng ngoài cho nút nhấn / công tắc (FPGA đã bật Weak Pull-up nội)", "1.000 đ"),
        
        # Nhóm điều khiển
        ("9", "Nút nhấn nhả 4 chân (Tactile switch)", "6x6x5mm", "3 nút", "5 nút", "Nút Reset (PIN_58), Khẩn cấp Làn A (PIN_60), Khẩn cấp Làn B (PIN_65)", "500 đ"),
        ("10", "Công tắc cần gạt 3 vị trí ON-OFF-ON", "MTS-103 (3 chân) hoặc MTS-203 (6 chân)", "1 cái", "2 cái", "Tích hợp 3 chế độ: Gạt trái = Ban đêm (PIN_67), Giữa = Tự động bình thường, Gạt phải = Tạm dừng (PIN_69)", "4.000 đ"),
        
        # Nhóm phụ kiện test
        ("11", "Breadboard MB-102 (Bo cắm test)", "830 lỗ (165 x 55 mm)", "1 bo", "1 - 2 bo", "Cắm linh kiện chạy thử nghiệm trước khi hàn mạch in PCB", "25.000 đ"),
        ("12", "Dây cắm Breadboard Đực - Cái", "Male to Female 20cm", "1 tép", "1 tép (40 sợi)", "Nối từ hàng cọc kim của bo FPGA sang Breadboard", "15.000 đ"),
        ("13", "Dây cắm Breadboard Đực - Đực", "Male to Male 10cm / 20cm", "1 tép", "1 tép (40 sợi)", "Cầu dây nối các linh kiện trên mặt Breadboard", "15.000 đ"),
        ("14", "Rào Cái 2.54mm 2 hàng (Nữ)", "Female Header 2x20 pin", "2 thanh", "4 thanh", "Hàn lên bo mạch PCB để cắm bo mạch FPGA Cyclone IV lên", "3.000 đ")
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
    
    # Callout
    add_callout(
        doc,
        "HƯỚNG DẪN ĐẤU NỐI VỚI IC ĐỆM ULN2803A VÀ LED ANODE CHUNG: "
        "Khi cắm mạch với LED 7 đoạn Anode chung, chân FPGA phát mức 1 (+3.3V) cấp nguồn cho DIG1/DIG2 (Anode) "
        "và phát mức 1 (Active-High) kích ngõ vào IC đệm dòng ULN2803A. Khi nhận mức 1, IC đệm ULN2803A kéo ngõ ra tương ứng "
        "xuống Mass (GND) để làm sáng thanh đoạn LED qua điện trở hạn dòng 330Ω, giúp bảo vệ an toàn 100% cho chip FPGA!",
        title="NGUYÊN LÝ ĐIỀU KHIỂN & ĐỆM DÒNG ULN2803A:",
        border_color="0E7490",
        bg_color="F0F9FF"
    )
    
    doc.add_paragraph()
    
    # --------------------------------------------------------------------------
    # MỤC 2: SƠ ĐỒ KẾT NỐI CHÂN CON LED 7 ĐOẠN 10 CHÂN ANODE CHUNG (5621AH)
    # --------------------------------------------------------------------------
    h1 = doc.add_heading(level=1)
    h1.paragraph_format.space_before = Pt(14)
    h1.paragraph_format.space_after = Pt(4)
    r = h1.add_run("2. Sơ Đồ Chân Thực Tế LED 7 Đoạn Đôi 10 Chân Anode Chung (5621AH / 3621AH)")
    r.font.name = 'Segoe UI'
    r.font.bold = True
    r.font.size = Pt(13)
    r.font.color.rgb = COLOR_PRIMARY
    
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(6)
    p.add_run(
        "Sơ đồ 10 chân chuẩn Type-B đã được kiểm chứng hoạt động chính xác 100% trên phần cứng thực tế:\n"
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
        ("Chân 10", "Thanh A", "Trở 330Ω qua ULN (1B/1C)", "PIN_129", "PIN_111", "Thanh ngang trên đỉnh (Mức 1 FPGA kích sáng)"),
        ("Chân 9",  "Thanh B", "Trở 330Ω qua ULN (2B/2C)", "PIN_133", "PIN_113", "Thanh dọc trên bên phải (Mức 1 FPGA kích sáng)"),
        ("Chân 1",  "Thanh C", "Trở 330Ω qua ULN (3B/3C)", "PIN_136", "PIN_119", "Thanh dọc dưới bên phải (Mức 1 FPGA kích sáng)"),
        ("Chân 4",  "Thanh D", "Trở 330Ω qua ULN (4B/4C)", "PIN_138", "PIN_121", "Thanh ngang dưới đáy (Mức 1 FPGA kích sáng)"),
        ("Chân 3",  "Thanh E", "Trở 330Ω qua ULN (5B/5C)", "PIN_142", "PIN_125", "Thanh dọc dưới bên trái (Mức 1 FPGA kích sáng)"),
        ("Chân 6",  "Thanh F", "Trở 330Ω qua ULN (6B/6C)", "PIN_144", "PIN_127", "Thanh dọc trên bên trái (Mức 1 FPGA kích sáng)"),
        ("Chân 5",  "Thanh G", "Trở 330Ω qua ULN (7B/7C)", "PIN_143", "PIN_110", "Thanh ngang ở chính giữa (Mức 1 FPGA kích sáng)"),
        ("Chân 2",  "Dấu DP",  "Không cắm", "Để trống", "Để trống", "Dấu chấm lẻ (không dùng)"),
        ("Chân 8",  "DIG1 (Chục)",   "Nối thẳng FPGA", "PIN_141", "PIN_115", "Cực Dương chung Hàng chục (Mức 1 cấp 3.3V)"),
        ("Chân 7",  "DIG2 (Đơn vị)", "Nối thẳng FPGA", "PIN_137", "PIN_112", "Cực Dương chung Hàng đơn vị (Mức 1 cấp 3.3V)")
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
    # MỤC 3: PHÂN BỔ TỔNG CỘNG 30 CHÂN FPGA CỦA HỆ THỐNG
    # --------------------------------------------------------------------------
    h1 = doc.add_heading(level=1)
    h1.paragraph_format.space_before = Pt(14)
    h1.paragraph_format.space_after = Pt(4)
    r = h1.add_run("3. Bảng Tổng Hợp 30 Chân Tín Hiệu FPGA Hệ Thống (Zero-Crossing)")
    r.font.name = 'Segoe UI'
    r.font.bold = True
    r.font.size = Pt(13)
    r.font.color.rgb = COLOR_PRIMARY
    
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(6)
    p.add_run(
        "Hệ thống sử dụng tổng cộng 30 chân FPGA bao gồm 1 chân xung nhịp Clock 50MHz và 29 chân I/O ngoại vi "
        "được phân bổ đều đặn trên các hàng rào cắm theo nguyên tắc Zero-Crossing giúp layout mạch in PCB không bị đan chéo:"
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
        ("Xung Nhịp Master Clock 50MHz", "1 chân", "PIN_24 (CLK0 / GCLK0)", "Chân Clock Toàn Cục Onboard"),
        ("Đèn Giao Thông Làn A (Xanh, Vàng, Đỏ)", "3 chân", "PIN_39, PIN_43, PIN_46", "Rào Cắm Trên (Top Header)"),
        ("Đèn Giao Thông Làn B (Xanh, Vàng, Đỏ)", "3 chân", "PIN_50, PIN_52, PIN_54", "Rào Cắm Trên (Top Header)"),
        ("Nút Nhấn Điều Khiển (Reset, Khẩn cấp A, B)", "3 chân", "PIN_58, PIN_60, PIN_65", "Rào Cắm Trên (Top Header)"),
        ("Công Tắc Gạt (Ban đêm, Tạm dừng Pause)", "2 chân", "PIN_67, PIN_69", "Rào Cắm Trên (Top Header)"),
        ("LED 7 Đoạn Làn A (7 đoạn a..g + 2 digit)", "9 chân", "PIN_129..144 (a..g) và PIN_137, 141", "Rào Cắm Dưới (Bottom Header)"),
        ("LED 7 Đoạn Làn B (7 đoạn a..g + 2 digit)", "9 chân", "PIN_110..127 (a..g) và PIN_112, 115", "Rào Cắm Dưới (Bottom Header)"),
        ("Tổng Cộng Chân FPGA Sử Dụng", "30 chân", "1 Clock onboard + 11 chân Rào Trên + 18 chân Rào Dưới", "Rào Trái để trống 100%")
    ]
    
    for idx, (grp, count, pins, pos) in enumerate(io_data):
        bg = "FEF3C7" if idx == 7 else ("F8FAFC" if idx % 2 == 1 else "FFFFFF")
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
            if idx == 7:
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
    print(f"Generated BOM document (Anode chung): {file_path}")

if __name__ == "__main__":
    out_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "docs"))
    os.makedirs(out_dir, exist_ok=True)
    target_path = os.path.join(out_dir, "Danh_Sach_Linh_Kien_Do_An_Traffic_Light_Anode_Chung.docx")
    build_bom_document(target_path)
