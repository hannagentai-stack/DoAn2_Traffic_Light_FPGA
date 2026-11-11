# Hệ Thống Điều Khiển Đèn Giao Thông Ngã Tư Trên FPGA Cyclone IV

Dự án thiết kế và hiện thực hệ thống điều khiển đèn giao thông ngã tư 2 làn đường độc lập, tích hợp đồng hồ đếm lùi hiển thị trên LED 7 đoạn đôi sử dụng IC đệm dòng Darlington **ULN2803A / ULN2803G** và chip **FPGA Altera / Intel Cyclone IV E EP4CE6E22C8N**.

---

## 🌟 1. Tính Năng Kỹ Thuật Nổi Bật

1. **Chu trình FSM Moore 4 pha chuẩn giao thông:**
   - **Pha 1:** Làn A Xanh (25s) | Làn B Đỏ (28s)
   - **Pha 2:** Làn A Vàng (3s)  | Làn B Đỏ (3s)
   - **Pha 3:** Làn A Đỏ (33s)   | Làn B Xanh (30s)
   - **Pha 4:** Làn A Đỏ (3s)    | Làn B Vàng (3s)
2. **Khóa liên động an toàn phần cứng (Fail-Safe Hardware Interlock):**
   - Giám sát tín hiệu FSM thời gian thực. Nếu phát hiện sự cố nguy hiểm (Cả 2 làn cùng bật đèn Xanh hoặc Xanh-Vàng xung đột), mạch phần cứng lập tức cưỡng chế ngắt toàn bộ đèn xanh và ép sáng 2 đèn đỏ để chống đâm va.
3. **Chế độ ưu tiên Xe khẩn cấp đối xứng (Emergency Mode):**
   - Nút `KEY1`: Ưu tiên xe cứu thương/cứu hỏa Làn A (ép Làn A Xanh, Làn B Đỏ).
   - Nút `KEY2`: Ưu tiên xe cứu thương/cứu hỏa Làn B (ép Làn B Xanh, Làn A Đỏ).
   - Hệ thống hỗ trợ ưu tiên xe khẩn cấp độc lập cho cả 2 làn (hoạt động ngay cả trong Chế độ Ban đêm hoặc các pha đèn khác nhau).
4. **Công tắc cần gạt 3 vị trí (MTS-103 ON - OFF - ON):**
   - **Nấc Giữa (OFF):** Hệ thống tự động chuyển pha bình thường.
   - **Nấc Gạt Trái (ON 1):** Kích hoạt **Chế độ Ban Đêm** (Tắt LED 7 đoạn, đèn Vàng chớp tắt 1Hz cảnh báo giao thông).
   - **Nấc Gạt Phải (ON 2):** Kích hoạt **Chế độ Tạm Dừng (Pause)** (Đóng băng bộ đếm và trạng thái đèn).
5. **Đồng hồ đếm lùi 2 chữ số quét đa kênh:**
   - Tần số quét 1 kHz chống giật lag, chia sẻ bus 7 đoạn giúp tiết kiệm chân I/O.
   - Đệm dòng xả qua mảng Darlington **ULN2803A / ULN2803G (DIP-18)** bảo vệ cổng I/O FPGA an toàn 100%.

---

## 📌 2. Sơ Đồ Gán Chân GPIO (30 Chân FPGA Tổng Cộng)

Hệ thống sử dụng **30 chân FPGA** bao gồm: **1 chân Clock 50MHz** (PIN_24) và **29 chân I/O ngoại vi** (6 đèn LED giao thông, 3 nút bấm, 2 công tắc gạt, 18 chân cho 2 cụm LED 7 đoạn đôi). Thiết kế tối ưu theo nguyên tắc **Zero-Crossing PCB Routing**: Toàn bộ các chân điều khiển và đèn đều nằm ở **Hàng chân ngoài** của rào cắm trên, giúp đường mạch bắn thẳng tắp ra biên PCB mà không cần dùng via xuyên lớp.

### A. Cụm Đèn Giao Thông & Điều Khiển
| Tín hiệu | Hướng | Chân FPGA | Chức năng trên bo mạch |
| :--- | :---: | :---: | :--- |
| LEDG[0] | OUT | **PIN_39** | Đèn XANH Làn A |
| LEDR[0] | OUT | **PIN_43** | Đèn VÀNG Làn A |
| LEDR[1] | OUT | **PIN_46** | Đèn ĐỎ Làn A |
| LEDG[1] | OUT | **PIN_50** | Đèn XANH Làn B |
| LEDR[2] | OUT | **PIN_52** | Đèn VÀNG Làn B |
| LEDR[3] | OUT | **PIN_54** | Đèn ĐỎ Làn B |
| KEY[0] | IN | **PIN_58** | Nút nhấn Reset toàn hệ thống (KEY0) |
| KEY[1] | IN | **PIN_60** | Nút nhấn Khẩn cấp Làn A (KEY1) |
| KEY[2] | IN | **PIN_65** | Nút nhấn Khẩn cấp Làn B (KEY2) |
| SW[0] | IN | **PIN_67** | Chân 1 công tắc 3 nấc (Chế độ Ban đêm SW0) |
| SW[1] | IN | **PIN_69** | Chân 3 công tắc 3 nấc (Chế độ Tạm dừng Pause SW1) |
| CLOCK_50| IN | **PIN_24** | Xung nhịp Master Clock 50 MHz tích hợp trên kit |

### B. Cụm LED 7 Đoạn Đôi Anode Chung
| Thanh / Chân LED | Chân Socket LED | Nối qua ULN2803A | Chân FPGA Làn A | Chân FPGA Làn B |
| :---: | :---: | :---: | :---: | :---: |
| **Thanh A** | Chân 1 | IN1 $\rightarrow$ OUT1 | **PIN_129** | **PIN_111** |
| **Thanh B** | Chân 2 | IN2 $\rightarrow$ OUT2 | **PIN_133** | **PIN_113** |
| **Thanh C** | Chân 3 | IN3 $\rightarrow$ OUT3 | **PIN_136** | **PIN_119** |
| **Thanh D** | Chân 4 | IN4 $\rightarrow$ OUT4 | **PIN_138** | **PIN_121** |
| **Thanh E** | Chân 5 | IN5 $\rightarrow$ OUT5 | **PIN_142** | **PIN_125** |
| **Thanh F** | Chân 6 | IN6 $\rightarrow$ OUT6 | **PIN_144** | **PIN_127** |
| **Thanh G** | Chân 7 | IN7 $\rightarrow$ OUT7 | **PIN_143** | **PIN_110** |
| **DIG1 (Chục)** | Chân 8 | Cắm thẳng FPGA (Anode 3.3V) | **PIN_141** | **PIN_115** |
| **DIG2 (Đơn vị)** | Chân 9 | Cắm thẳng FPGA (Anode 3.3V) | **PIN_137** | **PIN_112** |

---

## 📂 3. Cấu Trúc Thư Mục Dự Án Chuẩn Công Nghiệp & Học Thuật

Cấu trúc thư mục được quy hoạch khoa học, rõ ràng theo tiêu chuẩn dự án FPGA công nghiệp:

```
DoAn2_Traffic_Light_FPGA/
├── rtl/                                    # Toàn bộ mã nguồn thiết kế phần cứng VHDL
│   ├── clk_divider.vhd                     # Module chia tần số (50MHz -> 1Hz, 1kHz, nhấp nháy 1Hz)
│   ├── fsm_controller.vhd                  # Module máy trạng thái FSM Moore 4 pha giao thông
│   ├── timer_counter.vhd                   # Module bộ đếm lùi thời gian & giải mã BCD hàng chục/đơn vị
│   ├── seg7_decoder.vhd                    # Module giải mã 7 đoạn quét động cho IC đệm ULN2803A / ULN2803G
│   └── traffic_light_top.vhd               # Top-level tích hợp toàn bộ hệ thống & mạch Fail-Safe Interlock
├── sim/                                    # Môi trường mô phỏng ModelSim / QuestaSim
│   ├── modelsim.ini                        # Cấu hình ánh xạ thư viện ModelSim
│   ├── run_modelsim.bat                    # Script khởi chạy môi trường ModelSim
│   ├── Chay_Mo_Phong_ModelSim.bat          # File kích hoạt 1-click tự động chạy mô phỏng
│   ├── run_sim.do                          # Macro tự động biên dịch, nạp wave và chạy kiểm thử
│   ├── wave.do                             # Lưu định dạng hiển thị dạng sóng tín hiệu
│   └── tb_traffic_light_top.vhd            # Testbench kiểm thử toàn diện 7 kịch bản tự động
├── bitstream/                              # Tệp nạp cấu hình FPGA & chip nhớ Flash (EPCS)
│   ├── traffic_light_top.sof               # File nạp trực tiếp qua JTAG (SRAM volatile)
│   ├── traffic_light_top.jic               # File nạp bộ nhớ Flash chuẩn EPCS4 (Silicon ID 0x12)
│   └── traffic_light_top_epcs16.jic         # File nạp bộ nhớ Flash dung lượng cao EPCS16 (Silicon ID 0x14)
├── docs/                                   # Báo cáo kỹ thuật, sơ đồ chân và tài liệu dự án
│   ├── Bao_Cao_Giai_Thich_Code_Va_Nguyen_Ly_Module.docx # Báo cáo kỹ thuật chi tiết từng module
│   ├── Danh_Sach_Chan_IO_FPGA_Cyclone_IV_Anode_Chung.docx # Bảng tra cứu 30 chân FPGA (1 Clock + 29 I/O) & vẽ Altium
│   ├── Danh_Sach_Linh_Kien_Do_An_Traffic_Light_Anode_Chung.docx # Bảng tổng hợp linh kiện và BOM
│   ├── HUONG_DAN_CHAY_DU_AN_ANODE_CHUNG.txt# Sổ tay hướng dẫn nhanh đấu nối phần cứng & nạp code
│   └── DoAn2_Traffic_Light_Anode_Chung.zip # Gói lưu trữ nén toàn bộ dự án
├── scripts/                                # Công cụ script tự động sinh tài liệu
│   ├── generate_bom_doc.py                 # Script tự động xuất BOM sang định dạng Word (.docx)
│   └── generate_pinout_doc.py              # Script tự động xuất bảng chân I/O sang Word (.docx)
├── traffic_light_top.qpf                   # Quartus Prime Project File
├── traffic_light_top.qsf                   # Quartus Settings File (30 Pin assignments & 3.3V LVTTL)
├── traffic_light_top.sdc                   # Ràng buộc thời gian Timing Constraint 50MHz
├── .gitignore                              # Cấu hình bỏ qua các file tạm thời, biên dịch, simulation
└── README.md                               # Hướng dẫn chi tiết & tài liệu tổng quan dự án
```

---

## 🚀 4. Hướng Dẫn Nạp Code Vào Bo FPGA Cyclone IV

1. Kết nối cáp **USB-Blaster** từ máy tính đến cổng nạp **JTAG** của bo mạch Cyclone IV.
2. Mở phần mềm **Quartus Prime** $\rightarrow$ chọn menu **Tools** $\rightarrow$ **Programmer**.
3. Chọn **Hardware Setup...** $\rightarrow$ chọn **USB-Blaster**.
4. **Nạp chạy ngay (RAM):**
   * Nhấn **Add File...** $\rightarrow$ mở thư mục `bitstream/` $\rightarrow$ chọn `traffic_light_top.sof`.
   * Tích chọn ô **Program/Configure** $\rightarrow$ nhấn **Start** (Mạch nạp chạy ngay sau 2 giây).
5. **Nạp vĩnh viễn (Flash EPCS4 / EPCS16):**
   * Nhấn **Add File...** $\rightarrow$ mở thư mục `bitstream/` $\rightarrow$ chọn `traffic_light_top.jic`.
   * Tích chọn ô **Program/Configure** ở dòng `EPCS4` (hoặc `EPCS16` tùy bo kit) $\rightarrow$ nhấn **Start** (Lưu vĩnh viễn vào ROM, không mất khi ngắt nguồn điện).

---

## 🧪 5. Hướng Dẫn Chạy Mô Phỏng ModelSim

1. Truy cập vào thư mục `sim/`.
2. Nhấp đúp chuột vào file `Chay_Mo_Phong_ModelSim.bat` (hoặc mở ModelSim và gõ lệnh `do run_sim.do`).
3. Hệ thống sẽ tự động biên dịch toàn bộ các file VHDL trong `rtl/` và testbench `sim/tb_traffic_light_top.vhd`, nạp dạng sóng đầy đủ màu sắc từ `wave.do`, và chạy qua 7 kịch bản kiểm thử:
   - **Kịch bản 1:** Khởi động và Reset hệ thống.
   - **Kịch bản 2:** Chu trình bình thường Vòng 1 (Đầy đủ 4 pha).
   - **Kịch bản 3:** Kiểm tra độ ổn định chu trình Vòng 2.
   - **Kịch bản 4:** Kích hoạt Chế độ Ban Đêm (Đèn vàng chớp 1Hz).
   - **Kịch bản 5:** Kích hoạt Chế độ Tạm Dừng (Pause đóng băng bộ đếm).
   - **Kịch bản 6:** Ưu tiên xe khẩn cấp Làn A (Ép đèn xanh Làn A).
   - **Kịch bản 7:** Ưu tiên xe khẩn cấp Làn B (Ép đèn xanh Làn B).

---
*Tác giả: Nguyễn Huy Hân |Đồ Án Chuyên Ngành*
