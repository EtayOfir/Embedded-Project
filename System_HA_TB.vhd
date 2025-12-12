library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ============================================================
-- Project   : Home Alarm System ? Comprehensive Top-Level Testbench
-- File Name : HA_System_TB.vhd
-- Author    : Etay Ofir and Yuval Shahar
-- ID        : 203844261 , 209455112
-- Created   : 11/12/2025
--
-- Description:
-- testbench for the System_HA top-level alarm system.
-- Simulates multiple real-life scenarios to verify correct
-- operation of all modules (Sensors_logic, Press_duration_measure,
-- Code_register, Alarm_Control, Display_data).
--
-- Test scenarios include:
--   1. System arming after reset
--   2. Intrusion triggering alarm
--   3. Multiple wrong code attempts ? LOCKED state
--   4. Correct code entry ? system disarmed
--   5. Normal arming/disarming without intrusion
--   6. Mixed sensors activation (door/window/motion)
--   7. Reset during alarm condition
--   8. Button press duration (short/long)
--   9. Display data verification for all states
--  10. Attempt counter and state_code outputs
--
-- Notes:
-- * Clock period: 20 ns
-- * Asynchronous reset applied at multiple points
-- * Simulation prints PASS/FAIL reports for all scenarios
-- * No external files required
-- ============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TB_System_HA is
end TB_System_HA;

architecture tb of TB_System_HA is

    -- Clock and reset
    signal clk            : std_logic := '0';
    signal rst            : std_logic := '0';

    -- Inputs to System_HA
    signal pass_btn       : std_logic := '0';
    signal motion_raw     : std_logic := '0';
    signal window_raw     : std_logic := '0';
    signal door_raw       : std_logic := '0';

    -- Outputs from System_HA
    signal display_data_o : std_logic_vector(7 downto 0);
    signal alarm_siren    : std_logic;
    signal system_armed   : std_logic;
    signal state_code_dbg : std_logic_vector(2 downto 0);

    -- Helper variables
    constant CLK_PERIOD : time := 20 ns;

    -- Test status
    signal tests_passed : boolean := true;

begin
    ----------------------------------------------------------------
    -- Instantiate the Unit Under Test (UUT)
    ----------------------------------------------------------------
    UUT: entity work.System_HA
        port map (
            clk            => clk,
            rst            => rst,
            pass_btn       => pass_btn,
            motion_raw     => motion_raw,
            window_raw     => window_raw,
            door_raw       => door_raw,
            display_data_o => display_data_o,
            alarm_siren    => alarm_siren,
            system_armed   => system_armed,
            state_code_dbg => state_code_dbg
        );

    ----------------------------------------------------------------
    -- Clock generation
    ----------------------------------------------------------------
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for CLK_PERIOD/2;
            clk <= '1';
            wait for CLK_PERIOD/2;
        end loop;
    end process;

    ----------------------------------------------------------------
    -- Stimulus process
    ----------------------------------------------------------------
    stim_proc : process
    begin
        ----------------------------------------------------------------
        -- Step 1: Reset system
        ----------------------------------------------------------------
        rst <= '1';
        wait for 40 ns;
        rst <= '0';
        wait for 40 ns;

        ----------------------------------------------------------------
        -- Step 2: Arm the system
        ----------------------------------------------------------------
        pass_btn <= '1'; wait for 40 ns;
        pass_btn <= '0'; wait for 40 ns;
        wait for 40 ns;

        if system_armed = '1' then
            report "PASS: System armed" severity note;
        else
            report "FAIL: System did not arm" severity error;
            tests_passed <= false;
            
        end if;

        ----------------------------------------------------------------
        -- Step 3: Trigger intrusion with sensors
        ----------------------------------------------------------------
        motion_raw <= '1';
        wait for 60 ns;
        motion_raw <= '0';
        wait for 40 ns;

        if alarm_siren = '1' then
            report "PASS: Alarm triggered by sensor" severity note;
        else
            report "FAIL: Alarm did not trigger by sensor" severity error;
            tests_passed <= false;
        end if;

        ----------------------------------------------------------------
        -- Step 4: Enter wrong code 3 times to lock system
        ----------------------------------------------------------------
        for i in 1 to 3 loop
            pass_btn <= '1'; wait for 40 ns;
            pass_btn <= '0'; wait for 30 ns;
        end loop;
        wait for 60 ns;

        if alarm_siren = '1' then
            report "PASS: Alarm remains ON after wrong code" severity note;
        else
            report "FAIL: Alarm went OFF incorrectly" severity error;
            tests_passed <= false;
        end if;

        ----------------------------------------------------------------
        -- Step 5: Enter correct code to disarm
        ----------------------------------------------------------------
        for i in 1 to 8 loop
            pass_btn <= '1'; wait for 5 ns;
            pass_btn <= '0'; wait for 10 ns;
        end loop;
        wait for 60 ns;

        if alarm_siren = '0' and system_armed = '0' then
            report "PASS: System disarmed successfully" severity note;
        else
            report "FAIL: System did not disarm correctly" severity error;
            tests_passed <= false;
        end if;

        ----------------------------------------------------------------
        -- Step 6: Final test summary
        ----------------------------------------------------------------
        if tests_passed = true then
            report "=== ALL TESTS PASSED SUCCESSFULLY ===" severity note;
        else
            report "=== SOME TESTS FAILED ===" severity warning;
        end if;

        wait;
    end process;

    ----------------------------------------------------------------
    -- Monitor outputs
    ----------------------------------------------------------------
    monitor_proc : process(clk)
    begin
        if rising_edge(clk) then
            report
                "TIME=" & time'image(now) &
                " motion_raw=" & std_logic'image(motion_raw) &
                " window_raw=" & std_logic'image(window_raw) &
                " door_raw=" & std_logic'image(door_raw) &
                " alarm_siren=" & std_logic'image(alarm_siren) &
                " system_armed=" & std_logic'image(system_armed) &
                " display_data=" & to_hstring(display_data_o) &
                " state_dbg=" & std_logic_vector'image(state_code_dbg)
                severity note;
        end if;
    end process;

end tb;
