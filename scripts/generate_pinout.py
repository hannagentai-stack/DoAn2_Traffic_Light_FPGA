"""Export FPGA pin assignments directly from the immutable Quartus QSF."""
from pathlib import Path
import re
ROOT = Path(__file__).resolve().parents[1]

def build():
    qsf = (ROOT / 'traffic_light_top.qsf').read_text(encoding='utf-8-sig')
    pins = re.findall(r'^set_location_assignment\s+(PIN_\d+)\s+-to\s+(\S+)', qsf, re.M)
    assert len(pins) == 30 and len({p for p, _ in pins}) == 30
    text = '''# Bảng chân FPGA hiện hành

Sinh trực tiếp từ traffic_light_top.qsf bằng scripts/generate_pinout.py.
Gán chân FPGA không thay đổi trong bản cập nhật độ ổn định ngày 17/11/2026.
Đây là bảng chân FPGA, không phải bảng chân vật lý của mọi loại LED 7 đoạn.

CLOCK_50: 50 MHz, 20 ns. KEY và SW: Active-Low. LEDG/LEDR, SEG qua ULN2803A
và DIG: Active-High. SEG[0..6] tương ứng a,b,c,d,e,f,g.
DIG[0] là đơn vị; DIG[1] là hàng chục. LEDR[0/1] là vàng/đỏ A;
LEDR[2/3] là vàng/đỏ B; LEDG[0/1] là xanh A/B.

| Cổng | Chân FPGA |
| --- | --- |
'''
    text += ''.join(f'| `{port}` | {pin} |\n' for pin, port in pins)
    text += '\nNguồn đối chiếu: [QSF](../../traffic_light_top.qsf). Không suy đoán thông số dòng hoặc chân socket LED từ bảng này.\n'
    (ROOT / 'docs/hardware/PINOUT.md').write_text(text, encoding='utf-8')
    print('Exported 30 unique assignments')
if __name__ == '__main__': build()
