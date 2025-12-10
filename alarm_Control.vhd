library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- ============================================================
-- Project   : Home Alarm System
-- File Name : alarm_Control.vhd
-- Author    : Etay Ofir and Yuval Shahar
-- ID        : 203844261 , 209455112
-- Created   : 10/12/2025
--
-- Description:
-- Alarm control module for home security system.
-- Handles system states: DISARMED, ARMED, INTRUSION, ALARM,
-- CODE_ENTRY, and LOCKED.
-- Manages alarm siren, code entry, attempts counter, and arming.
--
-- Notes:
-- * Synchronous with clock, asynchronous reset.
-- * Integer attempts counter (0-7).
-- * State_code output available for monitoring.
-- ============================================================

entity alarm_Control is
    port (
        clk : in std_logic;
        rst : in std_logic;
        intrusion_detected : in std_logic;
        code_ready : in std_logic;
        code_matched : in std_logic;
        enable_press: out std_logic;
        clear_code : out std_logic;
        alarm_siren : out std_logic;
        system_armed : out std_logic;
        attempts: out integer range 0 to 7;
        state_code: out std_logic_vector(7 downto 0)
    );
end alarm_Control;
   
architecture rtl of alarm_Control is
    type state_type is (DISARMED, ARMED, INTRUSION, ALARM, CODE_ENTRY, LOCKED);
    signal current_state, next_state : state_type;

    -- Internal signals
    signal attempts_int : integer range 0 to 7 := 0;
    signal attempts_next: integer range 0 to 7 := 0;
    signal state_code_int : std_logic_vector(7 downto 0) := (others => '0');

begin

    --------------------------------------------------------------------
    -- Clocked process: state updates
    --------------------------------------------------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            current_state <= DISARMED;
            attempts_int <= 0;
            state_code_int <= (others => '0');
        elsif rising_edge(clk) then
            current_state <= next_state;
            attempts_int <= attempts_next;  -- only here
        end if;
    end process;

    --------------------------------------------------------------------
    -- Combinational process: next state and outputs
    --------------------------------------------------------------------
    process(current_state, intrusion_detected, code_ready, code_matched, attempts_int)
    begin
        -- Default outputs
        enable_press <= '0';
        clear_code <= '0';
        alarm_siren <= '0';
        system_armed <= '0';
        next_state <= current_state;
        attempts_next <= attempts_int; -- default: no change

        case current_state is
            when DISARMED =>
                system_armed <= '0';
                if code_ready = '1' then
                    next_state <= ARMED;
                end if;

            when ARMED =>
                system_armed <= '1';
                if intrusion_detected = '1' then
                    next_state <= INTRUSION;
                elsif code_ready = '1' then
                    next_state <= DISARMED;
                end if;

            when INTRUSION =>
                alarm_siren <= '1';
                next_state <= ALARM;

            when ALARM =>
                alarm_siren <= '1';
                if code_ready = '1' then
                    next_state <= CODE_ENTRY;
                end if;

            when CODE_ENTRY =>
                enable_press <= '1';
                if code_matched = '1' then
                    clear_code <= '1';
                    next_state <= DISARMED;
                    attempts_next <= 0;
                else
                    attempts_next <= attempts_int + 1;
                    if attempts_int >= 3 then 
                        next_state <= LOCKED;
                    else
                        next_state <= ALARM;
                    end if;
                end if;

            when LOCKED =>
                alarm_siren <= '1';
        end case;
    end process;
    --------------------------------------------------------------------
    attempts <= attempts_int;
    state_code <= state_code_int;

end architecture;
