library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_traffic_light_top is
end 
entity tb_traffic_light_top;

architecture sim of tb_traffic_light_top is
    constant CLK_PERIOD : time := 20 ns;
    signal clk_50m : std_logic := '0';
    signal key     : std_logic_vector(2 downto 0) := "111";
    signal sw      : std_logic_vector(1 downto 0) := "00";
    signal ledr    : std_logic_vector(3 downto 0);
    signal ledg    : std_logic_vector(1 downto 0);
    signal hex0    : std_logic_vector(6 downto 0);
    signal hex1    : std_logic_vector(6 downto 0);
    signal hex2    : std_logic_vector(6 downto 0);
    signal hex3    : std_logic_vector(6 downto 0);
    constant SEG_0     : std_logic_vector(6 downto 0) := "1000000";
    constant SEG_1     : std_logic_vector(6 downto 0) := "1111001";
    constant SEG_2     : std_logic_vector(6 downto 0) := "0100100";
    constant SEG_3     : std_logic_vector(6 downto 0) := "0110000";
    constant SEG_4     : std_logic_vector(6 downto 0) := "0011001";
    constant SEG_5     : std_logic_vector(6 downto 0) := "0010010";
    constant SEG_6     : std_logic_vector(6 downto 0) := "0000010";
    constant SEG_7     : std_logic_vector(6 downto 0) := "1111000";
    constant SEG_8     : std_logic_vector(6 downto 0) := "0000000";
    constant SEG_9     : std_logic_vector(6 downto 0) := "0010000";
    constant SEG_BLANK : std_logic_vector(6 downto 0) := "1111111";
    signal sim_done : boolean := false;

begin

    dut: 
entity work.traffic_light_top
        generic map (
            SIMULATION => true
        )
        port map (
            CLOCK_50 => clk_50m,
            KEY      => key,
            SW       => sw,
            LEDR     => ledr,
            LEDG     => ledg,
            HEX0     => hex0,
            HEX1     => hex1,
            HEX2     => hex2,
            HEX3     => hex3
        );
    clk_gen: 
process
    
begin

        while not sim_done loop
            clk_50m <= '0';
            wait for CLK_PERIOD / 2;
            clk_50m <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end 
process;
    stim_proc: 
process
        variable t_phase_start : time;
        variable t_phase_dur   : time;
        variable frozen_hex0   : std_logic_vector(6 downto 0);
        variable frozen_hex1   : std_logic_vector(6 downto 0);
        variable frozen_hex2   : std_logic_vector(6 downto 0);
        variable frozen_hex3   : std_logic_vector(6 downto 0);
        variable frozen_ledg   : std_logic_vector(1 downto 0);
        variable frozen_ledr   : std_logic_vector(3 downto 0);
        variable t_blink_start : time;
        variable t_blink_high  : time;
        variable t_blink_low   : time;
    
begin

        key <= "111";
        sw  <= "00";
        wait for 40 ns;
        key(0) <= '0';
        wait for 100 ns;
        key(0) <= '1';
        wait for 40 ns;
        wait until rising_edge(clk_50m) and ledr(1) = '1';
        t_phase_dur := now - t_phase_start;
        t_phase_start := now;
        wait until rising_edge(clk_50m);
        wait until rising_edge(clk_50m) and ledg(1) = '1';
        t_phase_dur := now - t_phase_start;
        t_phase_start := now;
        wait until rising_edge(clk_50m);
        wait until rising_edge(clk_50m) and ledr(3) = '1';
        t_phase_dur := now - t_phase_start;
        t_phase_start := now;
        wait until rising_edge(clk_50m);
        wait until rising_edge(clk_50m) and ledg(0) = '1';
        t_phase_dur := now - t_phase_start;
        t_phase_start := now;
        wait until rising_edge(clk_50m);
        wait until rising_edge(clk_50m) and ledr(1) = '1';
        t_phase_dur := now - t_phase_start;
        t_phase_start := now;
        wait until rising_edge(clk_50m);
        wait until rising_edge(clk_50m) and ledg(1) = '1';
        t_phase_dur := now - t_phase_start;
        t_phase_start := now;
        wait until rising_edge(clk_50m);
        wait until rising_edge(clk_50m) and ledr(3) = '1';
        t_phase_dur := now - t_phase_start;
        t_phase_start := now;
        wait until rising_edge(clk_50m);
        wait until rising_edge(clk_50m) and ledg(0) = '1';
        t_phase_dur := now - t_phase_start;
        t_phase_start := now;
        wait until rising_edge(clk_50m);
        wait for 200 ns;
        wait until rising_edge(clk_50m) and ledr(1) = '0';
        wait until rising_edge(clk_50m) and ledr(1) = '1';
        t_blink_start := now;
        wait until rising_edge(clk_50m) and ledr(1) = '0';
        t_blink_high := now - t_blink_start;
        t_blink_start := now;
        wait until rising_edge(clk_50m) and ledr(1) = '1';
        t_blink_low := now - t_blink_start;
        t_blink_start := now;
        wait until rising_edge(clk_50m) and ledr(1) = '0';
        t_blink_high := now - t_blink_start;
        t_blink_start := now;
        wait until rising_edge(clk_50m) and ledr(1) = '1';
        t_blink_low := now - t_blink_start;
        sw(0) <= '0';
        wait for 200 ns;
        sw(1) <= '1';
        wait for 100 ns;
        frozen_hex0 := hex0;
        frozen_hex1 := hex1;
        frozen_hex2 := hex2;
        frozen_hex3 := hex3;
        frozen_ledg := ledg;
        frozen_ledr := ledr;
        wait for 4.0 us;
        sw(1) <= '0';
        wait for 2.0 us;
        wait until rising_edge(clk_50m) and ledg(1) = '1' and ledr(0) = '1';
        wait for 2.0 us;
        key(1) <= '0';
        wait for 100 ns;
        wait for 5.0 us;
        key(1) <= '1';
        wait for 200 ns;
        wait for 2.0 us;
        key(2) <= '0';
        wait until rising_edge(clk_50m) and ledg(1) = '1';
        t_phase_start := now;
        key(2) <= '1';
        wait until rising_edge(clk_50m);
        wait until rising_edge(clk_50m) and ledr(3) = '1';
        t_phase_dur := now - t_phase_start;
        t_phase_start := now;
        wait until rising_edge(clk_50m);
        wait until rising_edge(clk_50m) and ledg(0) = '1';
        t_phase_dur := now - t_phase_start;
        wait until rising_edge(clk_50m);
        wait for 2.0 us;
        sim_done <= true;
        wait;
    end 
process;
end 
architecture sim;