library ieee;
use ieee.std_logic_1164.all;

-- ============================================================
-- Project   : Home Alarm System ? Sensors Logic
-- File Name : Sensors_logic.vhd
-- Author    : Etay Ofir
-- ID        : 203844261
-- Created   : 24/11/2025
--
-- Description:
-- This module implements the sensor filtering (debounce) and 
-- intrusion detection logic for the Home Alarm System project.
-- It generates clean signals for door, window, and motion sensors,
-- and asserts 'detected' when at least two sensors are clean.
--
-- Notes:
-- * Asynchronous reset.
-- * Clean signal requires 3 consecutive clock cycles of HIGH.
-- * Output 'detected' = 1 if ? 2 sensors are active.
-- ============================================================

entity Sensors_logic is
  port (
  -- clock and reset signals
    clk          : in  std_logic;
    rst          : in  std_logic;

-- raw sensor input signals (with noise)
    door_sens    : in  std_logic;
    window_sens  : in  std_logic;
    motion_sens  : in  std_logic;

-- signals are "clean" after debounce
    door_clean   : out std_logic;
    window_clean : out std_logic;
    motion_clean : out std_logic;
    detected     : out std_logic  -- detected = 1 if at least 2 sensors are clean
  );
end Sensors_logic;

architecture rtl of Sensors_logic is

  -- Number of consecutive clock cycles required to be considered "clean"
  constant DEBOUNCE_COUNT : integer := 3;

  -- Counters for each sensor (count how many consecutive clock cycles the input is '1')
  signal cnt_door   : integer range 0 to DEBOUNCE_COUNT := 0;
  signal cnt_window : integer range 0 to DEBOUNCE_COUNT := 0;
  signal cnt_motion : integer range 0 to DEBOUNCE_COUNT := 0;

  -- Internal signals to hold clean states before assigning to outputs
  signal door_clean_int   : std_logic := 'Z';
  signal window_clean_int : std_logic := 'Z';
  signal motion_clean_int : std_logic := 'Z';

begin

  -- Assign internal clean signals to outputs
  door_clean   <= door_clean_int;
  window_clean <= window_clean_int;
  motion_clean <= motion_clean_int;

  process (clk, rst)
  begin
    if rst = '1' then
      -- Asynchronous reset
      cnt_door   <= 0;
      cnt_window <= 0;
      cnt_motion <= 0;

      door_clean_int   <= 'Z';
      window_clean_int <= 'Z';
      motion_clean_int <= 'Z';
      detected     <= 'Z';

    elsif rising_edge(clk) then
      -------------------------------------------------------------------
      -- Debounce for door sensor
      -------------------------------------------------------------------
      if door_sens = '1' then -- sensor saying "there is something"
        if cnt_door < DEBOUNCE_COUNT then -- if the count is less than 3, increment it
          cnt_door <= cnt_door + 1;
        end if;
      else
        cnt_door <= 0; -- sensor saying "nothing", reset count
      end if;

      -- if count reached 3, set clean signal else reset it
      if cnt_door >= DEBOUNCE_COUNT then
        door_clean_int <= '1';
      else
        door_clean_int <= '0';
      end if;

      -------------------------------------------------------------------
      -- Debounce for window sensor
      -------------------------------------------------------------------
      if window_sens = '1' then -- sensor saying "there is something"
        if cnt_window < DEBOUNCE_COUNT then -- if the count is less than 3, increment it
          cnt_window <= cnt_window + 1;
        end if;
      else
        cnt_window <= 0; -- sensor saying "nothing", reset count
      end if;

      -- if count reached 3, set clean signal else reset it
      if cnt_window >= DEBOUNCE_COUNT then
        window_clean_int <= '1';
      else
        window_clean_int <= '0';
      end if;

      -------------------------------------------------------------------
      -- Debounce for motion sensor
      -------------------------------------------------------------------
      if motion_sens = '1' then -- sensor saying "there is something"
        if cnt_motion < DEBOUNCE_COUNT then -- if the count is less than 3, increment it
          cnt_motion <= cnt_motion + 1;
        end if;
      else
        cnt_motion <= 0; -- sensor saying "nothing", reset count
      end if;

      -- if count reached 3, set clean signal else reset it
      if cnt_motion >= DEBOUNCE_COUNT then
        motion_clean_int <= '1';
      else
        motion_clean_int <= '0';
      end if;

      -------------------------------------------------------------------
      -- detected = '1' if at least two clean sensors are '1'
      -------------------------------------------------------------------
      if ( (door_clean_int   = '1' and window_clean_int = '1') or
           (door_clean_int   = '1' and motion_clean_int = '1') or
           (window_clean_int = '1' and motion_clean_int = '1') ) then
        detected <= '1';
      else
        detected <= '0';
      end if;

    end if;
  end process;

end rtl;
