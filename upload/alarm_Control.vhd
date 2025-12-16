library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alarm_Control is
    port (
        clk                : in  std_logic;
        rst                : in  std_logic;
        intrusion_detected : in  std_logic;
        code_ready         : in  std_logic;
        code_match         : in  std_logic;

        enable_press       : out std_logic;
        clear_code         : out std_logic;
        alarm_siren        : out std_logic;
        system_armed       : out std_logic;

        attempts           : out integer range 0 to 7;
        state_code         : out std_logic_vector(2 downto 0)
    );
end alarm_Control;

architecture rtl of alarm_Control is

    type state_type is (DISARMED, ARMED, ALARM, LOCKED);
    signal current_state, next_state : state_type := ARMED;

    signal attempts_int  : integer range 0 to 7 := 0;
    signal attempts_next : integer range 0 to 7 := 0;

    constant LOCK_CYCLES : integer := 5;
    signal lock_cnt_int  : integer range 0 to LOCK_CYCLES := 0;
    signal lock_cnt_next : integer range 0 to LOCK_CYCLES := 0;

    signal state_code_int, state_code_next : std_logic_vector(2 downto 0) := "001";

    constant MAX_WRONG_ATTEMPTS : integer := 3;

begin

    --------------------------------------------------------------------
    -- Registers (async reset)
    --------------------------------------------------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            current_state  <= ARMED;      -- per assignment assumption
            attempts_int   <= 0;
            lock_cnt_int   <= 0;
            state_code_int <= "001";      -- ARMED

        elsif rising_edge(clk) then
            current_state  <= next_state;
            attempts_int   <= attempts_next;
            lock_cnt_int   <= lock_cnt_next;
            state_code_int <= state_code_next;
        end if;
    end process;

    --------------------------------------------------------------------
    -- FSM comb logic
    --------------------------------------------------------------------
    process(current_state, intrusion_detected, code_ready, code_match,
            attempts_int, lock_cnt_int)
        variable wrong_next : integer range 0 to 7;
    begin
        -- defaults
        next_state      <= current_state;
        attempts_next   <= attempts_int;
        lock_cnt_next   <= lock_cnt_int;

        enable_press    <= '0';
        clear_code      <= '0';
        alarm_siren     <= '0';
        system_armed    <= '0';
        state_code_next <= (others => '0');

        -- default for helper
        wrong_next := attempts_int;

        case current_state is

            ------------------------------------------------------------
            -- DISARMED
            ------------------------------------------------------------
            when DISARMED =>
                state_code_next <= "000";
                enable_press    <= '1';

                if code_ready = '1' then
                    clear_code <= '1'; -- pulse to reset Code_register

                    if code_match = '1' then
                        next_state    <= ARMED;
                        attempts_next <= 0;
                    else
                        -- count wrong attempt
                        if attempts_int < 7 then
                            wrong_next := attempts_int + 1;
                        else
                            wrong_next := 7;
                        end if;

                        attempts_next <= wrong_next;

                        -- lock after 3 wrong attempts
                        if wrong_next >= MAX_WRONG_ATTEMPTS then
                            next_state    <= LOCKED;
                            lock_cnt_next <= 0;
                        end if;
                    end if;
                end if;

            ------------------------------------------------------------
            -- ARMED
            ------------------------------------------------------------
            when ARMED =>
                state_code_next <= "001";
                system_armed    <= '1';
                enable_press    <= '1';

                if intrusion_detected = '1' then
                    next_state <= ALARM;

                elsif code_ready = '1' then
                    clear_code <= '1';

                    if code_match = '1' then
                        next_state    <= DISARMED;
                        attempts_next <= 0;
                    else
                        if attempts_int < 7 then
                            wrong_next := attempts_int + 1;
                        else
                            wrong_next := 7;
                        end if;

                        attempts_next <= wrong_next;

                        if wrong_next >= MAX_WRONG_ATTEMPTS then
                            next_state    <= LOCKED;
                            lock_cnt_next <= 0;
                        end if;
                    end if;
                end if;

            ------------------------------------------------------------
            -- ALARM
            ------------------------------------------------------------
            when ALARM =>
                state_code_next <= "010";
                alarm_siren     <= '1';
                system_armed    <= '1';
                enable_press    <= '1';

                if code_ready = '1' then
                    clear_code <= '1';

                    if code_match = '1' then
                        next_state    <= DISARMED;
                        attempts_next <= 0;
                    else
                        if attempts_int < 7 then
                            wrong_next := attempts_int + 1;
                        else
                            wrong_next := 7;
                        end if;

                        attempts_next <= wrong_next;

                        if wrong_next >= MAX_WRONG_ATTEMPTS then
                            next_state    <= LOCKED;
                            lock_cnt_next <= 0;
                        end if;
                    end if;
                end if;

            ------------------------------------------------------------
            -- LOCKED
            ------------------------------------------------------------
            when LOCKED =>
                state_code_next <= "011";
                alarm_siren     <= '1';
                system_armed    <= '1';
                enable_press    <= '0';

                if lock_cnt_int < LOCK_CYCLES then
                    lock_cnt_next <= lock_cnt_int + 1;
                else
                    lock_cnt_next <= 0;
                    -- keep alarm on, but reset attempts so next correct code can disarm
                    attempts_next <= 0;
                    next_state    <= ALARM;
                end if;

        end case;
    end process;

    attempts   <= attempts_int;
    state_code <= state_code_int;

end rtl;
