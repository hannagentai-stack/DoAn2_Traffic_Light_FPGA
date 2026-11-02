--------------------------------------------------------------------------------
-- DU AN: THIET KE HE THONG DIEU KHIEN DEN GIAO THONG NGA TU TREN FPGA CYCLONE IV
-- MODULE: clk_divider (BO CHIA TAN SO VA TAO NHIP CHUAN)
--
-- MUC DICH HOC TAP:
--   1. Hoc cach chia xung nhip thach anh cao tan (50 MHz) xuong tan so thap (1 Hz).
--   2. Hieu ro nguyen ly "Thiet ke dong bo" (Synchronous Design): Khong bao gio tao
--      xung clock moi (Ripple Clock) ma chi tao xung cho phep (Clock Enable / Tick)
--      de tranh lech pha (Clock Skew).
--   3. Su dung tham so Generic (SIMULATION) de giup mo phong ModelSim nhanh gap
--      1 trieu lan ma khong can sua doi logic cua mach.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all; -- Thu vien chuan ve cac kieu du lieu logic (std_logic, std_logic_vector)
use ieee.numeric_std.all;    -- Thu vien chuan xu ly so hoc (unsigned, signed)

entity clk_divider is
    generic (
        -- Tham so cau hinh che do:
        -- false : Che do nap chip thuc te (dem du 50.000.000 xung clock = 1 giay)
        -- true  : Che do mo phong ModelSim (thu nho con 50 xung clock de xem song tuc thi)
        SIMULATION : boolean := false
    );
    port (
        -- Tin hieu vao (Input)
        clk_50m       : in  std_logic; -- Xung clock goc 50 MHz tu thach anh tren bo mach (PIN_24 hoac PIN_23)
        rst_n         : in  std_logic; -- Tin hieu Reset toan he thong, tich cuc muc thap '0' (Active-Low)
        
        -- Tin hieu ra (Output)
        xung_tick_1hz : out std_logic; -- Xung kich rong dung 1 chu ky clock (20ns), phat ra moi giay 1 lan
        xung_chop_1hz : out std_logic  -- Xung vuong doi xung 50% duty (0.5s muc 1, 0.5s muc 0) de chop den vang
    );
end entity clk_divider;

architecture rtl of clk_divider is

    -- =========================================================================
    -- KHAI BAO HANG SO (CONSTANTS)
    -- =========================================================================
    -- Khi chay thuc te tren phan cung (50 MHz = 50.000.000 chu ky moi giay):
    constant CHU_KY_DAY_PHAN_CUNG  : natural := 50000000; -- 50 trieu chu ky cho 1 giay day du
    constant NUA_CHU_KY_PHAN_CUNG  : natural := 25000000; -- 25 trieu chu ky cho nua giay (duty 50%)

    -- Khi chay mo phong tren ModelSim (rut ngan 1 trieu lan de giam thoi gian cho):
    constant CHU_KY_DAY_MO_PHONG   : natural := 50;       -- 50 chu ky cho 1 giay mo phong
    constant NUA_CHU_KY_MO_PHONG   : natural := 25;       -- 25 chu ky cho nua giay mo phong

    -- =========================================================================
    -- HAM TINH TOAN SO DEM GIOI HAN (FUNCTIONS)
    -- Ham nay chay luc bien dich (Compile-time) de tu dong chon nguong dem phu hop
    -- =========================================================================
    function lay_chu_ky_day(co_mo_phong : boolean) return natural is
    begin
        if co_mo_phong then
            return CHU_KY_DAY_MO_PHONG;  -- Neu dang mo phong thi lay nguong 50
        else
            return CHU_KY_DAY_PHAN_CUNG; -- Neu chay tren chip that thi lay 50 trieu
        end if;
    end function;

    function lay_nua_chu_ky(co_mo_phong : boolean) return natural is
    begin
        if co_mo_phong then
            return NUA_CHU_KY_MO_PHONG;  -- Nguong nua chu ky luc mo phong
        else
            return NUA_CHU_KY_PHAN_CUNG; -- Nguong nua chu ky tren chip that
        end if;
    end function;

    -- Tinh toan nguong dem chinh thuc dua vao tham so SIMULATION truyen vao
    constant GIOI_HAN_DEM     : natural := lay_chu_ky_day(SIMULATION);
    constant GIOI_HAN_NUA_DEM : natural := lay_nua_chu_ky(SIMULATION);

    -- =========================================================================
    -- KHAI BAO CAC THANH GHI NOI (INTERNAL SIGNALS / REGISTERS)
    -- =========================================================================
    -- Thanh ghi bo dem so nguyen, Quartus se tu dong tong hop thanh khoang 26 Flip-Flop
    signal thanh_ghi_dem  : natural range 0 to GIOI_HAN_DEM - 1 := 0;

    -- Thanh ghi luu trang thai logic cua xung chop 1Hz (khoi tao bang '1')
    signal thanh_ghi_chop : std_logic := '1';

    -- Thanh ghi luu xung kich tick 1Hz (khoi tao bang '0')
    signal thanh_ghi_tick : std_logic := '0';

begin

    -- =========================================================================
    -- TIEN TRINH CHIA TAN DONG BO (SYNCHRONOUS DIVIDER PROCESS)
    -- Nhay theo suon duong cua clock goc 50 MHz (rising_edge)
    -- Ho tro Reset bat dong bo muc thap (rst_n = '0')
    -- =========================================================================
    process(clk_50m, rst_n)
    begin
        -- 1. Kiem tra tin hieu Reset he thong
        if rst_n = '0' then
            -- Khi nhan nut Reset (ve 0): Xoa toan bo bo dem va khoi tao lai gia tri ban dau
            thanh_ghi_dem  <= 0;
            thanh_ghi_chop <= '1';
            thanh_ghi_tick <= '0';

        -- 2. Kiem tra suon duong xung clock 50 MHz
        elsif rising_edge(clk_50m) then
            
            -- Truong hop A: Bo dem da dem du 1 giay (cham nguong toi da)
            if thanh_ghi_dem = GIOI_HAN_DEM - 1 then
                thanh_ghi_dem  <= 0;   -- Reset bo dem ve 0 de bat dau giay tiep theo
                thanh_ghi_tick <= '1'; -- Phat xung tick len muc 1 (CHI TRONG DUNG 1 CHU KY 20ns!)
                thanh_ghi_chop <= '1'; -- Keo xung chop len muc 1 (bat dau nua chu ky sang)

            -- Truong hop B: Bo dem da dem du nua giay
            elsif thanh_ghi_dem = GIOI_HAN_NUA_DEM - 1 then
                thanh_ghi_dem  <= thanh_ghi_dem + 1; -- Tiep tuc tang bo dem len 1
                thanh_ghi_tick <= '0';               -- Xung tick phai ve muc 0
                thanh_ghi_chop <= '0';               -- Ha xung chop ve 0 (bat dau nua chu ky tat)

            -- Truong hop C: Qua trinh dem binh thuong giua cac chu ky
            else
                thanh_ghi_dem  <= thanh_ghi_dem + 1; -- Tang bo dem them 1 don vi
                thanh_ghi_tick <= '0';               -- Dam bao xung tick giu nguyen muc 0
            end if;

        end if;
    end process;

    -- =========================================================================
    -- GAN TIN HIEU RA NGOAI CAC CONG OUTPUT CUA MODULE
    -- =========================================================================
    xung_tick_1hz <= thanh_ghi_tick; -- Dua xung kich 1 chu ky ra khoi dem Timer
    xung_chop_1hz <= thanh_ghi_chop; -- Dua xung vuong chop tat 1Hz ra khoi dieu khien den FSM

end architecture rtl;
