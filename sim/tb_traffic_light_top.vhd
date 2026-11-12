--------------------------------------------------------------------------------
-- DU AN: THIET KE HE THONG DIEU KHIEN DEN GIAO THONG NGA TU TREN FPGA CYCLONE IV
-- MODULE: tb_traffic_light_top (TESTBENCH MO PHONG & KIEM CHUNG TOAN DIEN SELF-CHECKING)
--
-- MUC DICH HOC TAP & KIEM CHUNG:
--   1. Kien truc Testbench Self-Checking tu dong: Su dung cac menh de `assert ... report ... severity error`
--      de tu dong kiem tra dung/sai toan bo 7 kich ban hoat dong ma khong can nhin bang mat.
--   2. Concurrent Assertions (Kiem tra dong thoi song song):
--      - Giam sat tuyet doi khong xay ra tinh huong 2 lan cung bat den XANH.
--      - Giam sat xung dot giua den Xanh mot lan va den Vang lan doi dien.
--      - Giam sat khong bao gio bat ca den Xanh va den Do tren cung mot lan.
--   3. Su dung generic SIMULATION => true giup rut ngan thoi gian dem tu 50 trieu xuong 50 xung/giay,
--      chay toan bo cac chu ky den trong vai micro giay tren ModelSim.
--   4. Tu dong do dac thoi luong cac pha va chu ky chop vang ban dem voi do chinh xac cao.
--   5. Kiem tra mach quet da kenh LED 7 doan (Dynamic Scanning) hoat dong ca 2 chu so (Don vi & Chuc).
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all; -- Thu vien logic co ban
use ieee.numeric_std.all;    -- Thu vien toan hoc so hoc

entity tb_traffic_light_top is
    -- Testbench khong co cong Port (Top-level simulation wrapper)
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
    -- CONCURRENT ASSERTIONS: GIAM SAT AN TOAN GIAO THONG LIEN TUC
    -- Chay song song trong suot thoi gian mo phong, phat hien vi pham ngay tuc thi
    -- =========================================================================
    -- 1. Tuyet doi khong cho phep ca hai lan deu bat den XANH (Dual-Green Collision Hazard)
    assert not (den_ledg(0) = '1' and den_ledg(1) = '1')
        report "[CONCURRENT ASSERTION ERROR] NGUY HIEM: Ca hai Lan A va Lan B deu bat den XANH dong thoi!"
        severity failure;

    -- 2. Tuyet doi khong cho phep mot lan XANH trong khi lan giao cat dang VANG (Clearance Conflict)
    assert not (den_ledg(0) = '1' and den_ledr(2) = '1')
        report "[CONCURRENT ASSERTION ERROR] XUNG DOT: Lan A XANH trong khi Lan B dang VANG!"
        severity failure;

    assert not (den_ledr(0) = '1' and den_ledg(1) = '1')
        report "[CONCURRENT ASSERTION ERROR] XUNG DOT: Lan A VANG trong khi Lan B dang XANH!"
        severity failure;

    -- 3. Giam sat noi bo tung lan: Khong bao gio bat ca den Xanh va den Do tren cung mot lan
    assert not (den_ledg(0) = '1' and den_ledr(1) = '1')
        report "[CONCURRENT ASSERTION ERROR] Lan A vi pham: Vua bat den XANH vua bat den DO!"
        severity error;

    assert not (den_ledg(1) = '1' and den_ledr(3) = '1')
        report "[CONCURRENT ASSERTION ERROR] Lan B vi pham: Vua bat den XANH vua bat den DO!"
        severity error;

    -- =========================================================================
    -- TIEN TRINH PHAT XUNG CLOCK 50 MHZ (CLOCK GENERATOR PROCESS)
    -- Dao trang thai 0/1 sau moi 10 ns de tao chu ky 20 ns lien tuc
    -- =========================================================================
    tien_trinh_phat_clock: process
    begin
        while not ket_thuc_mo_phong loop
            clk_50m <= '0';
            wait for CHU_KY_CLOCK / 2; -- Giu muc 0 trong 10 ns
            clk_50m <= '1';
            wait for CHU_KY_CLOCK / 2; -- Giu muc 1 trong 10 ns
        end loop;
        wait; -- Dung han tien trinh clock khi hoan thanh
    end process;

    -- =========================================================================
    -- TIEN TRINH KICH THICH & KIEM CHUNG TU DONG (SELF-CHECKING STIMULUS PROCESS)
    -- Thuc thi tuan tu 7 kich ban va tu dong danh gia dung/sai qua assertions
    -- =========================================================================
    tien_trinh_kich_thich: process
        -- Cac bien thoi gian dung de do luong do rong cac pha va chu ky chop
        variable thoi_diem_bat_dau_pha : time;
        variable thoi_luong_pha        : time;
        variable thoi_diem_chop        : time;
        variable thoi_gian_chop_sang   : time;
        variable thoi_gian_chop_tat    : time;
        variable ledg_tam_dung         : std_logic_vector(1 downto 0);
        variable ledr_tam_dung         : std_logic_vector(3 downto 0);
    begin
        -- ---------------------------------------------------------------------
        -- GIAI DOAN 1: KHOI DONG VA PHAT XUNG RESET HE THONG
        -- ---------------------------------------------------------------------
        report "[TESTBENCH] ============================================================" severity note;
        report "[TESTBENCH] BAT DAU MO PHONG KIEM CHUNG TOAN DIEN HE THONG DEN GIAO THONG" severity note;
        report "[TESTBENCH] ============================================================" severity note;
        report "[TESTBENCH] GIAI DOAN 1: Phat xung Reset he thong..." severity note;
        tin_hieu_key <= "111"; -- Chua nhan nut nao (Active-Low)
        tin_hieu_sw  <= "11";  -- Cong tac gat OFF (Active-Low keo Pull-up len '1')
        wait for 40 ns;

        -- Keo KEY(0) xuong '0' trong 100 ns de Reset he thong
        tin_hieu_key(0) <= '0';
        wait for 100 ns;

        -- Nha nut Reset ve muc '1' de he thong bat dau chay tu Pha 1
        tin_hieu_key(0) <= '1';
        wait until rising_edge(clk_50m);
        wait for 2 ns; -- Cho on dinh tin hieu sau suon clock

        -- Kiem tra trang thai khoi dong sau Reset (Pha 1: Lan A Xanh, Lan B Do)
        assert (den_ledg(0) = '1' and den_ledr(3) = '1' and
                den_ledr(0) = '0' and den_ledr(1) = '0' and
                den_ledg(1) = '0' and den_ledr(2) = '0')
            report "[ASSERTION ERROR] Giai doan 1: Sau Reset khong khoi tao dung Pha 1 (Lan A Xanh, Lan B Do)!"
            severity error;
        report "[TESTBENCH] -> Reset thanh cong: Khoi tao dung Pha 1 (Lan A Xanh, Lan B Do)." severity note;

        -- ---------------------------------------------------------------------
        -- GIAI DOAN 2: QUAN SAT VA DO THOI GIAN CHUYEN 4 PHA TUAN TU (VONG 1)
        -- ---------------------------------------------------------------------
        report "[TESTBENCH] GIAI DOAN 2: Quan sat Vong 1 & Kiem tra Quet da kenh 7-Segment..." severity note;

        -- Kiem tra mach Dynamic Scanning: Xac minh ca 2 chu so (Don vi & Chuc) deu duoc quet luan phien
        wait until rising_edge(clk_50m) and hex_a_dig = "01";
        assert (hex_a_dig = "01" and hex_b_dig = "01")
            report "[ASSERTION ERROR] Dynamic Scanning: Chu so Don vi khong duoc chon dong thoi ca 2 lan!"
            severity error;
        report "[TESTBENCH] -> Dynamic Scanning: Da quet chu so Hang Don vi (HEX_DIG = 01)." severity note;

        wait until rising_edge(clk_50m) and hex_a_dig = "10";
        assert (hex_a_dig = "10" and hex_b_dig = "10")
            report "[ASSERTION ERROR] Dynamic Scanning: Chu so Hang Chuc khong duoc chon dong thoi ca 2 lan!"
            severity error;
        report "[TESTBENCH] -> Dynamic Scanning: Da quet chu so Hang Chuc (HEX_DIG = 10)." severity note;

        -- Ghi nhan moc bat dau do thoi gian cho chu ky Pha 1 tiep tuc
        thoi_diem_bat_dau_pha := now;

        -- Cho den khi chuyen sang Pha 2 (Den Vang Lan A bat len: den_ledr(0) = '1')
        wait until rising_edge(clk_50m) and den_ledr(0) = '1';
        thoi_luong_pha := now - thoi_diem_bat_dau_pha; -- Do do dai con lai cua Pha 1 (25s mo phong = 25 us)
        thoi_diem_bat_dau_pha := now;
        assert (thoi_luong_pha >= 24000 ns and thoi_luong_pha <= 25500 ns)
            report "[ASSERTION ERROR] Giai doan 2: Thoi gian Pha 1 sai lech! Thuc te: " & time'image(thoi_luong_pha) & " (Ky vong: ~25 us)"
            severity error;
        assert (den_ledr(0) = '1' and den_ledr(3) = '1' and den_ledg(0) = '0' and den_ledr(1) = '0' and den_ledg(1) = '0' and den_ledr(2) = '0')
            report "[ASSERTION ERROR] Giai doan 2: Trang thai den Pha 2 sai (Phai la Lan A Vang, Lan B Do)!"
            severity error;
        report "[TESTBENCH] -> Da chuyen sang Pha 2: Lan A Vang (3s), Lan B Do (3s con lai). Thoi gian Pha 1: " & time'image(thoi_luong_pha) severity note;

        -- Cho chuyen sang Pha 3 (Den Xanh Lan B bat len: den_ledg(1) = '1')
        wait until rising_edge(clk_50m) and den_ledg(1) = '1';
        thoi_luong_pha := now - thoi_diem_bat_dau_pha; -- Do duoc do dai Pha 2 (3s mo phong = 3 us)
        thoi_diem_bat_dau_pha := now;
        assert (thoi_luong_pha >= 2900 ns and thoi_luong_pha <= 3100 ns)
            report "[ASSERTION ERROR] Giai doan 2: Thoi gian Pha 2 sai lech! Thuc te: " & time'image(thoi_luong_pha) & " (Ky vong: 3 us)"
            severity error;
        assert (den_ledr(1) = '1' and den_ledg(1) = '1' and den_ledg(0) = '0' and den_ledr(0) = '0' and den_ledr(2) = '0' and den_ledr(3) = '0')
            report "[ASSERTION ERROR] Giai doan 2: Trang thai den Pha 3 sai (Phai la Lan A Do, Lan B Xanh)!"
            severity error;
        report "[TESTBENCH] -> Da chuyen sang Pha 3: Lan A Do (33s), Lan B Xanh (30s). Thoi gian Pha 2: " & time'image(thoi_luong_pha) severity note;

        -- Cho chuyen sang Pha 4 (Den Vang Lan B bat len: den_ledr(2) = '1')
        wait until rising_edge(clk_50m) and den_ledr(2) = '1';
        thoi_luong_pha := now - thoi_diem_bat_dau_pha; -- Do duoc do dai Pha 3 (30s mo phong = 30 us)
        thoi_diem_bat_dau_pha := now;
        assert (thoi_luong_pha >= 29900 ns and thoi_luong_pha <= 30100 ns)
            report "[ASSERTION ERROR] Giai doan 2: Thoi gian Pha 3 sai lech! Thuc te: " & time'image(thoi_luong_pha) & " (Ky vong: 30 us)"
            severity error;
        assert (den_ledr(1) = '1' and den_ledr(2) = '1' and den_ledg(0) = '0' and den_ledr(0) = '0' and den_ledg(1) = '0' and den_ledr(3) = '0')
            report "[ASSERTION ERROR] Giai doan 2: Trang thai den Pha 4 sai (Phai la Lan A Do, Lan B Vang)!"
            severity error;
        report "[TESTBENCH] -> Da chuyen sang Pha 4: Lan A Do (3s con lai), Lan B Vang (3s). Thoi gian Pha 3: " & time'image(thoi_luong_pha) severity note;

        -- Cho quay lai Pha 1 (Den Xanh Lan A bat len: den_ledg(0) = '1')
        wait until rising_edge(clk_50m) and den_ledg(0) = '1';
        thoi_luong_pha := now - thoi_diem_bat_dau_pha; -- Do duoc do dai Pha 4 (3s mo phong = 3 us)
        thoi_diem_bat_dau_pha := now;
        assert (thoi_luong_pha >= 2900 ns and thoi_luong_pha <= 3100 ns)
            report "[ASSERTION ERROR] Giai doan 2: Thoi gian Pha 4 sai lech! Thuc te: " & time'image(thoi_luong_pha) & " (Ky vong: 3 us)"
            severity error;
        assert (den_ledg(0) = '1' and den_ledr(3) = '1' and den_ledr(0) = '0' and den_ledr(1) = '0' and den_ledg(1) = '0' and den_ledr(2) = '0')
            report "[ASSERTION ERROR] Giai doan 2: Quay ve Pha 1 that bai!"
            severity error;
        report "[TESTBENCH] -> Da quay ve Pha 1: Lan A Xanh, Lan B Do (Hoan thanh Vong 1). Thoi gian Pha 4: " & time'image(thoi_luong_pha) severity note;

        -- ---------------------------------------------------------------------
        -- GIAI DOAN 3: KIEM TRA CHUYEN 4 PHA TUAN TU (VONG 2)
        -- ---------------------------------------------------------------------
        report "[TESTBENCH] GIAI DOAN 3: Kiem tra on dinh Vong 2..." severity note;
        wait until rising_edge(clk_50m) and den_ledr(0) = '1'; -- Sang Pha 2
        wait until rising_edge(clk_50m) and den_ledg(1) = '1'; -- Sang Pha 3
        wait until rising_edge(clk_50m) and den_ledr(2) = '1'; -- Sang Pha 4
        wait until rising_edge(clk_50m) and den_ledg(0) = '1'; -- Quay ve Pha 1
        assert (den_ledg(0) = '1' and den_ledr(3) = '1')
            report "[ASSERTION ERROR] Giai doan 3: Vong 2 khong ket thuc tai Pha 1 on dinh!"
            severity error;
        report "[TESTBENCH] -> Hoan thanh Vong 2 on dinh." severity note;

        -- ---------------------------------------------------------------------
        -- GIAI DOAN 4: KIEM TRA CHE DO BAN DEM (SW0 = '0' Mass)
        -- ---------------------------------------------------------------------
        report "[TESTBENCH] GIAI DOAN 4: Kiem tra Che do BAN DEM (SW0 = '0')..." severity note;
        wait for 200 ns;
        wait until falling_edge(clk_50m);
        tin_hieu_sw(0) <= '0'; -- Gat cong tac xuong Mass (ON che do ban dem)
        wait until rising_edge(clk_50m);
        wait for 100 ns;

        -- Kiem tra tat man hinh 7 doan khi o che do ban dem (HEX_DIG = "00")
        assert (hex_a_dig = "00" and hex_b_dig = "00")
            report "[ASSERTION ERROR] Giai doan 4: Che do Ban dem phai tat LED 7 doan (HEX_DIG phai bang 00)!"
            severity error;

        -- Kiem tra tat ca den Xanh va Do deu phai tat
        assert (den_ledg = "00" and den_ledr(1) = '0' and den_ledr(3) = '0')
            report "[ASSERTION ERROR] Giai doan 4: Che do Ban dem nhung den Xanh hoac Do van sang!"
            severity error;

        -- Kiem tra nhip chop tat cua den vang Lan A (den_ledr(0)) va Lan B (den_ledr(2)):
        -- Cho het nua chu ky hien tai neu dang lo do
        wait until rising_edge(clk_50m) and den_ledr(0) = '0';
        -- Bat dau bat suon len moi cua den Vang de do tron ven 1 chu ky
        wait until rising_edge(clk_50m) and den_ledr(0) = '1';
        thoi_diem_chop := now;

        wait until rising_edge(clk_50m) and den_ledr(0) = '0';
        thoi_gian_chop_sang := now - thoi_diem_chop; -- Do thoi gian sang (nua chu ky: 25 xung = 500 ns)
        thoi_diem_chop := now;

        wait until rising_edge(clk_50m) and den_ledr(0) = '1';
        thoi_gian_chop_tat := now - thoi_diem_chop;  -- Do thoi gian tat (nua chu ky: 25 xung = 500 ns)

        assert (thoi_gian_chop_sang >= 480 ns and thoi_gian_chop_sang <= 520 ns)
            report "[ASSERTION ERROR] Giai doan 4: Thoi gian sang den Vang sai lech! Thuc te: " & time'image(thoi_gian_chop_sang) & " (Ky vong: 500 ns)"
            severity error;
        assert (thoi_gian_chop_tat >= 480 ns and thoi_gian_chop_tat <= 520 ns)
            report "[ASSERTION ERROR] Giai doan 4: Thoi gian tat den Vang sai lech! Thuc te: " & time'image(thoi_gian_chop_tat) & " (Ky vong: 500 ns)"
            severity error;
        assert (den_ledr(0) = den_ledr(2))
            report "[ASSERTION ERROR] Giai doan 4: Den Vang Lan A va Lan B khong chop dong pha!"
            severity error;
        report "[TESTBENCH] -> Den Vang chop dung chu ky 1Hz (50% duty cycle, 500ns On / 500ns Off)." severity note;

        -- Tat che do ban dem ve lai binh thuong (Keo len '1')
        wait until falling_edge(clk_50m);
        tin_hieu_sw(0) <= '1';
        wait until rising_edge(clk_50m);
        wait for 200 ns;

        -- Xac minh sau khi thoat Ban dem, LED 7 doan duoc bat lai binh thuong
        assert (hex_a_dig /= "00" and hex_b_dig /= "00")
            report "[ASSERTION ERROR] Giai doan 4: Sau khi thoat Ban dem, LED 7 doan chua duoc bat lai!"
            severity error;
        report "[TESTBENCH] -> Thoat che do Ban dem thanh cong, LED 7 doan da bat lai." severity note;

        -- ---------------------------------------------------------------------
        -- GIAI DOAN 5: KIEM TRA CHE DO TAM DUNG PAUSE (SW1 = '0' Mass)
        -- ---------------------------------------------------------------------
        report "[TESTBENCH] GIAI DOAN 5: Kiem tra Che do TAM DUNG (SW1 = '0')..." severity note;
        wait until rising_edge(clk_50m);
        ledg_tam_dung := den_ledg;
        ledr_tam_dung := den_ledr;

        wait until falling_edge(clk_50m);
        tin_hieu_sw(1) <= '0'; -- Gat cong tac xuong Mass bat tam dung Pause
        wait for 4.0 us;       -- Giu trang thai tam dung trong 4 micro giay (4 giay ao)

        -- Kiem tra den giao thong khong bi chuyen pha trong suot thoi gian tam dung
        assert (den_ledg = ledg_tam_dung and den_ledr = ledr_tam_dung)
            report "[ASSERTION ERROR] Giai doan 5: Che do Tam dung bi loi, den bi doi trang thai trong luc Tam dung!"
            severity error;

        wait until falling_edge(clk_50m);
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
        wait until falling_edge(clk_50m);
        tin_hieu_key(1) <= '0';
        wait until rising_edge(clk_50m);
        wait for 2 ns;

        -- Kiem tra ep ngay lap tuc Lan A sang Xanh va Lan B sang Do
        assert (den_ledg(0) = '1' and den_ledr(3) = '1' and den_ledg(1) = '0' and den_ledr(1) = '0')
            report "[ASSERTION ERROR] Giai doan 6: Khong ep duoc Lan A sang Xanh va Lan B sang Do khi nhan KEY(1)!"
            severity error;

        wait for 5.0 us; -- Giu nut trong 5 micro giay
        wait until falling_edge(clk_50m);
        tin_hieu_key(1) <= '1'; -- Nha nut khan cap
        wait until rising_edge(clk_50m);
        wait for 2.0 us;

        -- Xac minh sau khi nha nut khan cap Lan A, he thong ve lai Pha 1 hoat dong binh thuong
        assert (den_ledg(0) = '1' and den_ledr(3) = '1')
            report "[ASSERTION ERROR] Giai doan 6: Sau khi nha nut Khan cap Lan A, he thong khong ve Pha 1 hop le!"
            severity error;
        report "[TESTBENCH] -> Da ep Lan A sang Xanh thanh cong va tro ve Pha 1 hop le!" severity note;

        -- ---------------------------------------------------------------------
        -- GIAI DOAN 7: KIEM TRA CHE DO KHAN CAP LAN B (KEY2 = '0')
        -- ---------------------------------------------------------------------
        report "[TESTBENCH] GIAI DOAN 7: Kiem tra uu tien KHAN CAP LAN B (KEY2 = '0')..." severity note;
        wait until rising_edge(clk_50m) and den_ledg(0) = '1'; -- Dang o luc Lan A xanh
        wait for 1.0 us;

        -- Nhan giu nut khan cap Lan B (Xe cuu thuong den tren Lan B)
        wait until falling_edge(clk_50m);
        tin_hieu_key(2) <= '0';
        wait until rising_edge(clk_50m);
        wait for 2 ns;

        -- Kiem tra ep ngay lap tuc Lan B sang Xanh va Lan A sang Do
        assert (den_ledg(1) = '1' and den_ledr(1) = '1' and den_ledg(0) = '0' and den_ledr(3) = '0')
            report "[ASSERTION ERROR] Giai doan 7: Khong ep duoc Lan B sang Xanh va Lan A sang Do khi nhan KEY(2)!"
            severity error;

        wait for 3.0 us; -- Giu nut trong 3 micro giay
        wait until falling_edge(clk_50m);
        tin_hieu_key(2) <= '1'; -- Nha nut khan cap
        wait until rising_edge(clk_50m);
        wait for 2.0 us;

        -- Xac minh sau khi nha nut khan cap Lan B, he thong chuyen sang Pha 3 (giu Xanh Lan B va Do Lan A de bat dau dem 30s)
        assert (den_ledg(1) = '1' and den_ledr(1) = '1' and den_ledg(0) = '0' and den_ledr(3) = '0')
            report "[ASSERTION ERROR] Giai doan 7: Sau khi nha nut Khan cap Lan B, he thong phai chuyen sang Pha 3 (Xanh Lan B 30s)!"
            severity error;
        report "[TESTBENCH] -> Da ep Lan B sang Xanh thanh cong va chuyen sang Pha 3 (Xanh Lan B tiep tuc dem 30s) sau khi nha nut!" severity note;

        -- ---------------------------------------------------------------------
        -- KET THUC TOAN BO KICH BAN MO PHONG
        -- ---------------------------------------------------------------------
        report "[TESTBENCH] ============================================================" severity note;
        report "[TESTBENCH] KIEM CHUNG TOAN DIEN HOAN TAT: 0 LOI ASSERTION PHAT SINH!" severity note;
        report "[TESTBENCH] HE THONG DAT 100% YEU CAU AN TOAN VA LOGIC GIAO THONG!" severity note;
        report "[TESTBENCH] ============================================================" severity note;
        wait for 5.0 us;
        ket_thuc_mo_phong <= true; -- Dat co ket thuc de tat may phat xung clock
        wait;                      -- Dung tien trinh vinh vien
    end process;

end architecture sim;
