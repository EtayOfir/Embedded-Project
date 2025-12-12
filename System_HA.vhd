library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ============================================================
-- Project   : Home Alarm System - Top-Level
-- File Name : System_HA.vhd
-- Author    : Etay Ofir and Yuval Shahar
-- ID        : 203844261 , 209455112
-- Created   : 11/12/2025
-- Description:
-- Top-level integration of all Home Alarm modules.
-- ============================================================

entity System_HA is
    port (
        clk            : in  std_logic;
        rst            : in  std_logic;
        pass_btn       : in  std_logic;
        motion_raw     : in  std_logic;
        window_raw     : in  std_logic;
        door_raw       : in  std_logic;
        display_data_o : out std_logic_vector(7 downto 0);
        alarm_siren    : out std_logic;
        system_armed   : out std_logic;
        state_code_dbg : out std_logic_vector(2 downto 0)
    );
end System_HA;

architecture rtl of System_HA is

    ----------------------------------------------------------------
    -- Internal signals
    ----------------------------------------------------------------
    signal door_clean, window_clean, motion_clean : std_logic;
    signal intrusion_detected                     : std_logic;

    signal bit_out   : std_logic;
    signal bit_valid : std_logic;

    signal code_ready  : std_logic;
    signal code_match  : std_logic;
    signal code_vector : std_logic_vector(7 downto 0);

    signal enable_press : std_logic;
    signal clear_code   : std_logic;
    signal attempts_int : integer range 0 to 7;
    signal state_code   : std_logic_vector(7 downto 0);

begin
    ----------------------------------------------------------------
    -- Sensors Logic
    ----------------------------------------------------------------
    U_sensors: entity work.Sensors_logic
        port map (
            clk          => clk,
            rst          => rst,
            door_sens    => door_raw,
            window_sens  => window_raw,
            motion_sens  => motion_raw,
            door_clean   => door_clean,
            window_clean => window_clean,
            motion_clean => motion_clean,
            detected     => intrusion_detected
        );

    state_code_dbg <= motion_clean & window_clean & door_clean;

    ----------------------------------------------------------------
    -- Press Duration Measure
    ----------------------------------------------------------------
    U_press: entity work.Press_duration_measure
        generic map (K => 3)
        port map (
            clk       => clk,
            rst       => rst,
            btn_in    => pass_btn,
            enable    => enable_press,
            bit_out   => bit_out,
            bit_valid => bit_valid
        );

    ----------------------------------------------------------------
    -- Code Register
    ----------------------------------------------------------------
    U_code: entity work.Code_register
        port map (
            clk         => clk,
            rst         => clear_code,
            bit_in      => bit_out,
            valid       => bit_valid,
            code_ready  => code_ready,
            code_match  => code_match,
            code_vector => code_vector
        );

    ----------------------------------------------------------------
    -- Alarm Control
    ----------------------------------------------------------------
    U_alarm: entity work.alarm_Control
        port map (
            clk                => clk,
            rst                => rst,
            intrusion_detected => intrusion_detected,
            code_ready         => code_ready,
            code_matched       => code_match,
            enable_press       => enable_press,
            clear_code         => clear_code,
            alarm_siren        => alarm_siren,
            system_armed       => system_armed,
            attempts           => attempts_int,
            state_code         => state_code
        );

    ----------------------------------------------------------------
    -- Display Data
    ----------------------------------------------------------------
    U_display: entity work.Display_data
        port map (
            clk        => clk,
            rst        => rst,
            attempt    => std_logic_vector(to_unsigned(attempts_int, 4)),
            state_code => to_integer(unsigned(state_code(2 downto 0))),
            data       => display_data_o
        );

end rtl;
