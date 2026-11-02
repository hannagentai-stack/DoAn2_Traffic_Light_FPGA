@echo off
cd /d "%~dp0sim"
echo ==============================================================================
echo   KHOI DONG MO PHONG MODELSIM - HE THONG DIEU KHIEN DEN GIAO THONG CYCLONE IV
echo ==============================================================================

where vsim >nul 2>nul
if %errorlevel% equ 0 (
    start "" vsim -gui -do run_sim.do
    exit /b
)

if exist "C:\intelFPGA_lite\20.1\modelsim_ase\win32aloem\vsim.exe" (
    start "" "C:\intelFPGA_lite\20.1\modelsim_ase\win32aloem\vsim.exe" -gui -do run_sim.do
    exit /b
)

if exist "C:\intelFPGA_lite\18.1\modelsim_ase\win32aloem\vsim.exe" (
    start "" "C:\intelFPGA_lite\18.1\modelsim_ase\win32aloem\vsim.exe" -gui -do run_sim.do
    exit /b
)

if exist "C:\altera\13.0sp1\modelsim_ase\win32aloem\vsim.exe" (
    start "" "C:\altera\13.0sp1\modelsim_ase\win32aloem\vsim.exe" -gui -do run_sim.do
    exit /b
)

echo [CANH BAO] Khong tim thay duong dan ModelSim tu dong.
echo Ban vui long mo thu cong ModelSim, chon Change Directory toi thu muc sim va go lenh: do run_sim.do
pause
