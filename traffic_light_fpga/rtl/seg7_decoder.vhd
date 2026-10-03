--------------------------------------------------------------------------------
-- Project   : DE2-115 FPGA Traffic Light Controller
-- File      : seg7_decoder.vhd
-- Standard  : IEEE 1164 & numeric_std
-- Target    : Altera Cyclone IV E (EP4CE115F29C7)
-- Description:
--   Active-Low 7-Segment Decoder with Blanking support.
--   - Maps 4-bit BCD input (0-9) to 7 segments (g, f, e, d, c, b, a).
--   - Active-Low: '0' = segment ON (illuminated), '1' = segment OFF.
--   - Blanking input: when blank = '1', forces all segments OFF ("1111111").
--   - Invalid BCD inputs (10-15) are safely blanked to "1111111".
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity seg7_decoder is
    port (
        bcd_in  : in  std_logic_vector(3 downto 0);
        blank   : in  std_logic;
        seg_out : out std_logic_vector(6 downto 0)
    );
end entity seg7_decoder;

architecture rtl of seg7_decoder is
begin

    process(bcd_in, blank)
    begin
        if blank = '1' then
            seg_out <= "1111111"; -- Blank (All OFF)
        else
            case bcd_in is
                when "0000" => seg_out <= "1000000"; -- '0' (0x40)
                when "0001" => seg_out <= "1111001"; -- '1' (0x79)
                when "0010" => seg_out <= "0100100"; -- '2' (0x24)
                when "0011" => seg_out <= "0110000"; -- '3' (0x30)
                when "0100" => seg_out <= "0011001"; -- '4' (0x19)
                when "0101" => seg_out <= "0010010"; -- '5' (0x12)
                when "0110" => seg_out <= "0000010"; -- '6' (0x02)
                when "0111" => seg_out <= "1111000"; -- '7' (0x78)
                when "1000" => seg_out <= "0000000"; -- '8' (0x00)
                when "1001" => seg_out <= "0010000"; -- '9' (0x10)
                when others => seg_out <= "1111111"; -- Blank for invalid BCD
            end case;
        end if;
    end process;

end architecture rtl;
