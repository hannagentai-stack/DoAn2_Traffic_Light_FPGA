# Cập nhật độ ổn định — 17/11/2026

Phạm vi: tăng độ ổn định của thiết kế hiện hữu. Giữ nguyên gán chân QSF,
clock 50 MHz / 20 ns, phân cực SEG/DIG/đèn và nút/công tắc, thứ tự ưu tiên,
4 pha 25–3–30–3 giây, các chế độ đặc biệt và logic Fail-Safe Interlock.

## Thay đổi RTL

- KEY1, KEY2, SW0, SW1 qua hai thanh ghi đồng bộ, rồi bộ lọc riêng từng ngõ
  vào. Yêu cầu mức mới ổn định 500.000 clock (10 ms) ở cả nhấn và nhả.
  Độ trễ phản hồi khoảng 10 ms cộng vài chu kỳ clock.
- KEY0 kích hoạt reset bất đồng bộ; nhả reset qua hai tầng đồng bộ rồi
  chờ mức cao ổn định 10 ms. Mỗi lần dội xuống thấp bắt đầu lại thời gian chờ.
- SIMULATION=true rút ngắn bộ lọc xuống 3 clock; không có wait/delay mô phỏng
  trong RTL. Khi tổng hợp/nạp thật luôn để SIMULATION=false (mặc định).
- clk_divider dùng bộ đếm giây riêng: xóa khi nạp pha, giữ nguyên phần lẻ khi
  Pause. Bộ đếm nhấp nháy chạy độc lập, không bị Pause hoặc nạp pha ảnh hưởng.
- timer_counter giữ cờ hết giờ đến lần nạp pha tiếp theo; che cờ cũ trong
  chu kỳ nạp để tránh bỏ qua pha mới.
- FSM và biểu thức Interlock giữ nguyên. Pha vẫn có độ trễ bắt tay timer/FSM
  vài chu kỳ 20 ns; đã loại bỏ sai lệch gần một giây khi thoát chế độ đặc biệt.

## Kiểm chứng

Chạy tại thư mục gốc bằng ModelSim Intel FPGA Edition 20.1:

```text
vsim -c -do "do sim/run_regression.do; quit -f"
```

Hoặc từ sim/: `vsim -c -do "do run_regression.do; quit -f"`.
`run_sim.do` vẫn chạy riêng 7 kịch bản cơ bản và giữ cách xem waveform cũ.
`run_regression.do` chạy cả bộ cơ bản và kiểm tra ổn định bổ sung.
Assertion/compile lỗi hoặc timeout làm batch thoát với mã khác 0.

Kết quả:

- Biên dịch VHDL-93: 0 lỗi, 0 cảnh báo.
- 7 kịch bản cơ bản: PASS, watchdog không kích hoạt.
- Reset kích hoạt bất đồng bộ, nhả có lọc dội và đồng bộ: PASS.
- Cả bốn ngõ điều khiển lọc xung ngắn lúc nhấn và nhả: PASS.
- Đủ một giây đầu sau thoát khẩn cấp A, B và ban đêm, mỗi loại ở ba thời điểm: PASS.
- Pause giữ phần lẻ giây và bộ đếm; nhấp nháy tiếp tục: PASS.
- Pause ngay giữa phát cờ hết giờ và FSM tiếp nhận; tiếp tục chuyển đúng một pha: PASS.
- Chèn lỗi hai xanh, xanh A/vàng B, vàng A/xanh B và phục hồi: PASS ở mức RTL.

Quartus Prime Lite 20.1 Full Compilation + TimeQuest (SIMULATION=false):

- EP4CE6E22C8; 388/6.272 LEs (6%), 205 registers, 30 pins.
- Setup slack tối thiểu +11,661 ns; hold tối thiểu +0,186 ns.
- Recovery/removal đạt; Quartus nhận diện 5 chuỗi đồng bộ, mỗi chuỗi 2 tầng.
- 0 lỗi; 3 cảnh báo cũ: giấy phép LogicLock, thiếu drive strength tường minh,
  và yêu cầu điện áp I/O Cyclone IV. Không tự thay đổi QSF để giải quyết các
  vấn đề điện cần đối chiếu với bo mạch thực tế.

## File nạp và giới hạn

Đã tạo lại bằng Quartus 20.1 từ bản RTL sửa:

- bitstream/traffic_light_top.sof: nạp SRAM.
- bitstream/traffic_light_top.jic: EPCS4, SFL EP4CE6.
- bitstream/traffic_light_top_epcs16.jic: EPCS16, SFL EP4CE6.

Chọn JIC đúng chip Flash thực tế. Chưa nạp/thử trên bo vật lý; chưa kiểm chứng
chèn lỗi trên netlist sau tổng hợp hoặc bảo đảm an toàn trước mọi lỗi silicon.
Mô phỏng RTL không mô hình hóa metastability analog.

Báo cáo hiện hành gồm BAO_CAO_KY_THUAT.md và bản Word cùng thư mục.
Tài liệu phần cứng đời trước chuyển sang docs/archive/ để tra cứu lịch sử.
Gói ZIP hiện hành trong releases/ được tạo lại sau cập nhật tài liệu.
