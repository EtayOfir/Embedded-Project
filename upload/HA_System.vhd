library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity HA_System is
    port (
        clk            : in  std_logic;
        rst            : in  std_logic;

        pass_btn       : in  std_logic;
        door_raw       : in  std_logic;
        window_raw     : in  std_logic;
        motion_raw     : in  std_logic;

        alarm_siren    : out std_logic;
        system_armed   : out std_logic;
        display_data   : out std_logic_vector(7 downto 0);

        -- Per assignment: 3-bit debug output containing sensors values
        state_code_dbg : out std_logic_vector(2 downto 0)
    );
end HA_System;

architecture rtl of HA_System is
    -- Sensors
    signal door_clean_s, window_clean_s, motion_clean_s : std_logic;
    signal intrusion_detected_s : std_logic;

    -- Press duration -> serial bits
    signal bit_out_s, bit_valid_s : std_logic;

    -- Code register outputs
    signal code_ready_s, code_match_s : std_logic;
    signal code_vector_s : std_logic_vector(7 downto 0);

    -- Controller outputs
    signal enable_press_s : std_logic;
    signal clear_code_s   : std_logic;
    signal attempts_s     : integer range 0 to 7;
    signal state_code_s   : std_logic_vector(2 downto 0);

    -- Internal reset ONLY for Code_register (clear_code goes to Code_register.rst)
    signal rst_code_reg_s : std_logic;

    -- Display inputs
    signal attempt4_s  : std_logic_vector(3 downto 0);
    signal state_int_s : integer range 0 to 7;

begin
    --------------------------------------------------------------------
    -- Debug: show cleaned sensors on 3-bit output (door, window, motion)
    --------------------------------------------------------------------
    state_code_dbg <= door_clean_s & window_clean_s & motion_clean_s;

    --------------------------------------------------------------------
    -- IMPORTANT: clear_code resets ONLY the Code_register (not the FSM)
    --------------------------------------------------------------------
    rst_code_reg_s <= rst or clear_code_s;

    --------------------------------------------------------------------
    -- Display helper signals
    --------------------------------------------------------------------
    attempt4_s  <= code_vector_s(3 downto 0);
    state_int_s <= to_integer(unsigned(state_code_s));

    --------------------------------------------------------------------
    -- Sensors logic (debounce + detected)
    --------------------------------------------------------------------
    u_sensors: entity work.Sensors_logic
        port map (
            clk          => clk,
            rst          => rst,
            door_sens    => door_raw,
            window_sens  => window_raw,
            motion_sens  => motion_raw,
            door_clean   => door_clean_s,
            window_clean => window_clean_s,
            motion_clean => motion_clean_s,
            detected     => intrusion_detected_s
        );

    --------------------------------------------------------------------
    -- Press duration measure (button -> bits)
    --------------------------------------------------------------------
    u_press: entity work.Press_duration_measure
        generic map ( K => 3 )
        port map (
            clk       => clk,
            rst       => rst,
            btn_in    => pass_btn,
            enable    => enable_press_s,
            bit_out   => bit_out_s,
            bit_valid => bit_valid_s
        );

    --------------------------------------------------------------------
    -- Code register (collect 8 bits)
    -- Reset is OR'ed with clear_code_s
    --------------------------------------------------------------------
    u_code: entity work.Code_register
        port map (
            clk         => clk,
            rst         => rst_code_reg_s,
            bit_in      => bit_out_s,
            valid       => bit_valid_s,
            code_ready  => code_ready_s,
            code_match  => code_match_s,
            code_vector => code_vector_s
        );

    --------------------------------------------------------------------
    -- Alarm controller (FSM)
    --------------------------------------------------------------------
    u_ctrl: entity work.alarm_Control
        port map (
            clk                => clk,
            rst                => rst,
            intrusion_detected => intrusion_detected_s,
            code_ready         => code_ready_s,
            code_match         => code_match_s,
            enable_press       => enable_press_s,
            clear_code         => clear_code_s,
            alarm_siren        => alarm_siren,
            system_armed       => system_armed,
            attempts           => attempts_s,
            state_code         => state_code_s
        );

    --------------------------------------------------------------------
    -- Display data
    --------------------------------------------------------------------
    u_disp: entity work.Display_data
        port map (
            clk        => clk,
            rst        => rst,
            attempt    => attempt4_s,
            state_code => state_int_s,
            data       => display_data
        );

end rtl;
