library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ============================================================
-- Project   : Home Alarm System – Display Data Testbench
-- File Name : Display_data_TB.vhd
-- Author    : Etay Ofir and Yuval Shahar
-- ID        : 203844261 , 209455112
-- Created   : 28/11/2025
--
-- Description:
-- Testbench for the Display_data module. Verifies correct display
-- output for all system states, attempts handling, alarm behavior,
-- and reset functionality. Drives state_code and attempt inputs
-- and checks that the data bus matches expected patterns.
--
-- Notes:
-- * Pure simulation (non-synthesizable TB).
-- * Clock period = 10 ns.
-- * Asynchronous reset tested at beginning and during alarm.
-- * Validates:
--     - Armed state display
--     - Alarm activation / persistence through reset
--     - Attempt display for values 1–7
--     - Successful code display
--     - Final reset → data = 'Z'
-- * Uses assert/report for automatic pass/fail messages.
--
-- Ports under test:
--   clk, rst, attempt, state_code → inputs to DUT
--   data → 8-bit visual output from DUT
-- ============================================================

entity Display_data_TB is
end Display_data_TB;

architecture rtl of Display_data_TB is
    signal clk        : std_logic := '0';
    signal rst        : std_logic := '0';
    signal attempt    : std_logic_vector(3 downto 0) := (others => '0');
    signal state_code : integer range 0 to 7 := 0;
    signal data       : std_logic_vector(7 downto 0);
    constant clk_period : time := 10 ns;

    -- Constants from DUT
    constant DISPLAY_SUCCESS  : std_logic_vector(7 downto 0) := x"0F";
    constant DISPLAY_FAILURE  : std_logic_vector(7 downto 0) := x"0A";
    constant DISPLAY_ARMED    : std_logic_vector(7 downto 0) := x"08";
    constant DISPLAY_CONSTANT : std_logic_vector(7 downto 0) := x"00";

begin
    -- Instantiate DUT
    DUT: entity work.Display_data
        port map(
            clk        => clk,
            rst        => rst,
            attempt    => attempt,
            state_code => state_code,
            data       => data
        );

    -- Clock generation
    clk_process : process
    begin
        loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
    end process;

    -- Test stimulus
    stim_proc: process
    begin
        -- Initial reset
        rst <= '1';
        report "Applying initial reset...";
        wait for 20 ns;
        rst <= '0';
        report "Reset released.";
        wait for 20 ns;

        -- Armed state
        state_code <= 1;
        wait for clk_period;
        assert data = DISPLAY_ARMED
            report "ERROR: Armed state mismatch!" severity error;
        report "System armed OK.";

        -- Intrusion detected → Alarm activated
        state_code <= 2;
        wait for clk_period;
        assert data = DISPLAY_FAILURE
            report "ERROR: Alarm state mismatch!" severity error;
        report "Alarm activated OK.";

        -- Reset while alarm active → should NOT clear alarm
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        wait for clk_period;
        assert data = DISPLAY_FAILURE
            report "ERROR: Alarm incorrectly reset!" severity error;
        report "Alarm correctly remained active after reset.";

        -- Display attempts (7 attempts)
        for i in 1 to 7 loop
            attempt    <= std_logic_vector(to_unsigned(i, attempt'length));
            state_code <= 4;  -- Display attempts
            wait for clk_period;

            assert data(3 downto 0) = std_logic_vector(to_unsigned(i,4))
                report "ERROR: Attempt display mismatch for attempt " &
                       integer'image(i)
                severity error;

            report "Attempt " & integer'image(i) &
                   " displayed OK: data=" &
                   integer'image(to_integer(unsigned(data)));
        end loop;

        -- Successful code entered → alarm clears
        state_code <= 3;
        wait for clk_period;
        assert data = DISPLAY_SUCCESS
            report "ERROR: Success state mismatch!" severity error;
        report "Successful code entered OK. Alarm cleared.";

        -- Final reset → data should go Z
        rst <= '1';
        wait for clk_period;
        assert data = (7 downto 0 => 'Z')
            report "ERROR: Data did not go to Z on final reset!" severity error;
        report "Final reset OK.";

        report "ALL TESTS PASSED SUCCESSFULLY.";
        wait;
    end process;

end rtl;
