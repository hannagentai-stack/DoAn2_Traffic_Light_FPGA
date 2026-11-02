--------------------------------------------------------------------------------
-- DU AN: TEST CHOP TAT 1 LED TREN CHAN GPIO NGOAI & LED ONBOARD
-- Chip muc tieu: Altera / Intel Cyclone IV E (EP4CE6E22C8N)
-- Tan so thach anh: 50 MHz (PIN_24)
-- Chan GPIO ngoai: PIN_38 (Top Header - Active-High: '1' la sang LED)
-- Chan LED tren bo: PIN_1 (Onboard D1 - Active-Low: '0' la sang LED)
-- Tan so chop tat: 1 Hz (0.5 giay sang, 0.5 giay tat)
--------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity led_blink is
    port (
        clk_50mhz   : in  std_logic; -- Xung thach anh 50MHz tren kit (PIN_24)
        led_gpio    : out std_logic; -- Chan GPIO ngoai (PIN_38, noi qua tro 220-330R ra LED xuong GND)
        led_onboard : out std_logic  -- Chan LED co san tren bo mach (PIN_1)
    );
end entity led_blink;

architecture Behavioral of led_blink is
    -- Thach anh 50 MHz co chu ky T = 20 ns, tuong ung 50,000,000 xung trong 1 giay.
    -- De LED dao trang thai sau moi 0.5 giay (chu ky chop tat 1s), ta dem:
    -- 50,000,000 / 2 = 25,000,000 chu ky xung nhip.
    constant GIOI_HAN_DEM : integer := 25000000;
    
    -- Bien dem so chu ky xung nhip
    signal bo_dem         : integer range 0 to GIOI_HAN_DEM := 0;
    
    -- Tin hieu luu trang thai logic cua LED ('0' hoac '1')
    signal trang_thai_led : std_logic := '0';
begin

    -- Tien trinh dem xung nhip 50MHz de tao nhip chop tat 0.5s
    process(clk_50mhz)
    begin
        if rising_edge(clk_50mhz) then
            if bo_dem >= GIOI_HAN_DEM - 1 then
                bo_dem <= 0;
                trang_thai_led <= not trang_thai_led; -- Dao trang thai LED sau moi 0.5s
            else
                bo_dem <= bo_dem + 1;
            end if;
        end if;
    end process;

    -- 1. Xuat tin hieu ra chan GPIO ngoai PIN_38 (Active-High: '1' la sang)
    led_gpio <= trang_thai_led;

    -- 2. Xuat tin hieu ra chan LED Onboard PIN_1 (Active-Low tren kit nen can dao lai)
    -- Khi led_gpio = '1' (sang), led_onboard = '0' (cung sang dong bo)
    led_onboard <= not trang_thai_led;

end architecture Behavioral;
