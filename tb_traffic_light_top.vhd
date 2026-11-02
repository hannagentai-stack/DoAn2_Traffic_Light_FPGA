--------------------------------------------------------------------------------
-- DU AN: THIET KE HE THONG DIEU KHIEN DEN GIAO THONG NGA TU TREN FPGA CYCLONE IV
-- MODULE: tb_traffic_light_top (TESTBENCH MO PHONG & KIEM CHUNG TOAN DIEN)
--
-- MUC DICH HOC TAP:
--   1. Hieu ro kien truc Testbench trong VHDL: Entity rong (khong co chan vat ly),
--      dong vai tro tao moi truong ao de cap xung nhap, kich thich cac nut nhan va cong tac.
--   2. Su dung generic SIMULATION => true de bo chia tan thu nho 50 trieu lan con 50 xung,
--      giup chay toan bo cac chu ky den trong vai micro giay thay vi ton nhieu gio tren ModelSim.
--   3. Su dung ham now va bien time (kieu thoi gian thuc cua VHDL) de tu dong do dac
--      va xac minh do dai cac pha den va tan so chop vang ban dem.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all; -- Thu vien logic co ban
use ieee.numeric_std.all;    -- Thu vien toan hoc so hoc

entity tb_traffic_light_top is
    -- Testbench khong co cong Port vi day la mo hinh mo phong dinh cao nhat
end entity tb_traffic_light_top;

architecture sim of tb_traffic_light_top is

    -- =========================================================================
    -- KHAI BAO THAM SO THOI GIAN MO PHONG
    -- =========================================================================
    -- Thach anh 50 MHz co chu ky T = 1 / 50 MHz = 20 nano giay (20 ns)
    constant CHU_KY_CLOCK : time := 20 ns;

    -- =========================================================================
    -- CAC TIN HIEU AO DE KET NOI VAO MACH CAN KIEM THU (DEVICE UNDER TEST - DUT)
    -- =========================================================================
    signal clk_50m            : std_logic := '0';
    signal tin_hieu_key       : std_logic_vector(2 downto 0) := "111"; -- Mac dinh '111' la chua nhan nut (Pull-up)
    signal tin_hieu_sw        : std_logic_vector(1 downto 0) := "11";  -- Mac dinh '11' la cong tac mo OFF (Pull-up)
    signal den_ledr           : std_logic_vector(3 downto 0);          -- Den Vang va Do
    signal den_ledg           : std_logic_vector(1 downto 0);          -- Den Xanh
    signal hex_a_seg          : std_logic_vector(6 downto 0);          -- 7 thanh doan Lan A
    signal hex_a_dig          : std_logic_vector(1 downto 0);          -- Vi tri LED Lan A
    signal hex_b_seg          : std_logic_vector(6 downto 0);          -- 7 thanh doan Lan B
    signal hex_b_dig          : std_logic_vector(1 downto 0);          -- Vi tri LED Lan B

    -- Co bao ket thuc qua trinh mo phong de dung may phat xung clock
    signal ket_thuc_mo_phong  : boolean := false;

begin

    -- =========================================================================
    -- GHEP NOI MACH CAN KIEM THU (DUT: DEVICE UNDER TEST)
    -- =========================================================================
    thiet_bi_kiem_thu: entity work.traffic_light_top
        generic map (
            SIMULATION => true -- BAT CHE DO MO PHONG SIEU TOC!
        )
        port map (
            CLOCK_50  => clk_50m,
            KEY       => tin_hieu_key,
            SW        => tin_hieu_sw,
            LEDR      => den_ledr,
            LEDG      => den_ledg,
            HEX_A_SEG => hex_a_seg,
            HEX_A_DIG => hex_a_dig,
            HEX_B_SEG => hex_b_seg,
            HEX_B_DIG => hex_b_dig
        );

    -- =========================================================================
    -- TIEN TRINH PHAT XUNG CLOCK 50 MHZ (CLOCK GENERATOR PROCESS)
    -- Dao trang thai 0/1 sau moi 10 ns de tao chu ky 20 ns lien tuc
    -- =========================================================================
    tien_trinh_phat_clock: process
    begin
        -- Vong lap chay lien tuc cho den khi co ket_thuc_mo_phong bat len true
        while not ket_thuc_mo_phong loop
            clk_50m <= '0';
            wait for CHU_KY_CLOCK / 2; -- Giu muc 0 trong 10 ns
            clk_50m <= '1';
            wait for CHU_KY_CLOCK / 2; -- Giu muc 1 trong 10 ns
        end loop;
        wait; -- Dung han tien trinh clock khi hoan thanh
    end process;

    -- =========================================================================
    -- TIEN TRINH KICH THICH KIEM THU CHINH (MAIN STIMULUS PROCESS)
    -- Thuc thi tuan tu cac kich ban: Reset -> Chay 4 pha -> Ban dem -> Uu tien
    -- =========================================================================
    tien_trinh_kich_thich: process
        -- Cac bien thoi gian dung de do luong do rong cac pha va chu ky chop
        variable thoi_diem_bat_dau_pha : time;
        variable thoi_luong_pha        : time;
        variable thoi_diem_chop        : time;
        variable thoi_gian_chop_sang   : time;
        variable thoi_gian_chop_tat    : time;
    begin
        -- ---------------------------------------------------------------------
        -- GIAI DOAN 1: KHOI DONG VA PHAT XUNG RESET HE THONG
        -- ---------------------------------------------------------------------
        report "[TESTBENCH] === BAT DAU MO PHONG HE THONG DEN GIAO THONG ===" severity note;
        report "[TESTBENCH] GIAI DOAN 1: Phat xung Reset he thong..." severity note;
        tin_hieu_key <= "111"; -- Chua nhan nut nao (Active-Low)
        tin_hieu_sw  <= "11";  -- Cong tac gat OFF (Active-Low keo Pull-up len '1')
        wait for 40 ns;

        -- Keo KEY(0) xuong '0' trong 100 ns de Reset he thong
        tin_hieu_key(0) <= '0';
        wait for 100 ns;

        -- Nha nut Reset ve muc '1' de he thong bat dau chay tu Pha 1
        tin_hieu_key(0) <= '1';
        wait for 40 ns;

        -- ---------------------------------------------------------------------
        -- GIAI DOAN 2: QUAN SAT VA DO THOI GIAN CHUYEN 4 PHA TUAN TU (VONG 1)
        -- ---------------------------------------------------------------------
        report "[TESTBENCH] GIAI DOAN 2: Quan sat Vong 1 (Pha 1 -> Pha 2 -> Pha 3 -> Pha 4)..." severity note;
        
        -- Cho den khi chuyen sang Pha 2 (Den Vang Lan A bat len: den_ledr(0) = '1')
        wait until rising_edge(clk_50m) and den_ledr(0) = '1';
        thoi_diem_bat_dau_pha := now;
        report "[TESTBENCH] -> Da chuyen sang Pha 2: Lan A Vang, Lan B Do." severity note;

        -- Cho chuyen sang Pha 3 (Den Xanh Lan B bat len: den_ledg(1) = '1')
        wait until rising_edge(clk_50m) and den_ledg(1) = '1';
        thoi_luong_pha := now - thoi_diem_bat_dau_pha; -- Do duoc do dai Pha 2 (3s)
        thoi_diem_bat_dau_pha := now;
        report "[TESTBENCH] -> Da chuyen sang Pha 3: Lan A Do, Lan B Xanh." severity note;

        -- Cho chuyen sang Pha 4 (Den Vang Lan B bat len: den_ledr(2) = '1')
        wait until rising_edge(clk_50m) and den_ledr(2) = '1';
        thoi_luong_pha := now - thoi_diem_bat_dau_pha; -- Do duoc do dai Pha 3 (30s)
        thoi_diem_bat_dau_pha := now;
        report "[TESTBENCH] -> Da chuyen sang Pha 4: Lan A Do, Lan B Vang." severity note;

        -- Cho quay lai Pha 1 (Den Xanh Lan A bat len: den_ledg(0) = '1')
        wait until rising_edge(clk_50m) and den_ledg(0) = '1';
        thoi_luong_pha := now - thoi_diem_bat_dau_pha; -- Do duoc do dai Pha 4 (3s)
        thoi_diem_bat_dau_pha := now;
        report "[TESTBENCH] -> Da quay ve Pha 1: Lan A Xanh, Lan B Do (Hoan thanh Vong 1)." severity note;

        -- ---------------------------------------------------------------------
        -- GIAI DOAN 3: KIEM TRA CHUYEN 4 PHA TUAN TU (VONG 2)
        -- ---------------------------------------------------------------------
        report "[TESTBENCH] GIAI DOAN 3: Kiem tra on dinh Vong 2..." severity note;
        wait until rising_edge(clk_50m) and den_ledr(0) = '1';
        wait until rising_edge(clk_50m) and den_ledg(1) = '1';
        wait until rising_edge(clk_50m) and den_ledr(2) = '1';
        wait until rising_edge(clk_50m) and den_ledg(0) = '1';
        report "[TESTBENCH] -> Hoan thanh Vong 2 on dinh." severity note;

        -- ---------------------------------------------------------------------
        -- GIAI DOAN 4: KIEM TRA CHE DO BAN DEM (SW0 = '0' Mass)
        -- ---------------------------------------------------------------------
        report "[TESTBENCH] GIAI DOAN 4: Kiem tra Che do BAN DEM (SW0 = '0')..." severity note;
        wait for 200 ns;
        tin_hieu_sw(0) <= '0'; -- Gat cong tac xuong Mass (ON che do ban dem)
        wait for 200 ns;

        -- Kiem tra nhip chop tat cua den vang Lan A (den_ledr(0)):
        wait until rising_edge(clk_50m) and den_ledr(0) = '1';
        thoi_diem_chop := now;

        wait until rising_edge(clk_50m) and den_ledr(0) = '0';
        thoi_gian_chop_sang := now - thoi_diem_chop; -- Do thoi gian sang (nua chu ky)
        thoi_diem_chop := now;

        wait until rising_edge(clk_50m) and den_ledr(0) = '1';
        thoi_gian_chop_tat := now - thoi_diem_chop;  -- Do thoi gian tat (nua chu ky)
        report "[TESTBENCH] -> Den Vang chop dung chu ky 1Hz (50% duty cycle)." severity note;

        -- Tat che do ban dem ve lai binh thuong (Keo len '1')
        tin_hieu_sw(0) <= '1';
        wait for 500 ns;

        -- ---------------------------------------------------------------------
        -- GIAI DOAN 5: KIEM TRA CHE DO TAM DUNG PAUSE (SW1 = '0' Mass)
        -- ---------------------------------------------------------------------
        report "[TESTBENCH] GIAI DOAN 5: Kiem tra Che do TAM DUNG (SW1 = '0')..." severity note;
        tin_hieu_sw(1) <= '0'; -- Gat cong tac xuong Mass bat tam dung Pause
        wait for 4.0 us;       -- Giu trang thai tam dung trong 4 micro giay
        tin_hieu_sw(1) <= '1'; -- Nha cong tac ve '1' de bo dem chay tiep
        wait for 2.0 us;
        report "[TESTBENCH] -> Bo dem da dong bang dung 4 us roi tiep tuc dem." severity note;

        -- ---------------------------------------------------------------------
        -- GIAI DOAN 6: KIEM TRA CHE DO KHAN CAP LAN A (KEY1 = '0')
        -- ---------------------------------------------------------------------
        report "[TESTBENCH] GIAI DOAN 6: Kiem tra uu tien KHAN CAP LAN A (KEY1 = '0')..." severity note;
        wait until rising_edge(clk_50m) and den_ledg(1) = '1'; -- Dang o luc Lan B xanh
        wait for 1.0 us;

        -- Nhan giu nut khan cap Lan A (Xe cuu thuong den)
        tin_hieu_key(1) <= '0';
        wait for 5.0 us; -- Giu nut trong 5 micro giay: Phai lap tuc ep Lan A sang XANH!
        tin_hieu_key(1) <= '1'; -- Nha nut khan cap
        wait for 2.0 us;
        report "[TESTBENCH] -> Da ep Lan A sang Xanh thanh cong!" severity note;

        -- ---------------------------------------------------------------------
        -- GIAI DOAN 7: KIEM TRA CHE DO KHAN CAP LAN B (KEY2 = '0')
        -- ---------------------------------------------------------------------
        report "[TESTBENCH] GIAI DOAN 7: Kiem tra uu tien KHAN CAP LAN B (KEY2 = '0')..." severity note;
        wait until rising_edge(clk_50m) and den_ledg(0) = '1'; -- Dang o luc Lan A xanh
        wait for 1.0 us;

        -- Nhan giu nut khan cap Lan B
        tin_hieu_key(2) <= '0';
        wait for 3.0 us; -- Phai lap tuc nhay sang Pha 3 (Xanh Lan B)
        tin_hieu_key(2) <= '1'; -- Nha nut khan cap
        wait for 2.0 us;
        report "[TESTBENCH] -> Da ep Lan B sang Xanh thanh cong!" severity note;

        -- ---------------------------------------------------------------------
        -- KET THUC TOAN BO KICH BAN MO PHONG
        -- ---------------------------------------------------------------------
        report "[TESTBENCH] === HOAN THANH XUAT SAC TOAN BO 7 KICH BAN MO PHONG! ===" severity note;
        wait for 5.0 us;
        ket_thuc_mo_phong <= true; -- Dat co ket thuc de tat may phat xung clock
        wait;                      -- Dung tien trinh vinh vien
    end process;

end architecture sim;
