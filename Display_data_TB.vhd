library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
        generic map(N_bit => 3)
        port map(
            clk => clk,
            rst => rst,
            attempt => attempt,
            state_code => state_code,
            data => data
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

        -- Intrusion detected ? Alarm activated
        state_code <= 2;
        wait for clk_period;
        assert data = DISPLAY_FAILURE
            report "ERROR: Alarm state mismatch!" severity error;
        report "Alarm activated OK.";

        -- Try reset while alarm is active ? should not clear alarm
        rst <= '1';
        wait for clk_period;
        rst <= '0';
        wait for clk_period;
        assert data = DISPLAY_FAILURE
            report "ERROR: Alarm incorrectly reset!" severity error;
        report "Alarm correctly remained active after reset.";

        -- Display 7 failed attempts (alarm remains)
        for i in 1 to 7 loop
            attempt <= std_logic_vector(to_unsigned(i, attempt'length));
            state_code <= 4;  -- Display attempts
            wait for clk_period;
            assert data(3 downto 0) = std_logic_vector(to_unsigned(i,4))
                report "ERROR: Attempt display mismatch for attempt " & integer'image(i)
                severity error;
            report "Attempt " & integer'image(i) & " displayed OK: data=" & to_hstring(data);
        end loop;

        -- Successful code entered ? alarm stops
        state_code <= 3;
        wait for clk_period;
        assert data = DISPLAY_SUCCESS
            report "ERROR: Success state mismatch!" severity error;
        report "Successful code entered OK. Alarm cleared.";

        -- Final reset (no alarm) ? data should go to Z
        rst <= '1';
        wait for clk_period;
	    assert data = (7 downto 0 => 'Z')
            report "ERROR: Data did not go to Z on final reset!" severity error;
        report "Final reset OK.";

        report "ALL TESTS PASSED SUCCESSFULLY.";
        wait;
    end process;

end rtl;
