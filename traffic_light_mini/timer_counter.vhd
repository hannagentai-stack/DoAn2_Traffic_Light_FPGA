--------------------------------------------------------------------------------
-- DU AN: THIET KE HE THONG DIEU KHIEN DEN GIAO THONG NGA TU TREN FPGA CYCLONE IV
-- MODULE: timer_counter (BO DEM LUI THOI GIAN VA CHUYEN DOI MA BCD)
--
-- MUC DICH HOC TAP:
--   1. Hoc cach thiet ke bo dem lui dong bo (Synchronous Down-Counter) theo nhip tick 1Hz.
--   2. Hieu ro ky thuat nạp thoi gian khoi tao tuong ung voi tung pha giao thong.
--   3. BI QUYET THIET KE TOI UU TREN FPGA:
--      Chuyen doi nhi phan sang BCD (hang chuc va hang don vi) KHONG DUNG PHEP CHIA (/ 10)
--      hay phep chia lay du (mod 10). Phep chia tren FPGA rat nang, ton nhieu LE va cham.
--      Thay vao do, ta dung chuoi so sanh tru (>= 30, >= 20, >= 10) de bo tong hop tao ra
--      mach tru nhi phan don gian, sieu nhanh va tiet kiem tai nguyen chip.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all; -- Thu vien logic co ban
use ieee.numeric_std.all;    -- Thu vien toan hoc so hoc

entity timer_counter is
    port (
        -- Tin hieu clock va dieu khien dong bo
        clk_50m      : in  std_logic;                     -- Xung clock 50 MHz tu thach anh
        rst_n        : in  std_logic;                     -- Xung Reset he thong (muc 0 la Reset)
        xung_tick_1hz: in  std_logic;                     -- Xung kich moi giay 1 lan tu clk_divider
        tam_dung     : in  std_logic;                     -- Cong tac gat tam dung bo dem (Pause)
        nap_pha      : in  std_logic;                     -- Xung yeu cau nap thoi gian moi tu fsm_controller
        chon_pha     : in  std_logic_vector(1 downto 0);  -- Ma pha hien tai (00: Pha 1, 01: Pha 2, 10: Pha 3, 11: Pha 4)
        
        -- Tin hieu bao ket thuc pha
        co_het_gio   : out std_logic;                     -- Phat len '1' dung 1 xung clock khi dem het thoi gian
        
        -- Tin hieu BCD 4-bit xuat ra khoi giai ma LED 7 doan
        bcd_a_chuc   : out std_logic_vector(3 downto 0);  -- Chu so hang chuc thoi gian Lan A (0 .. 9)
        bcd_a_don_vi : out std_logic_vector(3 downto 0);  -- Chu so hang don vi thoi gian Lan A (0 .. 9)
        bcd_b_chuc   : out std_logic_vector(3 downto 0);  -- Chu so hang chuc thoi gian Lan B (0 .. 9)
        bcd_b_don_vi : out std_logic_vector(3 downto 0)   -- Chu so hang don vi thoi gian Lan B (0 .. 9)
    );
end entity timer_counter;

architecture rtl of timer_counter is

    -- =========================================================================
    -- KHAI BAO CAC THANH GHI DEM THOI GIAN (RANGE 0 DEN 63 CHIEM 6-BIT LOGIC)
    -- =========================================================================
    signal dem_lan_a         : natural range 0 to 63 := 25; -- Bien dem thoi gian con lai cua Lan A
    signal dem_lan_b         : natural range 0 to 63 := 28; -- Bien dem thoi gian con lai cua Lan B
    signal thanh_ghi_het_gio : std_logic := '0';            -- Thanh ghi luu co bao het gio

    -- =========================================================================
    -- THU TUC (PROCEDURE) TACH SO NHI PHAN SANG MA BCD BANG CHUOI SO SANH TRU
    -- Khong dung phep chia (/), chi dung cac bo so sanh va tru co ban tren FPGA.
    -- =========================================================================
    procedure chuyen_sang_bcd(
        gia_tri_vao : in  natural range 0 to 63;
        chuc_ra     : out std_logic_vector(3 downto 0);
        don_vi_ra   : out std_logic_vector(3 downto 0)
    ) is
    begin
        -- So sanh tu lon den nho de xac dinh hang chuc
        if gia_tri_vao >= 60 then
            chuc_ra   := "0110"; -- Hang chuc la 6
            don_vi_ra := std_logic_vector(to_unsigned(gia_tri_vao - 60, 4));
        elsif gia_tri_vao >= 50 then
            chuc_ra   := "0101"; -- Hang chuc la 5
            don_vi_ra := std_logic_vector(to_unsigned(gia_tri_vao - 50, 4));
        elsif gia_tri_vao >= 40 then
            chuc_ra   := "0100"; -- Hang chuc la 4
            don_vi_ra := std_logic_vector(to_unsigned(gia_tri_vao - 40, 4));
        elsif gia_tri_vao >= 30 then
            chuc_ra   := "0011"; -- Hang chuc la 3
            don_vi_ra := std_logic_vector(to_unsigned(gia_tri_vao - 30, 4));
        elsif gia_tri_vao >= 20 then
            chuc_ra   := "0010"; -- Hang chuc la 2
            don_vi_ra := std_logic_vector(to_unsigned(gia_tri_vao - 20, 4));
        elsif gia_tri_vao >= 10 then
            chuc_ra   := "0001"; -- Hang chuc la 1
            don_vi_ra := std_logic_vector(to_unsigned(gia_tri_vao - 10, 4));
        else
            chuc_ra   := "0000"; -- Hang chuc la 0 (tu 0 den 9)
            don_vi_ra := std_logic_vector(to_unsigned(gia_tri_vao, 4));
        end if;
    end procedure;

begin

    -- =========================================================================
    -- PROCESS: BO DEM LUI DONG BO (SYNCHRONOUS DOWN-COUNTER)
    -- Tuan theo xung clock 50 MHz va su dung tin hieu xung_tick_1hz lam Clock Enable
    -- =========================================================================
    process(clk_50m, rst_n)
    begin
        -- 1. Kiem tra Reset he thong
        if rst_n = '0' then
            dem_lan_a         <= 25; -- Mac dinh khoi dau Lan A con 25s
            dem_lan_b         <= 28; -- Mac dinh khoi dau Lan B con 28s
            thanh_ghi_het_gio <= '0';

        -- 2. Dong bo theo suon duong xung clock 50 MHz
        elsif rising_edge(clk_50m) then
            -- Xoa co het gio ve 0 o moi chu ky clock binh thuong (chi giu muc 1 dung 1 chu ky)
            thanh_ghi_het_gio <= '0';

            -- TH1: Co xung nap thoi gian moi tu FSM (Vua co su kien chuyen pha)
            if nap_pha = '1' then
                case chon_pha is
                    when "00" =>   -- Pha 1: Lan A Xanh, Lan B Do
                        dem_lan_a <= 25;
                        dem_lan_b <= 28;

                    when "01" =>   -- Pha 2: Lan A Vang (3s), Lan B Do (3s con lai)
                        dem_lan_a <= 3;
                        dem_lan_b <= 3;

                    when "10" =>   -- Pha 3: Lan A Do (33s), Lan B Xanh (30s)
                        dem_lan_a <= 33;
                        dem_lan_b <= 30;

                    when "11" =>   -- Pha 4: Lan A Do (3s con lai), Lan B Vang (3s)
                        dem_lan_a <= 3;
                        dem_lan_b <= 3;

                    when others =>
                        dem_lan_a <= 25;
                        dem_lan_b <= 28;
                end case;

            -- TH2: Co xung tick 1 giay va khong bi gat cong tac tam dung Pause
            elsif xung_tick_1hz = '1' and tam_dung = '0' then
                
                -- Kiem tra xem pha hien tai da dem den giay cuoi cung (mốc 1s) chua
                case chon_pha is
                    when "00" | "01" =>
                        -- O Pha 1 va Pha 2: Lan A la lan quyet dinh thoi gian chuyen pha
                        if dem_lan_a = 1 then
                            thanh_ghi_het_gio <= '1'; -- Kich co bao het gio de FSM chuyen pha
                        end if;

                    when "10" | "11" =>
                        -- O Pha 3 va Pha 4: Lan B la lan quyet dinh thoi gian chuyen pha
                        if dem_lan_b = 1 then
                            thanh_ghi_het_gio <= '1'; -- Kich co bao het gio de FSM chuyen pha
                        end if;

                    when others =>
                        null;
                end case;

                -- Thuc hien giam bien dem thoi gian tung giay (khong giam qua 1 truoc khi doi pha)
                if dem_lan_a > 1 then
                    dem_lan_a <= dem_lan_a - 1;
                end if;

                if dem_lan_b > 1 then
                    dem_lan_b <= dem_lan_b - 1;
                end if;

            end if;
        end if;
    end process;

    -- Xuat co bao het gio ra cho FSM
    co_het_gio <= thanh_ghi_het_gio;

    -- =========================================================================
    -- PROCESS: MACH TO HOP GIAI MA BCD LIEN TUC
    -- Chuyen doi gia tri so nguyen dem_lan_a va dem_lan_b sang ma BCD 4-bit
    -- =========================================================================
    process(dem_lan_a, dem_lan_b)
        variable tam_chuc_a, tam_don_vi_a : std_logic_vector(3 downto 0);
        variable tam_chuc_b, tam_don_vi_b : std_logic_vector(3 downto 0);
    begin
        -- Goi thu tuc tach so BCD cho Lan A
        chuyen_sang_bcd(dem_lan_a, tam_chuc_a, tam_don_vi_a);
        -- Goi thu tuc tach so BCD cho Lan B
        chuyen_sang_bcd(dem_lan_b, tam_chuc_b, tam_don_vi_b);

        -- Gan gia tri ra cac cong BCD cua module
        bcd_a_chuc   <= tam_chuc_a;
        bcd_a_don_vi <= tam_don_vi_a;
        bcd_b_chuc   <= tam_chuc_b;
        bcd_b_don_vi <= tam_don_vi_b;
    end process;

end architecture rtl;
