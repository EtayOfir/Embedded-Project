library ieee;
use ieee.std_logic_1164.all;

-- ============================================================
-- Project   : Home Alarm System - Sensors Logic Testbench
-- File Name : Sensors_Logic_TB.vhd
-- Author    : Etay Ofir and Yuval Shahar
-- ID        : 203844261 , 209455112
-- Created   : 24/11/2025
--
-- Description:
-- Testbench for the Sensors_logic module.
-- Generates clock, reset, noise pulses, and verifies debounce
-- and detection logic using ASSERT/REPORT.
-- Simulation ends cleanly without using severity failure.
-- ============================================================

entity Sensors_Logic_TB is
end Sensors_Logic_TB;

architecture tb of Sensors_Logic_TB is

  -- clock and reset signals
  signal clk          : std_logic := '0';
  signal rst          : std_logic := '0';

  -- raw sensor input signals (with noise)
  signal door_sens    : std_logic := '0';
  signal window_sens  : std_logic := '0';
  signal motion_sens  : std_logic := '0';

  -- signals are "clean" after debounce
  signal door_clean   : std_logic;
  signal window_clean : std_logic;
  signal motion_clean : std_logic;
  signal detected     : std_logic;

begin

  --------------------------------------------------------------------
  -- UUT instantiation
  --------------------------------------------------------------------
  UUT: entity work.Sensors_logic
    port map (
      clk          => clk,
      rst          => rst,
      door_sens    => door_sens,
      window_sens  => window_sens,
      motion_sens  => motion_sens,
      door_clean   => door_clean,
      window_clean => window_clean,
      motion_clean => motion_clean,
      detected     => detected
    );

  --------------------------------------------------------------------
  -- Clock generation: 20 ns period (200 cycles)
  --------------------------------------------------------------------
  clk_process : process
  begin
    for i in 0 to 200 loop
      clk <= '0';
      wait for 10 ns;
      clk <= '1';
      wait for 10 ns;
    end loop;
    wait;
  end process;

  --------------------------------------------------------------------
  -- Monitor every rising clock edge
  --------------------------------------------------------------------
  monitor_proc : process(clk)
  begin
    if rising_edge(clk) then
      report
        "TIME=" & time'image(now) &
        " door_sens="    & std_logic'image(door_sens)    &
        " window_sens="  & std_logic'image(window_sens)  &
        " motion_sens="  & std_logic'image(motion_sens)  &
        " | door_clean="   & std_logic'image(door_clean)   &
        " window_clean=" & std_logic'image(window_clean) &
        " motion_clean=" & std_logic'image(motion_clean) &
        " detected="     & std_logic'image(detected)
        severity note;
    end if;
  end process;

  --------------------------------------------------------------------
  -- Testbench stimulus + checks
  --------------------------------------------------------------------
  stim_proc : process
  begin
    -------------------------------------------------------------
    -- Step 1: Reset
    -------------------------------------------------------------
    report "=== Step 1: Applying reset ===" severity note;

    rst <= '1';
    wait for 25 ns;
    rst <= '0';
    wait for 20 ns;

    -------------------------------------------------------------
    -- Step 2: Short noise pulse
    -------------------------------------------------------------
    report "=== Step 2: Short door noise (should NOT be debounced) ==="
      severity note;

    door_sens <= '1';
    wait for 40 ns;
    door_sens <= '0';
    wait for 60 ns;

    assert (door_clean = '0' and detected = '0')
      report "ERROR Step 2: Noise incorrectly debounced. door_clean=" &
             std_logic'image(door_clean) &
             " detected=" & std_logic'image(detected)
      severity error;

    -------------------------------------------------------------
    -- Step 3: Long door activation
    -------------------------------------------------------------
    report "=== Step 3: Long door activation (should be debounced) ==="
      severity note;

    door_sens <= '1';
    wait for 80 ns;

    assert (door_clean = '1')
      report "FAIL Step 3: door_clean did NOT become '1'. "
      severity error;

    door_sens <= '0';
    wait for 60 ns;

    assert (door_clean = '0')
      report "FAIL Step 3: door_clean did NOT return to '0'. "
      severity error;

    report "Step 3 passed: Door debounce works" severity note;

    -------------------------------------------------------------
    -- Step 4: Two sensors active
    -------------------------------------------------------------
    report "=== Step 4: window_sens + motion_sens active (detected must be '1') ==="
      severity note;

    window_sens <= '1';
    motion_sens <= '1';
    wait for 120 ns;

    assert (window_clean = '1')
      report "FAIL Step 4: window_clean not '1'." severity error;

    assert (motion_clean = '1')
      report "FAIL Step 4: motion_clean not '1'." severity error;

    assert (detected = '1')
      report "FAIL Step 4: detected not '1' for 2 sensors active." severity error;

    window_sens <= '0';
    motion_sens <= '0';
    wait for 60 ns;

    assert (detected = '0')
      report "FAIL Step 4: detected did not return to '0'." severity error;

    report "Step 4 passed: Detection logic works" severity note;

    -------------------------------------------------------------
    -- End of simulation CLEANLY (no failure)
    -------------------------------------------------------------
    report "=== ALL TESTS COMPLETED ===" severity note;

    wait for 40 ns;

    -- clean simulation exit
    report "Simulation finished" severity note;

    wait;  -- TB stops here
  end process;

end tb;
