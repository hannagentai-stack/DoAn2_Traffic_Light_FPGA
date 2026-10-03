# BẢN ĐỀ CƯƠNG ĐĂNG KÝ ĐỀ TÀI ĐỒ ÁN 2 CHUYÊN NGÀNH

**Sinh viên thực hiện:** [Họ và tên sinh viên]  
**Mã số sinh viên:** [Mã số SV]  
**Lớp học phần:** [Tên lớp]  
**Giảng viên hướng dẫn:** Thầy/Cô [Họ và tên Giảng viên]  
**Khoa / Bộ môn:** [Tên Khoa / Bộ môn]  

---

## PHẦN 1: TỔNG QUAN ĐỀ TÀI, MỤC TIÊU & THUYẾT MINH TÍNH NĂNG

### 1.1. Tên đề tài
* **Tên tiếng Việt:** *"Thiết kế và kiểm chứng hệ thống điều khiển đèn giao thông ngã tư 2 làn đường trên FPGA Cyclone IV (Kit Altera EP4CE6E22C8N) bằng VHDL"*
* **Tên tiếng Anh:** *"Design and Verification of a 2-Way Traffic Light Controller on Altera Cyclone IV FPGA using VHDL"*

### 1.2. Lý do chọn đề tài & Tính cấp thiết
1. **Tính thực tiễn:** Điều khiển giao thông tại các nút giao thông đô thị đòi hỏi tính thời gian thực (Real-time), độ ổn định cao và tuyệt đối không được phép xảy ra xung đột pha (xung đột Xanh - Xanh có thể gây tai nạn giao thông nghiêm trọng).
2. **Ưu thế của công nghệ FPGA:** Khác với vi điều khiển truyền thống (vận hành tuần tự, dễ bị trễ do ngắt hoặc treo hệ thống), FPGA cho phép xử lý song song phần cứng thực sự, tốc độ phản hồi tức thời ở cấp độ nano-giây và độ tin cậy phần cứng vượt trội.
3. **Mục tiêu chuyên môn:** Giúp sinh viên nắm vững quy trình thiết kế vi mạch số (Digital ASIC/FPGA Design Flow) chuẩn công nghiệp: từ phân tích yêu cầu $\rightarrow$ thiết kế kiến trúc RTL $\rightarrow$ mô phỏng kiểm chứng chức năng (Functional Verification) $\rightarrow$ tổng hợp logic và nạp mạch thực tế.

### 1.3. Mục tiêu của đề tài
* **Về học thuật:** Làm chủ ngôn ngữ VHDL chuẩn IEEE (`numeric_std`), thiết kế logic đồng bộ 100% (Synchronous Logic), triệt tiêu hoàn toàn Latch ngoài ý muốn, làm chủ phần mềm Intel Quartus Prime và ModelSim-Intel FPGA.
* **Về sản phẩm:** Hoàn thiện mô hình sa bàn ngã tư 4 cột đèn giao thông, đếm lùi thời gian trên LED 7 đoạn, có khóa an toàn phần cứng và các chế độ điều khiển thông minh.

### 1.4. Thuyết minh tính năng kỹ thuật của hệ thống

#### A. Chu kỳ 4 pha tiêu chuẩn (Normal FSM Mode):
Hệ thống quản lý chu kỳ giao thông ngã tư 2 làn đường (Tuyến A và Tuyến B) với thời gian đếm lùi độc lập hiển thị trên 4 bộ LED 7 đoạn:
* **Pha 1 (25 giây):** Tuyến A XANH (25s) — Tuyến B ĐỎ (28s).
* **Pha 2 (3 giây):** Tuyến A VÀNG (3s) — Tuyến B ĐỎ (tiếp tục đếm 3s còn lại).
* **Pha 3 (30 giây):** Tuyến A ĐỎ (33s) — Tuyến B XANH (30s).
* **Pha 4 (3 giây):** Tuyến A ĐỎ (tiếp tục đếm 3s còn lại) — Tuyến B VÀNG (3s).

#### B. Các tính năng nâng cao & an toàn phần cứng:
1. **Khóa liên động an toàn phần cứng (Hardware Interlock Barrier):** Thiết kế tầng logic cổng phần cứng độc lập đảm bảo **tuyệt đối không bao giờ xuất tín hiệu Xanh cho cả 2 tuyến cùng một thời điểm**, triệt tiêu nguy cơ xung đột tại ngã tư.
2. **Chế độ ưu tiên xe khẩn cấp (Emergency Mode - Nút `KEY1`):** Khi có xe cứu thương/cứu hỏa/cảnh sát tiếp cận, nhấn nút sẽ lập tức ngắt chu kỳ thông thường (Preemption), cấp đèn Xanh ngay cho tuyến ưu tiên và khóa đèn Đỏ tuyến còn lại. Sau khi nhả nút, hệ thống nạp lại chu kỳ an toàn.
3. **Chế độ ban đêm tiết kiệm năng lượng (Night Mode - Công tắc `SW0`):** Nhấp nháy đèn Vàng ở tần số chuẩn 1 Hz cho cả 2 tuyến để cảnh báo giảm tốc độ, đồng thời tự động tắt (blank) toàn bộ màn hình LED 7 đoạn để tiết kiệm năng lượng.
4. **Chế độ tạm dừng kiểm tra (Hold/Pause Mode - Công tắc `SW1`):** Cho phép cảnh sát giao thông đóng băng thời gian và giữ nguyên trạng thái đèn hiện tại để điều tiết thủ công, khi nhả công tắc mạch tiếp tục đếm lùi bình thường không bị lỗi nhịp.

---

## PHẦN 2: DANH SÁCH LINH KIỆN & THIẾT BỊ SỬ DỤNG TRÊN MÔ HÌNH

Hệ thống được thiết kế theo giải pháp an toàn cao, sử dụng nguồn ATX chuyên dụng kết hợp module chuyển đổi `HU-M28` và IC đệm dòng `ULN2803` để bảo vệ tối đa cho chip FPGA:

| STT | Khối chức năng | Tên linh kiện / Thiết bị | Thông số / Mã hiệu | Số lượng | Vai trò trong hệ thống |
| :---: | :--- | :--- | :--- | :---: | :--- |
| 1 | **Khối nguồn** | Nguồn máy tính PC (ATX PSU) | EDRA EP350PRO ($\ge 250\text{W}$) | 01 cái | Nguồn tổng công suất ổn định, chống sụt áp |
| 2 | **Khối nguồn** | Module chuyển đổi nguồn ATX | **HU-M28** (có công tắc, cầu chì 5A, cổng USB, cọc ốc) | 01 bo | Kích nguồn an toàn, chia các đường 5V, 3.3V, GND có cầu chì bảo vệ |
| 3 | **Xử lý trung tâm**| Bo mạch FPGA Cyclone IV | **Altera EP4CE6E22C8N** (Thạch anh 50MHz tại `PIN_23`) | 01 bo | Nạp mã RTL VHDL, xử lý máy trạng thái FSM, bộ đếm và khóa logic |
| 4 | **Nạp mạch** | Mạch nạp USB-Blaster | Chuẩn Altera USB-Blaster JTAG | 01 bộ | Nạp file biên dịch `.sof` từ Quartus Prime xuống chip FPGA |
| 5 | **Đệm công suất** | IC đệm mảng Transistor | **ULN2803** (DIP-18, tích hợp 8 cặp Darlington $500\text{ mA}$) | 02 con | Cách ly điện áp, khuếch đại dòng kéo 4 cột đèn mà không gây quá tải chân FPGA |
| 6 | **Đèn tín hiệu** | LED đơn 5mm màu Đỏ / Vàng / Xanh | LED 5mm ($V_F \approx 1.9\text{V} - 3.0\text{V}$) | 12 bóng | Bố trí vào 4 cột đèn ngã tư (mỗi cột có 1 Đỏ, 1 Vàng, 1 Xanh) |
| 7 | **Đếm lùi thời gian**| Module LED 7 đoạn đôi | Loại 2-digit 0.56 inch Anode chung | 02 module | 01 cụm hiển thị Tuyến A (`HEX1, HEX0`) và 01 cụm hiển thị Tuyến B (`HEX3, HEX2`) |
| 8 | **Điều khiển vào** | Nút nhấn nhả (Push Button) | Nút 4 chân mini 6x6mm | 02 cái | Nút Reset cứng (`KEY0`) & Nút ưu tiên khẩn cấp (`KEY1`) |
| 9 | **Điều khiển vào** | Công tắc gạt mini 3 chân | Slide Switch SPDT | 02 cái | Switch Chế độ ban đêm (`SW0`) & Switch Tạm dừng (`SW1`) |
| 10 | **Linh kiện thụ động**| Điện trở $330\,\Omega$ & $10\text{k}\Omega$ | Trở than 1/4W | 25 con | $330\,\Omega$ hạn dòng bảo vệ LED; $10\text{k}\Omega$ làm trở kéo chống nhiễu nút bấm |
| 11 | **Đấu nối & Sa bàn**| Breadboard MB-102 & Dây cắm | Bo test 830 lỗ + Dây Đực-Cái, Đực-Đực | 01 bộ | Cắm mạch đệm, nút bấm và đấu nối dây tín hiệu từ FPGA ra sa bàn |
| 12 | **Sa bàn mô hình** | Tấm Formex 5mm + Que cột đèn | Tấm nền $40\text{cm} \times 40\text{cm}$ | 01 bộ | Dựng mặt đường ngã tư thực tế gắn 4 cột đèn |

---

## PHẦN 3: LỘ TRÌNH THỰC HIỆN TRONG 6 TUẦN & KẾT QUẢ TỪNG TUẦN

* **TUẦN 1: Nghiên cứu lý thuyết & Xác lập kiến trúc hệ thống**
  * *Nội dung công việc:* Nghiên cứu lý thuyết máy trạng thái FSM Moore; xác lập bảng chuyển trạng thái (State Transition Table); vẽ sơ đồ khối kiến trúc phần cứng; phân bổ chu kỳ thời gian 4 pha và ma trận ưu tiên.
  * *Kết quả cần đạt:* Hoàn thiện tài liệu đặc tả kỹ thuật gồm bảng chuyển 25 trạng thái và sơ đồ FSM dạng Mermaid.

* **TUẦN 2: Thiết kế mã nguồn RTL VHDL (5 Module chuẩn hóa)**
  * *Nội dung công việc:* Hiện thực hóa 5 module VHDL thuần chuẩn `ieee.std_logic_1164` và `ieee.numeric_std`:
    1. `clk_divider.vhd`: Chia tần số 50MHz xuống 1Hz và tạo xung nhấp nháy 1Hz (có generic `SIMULATION`).
    2. `fsm_controller.vhd`: FSM Moore điều khiển chuyển pha, tích hợp thứ bậc ưu tiên.
    3. `timer_counter.vhd`: Đếm lùi song song 2 tuyến, tự động nạp lại thời gian và tách mã BCD $0..63$.
    4. `seg7_decoder.vhd`: Giải mã BCD sang LED 7 đoạn Active-Low kèm chức năng tắt màn hình ban đêm.
    5. `traffic_light_top.vhd`: Ghép nối các module và tích hợp khóa an toàn phần cứng (Interlock Safety).
  * *Kết quả cần đạt:* Bộ mã nguồn RTL VHDL hoàn chỉnh, biên dịch cú pháp thành công 100%, không có lỗi chốt ngoài ý muốn (Zero Inferred Latches).

* **TUẦN 3: Xây dựng Testbench & Kiểm chứng chức năng trên ModelSim**
  * *Nội dung công việc:* Viết testbench tự động `tb_traffic_light_top.vhd` kiểm thử 4 kịch bản vận hành (2 chu kỳ bình thường, chế độ ban đêm, tạm dừng, ưu tiên khẩn cấp); cài đặt kịch bản `run_sim.do` và định dạng sóng `wave.do`; kiểm tra xác thực khóa liên động bằng lệnh `assert`.
  * *Kết quả cần đạt:* Dạng sóng mô phỏng ModelSim đạt 100% không lỗi (0 Errors, 0 Warnings), chứng minh được ngã tư không bao giờ xảy ra trạng thái 2 tuyến cùng Xanh.

* **TUẦN 4: Chuẩn bị linh kiện & Thi công mô hình sa bàn phần cứng**
  * *Nội dung công việc:* Chuẩn bị đầy đủ linh kiện theo bảng BOM; dựng sa bàn ngã tư bằng tấm Formex; lắp ráp 4 cột đèn giao thông (12 bóng LED); đấu nối dây nguồn máy tính qua module `HU-M28`; cắm mạch đệm `ULN2803` và các nút nhấn, công tắc trên Breadboard.
  * *Kết quả cần đạt:* Sa bàn mô hình ngã tư 4 cột đèn hoàn thiện về mặt cơ khí và điện tử, sẵn sàng kết nối với bo FPGA.

* **TUẦN 5: Tổng hợp trên Quartus Prime & Nạp chạy thực tế trên Kit FPGA**
  * *Nội dung công việc:* Tạo project Quartus Prime cho chip `EP4CE6E22C8N`; gán chân I/O thực tế vào file `.qsf` và ràng buộc xung nhịp `.sdc`; biên dịch tổng hợp toàn bộ hệ thống; phân tích thời gian tĩnh (Timing Closure đạt $f_{\max} > 160\text{ MHz}$); kết nối cáp USB-Blaster nạp file `.sof` vào chip thật.
  * *Kết quả cần đạt:* Hệ thống nạp thành công xuống chip FPGA thật; điều khiển sa bàn 4 cột đèn và 4 bộ LED 7 đoạn hoạt động chính xác theo đúng kịch bản thiết kế.

* **TUẦN 6: Đánh giá tối ưu, Viết báo cáo tổng kết & Chuẩn bị bảo vệ**
  * *Nội dung công việc:* Đo đạc dòng điện tiêu thụ thực tế của hệ thống; quay video minh chứng hoạt động của toàn bộ các chế độ; hoàn thiện quyển báo cáo thuyết minh Đồ án 2 theo mẫu của Khoa; chuẩn bị slide thuyết trình bảo vệ trước hội đồng.
  * *Kết quả cần đạt:* Quyển báo cáo đồ án hoàn chỉnh, slide thuyết trình và mô hình phần cứng hoạt động ổn định 100%.
