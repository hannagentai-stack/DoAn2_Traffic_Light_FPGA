library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer_counter is
    port (
        clk_50m      : in  std_logic;
        reset_n      : in  std_logic;
        tick_1hz     : in  std_logic;
        pause        : in  std_logic;
        load_phase   : in  std_logic;
        phase_sel    : in  std_logic_vector(1 downto 0);
        timer_done   : out std_logic;
        bcd_a_tens   : out std_logic_vector(3 downto 0);
        bcd_a_units  : out std_logic_vector(3 downto 0);
        bcd_b_tens   : out std_logic_vector(3 downto 0);
        bcd_b_units  : out std_logic_vector(3 downto 0)
    );
end 
entity timer_counter;

architecture rtl of timer_counter is
    signal cnt_a : natural range 0 to 63 := 25;
    signal cnt_b : natural range 0 to 63 := 28;
    signal done_reg : std_logic := '0';
    procedure to_bcd(
        val      : in  natural range 0 to 63;
        tens_out : out std_logic_vector(3 downto 0);
        unit_out : out std_logic_vector(3 downto 0)
    ) is
    
begin

        if val >= 60 then
            tens_out := "0110";
            unit_out := std_logic_vector(to_unsigned(val - 60, 4));
        elsif val >= 50 then
            tens_out := "0101";
            unit_out := std_logic_vector(to_unsigned(val - 50, 4));
        elsif val >= 40 then
            tens_out := "0100";
            unit_out := std_logic_vector(to_unsigned(val - 40, 4));
        elsif val >= 30 then
            tens_out := "0011";
            unit_out := std_logic_vector(to_unsigned(val - 30, 4));
        elsif val >= 20 then
            tens_out := "0010";
            unit_out := std_logic_vector(to_unsigned(val - 20, 4));
        elsif val >= 10 then
            tens_out := "0001";
            unit_out := std_logic_vector(to_unsigned(val - 10, 4));
        else
            tens_out := "0000";
            unit_out := std_logic_vector(to_unsigned(val, 4));
        end if;
    end procedure;

begin

    
process(clk_50m, reset_n)
    
begin

        if reset_n = '0' then
            cnt_a    <= 25;
            cnt_b    <= 28;
            done_reg <= '0';
        elsif rising_edge(clk_50m) then
            done_reg <= '0';
            if load_phase = '1' then
                case phase_sel is
                    when "00" =>
                        cnt_a <= 25;
                        cnt_b <= 28;
                    when "01" =>
                        cnt_a <= 3;
                        cnt_b <= 3;
                    when "10" =>
                        cnt_a <= 33;
                        cnt_b <= 30;
                    when "11" =>
                        cnt_a <= 3;
                        cnt_b <= 3;
                    when others =>
                        cnt_a <= 25;
                        cnt_b <= 28;
                end case;
            elsif tick_1hz = '1' and pause = '0' then
                case phase_sel is
                    when "00" =>
                        if cnt_a = 1 then
                            done_reg <= '1';
                        end if;
                    when "01" =>
                        if cnt_a = 1 then
                            done_reg <= '1';
                        end if;
                    when "10" =>
                        if cnt_b = 1 then
                            done_reg <= '1';
                        end if;
                    when "11" =>
                        if cnt_b = 1 then
                            done_reg <= '1';
                        end if;
                    when others =>
                        null;
                end case;
                if cnt_a > 1 then
                    cnt_a <= cnt_a - 1;
                end if;
                if cnt_b > 1 then
                    cnt_b <= cnt_b - 1;
                end if;
            end if;
        end if;
    end 
process;
    timer_done <= done_reg;
    
process(cnt_a, cnt_b)
        variable t_a, u_a, t_b, u_b : std_logic_vector(3 downto 0);
    
begin

        to_bcd(cnt_a, t_a, u_a);
        to_bcd(cnt_b, t_b, u_b);
        bcd_a_tens  <= t_a;
        bcd_a_units <= u_a;
        bcd_b_tens  <= t_b;
        bcd_b_units <= u_b;
    end 
process;
end 
architecture rtl;