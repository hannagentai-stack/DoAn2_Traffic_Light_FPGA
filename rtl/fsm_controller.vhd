--------------------------------------------------------------------------------
-- DU AN: THIET KE HE THONG DIEU KHIEN DEN GIAO THONG NGA TU TREN FPGA CYCLONE IV
-- MODULE: fsm_controller (KHOI DIEU KHIEN MAY TRANG THAI FSM MOORE)
--
-- MUC DICH HOC TAP:
--   1. Hieu ro kien truc May trang thai huu han (Finite State Machine - FSM).
--   2. Ap dung chuan thiet ke cong nghiep 3-Process cho FSM Moore:
--      - Process 1 (Tuan tu): Luu tru trang thai dong bo theo clock 50 MHz.
--      - Process 2 (To hop): Tinh toan trang thai tiep theo dua tren cac dieu kien uu tien.
--      - Process 3 (To hop): Giai ma tin hieu ngo ra dieu khien den chi dua vao trang thai hien tai.
--   3. Uu diem cua FSM Moore trong giao thong: Ngo ra den on dinh tuyet doi,
--      khong bi anh huong boi xung nhon (glitches) tu cac nut nhan ngoai vi.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all; -- Thu vien logic co ban
use ieee.numeric_std.all;    -- Thu vien toan hoc so hoc

entity fsm_controller is
    port (
        -- Tin hieu dieu khien goc va dong bo
        clk_50m          : in  std_logic;                     -- Xung clock 50 MHz tu thach anh
        rst_n            : in  std_logic;                     -- Xung Reset he thong (muc 0 la Reset)
        xung_chop_1hz    : in  std_logic;                     -- Xung chop tat 1 Hz nhan tu clk_divider
        co_het_gio       : in  std_logic;                     -- Co bao het thoi gian pha tu timer_counter
        
        -- Tin hieu ngo vao tu nut nhan va cong tac ngoai vi
        sw_ban_dem       : in  std_logic;                     -- Cong tac gat che do ban dem (SW0)
        sw_tam_dung      : in  std_logic;                     -- Cong tac gat tam dung bo dem (SW1)
        key_khan_cap_a_n : in  std_logic;                     -- Nut bam uu tien khan cap Lan A (KEY1 - Active-Low)
        key_khan_cap_b_n : in  std_logic;                     -- Nut bam uu tien khan cap Lan B (KEY2 - Active-Low)
        
        -- Tin hieu dieu khien noi bo xuat sang cac module khac
        chon_pha         : out std_logic_vector(1 downto 0);  -- Ma 2-bit bao cho Timer biet dang o pha nao (00, 01, 10, 11)
        nap_pha          : out std_logic;                     -- Xung kich 1 chu ky clock yeu cau Timer nap lai so giay moi
        tat_seg7         : out std_logic;                     -- Tin hieu tat toan bo LED 7 doan khi o che do ban dem
        
        -- Tin hieu dieu khien truc tiep 6 den giao thong (Active-High: '1' la sang den)
        den_do_a         : out std_logic;                     -- Den DO Lan A
        den_vang_a       : out std_logic;                     -- Den VANG Lan A
        den_xanh_a       : out std_logic;                     -- Den XANH Lan A
        den_do_b         : out std_logic;                     -- Den DO Lan B
        den_vang_b       : out std_logic;                     -- Den VANG Lan B
        den_xanh_b       : out std_logic                      -- Den XANH Lan B
    );
end entity fsm_controller;

architecture rtl of fsm_controller is

    -- =========================================================================
    -- DINH NGHIA KIEU DU LIEU LIET KE CHO CAC TRANG THAI (STATE ENUMERATION)
    -- Giup code de doc, truc quan va Quartus se tu dong ma hoa One-Hot toi uu
    -- =========================================================================
    type kieu_trang_thai is (
        PHA_1,      -- Pha 1: Lan A XANH (25s), Lan B DO (28s)
        PHA_2,      -- Pha 2: Lan A VANG (3s),  Lan B DO (3s con lai)
        PHA_3,      -- Pha 3: Lan A DO (33s),   Lan B XANH (30s)
        PHA_4,      -- Pha 4: Lan A DO (3s con lai), Lan B VANG (3s)
        BAN_DEM,    -- Che do dem: Ca 2 lan deu chop den Vang 1 Hz, tat LED 7 doan
        KHAN_CAP,   -- Che do khan cap Lan A: Uu tien Lan A bat den XANH, Lan B bat den DO
        KHAN_CAP_B  -- Che do khan cap Lan B: Uu tien Lan B bat den XANH, Lan A bat den DO
    );

    -- =========================================================================
    -- KHAI BAO CAC THANH GHI TRANG THAI
    -- =========================================================================
    signal trang_thai_hien_tai : kieu_trang_thai := PHA_1; -- Luu trang thai dang hoat dong o chu ky hien tai
    signal trang_thai_ke_tiep   : kieu_trang_thai := PHA_1; -- Tinh toan trang thai se nhay toi o chu ky ke tiep
    signal trang_thai_truoc_do  : kieu_trang_thai := PHA_4; -- Luu trang thai cua chu ky truoc do de bat su kien chuyen pha

begin

    -- =========================================================================
    -- PROCESS 1: THANH GHI TRANG THAI (STATE REGISTER - TUAN TU DONG BO)
    -- Chi lam nhiem vu cap nhat trang thai moi tai suon duong xung clock 50 MHz
    -- =========================================================================
    process(clk_50m, rst_n)
    begin
        -- Kiem tra Reset he thong
        if rst_n = '0' then
            trang_thai_hien_tai <= PHA_1; -- Reset ve trang thai khoi dau la Pha 1
            trang_thai_truoc_do  <= PHA_4; -- Dat trang thai truoc do khac de kich nap thoi gian

        -- Dong bo theo suon duong clock 50 MHz
        elsif rising_edge(clk_50m) then
            trang_thai_hien_tai <= trang_thai_ke_tiep;   -- Chuyen sang trang thai ke tiep
            trang_thai_truoc_do  <= trang_thai_hien_tai; -- Luu lai trang thai vua trai qua
        end if;
    end process;

    -- =========================================================================
    -- MACH PHAT XUNG NAP THOI GIAN CHO TIMER (PULSE GENERATOR)
    -- Bieu thuc to hop: Khi trang_thai_hien_tai KHAC voi trang_thai_truoc_do,
    -- tuc la vua co su kien doi pha, tin hieu nap_pha se vot len '1' dung 1 chu ky clock!
    -- =========================================================================
    nap_pha <= '1' when (trang_thai_hien_tai /= trang_thai_truoc_do) else '0';

    -- =========================================================================
    -- PROCESS 2: MACH TO HOP CHUYEN TRANG THAI (NEXT-STATE COMBINATIONAL LOGIC)
    -- Xem xet toan bo cac ngo vao de quyet dinh trang thai tiep theo theo thu tu uu tien:
    --   Uu tien 1: Nut khan cap Lan A (key_khan_cap_a_n = '0')
    --   Uu tien 2: Nut khan cap Lan B (key_khan_cap_b_n = '0')
    --   Uu tien 3: Cong tac ban dem (sw_ban_dem = '1')
    --   Uu tien 4: Cong tac tam dung (sw_tam_dung = '1')
    --   Uu tien 5: Chuyen pha tuan tu binh thuong khi co_het_gio = '1'
    -- =========================================================================
    process(trang_thai_hien_tai, key_khan_cap_a_n, key_khan_cap_b_n, sw_ban_dem, sw_tam_dung, co_het_gio)
    begin
        -- Mac dinh giu nguyen trang thai hien tai neu khong co su kien moi
        trang_thai_ke_tiep <= trang_thai_hien_tai;

        -- 1. Uu tien cao nhat: Nhan nut uu tien xe cuu thuong Lan A
        if key_khan_cap_a_n = '0' then
            trang_thai_ke_tiep <= KHAN_CAP;

        -- 2. Uu tien nhi: Nhan nut uu tien xe cuu thuong Lan B (doi xung hoan toan voi Lan A)
        elsif key_khan_cap_b_n = '0' then
            trang_thai_ke_tiep <= KHAN_CAP_B;

        -- 3. Uu tien ba: Bat cong tac che do ban dem
        elsif sw_ban_dem = '1' then
            trang_thai_ke_tiep <= BAN_DEM;

        -- 4. Khi dang o che do Khan cap Lan A hoac Ban dem ma nha nut/tat cong tac: Quay ve Pha 1 (Xanh A)
        elsif trang_thai_hien_tai = KHAN_CAP or trang_thai_hien_tai = BAN_DEM then
            trang_thai_ke_tiep <= PHA_1;

        -- 5. Khi dang o che do Khan cap Lan B ma nha nut: Chuyen sang Pha 3 (cap tron ven 30s Xanh B cho Lan B)
        elsif trang_thai_hien_tai = KHAN_CAP_B then
            trang_thai_ke_tiep <= PHA_3;

        -- 6. Kiem tra cong tac tam dung Pause
        elsif sw_tam_dung = '1' then
            trang_thai_ke_tiep <= trang_thai_hien_tai; -- Dong bang, giu nguyen trang thai

        -- 7. Chu ky hoat dong binh thuong: Chuyen pha khi Timer bao co_het_gio = '1'
        else
            case trang_thai_hien_tai is
                when PHA_1 =>
                    if co_het_gio = '1' then
                        trang_thai_ke_tiep <= PHA_2; -- Het Pha 1 thi sang Pha 2 (Vang A - Do B)
                    end if;

                when PHA_2 =>
                    if co_het_gio = '1' then
                        trang_thai_ke_tiep <= PHA_3; -- Het Pha 2 thi sang Pha 3 (Do A - Xanh B)
                    end if;

                when PHA_3 =>
                    if co_het_gio = '1' then
                        trang_thai_ke_tiep <= PHA_4; -- Het Pha 3 thi sang Pha 4 (Do A - Vang B)
                    end if;

                when PHA_4 =>
                    if co_het_gio = '1' then
                        trang_thai_ke_tiep <= PHA_1; -- Het Pha 4 quay lai Pha 1 (Xanh A - Do B)
                    end if;

                when others =>
                    trang_thai_ke_tiep <= PHA_1; -- Phong ngua trang thai khong xac dinh
            end case;
        end if;
    end process;

    -- =========================================================================
    -- PROCESS 3: MACH TO HOP GIAI MA NGO RA (MOORE OUTPUT LOGIC)
    -- Tuan thu nguyen ly Moore: Tin hieu den chi duoc giai ma dua tren trang_thai_hien_tai.
    -- Dieu nay giup den hoat dong on dinh tuyet doi va khong bi nhap nhay.
    -- =========================================================================
    process(trang_thai_hien_tai, xung_chop_1hz)
    begin
        -- Khoi tao mac dinh tat ca cac ngo ra ve muc an toan (tranh latch khong mong muon)
        chon_pha   <= "00";
        tat_seg7   <= '0';
        den_do_a   <= '0';
        den_vang_a <= '0';
        den_xanh_a <= '0';
        den_do_b   <= '0';
        den_vang_b <= '0';
        den_xanh_b <= '0';

        case trang_thai_hien_tai is
            -- -----------------------------------------------------------------
            -- PHA 1: Lan A duoc di (XANH), Lan B phai dung (DO)
            -- -----------------------------------------------------------------
            when PHA_1 =>
                chon_pha   <= "00"; -- Bao Timer nap thoi gian Pha 1
                den_xanh_a <= '1';  -- Bat den XANH Lan A
                den_do_b   <= '1';  -- Bat den DO Lan B

            -- -----------------------------------------------------------------
            -- PHA 2: Lan A giam toc chuan bi dung (VANG), Lan B van dung (DO)
            -- -----------------------------------------------------------------
            when PHA_2 =>
                chon_pha   <= "01"; -- Bao Timer nap thoi gian Pha 2
                den_vang_a <= '1';  -- Bat den VANG Lan A
                den_do_b   <= '1';  -- Bat den DO Lan B

            -- -----------------------------------------------------------------
            -- PHA 3: Lan A phai dung (DO), Lan B duoc di (XANH)
            -- -----------------------------------------------------------------
            when PHA_3 =>
                chon_pha   <= "10"; -- Bao Timer nap thoi gian Pha 3
                den_do_a   <= '1';  -- Bat den DO Lan A
                den_xanh_b <= '1';  -- Bat den XANH Lan B

            -- -----------------------------------------------------------------
            -- PHA 4: Lan A van dung (DO), Lan B giam toc chuan bi dung (VANG)
            -- -----------------------------------------------------------------
            when PHA_4 =>
                chon_pha   <= "11"; -- Bao Timer nap thoi gian Pha 4
                den_do_a   <= '1';  -- Bat den DO Lan A
                den_vang_b <= '1';  -- Bat den VANG Lan B

            -- -----------------------------------------------------------------
            -- CHE DO BAN DEM: Chop vang ca 2 lan de canh bao giam toc do
            -- -----------------------------------------------------------------
            when BAN_DEM =>
                chon_pha   <= "00";
                tat_seg7   <= '1';          -- Tat het cac thanh LED 7 doan de tiet kiem dien
                den_vang_a <= xung_chop_1hz; -- Den VANG Lan A chop theo nhip 1 Hz
                den_vang_b <= xung_chop_1hz; -- Den VANG Lan B chop theo nhip 1 Hz

            -- -----------------------------------------------------------------
            -- CHE DO KHAN CAP: Uu tien thong xe tuyen chinh Lan A
            -- -----------------------------------------------------------------
            when KHAN_CAP =>
                chon_pha   <= "00";
                den_xanh_a <= '1'; -- Uu tien bat ngay den XANH Lan A cho xe cuu thuong
                den_do_b   <= '1'; -- Bat den DO Lan B chan tuyen cat ngang

            -- -----------------------------------------------------------------
            -- CHE DO KHAN CAP LAN B: Uu tien thong xe tuyen Lan B
            -- -----------------------------------------------------------------
            when KHAN_CAP_B =>
                chon_pha   <= "10";
                den_do_a   <= '1'; -- Bat den DO Lan A chan tuyen cat ngang
                den_xanh_b <= '1'; -- Uu tien bat ngay den XANH Lan B cho xe cuu thuong

            -- -----------------------------------------------------------------
            -- TRUONG HOP BAT THUONG: An toan nhat la bat den Do ca 2 lan
            -- -----------------------------------------------------------------
            when others =>
                chon_pha <= "00";
                den_do_a <= '1';
                den_do_b <= '1';
        end case;
    end process;

end architecture rtl;
