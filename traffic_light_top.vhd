--------------------------------------------------------------------------------
-- DU AN: THIET KE HE THONG DIEU KHIEN DEN GIAO THONG NGA TU TREN FPGA CYCLONE IV
-- MODULE: traffic_light_top (MODULE DINH KET NOI HE THONG & QUET LED DYNAMIC)
--
-- MUC DICH HOC TAP:
--   1. Hoc cach ghep noi kien truc phan tang (Structural Modeling): Ket noi 4 module
--      con (clk_divider, fsm_controller, timer_counter, seg7_decoder) lai thanh 1 he thong.
--   2. Hieu ro ky thuat quet da kenh LED 7 doan (Dynamic Scanning Multiplexing):
--      Quet luon phien giua chu so Hang Chuc va Hang Don Vi voi tan so 1 kHz. Nho hien tuong
--      luu anh quang hoc cua mat nguoi, ta thay ca 2 so sang lien tuc ma van tiet kiem
--      duoc 50% so luong chan I/O tren FPGA!
--   3. Tich hop Mach khoa an toan phan cung (Fail-safe Hardware Interlock):
--      Tu dong ngat ca 2 den xanh va ep bat 2 den do neu he thong bi loi logic, ngan chan
--      tuyet doi nguy co tai nan xe co o nga tu.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all; -- Thu vien logic co ban
use ieee.numeric_std.all;    -- Thu vien toan hoc so hoc

entity traffic_light_top is
    generic (
        -- Tham so mo phong: mac dinh la false (chay that tren phan cung)
        SIMULATION : boolean := false
    );
    port (
        -- 1. Xung nhap thach anh master 50 MHz tu kit FPGA (PIN_24 hoac PIN_23)
        CLOCK_50  : in  std_logic;

        -- 2. Cac nut nhan dieu khien ngoai vi (Active-Low: Bam nut la muc '0')
        --    KEY(0): Nut Reset toan he thong
        --    KEY(1): Nut uu tien khan cap Lan A (Xe cuu thuong / cuu hoa)
        --    KEY(2): Nut uu tien khan cap Lan B (Nhay thang sang Pha 3)
        KEY       : in  std_logic_vector(2 downto 0);

        -- 3. Cac cong tac gat che do hoat dong (Active-Low kem tro keo len noi: Noi GND la Bat, De ho la Tat)
        --    SW(0): Cong tac che do ban dem (Noi GND '0' la bat chop vang 1 Hz; de ho mac dinh chay binh thuong)
        --    SW(1): Cong tac tam dung bo dem thoi gian (Noi GND '0' la bat Pause; de ho mac dinh dem binh thuong)
        SW        : in  std_logic_vector(1 downto 0);

        -- 4. Tin hieu dieu khien den giao thong (Active-High: '1' la sang den)
        --    LEDR(0): Den VANG Lan A   |   LEDR(1): Den DO Lan A
        --    LEDR(2): Den VANG Lan B   |   LEDR(3): Den DO Lan B
        LEDR      : out std_logic_vector(3 downto 0);

        --    LEDG(0): Den XANH Lan A   |   LEDG(1): Den XANH Lan B
        LEDG      : out std_logic_vector(1 downto 0);

        -- 5. Cung cap tin hieu cho LED 7 doan Lan A
        HEX_A_SEG : out std_logic_vector(6 downto 0); -- 7 thanh doan (a..g) Lan A (Active-Low)
        HEX_A_DIG : out std_logic_vector(1 downto 0); -- Chan chon vi tri LED Don vi / Chuc Lan A

        -- 6. Cung cap tin hieu cho LED 7 doan Lan B
        HEX_B_SEG : out std_logic_vector(6 downto 0); -- 7 thanh doan (a..g) Lan B (Active-Low)
        HEX_B_DIG : out std_logic_vector(1 downto 0)  -- Chan chon vi tri LED Don vi / Chuc Lan B
    );
end entity traffic_light_top;

architecture structural of traffic_light_top is

    -- =========================================================================
    -- CAC DUONG DAY TIN HIEU NOI BO (INTERNAL CONNECTING SIGNALS)
    -- Dong vai tro nhu cac day dong ket noi giua cac IC chuc nang
    -- =========================================================================
    signal xung_tick_1hz_s : std_logic;                    -- Day truyen xung kich 1Hz tu clk_divider sang timer_counter
    signal xung_chop_1hz_s : std_logic;                    -- Day truyen xung vuong 1Hz tu clk_divider sang fsm_controller
    signal co_het_gio_s    : std_logic;                    -- Day bao het gio tu timer_counter sang fsm_controller
    signal chon_pha_s      : std_logic_vector(1 downto 0); -- Day bao ma pha tu fsm sang timer
    signal nap_pha_s       : std_logic;                    -- Day phat xung nap so giay tu fsm sang timer
    signal tat_seg7_s      : std_logic;                    -- Day bao tat man hinh tu fsm sang bo giai ma 7 doan

    -- Tin hieu chua ma BCD 4-bit thoi gian
    signal bcd_a_chuc_s    : std_logic_vector(3 downto 0); -- Chu so hang chuc Lan A
    signal bcd_a_don_vi_s  : std_logic_vector(3 downto 0); -- Chu so hang don vi Lan A
    signal bcd_b_chuc_s    : std_logic_vector(3 downto 0); -- Chu so hang chuc Lan B
    signal bcd_b_don_vi_s  : std_logic_vector(3 downto 0); -- Chu so hang don vi Lan B

    -- Tin hieu cong tac gat da qua dao logic (Active-Low kem tro keo len noi)
    signal sw_ban_dem_s    : std_logic; -- '1' khi noi SW(0) xuong GND, '0' khi de ho
    signal sw_tam_dung_s   : std_logic; -- '1' khi noi SW(1) xuong GND, '0' khi de ho

    -- Tin hieu den tho tu FSM truoc khi qua mach khoa an toan Interlock
    signal den_do_a_s      : std_logic;
    signal den_vang_a_s    : std_logic;
    signal den_xanh_a_s    : std_logic;
    signal den_do_b_s      : std_logic;
    signal den_vang_b_s    : std_logic;
    signal den_xanh_b_s    : std_logic;

    -- =========================================================================
    -- CAC TIN HIEU DUNG CHO BO QUET DYNAMIC SCANNING 1 KHZ
    -- =========================================================================
    -- Bo dem 50.000 chu ky clock (50 MHz / 50.000 = 1000 Hz = 1 kHz)
    signal bo_dem_quet     : integer range 0 to 49999 := 0;

    -- Bit chon vi tri LED: '0' la hien thi hang Don vi, '1' la hien thi hang Chuc
    signal chon_vi_tri_led : std_logic := '0';

    -- Bus du lieu BCD sau khi qua bo ghep kenh MUX 2-sang-1
    signal bcd_a_mux       : std_logic_vector(3 downto 0);
    signal bcd_b_mux       : std_logic_vector(3 downto 0);

begin

    -- =========================================================================
    -- KHOI 1: GHEP NOI BO CHIA TAN SO (clk_divider)
    -- =========================================================================
    khoi_chia_tan: entity work.clk_divider
        generic map (
            SIMULATION => SIMULATION -- Truyen tham so mo phong vao
        )
        port map (
            clk_50m       => CLOCK_50,
            rst_n         => KEY(0),
            xung_tick_1hz => xung_tick_1hz_s,
            xung_chop_1hz => xung_chop_1hz_s
        );

    -- Dao logic cong tac de ho tro tro keo len noi (Active-Low):
    -- Khi de ho: SW = '1' -> tin hieu dieu khien = '0' (Khong bat ban dem, khong tam dung)
    -- Khi noi GND: SW = '0' -> tin hieu dieu khien = '1' (Kich hoat ban dem hoac tam dung)
    sw_ban_dem_s  <= not SW(0);
    sw_tam_dung_s <= not SW(1);

    -- =========================================================================
    -- KHOI 2: GHEP NOI BO DIEU KHIEN FSM (fsm_controller)
    -- =========================================================================
    khoi_dieu_khien_fsm: entity work.fsm_controller
        port map (
            clk_50m          => CLOCK_50,
            rst_n            => KEY(0),
            xung_chop_1hz    => xung_chop_1hz_s,
            co_het_gio       => co_het_gio_s,
            sw_ban_dem       => sw_ban_dem_s,
            sw_tam_dung      => sw_tam_dung_s,
            key_khan_cap_a_n => KEY(1),
            key_khan_cap_b_n => KEY(2),
            chon_pha         => chon_pha_s,
            nap_pha          => nap_pha_s,
            tat_seg7         => tat_seg7_s,
            den_do_a         => den_do_a_s,
            den_vang_a       => den_vang_a_s,
            den_xanh_a       => den_xanh_a_s,
            den_do_b         => den_do_b_s,
            den_vang_b       => den_vang_b_s,
            den_xanh_b       => den_xanh_b_s
        );

    -- =========================================================================
    -- KHOI 3: GHEP NOI BO DEM LUI THOI GIAN & BCD (timer_counter)
    -- =========================================================================
    khoi_dem_thoi_gian: entity work.timer_counter
        port map (
            clk_50m       => CLOCK_50,
            rst_n         => KEY(0),
            xung_tick_1hz => xung_tick_1hz_s,
            tam_dung      => sw_tam_dung_s,
            nap_pha       => nap_pha_s,
            chon_pha      => chon_pha_s,
            co_het_gio    => co_het_gio_s,
            bcd_a_chuc    => bcd_a_chuc_s,
            bcd_a_don_vi  => bcd_a_don_vi_s,
            bcd_b_chuc    => bcd_b_chuc_s,
            bcd_b_don_vi  => bcd_b_don_vi_s
        );

    -- =========================================================================
    -- KHOI 4: MACH QUET DYNAMIC SCANNING 1 KHZ CHO LED 7 DOAN
    -- Moi chu ky 1 ms (50.000 xung 50MHz), tin hieu chon_vi_tri_led dao trang thai
    -- giup chuyen doi qua lai giua chu so Don vi va chu so Chuc voi toc do cuc nhanh
    -- =========================================================================
    process(CLOCK_50, KEY(0))
    begin
        if KEY(0) = '0' then
            bo_dem_quet     <= 0;
            chon_vi_tri_led <= '0';
        elsif rising_edge(CLOCK_50) then
            if bo_dem_quet = 49999 then
                bo_dem_quet     <= 0;
                chon_vi_tri_led <= not chon_vi_tri_led; -- Dao vi tri: 0 sang 1, 1 ve 0
            else
                bo_dem_quet     <= bo_dem_quet + 1;
            end if;
        end if;
    end process;

    -- Bo ghep kenh MUX 2-sang-1 lua chon du lieu BCD can giai ma:
    -- Khi chon_vi_tri_led = '0': Lay so hang Don vi
    -- Khi chon_vi_tri_led = '1': Lay so hang Chuc
    bcd_a_mux <= bcd_a_don_vi_s when chon_vi_tri_led = '0' else bcd_a_chuc_s;
    bcd_b_mux <= bcd_b_don_vi_s when chon_vi_tri_led = '0' else bcd_b_chuc_s;

    -- Dieu khien chan chon vi tri LED (DIGIT SELECT - Anode chung: cap 3.3V muc 1 vao cuc Duong chung):
    -- Khi chon_vi_tri_led = '0': Lay so hang Don vi -> Xuat '1' (3.3V) vao DIG Don vi
    -- Khi chon_vi_tri_led = '1': Lay so hang Chuc   -> Xuat '1' (3.3V) vao DIG Chuc
    -- Khi tat_seg7_s = '1' (Ban dem): Xuat '0' de ngat nguon ca 2 vi tri LED
    HEX_A_DIG(0) <= '1' when (chon_vi_tri_led = '0' and tat_seg7_s = '0') else '0'; -- Bat LED Don vi Lan A (Cap 3.3V Anode)
    HEX_A_DIG(1) <= '1' when (chon_vi_tri_led = '1' and tat_seg7_s = '0') else '0'; -- Bat LED Chuc Lan A (Cap 3.3V Anode)
    HEX_B_DIG(0) <= '1' when (chon_vi_tri_led = '0' and tat_seg7_s = '0') else '0'; -- Bat LED Don vi Lan B (Cap 3.3V Anode)
    HEX_B_DIG(1) <= '1' when (chon_vi_tri_led = '1' and tat_seg7_s = '0') else '0'; -- Bat LED Chuc Lan B (Cap 3.3V Anode)

    -- =========================================================================
    -- KHOI 5: GHEP NOI 2 BO GIAI MA 7 DOAN CHO LAN A VA LAN B
    -- Nho co ky thuat quet da kenh, ta chi can 2 IC giai ma thay vi can toi 4 IC!
    -- =========================================================================
    khoi_giai_ma_hex_a: entity work.seg7_decoder
        port map (
            bcd_vao => bcd_a_mux,
            tat_led => tat_seg7_s,
            seg7_ra => HEX_A_SEG
        );

    khoi_giai_ma_hex_b: entity work.seg7_decoder
        port map (
            bcd_vao => bcd_b_mux,
            tat_led => tat_seg7_s,
            seg7_ra => HEX_B_SEG
        );

    -- =========================================================================
    -- KHOI 6: MACH KHOA AN TOAN PHAN CUNG (FAIL-SAFE HARDWARE INTERLOCK)
    -- Giam sat tin hieu den tho tu FSM. Neu xay ra tinh huong nguy hiem (Ca 2 lan deu XANH),
    -- mach phan cung lap tuc can thiep: Ngat 2 den xanh va ep bat 2 den do de chong dam xe!
    -- =========================================================================
    process(den_xanh_a_s, den_xanh_b_s, den_vang_a_s, den_vang_b_s, den_do_a_s, den_do_b_s)
    begin
        -- Kiem tra tinh huong cam: Ca Lan A va Lan B deu bat den XANH
        if (den_xanh_a_s = '1' and den_xanh_b_s = '1') then
            -- Kich hoat che do bao ve nguy cap:
            LEDG(0) <= '0'; -- Ep tat den XANH Lan A
            LEDG(1) <= '0'; -- Ep tat den XANH Lan B
            LEDR(0) <= '0'; -- Tat vang Lan A
            LEDR(1) <= '1'; -- Ep bat den DO Lan A
            LEDR(2) <= '0'; -- Tat vang Lan B
            LEDR(3) <= '1'; -- Ep bat den DO Lan B
        else
            -- Hoat dong binh thuong: Xuat truc tiep tin hieu den tu FSM ra cac cong
            LEDG(0) <= den_xanh_a_s; -- Den Xanh Lan A
            LEDG(1) <= den_xanh_b_s; -- Den Xanh Lan B
            LEDR(0) <= den_vang_a_s; -- Den Vang Lan A
            LEDR(1) <= den_do_a_s;   -- Den Do Lan A
            LEDR(2) <= den_vang_b_s; -- Den Vang Lan B
            LEDR(3) <= den_do_b_s;   -- Den Do Lan B
        end if;
    end process;

end architecture structural;
