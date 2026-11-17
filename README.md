# Hệ thống đèn giao thông ngã tư trên FPGA Cyclone IV

VHDL cho Cyclone IV E **EP4CE6E22C8N**, Quartus Prime Lite **20.1** và ModelSim Intel FPGA Edition **20.1**. Phiên bản RTL `abff943` bổ sung đồng bộ/chống dội và sửa thời gian chuyển chế độ, Pause. Báo cáo cập nhật ngày **17/11/2026**.

## Kiến trúc và hành vi

| Pha | Làn A | Làn B | Thời gian pha |
| --- | --- | --- | --- |
| PHA_1 | Xanh 25 | Đỏ 28 | 25 giây |
| PHA_2 | Vàng 3 | Đỏ 3 | 3 giây |
| PHA_3 | Đỏ 33 | Xanh 30 | 30 giây |
| PHA_4 | Đỏ 3 | Vàng 3 | 3 giây |

- Clock 50 MHz tại PIN_24; constraint 20 ns; toàn bộ logic dùng clock này.
- KEY0 reset, KEY1 khẩn cấp A, KEY2 khẩn cấp B, SW0 ban đêm, SW1 Pause: **Active-Low**.
- SEG qua ULN2803A, DIG cấp anode chung và sáu đèn: **Active-High**.
- Hai tầng đồng bộ và lọc mức ổn định 10 ms cho KEY1/2, SW0/1. Reset kích hoạt bất đồng bộ, nhả đồng bộ sau thời gian lọc.
- Ưu tiên A > B > ban đêm; thoát khẩn cấp A/ban đêm về PHA_1, thoát khẩn cấp B về PHA_3. Yêu cầu đặc biệt có thể vượt Pause.
- Pause giữ bộ đếm và phần lẻ giây; nhịp nhấp nháy tiếp tục. Cờ hết giờ được giữ đến khi nạp pha.
- Bộ quét đặt trong top-level: đổi digit 1 kHz; mỗi digit được làm tươi 500 Hz. Ban đêm tắt SEG/DIG và nhấp nháy hai vàng 1 Hz.
- Interlock cưỡng chế tắt xanh/vàng, bật hai đỏ khi có hai xanh hoặc xanh–vàng đối diện. Đã kiểm tra chèn lỗi ở mức RTL.

## Tài liệu

- [Báo cáo kỹ thuật](docs/reports/BAO_CAO_KY_THUAT.md) và [bản Word](docs/reports/Bao_Cao_Giai_Thich_Code_Va_Nguyen_Ly_Module.docx).
- [Ghi chú sửa độ ổn định và số liệu kiểm chứng](docs/reports/STABILITY_UPDATE.md).
- [Bảng 30 chân lấy trực tiếp từ QSF](docs/hardware/PINOUT.md).
- [Hướng dẫn chạy và nạp](docs/guides/HUONG_DAN_CHAY_DU_AN_ANODE_CHUNG.txt).
- [Mục lục tài liệu](docs/README.md); [gói phát hành](releases/README.md).

## Cấu trúc thư mục

```text
rtl/            Năm tệp VHDL tổng hợp được
sim/            Testbench, regression và công cụ xem waveform
bitstream/      SOF, JIC EPCS4/EPCS16 và SHA256SUMS.txt
scripts/        Sinh báo cáo, xuất bảng chân, đóng gói phát hành
scripts/archive/  Script đời trước, chỉ để tra cứu lịch sử
docs/reports/   Báo cáo hiện hành ở dạng Markdown/Word và kết quả kiểm chứng
docs/hardware/  Bảng chân sinh từ QSF
docs/guides/    Hướng dẫn vận hành
docs/archive/   Tài liệu phần cứng đời trước, chưa được xác minh lại
releases/       ZIP hiện hành cùng checksum
build/          Kết quả xuất/kiểm tra cục bộ, không đưa lên Git
traffic_light_top.qpf / .qsf / .sdc   Dự án và ràng buộc Quartus
```

Giữ QPF/QSF/SDC tại gốc, RTL tại rtl/ và môi trường mô phỏng tại sim/ để không làm hỏng tham chiếu công cụ. Database Quartus và thư viện ModelSim là dữ liệu sinh tự động, được Git bỏ qua.

## Tổng hợp và mô phỏng

Mở `traffic_light_top.qpf` bằng Quartus 20.1, chạy Full Compilation với `SIMULATION=false` mặc định. Hoặc chạy từ thư mục gốc:

```text
quartus_sh --flow compile traffic_light_top
vsim -c -do "do sim/run_regression.do; quit -f"
```

Regression chạy bảy kịch bản cơ bản và các kiểm thử reset, dội nút, thời lượng sau đổi chế độ, Pause sát hết giờ và Interlock. Assertion, compile lỗi hoặc timeout làm batch trả mã khác 0. Trong GUI, từ sim/ chạy `do run_sim.do` để xem waveform của bộ cơ bản. Các BAT trong sim/ cũng mở GUI này.

`SIMULATION=true` chỉ dành cho kiểm thử nhanh: một giây tương ứng 50 clock, chống dội 3 clock, đổi digit mỗi 5 clock. Không dùng chế độ này để tạo file nạp thật.

## File nạp

| File | Mục đích |
| --- | --- |
| bitstream/traffic_light_top.sof | Nạp SRAM qua JTAG |
| bitstream/traffic_light_top.jic | Nạp Flash EPCS4, SFL EP4CE6 |
| bitstream/traffic_light_top_epcs16.jic | Nạp Flash EPCS16, SFL EP4CE6 |

Chọn USB-Blaster trong Quartus Programmer và **JIC đúng chip Flash thực tế**. Đối chiếu SHA-256 với bitstream/SHA256SUMS.txt trước khi dùng nếu cần kiểm tra toàn vẹn.

Kết quả bản RTL hiện hành: **388 LEs (6%), 205 registers, 30 pins**; setup slack nhỏ nhất **+11,661 ns**, hold **+0,186 ns**. Có ba cảnh báo Quartus còn lại được ghi trong báo cáo. Chưa thử trên bo thật hoặc chèn lỗi netlist sau tổng hợp; không coi kết quả mô phỏng là chứng nhận an toàn phần cứng.

## Cập nhật tài liệu và gói ZIP

Cài `requirements.txt` trong môi trường Python làm tài liệu. Từ thư mục gốc chạy:

```text
python scripts/generate_report.py
python scripts/generate_pinout.py
python scripts/package_release.py
```

Nguồn báo cáo là docs/reports/BAO_CAO_KY_THUAT.md. Sau khi sửa Word cần xuất và kiểm tra bố cục trước khi phát hành. Gói ZIP không chứa tài liệu archive, database, log tạm, thư viện work hoặc ZIP lồng nhau.

Tác giả: Nguyễn Huy Hân | Đồ án chuyên ngành
