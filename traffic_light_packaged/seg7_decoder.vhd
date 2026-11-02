--------------------------------------------------------------------------------
-- DU AN: THIET KE HE THONG DIEU KHIEN DEN GIAO THONG NGA TU TREN FPGA CYCLONE IV
-- MODULE: seg7_decoder (KHOI GIAI MA BCD SANG LED 7 DOAN ACTIVE-HIGH CATHODE CHUNG)
--
-- MUC DICH HOC TAP:
--   1. Hieu ro kien truc mach to hop giai ma (Combinational Decoder).
--   2. Nam vung quy uoc ma hoa LED 7 doan Active-High (Cuc Am chung / Cathode chung):
--      - Bit '1' : Thanh LED SANG (FPGA xuat 3.3V qua dien tro 330 Ohm vao Anode thanh doan).
--      - Bit '0' : Thanh LED TAT  (FPGA xuat 0V).
--      - Chuc nang dem dong: 4 chan DIG Cathode duoc keo xuong GND boi 1 IC ULN2003 duy nhat!
--   3. Thu tu 7 thanh doan tu bit 6 xuong bit 0: (g, f, e, d, c, b, a).
--   4. Tich hop chan tat_led (Blanking): Dung de ngat sang toan bo khi o che do ban dem.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all; -- Thu vien logic co ban
use ieee.numeric_std.all;    -- Thu vien toan hoc so hoc

entity seg7_decoder is
    port (
        -- Tin hieu vao
        bcd_vao : in  std_logic_vector(3 downto 0); -- Ma BCD 4-bit bieu dien cac so tu 0 den 9
        tat_led : in  std_logic;                    -- Chan dieu khien tat man hinh (Blanking: '1' la tat het)
        
        -- Tin hieu ra
        seg7_ra : out std_logic_vector(6 downto 0)  -- 7 thanh doan dieu khien cac doan (g, f, e, d, c, b, a)
    );
end entity seg7_decoder;

architecture rtl of seg7_decoder is

begin

    -- =========================================================================
    -- PROCESS: MACH TO HOP GIAI MA KHONG DUNG CLOCK (COMBINATIONAL PROCESS)
    -- Tuan theo bang chan ly chuan cho LED 7 doan Cathode chung (1 la sang, 0 la tat)
    -- =========================================================================
    process(bcd_vao, tat_led)
    begin
        -- Kiem tra tin hieu tat man hinh Blanking
        if tat_led = '1' then
            -- Khi tat_led = '1' (che do ban dem), xuat tat ca muc 0 de tat toan bo 7 thanh LED
            seg7_ra <= "0000000"; 
        else
            -- Giai ma tung gia tri so BCD 4-bit sang ma 7 doan:
            -- Thu tu bit: bit 6 la g, bit 5 la f, bit 4 la e, bit 3 la d, bit 2 la c, bit 1 la b, bit 0 la a
            case bcd_vao is
                -- So 0: Sang cac doan a,b,c,d,e,f (Tat doan g) -> "0111111"
                when "0000" => seg7_ra <= "0111111";

                -- So 1: Sang cac doan b,c (Tat a,d,e,f,g) -> "0000110"
                when "0001" => seg7_ra <= "0000110";

                -- So 2: Sang cac doan a,b,d,e,g (Tat c,f) -> "1011011"
                when "0010" => seg7_ra <= "1011011";

                -- So 3: Sang cac doan a,b,c,d,g (Tat e,f) -> "1001111"
                when "0011" => seg7_ra <= "1001111";

                -- So 4: Sang cac doan b,c,f,g (Tat a,d,e) -> "1100110"
                when "0100" => seg7_ra <= "1100110";

                -- So 5: Sang cac doan a,c,d,f,g (Tat b,e) -> "1101101"
                when "0101" => seg7_ra <= "1101101";

                -- So 6: Sang cac doan a,c,d,e,f,g (Tat b) -> "1111101"
                when "0110" => seg7_ra <= "1111101";

                -- So 7: Sang cac doan a,b,c (Tat d,e,f,g) -> "0000111"
                when "0111" => seg7_ra <= "0000111";

                -- So 8: Sang ca 7 doan a,b,c,d,e,f,g -> "1111111"
                when "1000" => seg7_ra <= "1111111";

                -- So 9: Sang cac doan a,b,c,d,f,g (Tat e) -> "1101111"
                when "1001" => seg7_ra <= "1101111";

                -- Truong hop ma loi (tu 10 den 15): Tat toan bo cac doan LED
                when others => seg7_ra <= "0000000";
            end case;
        end if;
    end process;

end architecture rtl;
