library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity clk_divider is
    generic (
        SIMULATION : boolean := false
    );
    port (
        clk_50m   : in  std_logic;
        reset_n   : in  std_logic;
        tick_1hz  : out std_logic;
        blink_1hz : out std_logic
    );
end 
entity clk_divider;

architecture rtl of clk_divider is
    constant FULL_COUNT_HW  : natural := 50000000;
    constant HALF_COUNT_HW  : natural := 25000000;
    constant FULL_COUNT_SIM : natural := 50;
    constant HALF_COUNT_SIM : natural := 25;
    function get_full_count(sim : boolean) return natural is
    
begin

        if sim then
            return FULL_COUNT_SIM;
        else
            return FULL_COUNT_HW;
        end if;
    end function;
    function get_half_count(sim : boolean) return natural is
    
begin

        if sim then
            return HALF_COUNT_SIM;
        else
            return HALF_COUNT_HW;
        end if;
    end function;
    constant FULL_COUNT : natural := get_full_count(SIMULATION);
    constant HALF_COUNT : natural := get_half_count(SIMULATION);
    signal count_reg : natural range 0 to FULL_COUNT - 1 := 0;
    signal blink_reg : std_logic := '1';
    signal tick_reg  : std_logic := '0';

begin

    
process(clk_50m, reset_n)
    
begin

        if reset_n = '0' then
            count_reg <= 0;
            blink_reg <= '1';
            tick_reg  <= '0';
        elsif rising_edge(clk_50m) then
            if count_reg = FULL_COUNT - 1 then
                count_reg <= 0;
                tick_reg  <= '1';
                blink_reg <= '1';
            elsif count_reg = HALF_COUNT - 1 then
                count_reg <= count_reg + 1;
                tick_reg  <= '0';
                blink_reg <= '0';
            else
                count_reg <= count_reg + 1;
                tick_reg  <= '0';
            end if;
        end if;
    end 
process;
    tick_1hz  <= tick_reg;
    blink_1hz <= blink_reg;
end 
architecture rtl;