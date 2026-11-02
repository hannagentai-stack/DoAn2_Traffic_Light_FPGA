library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity test_onboard_leds is
    port (
        clk_50m : in  std_logic;                     -- Thạch anh 50 MHz (chân PIN_24)
        leds    : out std_logic_vector(4 downto 0)   -- 5 LED onboard: PIN_1, PIN_2, PIN_3, PIN_7, PIN_11
    );
end entity test_onboard_leds;

architecture rtl of test_onboard_leds is

    -- 50 MHz = 50.000.000 xung/giây
    -- 0.5s sáng, 0.5s tắt (1 Hz) = 25.000.000 xung
    constant HALF_SEC : natural := 25000000;
    
    signal counter   : natural range 0 to HALF_SEC - 1 := 0;
    signal led_state : std_logic := '0';

begin

    process(clk_50m)
    begin
        if rising_edge(clk_50m) then
            if counter = HALF_SEC - 1 then
                counter   <= 0;
                led_state <= not led_state; -- Đảo trạng thái sau mỗi 0.5 giây
            else
                counter   <= counter + 1;
            end if;
        end if;
    end process;

    -- Đèn LED trên bo này là Active-Low (Mức '0' là SÁNG, mức '1' là TẮT)
    -- Xuất ra cả 5 LED in chữ 1, 2, 3, 7, 11 trên bo:
    leds(0) <= led_state;
    leds(1) <= led_state;
    leds(2) <= led_state;
    leds(3) <= led_state;
    leds(4) <= led_state;

end architecture rtl;