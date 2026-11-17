# Công cụ tài liệu

- generate_report.py: sinh Word từ docs/reports/BAO_CAO_KY_THUAT.md bằng python-docx.
- generate_pinout.py: xuất 30 chân từ QSF sang docs/hardware/PINOUT.md; không ghi vào QSF.
- package_release.py: tạo ZIP hiện hành và SHA-256 trong releases/.
- archive/: hai script sinh tài liệu đời trước, không nằm trong quy trình phát hành.

Chạy từ môi trường Python có các thư viện trong requirements.txt. Word cần được
render và kiểm tra mọi trang sau khi chỉnh bố cục. Không chạy script archive để
ghi đè tài liệu hiện hành; các thông số phần cứng đời trước chưa được xác minh lại.
