library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- ============================================================
-- Project   : Home Alarm System ? Alarm Control Testbench
-- File Name : alarm_Control_TB.vhd
-- Author    : Etay Ofir and Yuval Shahar
-- ID        : 203844261 , 209455112
-- Created   : 10/12/2025
--
-- Description:
-- Testbench for the alarm_Control module.
-- Applies reset, arms the system, triggers intrusion,
-- tests correct/incorrect code entry and LOCKED state.
-- Monitors outputs: alarm_siren, system_armed, attempts, enable_press, clear_code.
--
-- Notes:
-- * Clock = 10 ns period.
-- * Monitors signals every rising edge of clock.
-- * Reports PASS/FAIL for each test step.
-- * Simulation stops after all steps completed.
-- ============================================================

entity alarm_Control_TB is
end alarm_Control_TB;

architecture tb of alarm_Control_TB is

    -- Clock and reset
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';

    -- Inputs
    signal intrusion_detected : std_logic := '0';
    signal code_ready         : std_logic := '0';
    signal code_matched       : std_logic := '0';

    -- Outputs
    signal enable_press : std_logic;
    signal clear_code   : std_logic;
    signal alarm_siren  : std_logic;
    signal system_armed : std_logic;
    signal attempts     : integer;
    signal state_code   : std_logic_vector(7 downto 0);

    constant clk_period : time := 10 ns;

    -- Test result signals
    signal tb_passed : boolean := true;

begin

    --------------------------------------------------------------------
    -- DUT instantiation
    --------------------------------------------------------------------
    UUT: entity work.alarm_Control
        port map (
            clk => clk,
            rst => rst,
            intrusion_detected => intrusion_detected,
            code_ready => code_ready,
            code_matched => code_matched,
            enable_press => enable_press,
            clear_code => clear_code,
            alarm_siren => alarm_siren,
            system_armed => system_armed,
            attempts => attempts,
            state_code => state_code
        );

    --------------------------------------------------------------------
    -- Clock generation
    --------------------------------------------------------------------
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for clk_period/2;
            clk <= '1';
            wait for clk_period/2;
        end loop;
    end process;

    --------------------------------------------------------------------
    -- Monitor signals
    --------------------------------------------------------------------
    monitor_proc : process(clk)
    begin
        if rising_edge(clk) then
            report
                "TIME=" & time'image(now) &
                " intrusion_detected=" & std_logic'image(intrusion_detected) &
                " code_ready=" & std_logic'image(code_ready) &
                " code_matched=" & std_logic'image(code_matched) &
                " | enable_press=" & std_logic'image(enable_press) &
                " clear_code=" & std_logic'image(clear_code) &
                " alarm_siren=" & std_logic'image(alarm_siren) &
                " system_armed=" & std_logic'image(system_armed) &
                " attempts=" & integer'image(attempts);
        end if;
    end process;

    --------------------------------------------------------------------
    -- Test stimulus with checks
    --------------------------------------------------------------------
    stim_proc : process
    begin
        ----------------------------------------------------------------
        -- Step 1: Reset system
        ----------------------------------------------------------------
        report "=== Step 1: Applying reset ===" severity note;
        rst <= '1';
        wait for 20 ns;
        rst <= '0';
        wait for 20 ns;

        if system_armed /= '0' or attempts /= 0 then
            report "FAIL Step 1: System not reset correctly!" severity error;
            tb_passed <= false;
        else
            report "PASS Step 1: Reset OK" severity note;
        end if;

        ----------------------------------------------------------------
        -- Step 2: Arm the system
        ----------------------------------------------------------------
        report "=== Step 2: Arming system ===" severity note;
        code_ready <= '1';
        wait for 10 ns;
        code_ready <= '0';
        wait for 20 ns;

        if system_armed /= '1' then
            report "FAIL Step 2: System did not arm!" severity error;
            tb_passed <= false;
        else
            report "PASS Step 2: System armed successfully" severity note;
        end if;

        ----------------------------------------------------------------
        -- Step 3: Trigger intrusion
        ----------------------------------------------------------------
        report "=== Step 3: Trigger intrusion ===" severity note;
        intrusion_detected <= '1';
        wait for 10 ns;
        intrusion_detected <= '0';
        wait for 20 ns;

        if alarm_siren /= '1' then
            report "FAIL Step 3: Alarm siren did not turn ON!" severity error;
            tb_passed <= false;
        else
            report "PASS Step 3: Alarm siren activated" severity note;
        end if;

        ----------------------------------------------------------------
        -- Step 4: Enter wrong code 3 times ? LOCKED
        ----------------------------------------------------------------
        report "=== Step 4: Wrong code attempts ===" severity note;

        for i in 1 to 3 loop
            code_ready <= '1';
            code_matched <= '0';
            wait for 10 ns;
            code_ready <= '0';
            wait for 20 ns;
        end loop;

        if attempts /= 3 then
            report "FAIL Step 4: Attempts counter incorrect!" severity error;
            tb_passed <= false;
        else
            report "PASS Step 4: Attempts counter correct (3)" severity note;
        end if;

        if alarm_siren /= '1' then
            report "FAIL Step 4: Alarm siren should still be ON!" severity error;
            tb_passed <= false;
        else
            report "PASS Step 4: Alarm siren still ON" severity note;
        end if;

        ----------------------------------------------------------------
        -- Step 5: Try correct code after LOCKED ? should remain LOCKED
        ----------------------------------------------------------------
        report "=== Step 5: Attempt correct code after LOCKED ===" severity note;
        code_ready <= '1';
        code_matched <= '1';
        wait for 10 ns;
        code_ready <= '0';
        code_matched <= '0';
        wait for 20 ns;

        if alarm_siren /= '1' then
            report "FAIL Step 5: System should remain LOCKED!" severity error;
            tb_passed <= false;
        else
            report "PASS Step 5: System remains LOCKED" severity note;
        end if;

        ----------------------------------------------------------------
        -- Step 6: Optional ? check system can disarm before LOCKED
        ----------------------------------------------------------------
        report "=== Step 6: Disarm system before LOCKED ===" severity note;
        rst <= '1';
        wait for 10 ns;
        rst <= '0';
        code_ready <= '1';
        wait for 10 ns;
        code_ready <= '0';
        code_ready <= '1';
        code_matched <= '1';
        wait for 10 ns;
        code_ready <= '0';
        code_matched <= '0';
        wait for 20 ns;

        if system_armed /= '0' then
            report "FAIL Step 6: System did not disarm correctly!" severity error;
            tb_passed <= false;
        else
            report "PASS Step 6: System disarmed successfully" severity note;
        end if;

        ----------------------------------------------------------------
        -- Final report
        ----------------------------------------------------------------
        if tb_passed = true then
            report "=== ALL TESTS PASSED SUCCESSFULLY ===" severity note;
        else
            report "=== SOME TESTS FAILED ===" severity warning;
        end if;

        wait; -- Stop simulation
    end process;

end tb;
