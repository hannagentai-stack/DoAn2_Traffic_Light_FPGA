# Original User Request

## 2026-10-01T17:34:20Z

Requested team: Full team (RTL System Architect & Designer, Verification & Testbench Engineer, Synthesis & Timing Engineer, Documentation & Technical Guide)

Thiết kế, mô phỏng và kiểm chứng hoàn chỉnh hệ thống điều khiển đèn giao thông ngã tư 2 làn đường (Tuyến A - Tuyến B) bằng VHDL chuẩn cho kit Altera Cyclone IV E EP4CE115F29C7 (Terasic DE2-115), hỗ trợ các chế độ FSM tiêu chuẩn, Night Mode (nhấp nháy vàng 1 Hz), Pause/Hold (dừng đếm giữ trạng thái) và Emergency Force (ưu tiên khẩn cấp).

Working directory: c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_fpga
Integrity mode: development

## Requirements

### R1. RTL Architecture & Design (`rtl/`)
- Toàn bộ mã nguồn RTL VHDL tuân thủ chuẩn IEEE 1164 và numeric_std (nghiêm cấm `std_logic_arith` và `std_logic_unsigned`), thiết kế logic đồng bộ 100%, triệt tiêu hoàn toàn Inferred Latches.
- `clk_divider.vhd`: Chia tần số từ `CLOCK_50` (50 MHz, chân `Y2`) xuống 1 Hz và tạo xung nhấp nháy 1 Hz. Có generic `SIMULATION : boolean := false` để chia chu kỳ ngắn khi chạy mô phỏng.
- `timer_counter.vhd`: Bộ đếm lùi thời gian đồng bộ cho 2 tuyến, tự động reload thời gian đếm tương ứng với từng pha của FSM, tách giá trị đếm thành 2 số BCD 4-bit (`tens`, `units`) cấp cho bộ giải mã 7 đoạn.
- `fsm_controller.vhd`: FSM Moore chuẩn điều khiển chu kỳ giao thông:
  - Phase 1: Tuyến A Xanh (25s), Tuyến B Đỏ (28s).
  - Phase 2: Tuyến A Vàng (3s), Tuyến B Đỏ (3s còn lại).
  - Phase 3: Tuyến A Đỏ (33s), Tuyến B Xanh (30s).
  - Phase 4: Tuyến A Đỏ (3s còn lại), Tuyến B Vàng (3s).
  - Night Mode (`SW[0] = '1'`): Cả 2 tuyến nhấp nháy đèn Vàng ở tần số 1 Hz.
  - Pause/Hold (`SW[1] = '1'`): Giữ nguyên trạng thái và dừng bộ đếm lùi.
  - Emergency Force (`KEY[1]` active-low): Kích hoạt chuyển ngay sang luồng ưu tiên khẩn cấp.
  - Interlock Safety: Khóa logic đảm bảo tuyệt đối không xuất tín hiệu Xanh cho cả 2 tuyến cùng lúc trong bất kỳ trạng thái nào.
- `seg7_decoder.vhd`: Giải mã BCD (0-9) sang LED 7 đoạn Cathode chung (Active-Low: '0' sáng, '1' tắt), tự động tắt (blank) toàn bộ LED 7 đoạn khi ở Night Mode.
- `traffic_light_top.vhd`: Top-level module kết nối các module con, ánh xạ đúng tên port chuẩn DE2-115 (`CLOCK_50`, `KEY`, `SW`, `LEDR`, `LEDG`, `HEX0`..`HEX3`).

### R2. Verification & Simulation (`tb/`, `sim/`)
- `tb_traffic_light_top.vhd`: Testbench toàn diện tự động cấp clock 50 MHz (`SIMULATION => true`), reset hệ thống, kích thích qua 4 kịch bản:
  1. 2 chu kỳ hoạt động bình thường liên tiếp.
  2. Kích hoạt Night Mode (`SW[0] = '1'`).
  3. Kích hoạt Pause/Hold (`SW[1] = '1'`).
  4. Kích hoạt Emergency Force (`KEY[1]`).
  5. Tự động `assert` báo lỗi nghiêm trọng nếu xuất hiện trạng thái vi phạm an toàn liên động (`LEDG[0] = '1' and LEDG[1] = '1'`).
- `run_sim.do` & `wave.do`: Script tự động compile mã VHDL trên ModelSim/QuestaSim, nạp wave cấu hình sẵn theo nhóm (Clocks, Control Inputs, FSM State, Counters, LED Outputs, HEX Displays) và chạy kiểm thử.

### R3. Synthesis Constraints & Pin Mapping (`syn/`)
- `de2_115_pins.qsf`: Khai báo đầy đủ `set_location_assignment` và I/O standard `3.3-V LVTTL` cho toàn bộ các chân phần cứng:
  - `CLOCK_50` -> PIN_Y2
  - `KEY[0]` -> PIN_M23, `KEY[1]` -> PIN_M21
  - `SW[0]` -> PIN_AB28, `SW[1]` -> PIN_AC28
  - `LEDR[0..3]` và `LEDG[0..1]`
  - `HEX0`, `HEX1`, `HEX2`, `HEX3` (mỗi HEX 7 bit `[0..6]`).
- Báo cáo kiểm tra tổng hợp: Đảm bảo 0 Inferred Latches và đạt Timing Closure ở tần số 50 MHz.

### R4. Documentation & Deployment Guide (`docs/`)
- `fsm_state_diagram.md`: Tài liệu đặc tả FSM gồm bảng chuyển trạng thái (State Transition Table) và sơ đồ Mermaid chi tiết logic điều khiển và liên động an toàn.
- `timing_specifications.md`: Bảng định thời xung nhịp, phân bổ thời gian pha, và hướng dẫn chi tiết từng bước từ tạo Quartus Project, kiểm tra RTL Viewer, nạp file `.qsf` đến nạp file `.sof` qua cáp USB-Blaster xuống kit DE2-115 thật.

## Acceptance Criteria

### RTL & Synthesizability
- [ ] Toàn bộ mã nguồn RTL VHDL tuân thủ chuẩn IEEE 1164 / numeric_std, không có inferred latches.
- [ ] Top-level module ánh xạ chính xác cổng I/O theo đúng đặc tả phần cứng DE2-115.
- [ ] Chức năng Night Mode, Hold/Pause và Emergency Force hoạt động chính xác theo đặc tả.

### Verification & Simulation
- [ ] Testbench `tb_traffic_light_top.vhd` mô phỏng hoàn chỉnh cả 4 kịch bản mà không có bất kỳ assertion failure nào.
- [ ] Interlock safety check trong testbench đảm bảo không bao giờ có trạng thái 2 tuyến cùng Xanh.
- [ ] Script `run_sim.do` thực thi không lỗi trong ModelSim / QuestaSim.

### Constraints & Documentation
- [ ] File `de2_115_pins.qsf` đầy đủ vị trí chân và I/O standard cho toàn bộ ports.
- [ ] Tài liệu `docs/` cung cấp đầy đủ bảng chuyển trạng thái, sơ đồ mermaid và hướng dẫn triển khai thực tế.


## 2026-10-06T06:09:15Z

# Teamwork Project Prompt — Final

> Status: Launched
> Goal: Execute the prompt via teamwork_preview
> Requested team: Full Team

Tạo một phiên bản dự án Quartus mới độc lập (porting) từ dự án Đèn giao thông hiện tại, chuyển mục tiêu phần cứng từ board DE2-115 sang bo mạch mini ZCJ Cyclone IV EP4CE6E22C8N.

Working directory: c:/Users/handa/OneDrive/Documents/Projects/DoAn2/traffic_light_mini
Integrity mode: demo

## Requirements

### R1. Khởi tạo Dự án Mới & Clone Mã nguồn
Tạo một Quartus project mới tại thư mục `traffic_light_mini` với target device là `EP4CE6E22C8N`. Sao chép toàn bộ mã nguồn VHDL và các script testbench liên quan từ dự án gốc (`traffic_light_fpga`) sang thư mục mới mà không làm thay đổi logic hoạt động.

### R2. Gán chân hoàn toàn ra I/O Header (Module ngoài)
Thực hiện Pin Mapping mới hoàn toàn cho chip `EP4CE6E22C8N` trong file `.qsf`. Tín hiệu Clock 50MHz nối vào thạch anh trên bo (thường là PIN_23). **Toàn bộ** các tín hiệu I/O còn lại (nút nhấn KEY, công tắc SW, đèn LED, và LED 7 đoạn HEX) bắt buộc phải được gán vào các chân trên hai hàng rào cắm (GPIO Headers) thay vì dùng ngoại vi trên bo. Mục đích để kết nối 100% ra module bên ngoài.

### R3. Xác minh tính tương thích tài nguyên
Kiểm chứng lại quá trình tổng hợp (Synthesis) trên Quartus để đảm bảo mã nguồn VHDL hoàn toàn vừa vặn với dung lượng tài nguyên (LEs, Pins) nhỏ hơn của con chip `EP4CE6`.

## Acceptance Criteria

### RTL & Constraints
- [ ] File `traffic_light_top.qsf` phải cấu hình đúng thiết bị `EP4CE6E22C8N`.
- [ ] Các tín hiệu KEY, SW, LED, HEX được gán chính xác vào các PIN_xx hợp lệ nằm trên I/O Header của mạch (không trùng lặp chân nguồn/ground, khác với các PIN dùng cho LED/Nút nhấn hàn sẵn trên bo).

### Verification & Synthesis
- [ ] Lệnh biên dịch Quartus (`quartus_map`, `quartus_fit`, `quartus_asm`) trên thư mục mới thành công xuất ra file `.sof` với 0 errors.
