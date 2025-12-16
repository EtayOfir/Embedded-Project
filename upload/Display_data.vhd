library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ============================================================
-- Project   : Home Alarm System - Display Data Logic
-- File Name : Display_data.vhd
-- Author    : Etay Ofir and Yuval Shahar
-- ID        : 203844261 , 209455112
-- Created   : 28/11/2025
--
-- Description:
-- This module generates an 8-bit display output based on the current
-- system state and user input attempts. It shows success, failure,
-- armed status, alarm indication, or the entered code bits (attempt).
-- The module also tracks an internal alarm_active flag that latches
-- when an alarm condition occurs.
--
-- Notes:
-- * Asynchronous reset drives the output bus to 'Z'.
-- * Fixed 4-bit attempt input displayed as lower 4 bits of data.
-- * alarm_active latches when ST_ALARM occurs or a wrong code is entered.
-- * On ST_SUCCESS the alarm is cleared and success code is shown.
-- * data output reflects one of several predefined display patterns.
--
-- Ports:
--   clk        : System clock (rising edge)
--   rst        : Asynchronous reset
--   attempt    : 4-bit user code input
--   state_code : Current FSM state (0–7)
--   data       : 8-bit output for external display
-- ============================================================

entity Display_data is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        attempt    : in  std_logic_vector(3 downto 0);   -- fixed 4 bits
        state_code : in  integer range 0 to 7;
        data       : out std_logic_vector(7 downto 0)
    );
end Display_data;

architecture rtl of Display_data is
    -- Display patterns
    constant DISPLAY_SUCCESS  : std_logic_vector(7 downto 0) := x"0F";
    constant DISPLAY_FAILURE  : std_logic_vector(7 downto 0) := x"0A";
    constant DISPLAY_ARMED    : std_logic_vector(7 downto 0) := x"08";
    constant DISPLAY_CONSTANT : std_logic_vector(7 downto 0) := x"00";

    -- State codes
    constant ST_OFF     : integer := 0;
    constant ST_ARMED   : integer := 1;
    constant ST_ALARM   : integer := 2;
    constant ST_SUCCESS : integer := 3;
    constant ST_CODE    : integer := 4;

    -- Local constant for attempt width (just for slicing)
    constant N_bit_c : integer := 3;  -- attempt(3 downto 0)

    signal alarm_active : std_logic := '0';
begin
    process(clk, rst)
    begin
        -- Asynchronous reset
        if rst = '1' then
            data         <= (others => 'Z');  -- High impedance on reset
            alarm_active <= '0';

        -- On rising clock edge
        elsif rising_edge(clk) then

            -- Update alarm status
            if (state_code = ST_ALARM) or
               (state_code = ST_CODE and attempt = "0111") then  -- Trigger alarm
                alarm_active <= '1';
            elsif state_code = ST_SUCCESS then                   -- Clear alarm on success
                alarm_active <= '0';
            end if;

            -- Determine display data
            if state_code = ST_SUCCESS then
                data <= DISPLAY_SUCCESS;

            elsif state_code = ST_CODE then
                -- Show the 4 bits of attempt (padded to 8 bits)
                data <= "0000" & attempt(N_bit_c downto N_bit_c-3);  -- "0000" & attempt(3 downto 0)

            elsif alarm_active = '1' then
                data <= DISPLAY_FAILURE;

            else
                case state_code is
                    when ST_OFF =>
                        data <= DISPLAY_CONSTANT;
                    when ST_ARMED =>
                        data <= DISPLAY_ARMED;
                    when ST_ALARM =>
                        data <= DISPLAY_FAILURE;
                    when others =>
                        data <= DISPLAY_CONSTANT;
                end case;
            end if;
        end if;
    end process;

end rtl;
