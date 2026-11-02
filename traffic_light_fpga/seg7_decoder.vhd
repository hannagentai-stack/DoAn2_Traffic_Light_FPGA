library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity seg7_decoder is
    port (
        bcd_in  : in  std_logic_vector(3 downto 0);
        blank   : in  std_logic;
        seg_out : out std_logic_vector(6 downto 0)
    );
end 
entity seg7_decoder;

architecture rtl of seg7_decoder is

begin

    
process(bcd_in, blank)
    
begin

        if blank = '1' then
            seg_out <= "1111111";
        else
            case bcd_in is
                when "0000" => seg_out <= "1000000";
                when "0001" => seg_out <= "1111001";
                when "0010" => seg_out <= "0100100";
                when "0011" => seg_out <= "0110000";
                when "0100" => seg_out <= "0011001";
                when "0101" => seg_out <= "0010010";
                when "0110" => seg_out <= "0000010";
                when "0111" => seg_out <= "1111000";
                when "1000" => seg_out <= "0000000";
                when "1001" => seg_out <= "0010000";
                when others => seg_out <= "1111111";
            end case;
        end if;
    end 
process;
end 
architecture rtl;