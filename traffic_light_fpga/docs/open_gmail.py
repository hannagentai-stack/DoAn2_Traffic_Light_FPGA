import webbrowser
import urllib.parse
import os

subject = "[ĐỒ ÁN 2] Đăng ký đề tài & Kế hoạch thực hiện: Hệ thống điều khiển đèn giao thông ngã tư trên FPGA - SV: [Họ và tên] - MSSV: [MSSV]"

body = """Kính gửi: Thầy/Cô [Họ và tên Giảng viên hướng dẫn],
Bộ môn: [Tên Bộ môn / Khoa]

Em tên là: [Họ và tên của bạn]
Mã số sinh viên: [Mã số SV] - Lớp: [Tên lớp]

Em xin phép gửi Thầy/Cô bản đề cương đăng ký đề tài Đồ án 2 Chuyên ngành cùng kế hoạch triển khai chi tiết:

1. TỔNG QUAN, MỤC TIÊU & TÍNH NĂNG ĐỀ TÀI:
- Tên đề tài: "Thiết kế và kiểm chứng hệ thống điều khiển đèn giao thông ngã tư 2 làn đường trên FPGA Cyclone IV (Kit EP4CE6E22C8N) bằng VHDL".
- Mục tiêu: Nắm vững quy trình thiết kế vi mạch RTL VHDL chuẩn IEEE (numeric_std), logic đồng bộ 100%, triệt tiêu Latch; mô phỏng ModelSim và hiện thực trên kit FPGA.
- Tính năng kỹ thuật:
  + Chu kỳ 4 pha chuẩn: Pha 1 (Xanh A 25s / Đỏ B 28s), Pha 2 (Vàng A 3s / Đỏ B 3s), Pha 3 (Đỏ A 33s / Xanh B 30s), Pha 4 (Đỏ A 3s / Vàng B 3s). Đếm lùi trên 4 LED 7 đoạn.
  + Khóa liên động an toàn phần cứng (Interlock Barrier): Triệt tiêu tuyệt đối xung đột Xanh - Xanh.
  + Chế độ ưu tiên khẩn cấp (KEY1): Cấp quyền ưu tiên mở Xanh ngay cho xe cứu thương/cảnh sát.
  + Chế độ ban đêm (SW0): Nhấp nháy đèn Vàng 1 Hz, tự động tắt (blank) toàn bộ LED 7 đoạn.
  + Chế độ tạm dừng (SW1): Đóng băng bộ đếm và trạng thái đèn để điều tiết thủ công.

2. DANH SÁCH LINH KIỆN SỬ DỤNG:
- Khối nguồn: Nguồn máy tính ATX + Module chuyển đổi nguồn HU-M28 (có công tắc, cầu chì 5A, cổng USB, cọc ốc vít).
- Khối xử lý: Bo FPGA Cyclone IV EP4CE6E22C8N (50MHz) + Mạch nạp USB-Blaster.
- Khối đệm công suất: 02 IC đệm transistor ULN2803 (DIP-18, 500mA) cách ly an toàn chân FPGA.
- Đèn tín hiệu & hiển thị: 12 LED 5mm (4 Đỏ, 4 Vàng, 4 Xanh cho 4 cột đèn) + 02 Module LED 7 đoạn đôi.
- Điều khiển & phụ kiện: 02 Nút nhấn (KEY0 Reset, KEY1 Emergency), 02 Switch gạt (SW0 Night, SW1 Pause), trở 330R, trở 10k, Breadboard MB-102 và sa bàn Formex 5mm.

3. LỘ TRÌNH THỰC HIỆN TRONG 6 TUẦN:
- Tuần 1: Nghiên cứu lý thuyết, hoàn thiện đặc tả FSM Moore và bảng chuyển 25 trạng thái.
- Tuần 2: Viết mã nguồn RTL VHDL 5 module (clk_divider, fsm_controller, timer_counter, seg7_decoder, traffic_light_top). Đạt 0 Inferred Latches.
- Tuần 3: Xây dựng Testbench và mô phỏng trên ModelSim (chạy 4 kịch bản, assert khóa an toàn). Đạt 0 errors.
- Tuần 4: Thi công sa bàn ngã tư 4 cột đèn, đấu nối nguồn ATX qua HU-M28 và mạch đệm ULN2803.
- Tuần 5: Tổng hợp Quartus Prime, gán chân QSF, phân tích Timing Closure (fmax > 160MHz), nạp chip FPGA chạy thử nghiệm sa bàn thực tế.
- Tuần 6: Đo kiểm dòng tiêu thụ, quay video demo, hoàn thiện quyển báo cáo và slide bảo vệ.

Kính mong nhận được ý kiến đóng góp từ Thầy/Cô. Em xin chân thành cảm ơn!

Kính thư,
[Họ và tên của bạn]
Số điện thoại: [Số điện thoại]
Email: [Địa chỉ email]"""

enc_su = urllib.parse.quote(subject)
enc_body = urllib.parse.quote(body)
gmail_url = f"https://mail.google.com/mail/?view=cm&fs=1&su={enc_su}&body={enc_body}"

print("Opening Gmail compose window...")
webbrowser.open(gmail_url)
print("Done!")
