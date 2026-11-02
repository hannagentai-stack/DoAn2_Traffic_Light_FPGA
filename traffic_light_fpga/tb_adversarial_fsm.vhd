library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_adversarial_fsm is
end 
entity tb_adversarial_fsm;

architecture sim of tb_adversarial_fsm is
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
    signal fsm_phase_sel  : std_logic_vector(1 downto 0);
    signal fsm_load_phase : std_logic;
    signal fsm_blank_seg7 : std_logic;
    signal fsm_ra         : std_logic;
    signal fsm_ya         : std_logic;
    signal fsm_ga         : std_logic;
    signal fsm_rb         : std_logic;
    signal fsm_yb         : std_logic;
    signal fsm_gb         : std_logic;
    signal fsm_tick_1hz   : std_logic;
    signal fsm_blink_1hz  : std_logic;
    signal fsm_timer_done : std_logic := '0';
    signal sim_done : boolean := false;
    signal chatter_count : natural := 0;

begin

    dut_top: 
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
    u_fsm_clk_div: 
entity work.clk_divider
        generic map (
            SIMULATION => true
        )
        port map (
            clk_50m   => clk_50m,
            reset_n   => key(0),
            tick_1hz  => fsm_tick_1hz,
            blink_1hz => fsm_blink_1hz
        );
    dut_fsm: 
entity work.fsm_controller
        port map (
            clk_50m        => clk_50m,
            reset_n        => key(0),
            blink_1hz      => fsm_blink_1hz,
            timer_done     => fsm_timer_done,
            sw_night       => sw(0),
            sw_pause       => sw(1),
            key_emerg_n    => key(1),
            key_emerg_b_n  => key(2),
            phase_sel      => fsm_phase_sel,
            load_phase     => fsm_load_phase,
            blank_seg7     => fsm_blank_seg7,
            fsm_ra         => fsm_ra,
            fsm_ya         => fsm_ya,
            fsm_ga         => fsm_ga,
            fsm_rb         => fsm_rb,
            fsm_yb         => fsm_yb,
            fsm_gb         => fsm_gb
        );
    u_fsm_timer: 
entity work.timer_counter
        port map (
            clk_50m      => clk_50m,
            reset_n      => key(0),
            tick_1hz     => fsm_tick_1hz,
            pause        => sw(1),
            load_phase   => fsm_load_phase,
            phase_sel    => fsm_phase_sel,
            timer_done   => fsm_timer_done,
            bcd_a_tens   => open,
            bcd_a_units  => open,
            bcd_b_tens   => open,
            bcd_b_units  => open
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
    
process(clk_50m)
    
begin

        if rising_edge(clk_50m) then
            if fsm_load_phase = '1' then
                chatter_count <= chatter_count + 1;
            end if;
        end if;
    end 
process;
    stim_proc: 
process
        variable v_hex0_before : std_logic_vector(6 downto 0);
        variable v_hex1_before : std_logic_vector(6 downto 0);
        variable v_hex2_before : std_logic_vector(6 downto 0);
        variable v_hex3_before : std_logic_vector(6 downto 0);
        variable v_chatter_start : natural;
        variable v_chatter_diff  : natural;
        variable v_t_start       : time;
        variable v_t_dur         : time;
    
begin

        key <= "111";
        sw  <= "00";
        wait for 40 ns;
        key(0) <= '0';
        wait for 100 ns;
        key(0) <= '1';
        wait for 40 ns;
        wait until rising_edge(clk_50m) and ledg(1) = '1' and ledr(0) = '1';
        wait for 3.0 us;
        v_hex0_before := hex0;
        v_hex1_before := hex1;
        v_hex2_before := hex2;
        v_hex3_before := hex3;
        v_chatter_start := chatter_count;
        key(2) <= '0';
        wait for 200 ns;
        key(2) <= '1';
        wait for 40 ns;
        v_chatter_diff := chatter_count - v_chatter_start;
        v_chatter_start := chatter_count;
        key(2) <= '0';
        wait for 5.0 us;
        key(2) <= '1';
        wait for 40 ns;
        v_chatter_diff := chatter_count - v_chatter_start;
        wait until rising_edge(clk_50m) and ledr(3) = '1' and ledr(0) = '1';
        wait for 1.0 us;
        v_chatter_start := chatter_count;
        key(2) <= '0';
        wait for 200 ns;
        key(2) <= '1';
        wait for 40 ns;
        v_chatter_diff := chatter_count - v_chatter_start;
        key(2) <= '0';
        wait until rising_edge(clk_50m) and (ledg(0) = '1' or ledg(1) = '1');
        if ledg(0) = '1' then
            wait until rising_edge(clk_50m);
            if ledg(1) = '1' then
            end if;
        elsif ledg(1) = '1' then
        end if;
        key(2) <= '1';
        wait for 100 ns;
        wait for 100 ns;
        key <= "111";
        wait for 100 ns;
        key(1) <= '0';
        key(2) <= '0';
        wait for 200 ns;
        wait for 3.0 us;
        key(1) <= '1';
        wait until rising_edge(clk_50m) and ledg(1) = '1';
        wait for 40 ns;
        key(2) <= '1';
        wait for 200 ns;
        key(1) <= '0';
        key(2) <= '0';
        wait until rising_edge(clk_50m) and ledg(0) = '1';
        wait for 40 ns;
        key(1) <= '1';
        key(2) <= '1';
        wait for 200 ns;
        sw(0) <= '1';
        wait for 1.0 us;
        v_chatter_start := chatter_count;
        key(2) <= '0';
        wait for 100 ns;
        key(2) <= '1';
        wait for 100 ns;
        v_chatter_diff := chatter_count - v_chatter_start;
        wait for 200 ns;
        v_chatter_start := chatter_count;
        key(2) <= '0';
        wait for 2.0 us;
        key(2) <= '1';
        wait for 200 ns;
        v_chatter_diff := chatter_count - v_chatter_start;
        wait for 1.0 us;
        sw(0) <= '0';
        wait for 200 ns;
        wait for 2.0 us;
        sw(1) <= '1';
        wait for 1.0 us;
        v_hex0_before := hex0;
        wait for 1.0 us;
        key(2) <= '0';
        wait until rising_edge(clk_50m) and ledg(1) = '1';
        key(2) <= '1';
        wait for 100 ns;
        v_hex2_before := hex2;
        wait for 2.0 us;
        sw(1) <= '0';
        wait for 2.0 us;
                sw  <= std_logic_vector(to_unsigned(s, 2));
                wait for 100 ns;
            end loop;
        end loop;
        for i in 0 to 200 loop
            key(0) <= '1';
            if (i mod 3 = 0) then key(1) <= '0'; else key(1) <= '1'; end if;
            if (i mod 5 = 0) then key(2) <= '0'; else key(2) <= '1'; end if;
            if (i mod 7 = 0) then sw(0)  <= '1'; else sw(0)  <= '0'; end if;
            if (i mod 11 = 0) then sw(1) <= '1'; else sw(1)  <= '0'; end if;
            wait for 40 ns;
        end loop;
        key <= "111";
        sw  <= "00";
        wait for 500 ns;
        sim_done <= true;
        wait;
    end 
process;
end 
architecture sim;