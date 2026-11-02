library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fsm_controller is
    port (
        clk_50m        : in  std_logic;
        reset_n        : in  std_logic;
        blink_1hz      : in  std_logic;
        timer_done     : in  std_logic;
        sw_night       : in  std_logic;
        sw_pause       : in  std_logic;
        key_emerg_n    : in  std_logic;
        key_emerg_b_n  : in  std_logic;
        phase_sel      : out std_logic_vector(1 downto 0);
        load_phase     : out std_logic;
        blank_seg7     : out std_logic;
        fsm_ra         : out std_logic;
        fsm_ya         : out std_logic;
        fsm_ga         : out std_logic;
        fsm_rb         : out std_logic;
        fsm_yb         : out std_logic;
        fsm_gb         : out std_logic
    );
end 
entity fsm_controller;

architecture rtl of fsm_controller is
    type state_type is (S_PHASE1, S_PHASE2, S_PHASE3, S_PHASE4, S_NIGHT, S_EMERGENCY);
    signal current_state : state_type := S_PHASE1;
    signal next_state    : state_type := S_PHASE1;
    signal prev_state    : state_type := S_PHASE4;

begin

    
process(clk_50m, reset_n)
    
begin

        if reset_n = '0' then
            current_state <= S_PHASE1;
            prev_state    <= S_PHASE4;
        elsif rising_edge(clk_50m) then
            current_state <= next_state;
            prev_state    <= current_state;
        end if;
    end 
process;
    load_phase <= '1' when (current_state /= prev_state) else '0';
    
process(current_state, key_emerg_n, key_emerg_b_n, sw_night, sw_pause, timer_done)
    
begin

        next_state <= current_state;
        if key_emerg_n = '0' then
            next_state <= S_EMERGENCY;
        elsif key_emerg_b_n = '0' and
              sw_night = '0' and
              current_state /= S_PHASE3 and
              current_state /= S_PHASE4 then
            next_state <= S_PHASE3;
        elsif sw_night = '1' then
            next_state <= S_NIGHT;
        elsif current_state = S_EMERGENCY or current_state = S_NIGHT then
            next_state <= S_PHASE1;
        elsif sw_pause = '1' then
            next_state <= current_state;
        else
            case current_state is
                when S_PHASE1 =>
                    if timer_done = '1' then
                        next_state <= S_PHASE2;
                    end if;
                when S_PHASE2 =>
                    if timer_done = '1' then
                        next_state <= S_PHASE3;
                    end if;
                when S_PHASE3 =>
                    if timer_done = '1' then
                        next_state <= S_PHASE4;
                    end if;
                when S_PHASE4 =>
                    if timer_done = '1' then
                        next_state <= S_PHASE1;
                    end if;
                when others =>
                    next_state <= S_PHASE1;
            end case;
        end if;
    end 
process;
    
process(current_state, blink_1hz)
    
begin

        phase_sel  <= "00";
        blank_seg7 <= '0';
        fsm_ra     <= '0';
        fsm_ya     <= '0';
        fsm_ga     <= '0';
        fsm_rb     <= '0';
        fsm_yb     <= '0';
        fsm_gb     <= '0';
        case current_state is
            when S_PHASE1 =>
                phase_sel <= "00";
                fsm_ga    <= '1';
                fsm_rb    <= '1';
            when S_PHASE2 =>
                phase_sel <= "01";
                fsm_ya    <= '1';
                fsm_rb    <= '1';
            when S_PHASE3 =>
                phase_sel <= "10";
                fsm_ra    <= '1';
                fsm_gb    <= '1';
            when S_PHASE4 =>
                phase_sel <= "11";
                fsm_ra    <= '1';
                fsm_yb    <= '1';
            when S_NIGHT =>
                phase_sel  <= "00";
                blank_seg7 <= '1';
                fsm_ya     <= blink_1hz;
                fsm_yb     <= blink_1hz;
            when S_EMERGENCY =>
                phase_sel <= "00";
                fsm_ga    <= '1';
                fsm_rb    <= '1';
            when others =>
                phase_sel <= "00";
                fsm_ra    <= '1';
                fsm_rb    <= '1';
        end case;
    end 
process;
end 
architecture rtl;