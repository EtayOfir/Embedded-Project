library ieee;
use ieee.std_logic_1164.all;

-- ============================================================
-- Project   : Home Alarm System – Sensors Logic Testbench
-- File Name : Sensors_Logic_TB.vhd
-- Author    : Etay Ofir
-- ID        : 203844261
-- Created   : 24/11/2025
--
-- Description:
-- Testbench for the Sensors_logic module.
-- Generates clock, reset, random noise pulses, and valid sensor
-- activation sequences to verify debounce and detection behavior.
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
  signal detected     : std_logic;  -- detected = 1 if at least 2 sensors are clean

begin

  -- חיבור ה-UUT
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
-- Clock generation: 20 ns period (50 MHz)
  --------------------------------------------------------------------
  clk_process : process
  begin
    clk <= '0';
    wait for 10 ns;
    clk <= '1';
    wait for 10 ns;
  end process;

  --------------------------------------------------------------------
-- Stimulus generator for sensors and reset
  --------------------------------------------------------------------
  stim_proc : process
  begin
    -------------------------------------------------------------
    -- Step 1: initial asynchronous reset
    -------------------------------------------------------------
    rst <= '1';
    wait for 25 ns;
    rst <= '0';

    -------------------------------------------------------------
    -- Step 2: short door noise (< 3 clock cycles) -> must not propagate to door_clean
    -------------------------------------------------------------
    door_sens   <= '1';
    wait for 40 ns;       -- ~2 clock cycles
    door_sens   <= '0';
    wait for 60 ns;

    -------------------------------------------------------------
    -- Step 3: Door activated for a long duration (>= 3 cycles) -> door_clean should be '1'
    -------------------------------------------------------------
    door_sens   <= '1';
    wait for 80 ns;       -- ~4 clock cycles
    door_sens   <= '0';
    wait for 40 ns;

    -------------------------------------------------------------
    -- Step 4: window + motion activated together for a long duration
    -- When at least two clean sensors are '1' -> detected = '1'
    -------------------------------------------------------------
    window_sens <= '1';
    motion_sens <= '1';
    wait for 80 ns;       -- sufficient time for debounce
    window_sens <= '0';
    motion_sens <= '0';
    wait for 60 ns;

    -------------------------------------------------------------
    -- End of simulation
    -------------------------------------------------------------
    wait;
  end process;

end tb;
