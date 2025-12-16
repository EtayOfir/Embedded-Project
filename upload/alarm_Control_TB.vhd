library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alarm_Control_TB is
end alarm_Control_TB;

architecture tb of alarm_Control_TB is

    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    signal intrusion_detected : std_logic := '0';
    signal code_ready         : std_logic := '0';
    signal code_match         : std_logic := '0';

    signal enable_press : std_logic;
    signal clear_code   : std_logic;
    signal alarm_siren  : std_logic;
    signal system_armed : std_logic;
    signal attempts     : integer range 0 to 7;
    signal state_code   : std_logic_vector(2 downto 0);

    constant clk_period : time := 10 ns;

    --------------------------------------------------------------------
    -- Helper: Pulse code_ready with a chosen code_match value
    --------------------------------------------------------------------
    procedure pulse_code(
        signal s_code_ready : out std_logic;
        signal s_code_match : out std_logic;
        match_val           : std_logic
    ) is
    begin
        s_code_match <= match_val;
        s_code_ready <= '1';
        wait for clk_period;

        s_code_ready <= '0';
        s_code_match <= '0';
        wait for 2*clk_period;
    end procedure;

begin

    --------------------------------------------------------------------
    -- DUT
    --------------------------------------------------------------------
    UUT: entity work.alarm_Control
        port map (
            clk                => clk,
            rst                => rst,
            intrusion_detected => intrusion_detected,
            code_ready         => code_ready,
            code_match         => code_match,
            enable_press       => enable_press,
            clear_code         => clear_code,
            alarm_siren        => alarm_siren,
            system_armed       => system_armed,
            attempts           => attempts,
            state_code         => state_code
        );

    --------------------------------------------------------------------
    -- Clock generation
    --------------------------------------------------------------------
    clk <= not clk after clk_period/2;

    --------------------------------------------------------------------
    -- Stimulus
    --------------------------------------------------------------------
    stim_proc : process
    begin
        ----------------------------------------------------------------
        -- Step 1: Reset -> system should be ARMED (per assignment)
        ----------------------------------------------------------------
        report "=== Step 1: Applying reset ===" severity note;
        rst <= '1';
        wait for 3*clk_period;
        rst <= '0';
        wait for 3*clk_period;

        if system_armed /= '1' then
            report "FAIL Step 1: Expected system_armed='1' after reset" severity error;
        else
            report "PASS Step 1: Armed after reset" severity note;
        end if;

        ----------------------------------------------------------------
        -- Step 2: Trigger intrusion -> ALARM should turn ON
        ----------------------------------------------------------------
        report "=== Step 2: Trigger intrusion ===" severity note;
        intrusion_detected <= '1';
        wait for clk_period;
        intrusion_detected <= '0';
        wait for 3*clk_period;

        if alarm_siren /= '1' then
            report "FAIL Step 2: Expected alarm_siren='1' after intrusion" severity error;
        else
            report "PASS Step 2: Alarm ON" severity note;
        end if;

        ----------------------------------------------------------------
        -- Step 3: Enter wrong code 3 times -> should go LOCKED
        ----------------------------------------------------------------
        report "=== Step 3: Wrong code x3 -> LOCKED ===" severity note;

        pulse_code(code_ready, code_match, '0'); -- wrong #1
        pulse_code(code_ready, code_match, '0'); -- wrong #2
        pulse_code(code_ready, code_match, '0'); -- wrong #3

        -- allow FSM to settle
        wait for 3*clk_period;

        if attempts < 3 then
            report "FAIL Step 3: Expected attempts >= 3 after 3 wrong codes" severity error;
        else
            report "PASS Step 3: attempts counted" severity note;
        end if;

        if state_code /= "011" then
            report "FAIL Step 3: Expected state_code=011 (LOCKED)" severity error;
        else
            report "PASS Step 3: LOCKED state entered" severity note;
        end if;

        if enable_press /= '0' then
            report "FAIL Step 3: Expected enable_press='0' in LOCKED" severity error;
        else
            report "PASS Step 3: enable_press disabled in LOCKED" severity note;
        end if;

        ----------------------------------------------------------------
        -- Step 4: Wait LOCKED duration (LOCK_CYCLES=5) then back to ALARM
        ----------------------------------------------------------------
        report "=== Step 4: Wait for LOCKED release ===" severity note;
        wait for 8*clk_period; -- > LOCK_CYCLES + margin

        ----------------------------------------------------------------
        -- Step 5: Correct code -> DISARM (alarm OFF)
        ----------------------------------------------------------------
        report "=== Step 5: Correct code -> DISARM (alarm OFF) ===" severity note;
        pulse_code(code_ready, code_match, '1');

        wait for 3*clk_period;

        if alarm_siren /= '0' then
            report "FAIL Step 5: Expected alarm_siren='0' after correct code" severity error;
        else
            report "PASS Step 5: Alarm OFF" severity note;
        end if;

        if system_armed /= '0' then
            report "FAIL Step 5: Expected system_armed='0' after disarm" severity error;
        else
            report "PASS Step 5: System disarmed" severity note;
        end if;

        report "=== ALL TESTS DONE ===" severity note;
        wait;
    end process;

end tb;
