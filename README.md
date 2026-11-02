# Hệ Thống Điều Khiển Đèn Giao Thông Ngã Tư Trên FPGA Cyclone IV

Dự án thiết kế và hiện thực hệ thống điều khiển đèn giao thông ngã tư 2 làn đường độc lập, tích hợp đồng hồ đếm lùi hiển thị trên LED 7 đoạn đôi sử dụng IC đệm dòng **UL2803G** và chip **FPGA Altera / Intel Cyclone IV E EP4CE6E22C8N**.

---

## 🌟 1. Tính Năng Kỹ Thuật Nổi Bật

1. **Chu trình FSM Moore 4 pha chuẩn giao thông:**
   - **Pha 1:** Làn A Xanh (25s) | Làn B Đỏ (28s)
   - **Pha 2:** Làn A Vàng (3s)  | Làn B Đỏ (3s)
   - **Pha 3:** Làn A Đỏ (30s)   | Làn B Xanh (27s)
   - **Pha 4:** Làn A Đỏ (3s)    | Làn B Vàng (3s)
2. **Khóa liên động an toàn phần cứng (Fail-Safe Hardware Interlock):**
   - Giám sát tín hiệu FSM thời gian thực. Nếu phát hiện sự cố nguy hiểm (Cả 2 làn cùng bật đèn Xanh), mạch phần cứng lập tức cưỡng chế ngắt toàn bộ đèn xanh và ép sáng 2 đèn đỏ để chống đâm va.
3. **Chế độ ưu tiên Xe khẩn cấp (Emergency Mode):**
   - Nút `KEY1`: Ưu tiên xe cứu thương/cứu hỏa Làn A (ép Làn A Xanh, Làn B Đỏ).
   - Nút `KEY2`: Ưu tiên xe cứu thương/cứu hỏa Làn B (ép Làn B Xanh, Làn A Đỏ).
4. **Công tắc cần gạt 3 vị trí (MTS-103 ON - OFF - ON):**
   - **Nấc Giữa (OFF):** Hệ thống tự động chuyển pha bình thường.
   - **Nấc Gạt Trái (ON 1):** Kích hoạt **Chế độ Ban Đêm** (Tắt LED 7 đoạn, đèn Vàng chớp tắt 1Hz cảnh báo giao thông).
   - **Nấc Gạt Phải (ON 2):** Kích hoạt **Chế độ Tạm Dừng (Pause)** (Đóng băng bộ đếm và trạng thái đèn).
5. **Đồng hồ đếm lùi 2 chữ số quét đa kênh (Time-Division Multiplexing):**
   - Tần số quét 1 kHz chống giật lag, chia sẻ bus 7 đoạn giúp tiết kiệm chân I/O.
   - Đệm dòng xả qua mảng Darlington **UL2803G (DIP-18)** bảo vệ cổng I/O FPGA an toàn 100%.

---

## 📌 2. Sơ Đồ Gán Chân GPIO (Tối Ưu Cho Vẽ Mạch Altium)

Thiết kế tối ưu theo nguyên tắc **Zero-Crossing PCB Routing**: Toàn bộ các chân điều khiển và đèn đều nằm ở **Hàng chân ngoài (Outer row)** của rào cắm trên, giúp đường mạch bắn thẳng tắp ra biên PCB mà không cần dùng via xuyên lớp.

### A. Hàng Rào Trên (Top Header) - Cụm Đèn & Điều Khiển
| Tín hiệu | Hướng | Chân FPGA | Chức năng |
| :--- | :---: | :---: | :--- |
| `LEDG[0]` | OUT | **`PIN_39`** | Đèn XANH Làn A |
| `LEDR[0]` | OUT | **`PIN_43`** | Đèn VÀNG Làn A |
| `LEDR[1]` | OUT | **`PIN_46`** | Đèn ĐỎ Làn A |
| `LEDG[1]` | OUT | **`PIN_71`** | Đèn XANH Làn B |
| `LEDR[2]` | OUT | **`PIN_69`** | Đèn VÀNG Làn B |
| `LEDR[3]` | OUT | **`PIN_67`** | Đèn ĐỎ Làn B |
| `KEY[0]` | IN | **`PIN_50`** | Nút nhấn Reset toàn hệ thống |
| `KEY[1]` | IN | **`PIN_52`** | Nút nhấn Khẩn cấp Làn A |
| `KEY[2]` | IN | **`PIN_54`** | Nút nhấn Khẩn cấp Làn B |
| `SW[0]` | IN | **`PIN_58`** | Chân 1 công tắc 3 nấc (Chế độ Ban đêm) |
| `SW[1]` | IN | **`PIN_60`** | Chân 3 công tắc 3 nấc (Chế độ Tạm dừng Pause) |
| `CLOCK_50`| IN | **`PIN_24`** | Xung nhịp Master Clock 50 MHz tích hợp trên kit |

### B. Hàng Rào Dưới (Bottom Header) - Cụm LED 7 Đoạn Đôi Anode Chung (5621AH)
| Thanh / Chân LED | Chân LED 10P | Nối qua UL2803G | Chân FPGA Làn A | Chân FPGA Làn B |
| :---: | :---: | :---: | :---: | :---: |
| **Thanh A** | Chân 10 | In 1B $\rightarrow$ Out 1C $\rightarrow$ Trở 330Ω | **`PIN_144`** | **`PIN_127`** |
| **Thanh B** | Chân 9 | In 2B $\rightarrow$ Out 2C $\rightarrow$ Trở 330Ω | **`PIN_142`** | **`PIN_125`** |
| **Thanh C** | Chân 1 | In 3B $\rightarrow$ Out 3C $\rightarrow$ Trở 330Ω | **`PIN_138`** | **`PIN_121`** |
| **Thanh D** | Chân 4 | In 4B $\rightarrow$ Out 4C $\rightarrow$ Trở 330Ω | **`PIN_136`** | **`PIN_119`** |
| **Thanh E** | Chân 3 | In 5B $\rightarrow$ Out 5C $\rightarrow$ Trở 330Ω | **`PIN_133`** | **`PIN_113`** |
| **Thanh F** | Chân 6 | In 6B $\rightarrow$ Out 6C $\rightarrow$ Trở 330Ω | **`PIN_129`** | **`PIN_111`** |
| **Thanh G** | Chân 5 | In 7B $\rightarrow$ Out 7C $\rightarrow$ Trở 330Ω | **`PIN_143`** | **`PIN_115`** |
| **DIG1 (Chục)** | Chân 8 | Cắm thẳng FPGA (Dương chung 3.3V) | **`PIN_141`** | **`PIN_112`** |
| **DIG2 (Đơn vị)** | Chân 7 | Cắm thẳng FPGA (Dương chung 3.3V) | **`PIN_137`** | **`PIN_110`** |

---

## 📂 3. Cấu Trúc Thư Mục Dự Án Chuẩn Công Nghiệp & Học Thuật

Cấu trúc thư mục được quy hoạch khoa học, rõ ràng theo tiêu chuẩn dự án FPGA công nghiệp:

```
DoAn2_Traffic_Light_FPGA/
├── rtl/                                    # Toàn bộ mã nguồn thiết kế phần cứng VHDL
│   ├── clk_divider.vhd                     # Module chia tần số (50MHz -> 1Hz, 1kHz, nhấp nháy 1Hz)
│   ├── fsm_controller.vhd                  # Module máy trạng thái FSM Moore 4 pha giao thông
│   ├── timer_counter.vhd                   # Module bộ đếm lùi thời gian & giải mã BCD hàng chục/đơn vị
│   ├── seg7_decoder.vhd                    # Module giải mã 7 đoạn quét động cho IC đệm UL2803G
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
│   ├── traffic_light_top.jic               # File nạp bộ nhớ Flash EPCS4 (Non-volatile, lưu vĩnh viễn)
│   └── traffic_light_top_epcs4.jic         # Bản sao lưu cấu hình chuẩn EPCS4 (Silicon ID 0x12)
├── docs/                                   # Báo cáo kỹ thuật, sơ đồ chân và tài liệu dự án
│   ├── Bao_Cao_Giai_Thich_Code_Va_Nguyen_Ly_Module.docx # Báo cáo kỹ thuật chi tiết từng module
│   ├── Danh_Sach_Chan_IO_FPGA_Cyclone_IV_Anode_Chung.docx # Bảng tra cứu 29 chân I/O & vẽ Altium
│   ├── Danh_Sach_Linh_Kien_Do_An_Traffic_Light_Anode_Chung.docx # Bảng tổng hợp linh kiện và BOM
│   ├── HUONG_DAN_CHAY_DU_AN_ANODE_CHUNG.txt# Sổ tay hướng dẫn nhanh đấu nối phần cứng & nạp code
│   └── DoAn2_Traffic_Light_Anode_Chung.zip # Gói lưu trữ nén toàn bộ dự án
├── scripts/                                # Công cụ script tự động sinh tài liệu
│   ├── generate_bom_doc.py                 # Script tự động xuất BOM sang định dạng Word (.docx)
│   └── generate_pinout_doc.py              # Script tự động xuất bảng chân I/O sang Word (.docx)
├── traffic_light_top.qpf                   # Quartus Prime Project File
├── traffic_light_top.qsf                   # Quartus Settings File (29 Pin assignments & 3.3V LVTTL)
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
5. **Nạp vĩnh viễn (Flash EPCS4):**
   * Nhấn **Add File...** $\rightarrow$ mở thư mục `bitstream/` $\rightarrow$ chọn `traffic_light_top.jic`.
   * Tích chọn ô **Program/Configure** ở dòng `EPCS4` $\rightarrow$ nhấn **Start** (Lưu vĩnh viễn vào ROM, không mất khi ngắt nguồn điện).

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
*Tác giả: Nguyễn Huy Hân | Sinh viên Đồ Án Chuyên Ngành / Kỹ thuật Máy tính - Điện tử*
