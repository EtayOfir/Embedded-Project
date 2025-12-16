library ieee;
use ieee.std_logic_1164.all;

-- ============================================================
-- Project   : Home Alarm System - Sensors Logic
-- File Name : Sensors_logic.vhd
-- Author    : Etay Ofir and Yuval Shahar
-- ID        : 203844261 , 209455112
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
-- * 'detected' = '1' if >= 2 sensors are clean.
--
-- Implementation detail:
-- * Uses variables next_*_cnt to compute "next counter value" inside
--   the same clock cycle. This avoids an off-by-one issue caused by
--   signal update timing (signals update at end of process).
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

    -- detected = 1 if at least 2 sensors are clean
    detected     : out std_logic
  );
end Sensors_logic;

architecture rtl of Sensors_logic is

  -- Number of consecutive clock cycles required to be considered "clean"
  constant DEBOUNCE_COUNT : integer := 3;

  -- Counters for each sensor (count consecutive clock cycles input is '1')
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
    -- Next counter values (computed within the same clock cycle)
    variable next_door_cnt   : integer range 0 to DEBOUNCE_COUNT;
    variable next_window_cnt : integer range 0 to DEBOUNCE_COUNT;
    variable next_motion_cnt : integer range 0 to DEBOUNCE_COUNT;
  begin
    if rst = '1' then
      -- Asynchronous reset:
      -- Reset counters and put std_logic outputs to 'Z' (as required in the exercise)
      cnt_door   <= 0;
      cnt_window <= 0;
      cnt_motion <= 0;

      door_clean_int   <= 'Z';
      window_clean_int <= 'Z';
      motion_clean_int <= 'Z';
      detected         <= 'Z';

    elsif rising_edge(clk) then

      -------------------------------------------------------------------
      -- 1) Compute NEXT counter values for each sensor (debounce logic)
      --    Clean requires DEBOUNCE_COUNT consecutive HIGH samples.
      -------------------------------------------------------------------

      -- Door sensor next counter
      next_door_cnt := cnt_door;
      if door_sens = '1' then
        if next_door_cnt < DEBOUNCE_COUNT then
          next_door_cnt := next_door_cnt + 1;
        end if;
      else
        next_door_cnt := 0;
      end if;

      -- Window sensor next counter
      next_window_cnt := cnt_window;
      if window_sens = '1' then
        if next_window_cnt < DEBOUNCE_COUNT then
          next_window_cnt := next_window_cnt + 1;
        end if;
      else
        next_window_cnt := 0;
      end if;

      -- Motion sensor next counter
      next_motion_cnt := cnt_motion;
      if motion_sens = '1' then
        if next_motion_cnt < DEBOUNCE_COUNT then
          next_motion_cnt := next_motion_cnt + 1;
        end if;
      else
        next_motion_cnt := 0;
      end if;

      -------------------------------------------------------------------
      -- 2) Update counters (signals) using computed NEXT values
      -------------------------------------------------------------------
      cnt_door   <= next_door_cnt;
      cnt_window <= next_window_cnt;
      cnt_motion <= next_motion_cnt;

      -------------------------------------------------------------------
      -- 3) Update clean outputs based on NEXT values
      --    This ensures "exactly 3 consecutive cycles" behavior.
      -------------------------------------------------------------------
      if next_door_cnt >= DEBOUNCE_COUNT then
        door_clean_int <= '1';
      else
        door_clean_int <= '0';
      end if;

      if next_window_cnt >= DEBOUNCE_COUNT then
        window_clean_int <= '1';
      else
        window_clean_int <= '0';
      end if;

      if next_motion_cnt >= DEBOUNCE_COUNT then
        motion_clean_int <= '1';
      else
        motion_clean_int <= '0';
      end if;

      -------------------------------------------------------------------
      -- 4) Intrusion detection:
      --    detected = '1' if at least two clean sensors are '1'
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
