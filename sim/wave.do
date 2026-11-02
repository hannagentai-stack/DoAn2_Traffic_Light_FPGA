# ==============================================================================
# ModelSim / QuestaSim Waveform Configuration Script
# Du an : Thiet Ke He Thong Dieu Khien Den Giao Thong Nga Tu (Cyclone IV)
# File   : wave.do
# ==============================================================================

onerror {resume}
catch { quietly WaveActivateNextPane {} 0 }

# --- GROUP 1: XUNG CLOCK & RESET HE THONG ---
add wave -noupdate -divider {CLOCK & RESET}
add wave -noupdate -color Yellow -format Logic /tb_traffic_light_top/clk_50m
add wave -noupdate -color Red    -format Logic /tb_traffic_light_top/tin_hieu_key(0)
add wave -noupdate -color Cyan   -format Logic /tb_traffic_light_top/thiet_bi_kiem_thu/xung_tick_1hz_s
add wave -noupdate -color Orange -format Logic /tb_traffic_light_top/thiet_bi_kiem_thu/xung_chop_1hz_s

# --- GROUP 2: TIN HIEU DIEU KHIEN VA CONG TAC NGOAI VI ---
add wave -noupdate -divider {TIN HIEU NGO VAO (SW & KEY)}
add wave -noupdate -color Magenta -format Logic /tb_traffic_light_top/tin_hieu_sw(0)
add wave -noupdate -color Blue    -format Logic /tb_traffic_light_top/tin_hieu_sw(1)
add wave -noupdate -color Red     -format Logic /tb_traffic_light_top/tin_hieu_key(1)
add wave -noupdate -color Orange  -format Logic /tb_traffic_light_top/tin_hieu_key(2)

# --- GROUP 3: TRANG THAI MAY FSM ---
add wave -noupdate -divider {MAY TRANG THAI FSM}
add wave -noupdate -color Gold    -format Literal /tb_traffic_light_top/thiet_bi_kiem_thu/khoi_dieu_khien_fsm/trang_thai_hien_tai
add wave -noupdate -color Orange  -format Literal /tb_traffic_light_top/thiet_bi_kiem_thu/khoi_dieu_khien_fsm/trang_thai_ke_tiep
add wave -noupdate -color White   -format Literal -radix binary /tb_traffic_light_top/thiet_bi_kiem_thu/chon_pha_s
add wave -noupdate -color Cyan    -format Logic   /tb_traffic_light_top/thiet_bi_kiem_thu/nap_pha_s
add wave -noupdate -color Yellow  -format Logic   /tb_traffic_light_top/thiet_bi_kiem_thu/co_het_gio_s

# --- GROUP 4: BO DEM THOI GIAN & MA BCD ---
add wave -noupdate -divider {BO DEM GIAY & BCD}
add wave -noupdate -color Green  -format Literal -radix unsigned /tb_traffic_light_top/thiet_bi_kiem_thu/khoi_dem_thoi_gian/dem_lan_a
add wave -noupdate -color Cyan   -format Literal -radix unsigned /tb_traffic_light_top/thiet_bi_kiem_thu/khoi_dem_thoi_gian/dem_lan_b
add wave -noupdate -color White  -format Literal -radix unsigned /tb_traffic_light_top/thiet_bi_kiem_thu/bcd_a_chuc_s
add wave -noupdate -color White  -format Literal -radix unsigned /tb_traffic_light_top/thiet_bi_kiem_thu/bcd_a_don_vi_s
add wave -noupdate -color White  -format Literal -radix unsigned /tb_traffic_light_top/thiet_bi_kiem_thu/bcd_b_chuc_s
add wave -noupdate -color White  -format Literal -radix unsigned /tb_traffic_light_top/thiet_bi_kiem_thu/bcd_b_don_vi_s

# --- GROUP 5: DEN TIN HIEU GIAO THONG (LAN A & LAN B) ---
add wave -noupdate -divider {DEN GIAO THONG LAN A}
add wave -noupdate -color Green  -format Logic /tb_traffic_light_top/den_ledg(0)
add wave -noupdate -color Yellow -format Logic /tb_traffic_light_top/den_ledr(0)
add wave -noupdate -color Red    -format Logic /tb_traffic_light_top/den_ledr(1)

add wave -noupdate -divider {DEN GIAO THONG LAN B}
add wave -noupdate -color Green  -format Logic /tb_traffic_light_top/den_ledg(1)
add wave -noupdate -color Yellow -format Logic /tb_traffic_light_top/den_ledr(2)
add wave -noupdate -color Red    -format Logic /tb_traffic_light_top/den_ledr(3)

# --- GROUP 6: HIEN THI LED 7 DOAN ---
add wave -noupdate -divider {HIEN THI 7-SEGMENT}
add wave -noupdate -color Pink -format Logic                    /tb_traffic_light_top/thiet_bi_kiem_thu/tat_seg7_s
add wave -noupdate -color Gray -format Literal -radix hexadecimal /tb_traffic_light_top/hex_a_dig
add wave -noupdate -color Gray -format Literal -radix hexadecimal /tb_traffic_light_top/hex_a_seg
add wave -noupdate -color Gray -format Literal -radix hexadecimal /tb_traffic_light_top/hex_b_dig
add wave -noupdate -color Gray -format Literal -radix hexadecimal /tb_traffic_light_top/hex_b_seg

catch { TreeUpdate [SetDefaultTree] }
catch { configure wave -namecolwidth 280 }
catch { configure wave -valuecolwidth 100 }
catch { configure wave -justifyvalue left }
catch { configure wave -signalnamewidth 1 }
catch { configure wave -snapdistance 10 }
catch { configure wave -datasetprefix 0 }
catch { configure wave -rowmargin 4 }
catch { configure wave -childrowmargin 2 }
