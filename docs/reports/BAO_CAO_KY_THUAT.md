# Báo cáo thiết kế hệ thống đèn giao thông FPGA

Nguyễn Huy Hân | Đồ án chuyên ngành | Cập nhật ngày 17/11/2026

## 1 Tổng quan hệ thống

Hệ thống điều khiển hai làn giao cắt A và B trên Cyclone IV E EP4CE6E22C8N. Thiết kế sử dụng VHDL tổng hợp được, Quartus Prime Lite 20.1 và ModelSim Intel FPGA Edition 20.1. Bản RTL abff943 bổ sung xử lý ngõ vào và sửa sai lệch thời gian khi đổi chế độ hoặc Pause.

Clock duy nhất là CLOCK_50, 50 MHz tại PIN_24, chu kỳ ràng buộc 20 ns. Các khối tuần tự đều chạy bằng clock này; nhịp giây chỉ là clock enable. Không tạo clock chia để cấp cho FSM hoặc timer.

| Pha | Làn A | Làn B | Thời lượng danh định |
| --- | --- | --- | --- |
| PHA_1 | Xanh, đếm 25 | Đỏ, đếm 28 | 25 giây |
| PHA_2 | Vàng, đếm 3 | Đỏ, đếm 3 | 3 giây |
| PHA_3 | Đỏ, đếm 33 | Xanh, đếm 30 | 30 giây |
| PHA_4 | Đỏ, đếm 3 | Vàng, đếm 3 | 3 giây |

Một vòng danh định dài 61 giây. Chuyển pha có độ trễ bắt tay vài chu kỳ 20 ns. Hai làn hiển thị thời gian bằng hai cụm LED 7 đoạn đôi anode chung.

Luồng xử lý: KEY/SW → đồng bộ và chống dội → FSM → timer/BCD → ghép kênh → giải mã SEG. Ngõ đèn FSM đi qua Interlock trước khi ra LEDG/LEDR. clk_divider cung cấp nhịp đếm và nhịp nhấp nháy; top-level tạo nhịp quét hiển thị.

SEG đưa vào ULN2803A, DIG cấp anode và sáu đèn giao thông đều Active-High. KEY0/1/2, SW0/1 đều Active-Low. Gán chân trong QSF là nguồn đối chiếu chính thức và không được thay đổi trong bản cập nhật.

## 2 Đồng bộ reset và tạo nhịp

traffic_light_top.vhd ghép bốn loại module con; seg7_decoder được dùng hai lần. Bốn ngõ KEY1, KEY2, SW0, SW1 đi qua control_meta và control_sync trước khi được lọc độc lập thành control_clean. Mức mới phải ổn định 500.000 clock, tương đương 10 ms, ở cả nhấn và nhả. Độ trễ phản hồi khoảng 10 ms cộng vài chu kỳ clock.

KEY0 kéo thấp sẽ reset ngay cả khi không có cạnh clock. Khi KEY0 lên cao, reset_meta và reset_sync đồng bộ quá trình nhả; reset_count yêu cầu mức cao ổn định thêm 10 ms trước khi phát rst_n_s. Mỗi lần dội xuống thấp bắt đầu lại quá trình này. Các khối chức năng dùng rst_n_s thay vì KEY0 trực tiếp.

clk_divider.vhd dùng hai bộ đếm riêng. thanh_ghi_dem chạy liên tục từ 0 đến 49.999.999; thanh_ghi_chop sáng nửa chu kỳ đầu và tắt nửa chu kỳ sau, tạo nhấp nháy 1 Hz với duty 50%. Nhịp này không bị Pause hay nạp pha làm thay đổi.

dem_giay tạo nhịp đếm thời gian. nap_lai_giay xóa phần lẻ khi nạp pha mới; tam_dung giữ nguyên phần lẻ. xung_tick_1hz là clock enable tổ hợp, được timer nhận tại cùng cạnh clock mà dem_giay quay về 0. Vì vậy giây đầu sau nạp pha có đủ 50 triệu chu kỳ clock.

```vhdl
xung_tick_1hz <= '1' when dem_giay = GIOI_HAN_DEM - 1 and
                        nap_lai_giay = '0' and tam_dung = '0' and
                        rst_n = '1' else '0';
```

SIMULATION=false là mặc định dùng khi tổng hợp. SIMULATION=true chỉ đổi các hằng số: một giây còn 50 clock, nửa chu kỳ nhấp nháy 25 clock, bộ lọc 3 clock và mỗi lần đổi digit 5 clock. Đây vẫn là cấu trúc tổng hợp được, không có wait hay delay mô phỏng trong rtl/.

## 3 Máy trạng thái điều khiển

fsm_controller.vhd có bảy trạng thái: PHA_1, PHA_2, PHA_3, PHA_4, BAN_DEM, KHAN_CAP và KHAN_CAP_B. Ba tiến trình lần lượt giữ trạng thái, tính trạng thái kế tiếp và giải mã ngõ ra. Các pha bình thường chuyển theo thứ tự 1 → 2 → 3 → 4 → 1 khi co_het_gio được tiếp nhận.

Ưu tiên xử lý: khẩn cấp A, khẩn cấp B, yêu cầu ban đêm; tiếp đến là thoát chế độ đặc biệt, Pause và chuyển pha khi hết giờ. Khi nhấn đồng thời hai nút khẩn cấp, làn A được ưu tiên. Pause không ngăn yêu cầu khẩn cấp hoặc ban đêm.

| Trạng thái đặc biệt | Ngõ ra | Khi bỏ yêu cầu |
| --- | --- | --- |
| BAN_DEM | Hai vàng nhấp nháy, đỏ/xanh tắt, SEG/DIG tắt | Về PHA_1 nếu không còn khẩn cấp |
| KHAN_CAP | A xanh, B đỏ | Về PHA_1 nếu không còn ưu tiên khác |
| KHAN_CAP_B | A đỏ, B xanh | Về PHA_3 nếu không còn ưu tiên khác |

Trong trạng thái khẩn cấp, đèn giữ theo yêu cầu; bộ đếm vẫn có thể chạy xuống 1 nếu không Pause. Số hiển thị khi đang giữ khẩn cấp không dự báo thời điểm kết thúc yêu cầu. Khi thoát chế độ, timer nạp lại thời gian đầy đủ của pha bình thường tương ứng.

```vhdl
nap_pha <= '1' when
    (trang_thai_hien_tai /= trang_thai_truoc_do) else '0';
```

nap_pha tồn tại một chu kỳ clock sau mỗi lần đổi trạng thái và yêu cầu timer nạp thời gian mới. Khi reset, trạng thái hiện tại là PHA_1, trạng thái trước là PHA_4 để tạo yêu cầu nạp đầu tiên.

Ngõ ra các pha phụ thuộc trạng thái; riêng đèn vàng ở BAN_DEM còn được điều chế bởi xung_chop_1hz. Cấu trúc Moore không tự bảo đảm loại bỏ mọi glitch vật lý của giải mã tổ hợp. Kết quả hiện có là kiểm chứng chức năng RTL và timing theo SDC, chưa phải chứng nhận an toàn giao thông thực tế.

## 4 Bộ đếm hiển thị và Interlock

timer_counter.vhd giữ hai số nguyên 6-bit trong khoảng 0 đến 63. nap_pha có ưu tiên hơn đếm lùi. Khi có tick và không Pause, mỗi bộ đếm lớn hơn 1 giảm một đơn vị. PHA_1/2 dùng làn A quyết định hết giờ; PHA_3/4 dùng làn B.

Cờ hết giờ được đặt tại tick kết thúc khoảng đếm cuối, khi giá trị hiện tại là 1; không phát ngay khi vừa giảm từ 2 xuống 1. thanh_ghi_het_gio giữ mức 1 cho đến lần nạp pha tiếp theo. Trong chu kỳ nạp, ngõ co_het_gio bị che về 0 để cờ cũ không làm bỏ qua pha mới. Nhờ đó Pause đúng lúc hết giờ không làm mất sự kiện.

```vhdl
co_het_gio <= thanh_ghi_het_gio when nap_pha = '0' else '0';
```

Thủ tục chuyen_sang_bcd dùng các ngưỡng 60, 50, 40, 30, 20, 10 và phép trừ để tách hàng chục, hàng đơn vị. Không dùng phép chia hoặc modulo trong logic chuyển đổi này.

seg7_decoder.vhd giải mã BCD 0 đến 9 theo thứ tự bit g,f,e,d,c,b,a. Ví dụ số 0 là 0111111; số 1 là 0000110; số 8 là 1111111. tat_led=1 hoặc BCD ngoài khoảng 0–9 cho 0000000. Mức 1 trên SEG kích ULN dẫn và làm sáng nét tương ứng.

Bộ quét ở traffic_light_top.vhd đổi digit mỗi 50.000 clock, tức 1.000 lần đổi mỗi giây. Mỗi digit được chọn lại ở 500 Hz, duty xấp xỉ 50%. DIG(0) chọn đơn vị, DIG(1) chọn hàng chục. Ban đêm đặt cả DIG về 00 và SEG về 0000000.

Interlock kiểm tra ba điều kiện: hai xanh; xanh A cùng vàng B; vàng A cùng xanh B. Nếu có xung đột, LEDG=00 và LEDR=1010: tắt xanh/vàng, bật hai đỏ. Khi hết xung đột, ngõ ra trở lại theo FSM. Mạch không giám sát dòng LED, lỗi dây hoặc mọi dạng lỗi phần cứng.

## 5 Kết quả kiểm chứng

ModelSim 20.1 biên dịch VHDL-93 không lỗi/cảnh báo. Bảy kịch bản cơ bản kiểm tra reset, hai vòng pha bình thường, ban đêm, Pause và khẩn cấp A/B. Watchdog yêu cầu testbench hoàn tất trong 240 us; script chạy 250 us. Assertion thất bại hoặc lỗi biên dịch làm batch thoát với mã khác 0.

| Nhóm kiểm tra bổ sung | Kết quả |
| --- | --- |
| Reset bất đồng bộ và nhả có đồng bộ/lọc dội | PASS |
| Cả bốn ngõ điều khiển, dội lúc nhấn và nhả | PASS |
| Giây đầu sau thoát A/B/ban đêm, ba thời điểm mỗi loại | PASS |
| Pause giữ phần lẻ, nhịp nhấp nháy vẫn chạy | PASS |
| Pause giữa phát cờ và FSM nhận, không bỏ qua pha mới | PASS |
| Ba xung đột Interlock và phục hồi bằng chèn lỗi RTL | PASS |

Quartus Prime Lite 20.1 Full Compilation và TimeQuest với SIMULATION=false cho kết quả:

| Chỉ tiêu | Kết quả |
| --- | --- |
| Logic elements | 388 / 6.272, khoảng 6% |
| Registers và pins | 205 registers, 30 pins |
| Setup slack nhỏ nhất | +11,661 ns |
| Hold slack nhỏ nhất | +0,186 ns |
| Đồng bộ và reset | 5 chuỗi hai tầng; recovery/removal đạt |

Còn ba cảnh báo: tính năng LogicLock yêu cầu giấy phép, chưa chỉ định drive strength tường minh, và yêu cầu điện áp I/O Cyclone IV. Không đổi QSF để suy đoán thông số điện. Chưa thử trên bo thật, chưa chèn lỗi trên netlist sau tổng hợp; mô phỏng RTL không mô hình hóa metastability analog. Các ngõ ra hiển thị và ngõ vào bất đồng bộ được false-path theo SDC hiện hữu.

## 6 Tái lập và triển khai

Mở traffic_light_top.qpf tại thư mục gốc bằng Quartus 20.1 và chạy Full Compilation. QSF tham chiếu năm tệp rtl/ cùng SDC 20 ns. Giữ SIMULATION=false khi tạo file nạp. Có thể chạy lệnh từ thư mục gốc:

```text
quartus_sh --flow compile traffic_light_top
vsim -c -do "do sim/run_regression.do; quit -f"
```

Để xem waveform của bảy kịch bản cơ bản, mở ModelSim tại sim/ rồi chạy do run_sim.do. Regression đầy đủ chạy thêm stability_checks.do với các tín hiệu nội bộ được chèn lỗi; bài kiểm tra này dành cho RTL và cần +acc như script đã cấu hình.

| File trong bitstream/ | Mục đích |
| --- | --- |
| traffic_light_top.sof | Nạp SRAM qua JTAG, mất cấu hình khi tắt nguồn |
| traffic_light_top.jic | Flash EPCS4, Serial Flash Loader EP4CE6 |
| traffic_light_top_epcs16.jic | Flash EPCS16, Serial Flash Loader EP4CE6 |
| SHA256SUMS.txt | Đối chiếu toàn vẹn ba file nạp |

Trong Programmer, chọn USB-Blaster và đúng file nạp. Dùng JIC tương ứng chip Flash thực tế trên bo; không chọn file EPCS4 cho EPCS16 hoặc ngược lại. Bản cập nhật chỉ tạo file, chưa thực hiện nạp phần cứng.

Tài liệu hiện hành nằm trong docs/reports, docs/hardware và docs/guides. Bảng chân FPGA được sinh trực tiếp từ QSF; không suy ra thứ tự chân vật lý của mọi mã LED từ bảng đó. Tài liệu và script đời trước nằm trong thư mục archive, chỉ dùng tra cứu lịch sử.

Gói ZIP trong releases/ bao gồm mã nguồn, cấu hình, script mô phỏng, báo cáo hiện hành và file nạp; không gồm database Quartus, thư viện work, log tạm hoặc bản ZIP lồng nhau. scripts/package_release.py tạo lại gói bằng danh sách thư mục rõ ràng. Không dùng gói tài liệu cũ để thay thế nguồn hiện hành.
