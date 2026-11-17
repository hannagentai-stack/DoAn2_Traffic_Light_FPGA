# Bảng chân FPGA hiện hành

Sinh trực tiếp từ traffic_light_top.qsf bằng scripts/generate_pinout.py.
Gán chân FPGA không thay đổi trong bản cập nhật độ ổn định ngày 17/11/2026.
Đây là bảng chân FPGA, không phải bảng chân vật lý của mọi loại LED 7 đoạn.

CLOCK_50: 50 MHz, 20 ns. KEY và SW: Active-Low. LEDG/LEDR, SEG qua ULN2803A
và DIG: Active-High. SEG[0..6] tương ứng a,b,c,d,e,f,g.
DIG[0] là đơn vị; DIG[1] là hàng chục. LEDR[0/1] là vàng/đỏ A;
LEDR[2/3] là vàng/đỏ B; LEDG[0/1] là xanh A/B.

| Cổng | Chân FPGA |
| --- | --- |
| `CLOCK_50` | PIN_24 |
| `LEDG[0]` | PIN_39 |
| `LEDR[0]` | PIN_43 |
| `LEDR[1]` | PIN_46 |
| `LEDG[1]` | PIN_50 |
| `LEDR[2]` | PIN_52 |
| `LEDR[3]` | PIN_54 |
| `KEY[0]` | PIN_58 |
| `KEY[1]` | PIN_60 |
| `KEY[2]` | PIN_65 |
| `SW[0]` | PIN_67 |
| `SW[1]` | PIN_69 |
| `HEX_A_SEG[0]` | PIN_129 |
| `HEX_A_SEG[1]` | PIN_133 |
| `HEX_A_SEG[2]` | PIN_136 |
| `HEX_A_SEG[3]` | PIN_138 |
| `HEX_A_SEG[4]` | PIN_142 |
| `HEX_A_SEG[5]` | PIN_144 |
| `HEX_A_SEG[6]` | PIN_143 |
| `HEX_A_DIG[0]` | PIN_137 |
| `HEX_A_DIG[1]` | PIN_141 |
| `HEX_B_SEG[0]` | PIN_111 |
| `HEX_B_SEG[1]` | PIN_113 |
| `HEX_B_SEG[2]` | PIN_119 |
| `HEX_B_SEG[3]` | PIN_121 |
| `HEX_B_SEG[4]` | PIN_125 |
| `HEX_B_SEG[5]` | PIN_127 |
| `HEX_B_SEG[6]` | PIN_110 |
| `HEX_B_DIG[0]` | PIN_112 |
| `HEX_B_DIG[1]` | PIN_115 |

Nguồn đối chiếu: [QSF](../../traffic_light_top.qsf). Không suy đoán thông số dòng hoặc chân socket LED từ bảng này.
