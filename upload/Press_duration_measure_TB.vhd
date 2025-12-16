library ieee;
use ieee.std_logic_1164.all;

-- ============================================================
-- Project   : Home Alarm System – Press Duration Measure
-- File Name : Press_duration_measure_TB.vhd
-- Author    : Etay Ofir and Yuval Shahar
-- ID        : 203844261 , 209455112
-- Created   : 24/11/2025
--
-- Description:
-- This testbench verifies the Press_duration_measure module by
-- generating clock, reset, and controlled button press sequences.
-- It checks correct classification of button presses as:
--   * short press  (< K clock cycles) -> expected bit_out = '0'
--   * long press   (>= K clock cycles) -> expected bit_out = '1'
--
-- The testbench also observes the one-clock-cycle pulse on 
-- bit_valid, which indicates that bit_out contains a valid result.
--
-- Notes:
-- * A 50 MHz system clock (20 ns period) is generated.
-- * An asynchronous reset initializes the DUT; during reset the
--   outputs bit_out and bit_valid are expected to be 'Z'.
-- * The testbench applies both short and long button presses and
--   uses ASSERT/REPORT checks to validate the DUT behavior.
-- * A waveform monitor prints key signals at every rising clock 
--   edge to assist with simulation analysis.
-- * The clock runs for a limited number of cycles to ensure the 
--   simulation terminates cleanly.
-- ============================================================

entity Press_duration_measure_TB is
end Press_duration_measure_TB;

architecture tb of Press_duration_measure_TB is

  -- DUT signals
  signal clk       : std_logic := '0';
  signal rst       : std_logic := '0';
  signal btn_in    : std_logic := '0';
  signal enable    : std_logic := '0';
  signal bit_out   : std_logic;
  signal bit_valid : std_logic;

begin

  ----------------------------------------------------------------
  -- UUT instantiation
  ----------------------------------------------------------------
  UUT : entity work.Press_duration_measure
    port map (
      clk       => clk,
      rst       => rst,
      btn_in    => btn_in,
      enable    => enable,
      bit_out   => bit_out,
      bit_valid => bit_valid
    );

  ----------------------------------------------------------------
  -- Clock generator: 20 ns period (50 MHz), limited cycles
  ----------------------------------------------------------------
  clk_process : process
  begin
    -- 200 clock cycles are enough for this test
    for i in 0 to 200 loop
      clk <= '0';
      wait for 10 ns;
      clk <= '1';
      wait for 10 ns;
    end loop;
    wait;
  end process;

  ----------------------------------------------------------------
  -- Monitor: print the main signals on each rising edge of clk
  ----------------------------------------------------------------
  monitor_proc : process (clk)
  begin
    if rising_edge(clk) then
      report
        "TIME=" & time'image(now) &
        " btn_in="    & std_logic'image(btn_in)    &
        " enable="    & std_logic'image(enable)    &
        " | bit_out=" & std_logic'image(bit_out)   &
        " bit_valid=" & std_logic'image(bit_valid)
        severity note;
    end if;
  end process;

  ----------------------------------------------------------------
  -- Stimulus + self-checks
  ----------------------------------------------------------------
  stim_proc : process
  begin
    --------------------------------------------------------------
    -- Step 1: Global reset and reset check
    --------------------------------------------------------------
    report "=== Step 1: Applying reset ===" severity note;

    rst    <= '1';
    enable <= '0';
    btn_in <= '0';

    -- During reset, outputs should be 'Z'
    wait for 20 ns;
    assert (bit_out = 'Z' and bit_valid = 'Z')
      report "RESET check FAILED: expected bit_out='Z' and bit_valid='Z' during reset. Got: " &
             "bit_out=" & std_logic'image(bit_out) &
             " bit_valid=" & std_logic'image(bit_valid)
      severity error;

    wait for 20 ns;       -- still under reset
    rst    <= '0';        -- release reset
    enable <= '1';        -- enable measurement
    report "Reset released, starting button press tests" severity note;

    --------------------------------------------------------------
    -- Step 2: Short press: 2 clock cycles -> bit_out = '0'
    -- K = 3  =>  2 < K  => short press
    --------------------------------------------------------------
    report "=== Step 2: SHORT press (2 cycles) -> expect bit_out='0' ==="
      severity note;

    -- small delay before the press (2 clock cycles)
    wait until rising_edge(clk);
    wait until rising_edge(clk);

    -- short button press: hold for 2 clock cycles
    btn_in <= '1';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    btn_in <= '0';        -- release button

    -- gate-level design: bit_out set one cycle after release,
    -- bit_valid raised one more cycle later
    -- => wait 3 rising edges after release
    wait until rising_edge(clk);  -- 1st after release
    wait until rising_edge(clk);  -- 2nd after release
    wait until rising_edge(clk);  -- 3rd after release -> expect bit_valid = '1'

    assert (bit_valid = '1' and bit_out = '0')
      report "SHORT press FAILED: expected bit_valid='1' and bit_out='0'. Got: " &
             "bit_valid=" & std_logic'image(bit_valid) &
             " bit_out="  & std_logic'image(bit_out)
      severity error;

    -- check that bit_valid pulse ends (1 clock cycle high)
    wait until rising_edge(clk);  -- next cycle after the pulse
    assert (bit_valid = '0')
      report "SHORT press FAILED: bit_valid did not return to '0' after pulse."
      severity error;

    report "Step 2 PASSED: Short press detected correctly (bit_out='0')" severity note;

    --------------------------------------------------------------
    -- Step 3: Long press: 5 clock cycles -> bit_out = '1'
    -- K = 3  =>  5 >= K  => long press
    --------------------------------------------------------------
    report "=== Step 3: LONG press (5 cycles) -> expect bit_out='1' ==="
      severity note;

    -- long button press: hold for 5 clock cycles
    btn_in <= '1';
    for i in 1 to 5 loop
      wait until rising_edge(clk);
    end loop;
    btn_in <= '0';        -- release button

    -- same pipeline: wait 3 rising edges after release
    wait until rising_edge(clk);  -- 1st after release
    wait until rising_edge(clk);  -- 2nd after release
    wait until rising_edge(clk);  -- 3rd after release -> expect bit_valid = '1'

    assert (bit_valid = '1' and bit_out = '1')
      report "LONG press FAILED: expected bit_valid='1' and bit_out='1'. Got: " &
             "bit_valid=" & std_logic'image(bit_valid) &
             " bit_out="  & std_logic'image(bit_out)
      severity error;

    -- check that bit_valid pulse ends (1 clock cycle high)
    wait until rising_edge(clk);  -- next cycle after the pulse
    assert (bit_valid = '0')
      report "LONG press FAILED: bit_valid did not return to '0' after pulse."
      severity error;

    report "Step 3 PASSED: Long press detected correctly (bit_out='1')" severity note;

    --------------------------------------------------------------
    -- End of simulation
    --------------------------------------------------------------
    report "=== ALL TESTS COMPLETED SUCCESSFULLY ===" severity note;

    -- small delay before stopping
    wait until rising_edge(clk);
    report "Simulation finished" severity note;
    wait;
  end process;

end tb;
