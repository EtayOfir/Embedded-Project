library ieee;
use ieee.std_logic_1164.all;

-- ============================================================
-- Project   : Home Alarm System ? Press Duration Measure
-- File Name : Press_duration_measure.vhd
-- Author    : Etay Ofir
-- ID        : 203844261
-- Created   : 24/11/2025
--
-- Description:
-- This module measures the duration of a button press.
-- When enable='1' and btn_in goes from '0' to '1', it starts
-- counting clock cycles while btn_in='1'. When the button is
-- released (btn_in returns to '0'), the module decides:
--   * short press  (< K cycles) -> bit_out = '0'
--   * long press   (>= K cycles) -> bit_out = '1'
-- It then generates a one-clock-cycle pulse on bit_valid to
-- indicate that bit_out is ready.
--
-- Notes:
-- * Asynchronous reset.
-- * Generic K defines the threshold between short/long press.
-- * During reset, outputs (std_logic) are set to 'Z'.
-- ============================================================

entity Press_duration_measure is
  generic (
    K : integer := 3  -- number of clock cycles for LONG press
  );
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    btn_in    : in  std_logic;
    enable    : in  std_logic;  -- when '1', allows new measurement, when '0' ignores button presses

    bit_out   : out std_logic;  -- 0 = short press(less than K cycles), 1 = long press(K or more cycles)
    bit_valid : out std_logic   -- 1 for one clock when bit_out is ready
  );
end Press_duration_measure;


architecture rtl of Press_duration_measure is

  -- simple FSM for the button
  -- IDLE: waiting for new press
  -- COUNT: counting how many cycles button is pressed
  -- OUTPUT: outputting the result
  type state_type is (IDLE, COUNT, OUTPUT);
  signal state      : state_type := IDLE;

  -- count how many consecutive clock cycles button is pressed
  signal press_cnt  : integer range 0 to K := 0;

  -- btn_in value in previous clock cycle (for edge detection)
  signal btn_prev   : std_logic := '0';

begin

  process (clk, rst)
  begin
    if rst = '1' then
      ----------------------------------------------------------
      -- Asynchronous reset
      ----------------------------------------------------------
      state      <= IDLE;  -- reset to IDLE state
      press_cnt  <= 0;     -- clear press counter
      btn_prev   <= '0';   -- assuming button not pressed

      bit_out    <= 'Z';
      bit_valid  <= 'Z';

    elsif rising_edge(clk) then
      ----------------------------------------------------------
      -- default: no new bit this cycle
      ----------------------------------------------------------
      bit_valid <= '0';  -- default no valid output this cycle

      case state is

        --------------------------------------------------------
        -- IDLE: waiting for new press (enable=1 and 0->1 on btn)
        --------------------------------------------------------
        when IDLE =>
          press_cnt <= 0;  -- ready for next measurement

          if (enable = '1') and (btn_prev = '0') and (btn_in = '1') then
            -- detected rising edge of button while enabled
            state     <= COUNT;
            press_cnt <= 1;  -- first cycle of the press
          end if;

        --------------------------------------------------------
        -- COUNT: button is held down, count clock cycles
        --------------------------------------------------------
        when COUNT =>
          if btn_in = '1' then
            -- still pressed, increment count but cap at K
            if press_cnt < K then 
              press_cnt <= press_cnt + 1;
            end if;
          else
            -- button released -> decide on short / long press
            if press_cnt >= K then
              bit_out <= '1';   -- long press
            else
              bit_out <= '0';   -- short press
            end if;

            state <= OUTPUT;    -- next cycle will assert bit_valid
          end if;

        --------------------------------------------------------
        -- OUTPUT: raise bit_valid for exactly one clock
        --------------------------------------------------------
        when OUTPUT =>
          bit_valid <= '1';     -- one-cycle pulse
          state     <= IDLE;    -- back to waiting state
          press_cnt <= 0;
      end case;

      -- update previous button state for edge detection
      btn_prev <= btn_in;

    end if;
  end process;

end rtl;
