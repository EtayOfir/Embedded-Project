library ieee;
use ieee.std_logic_1164.all;

-- ============================================================
-- Testbench for Press_duration_measure
-- ==v==========================================================

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

  -- instantiate the DUT
  UUT : entity work.Press_duration_measure
    generic map (
      K => 3       -- threshold between short / long press
    )
    port map (
      clk       => clk,
      rst       => rst,
      btn_in    => btn_in,
      enable    => enable,
      bit_out   => bit_out,
      bit_valid => bit_valid
    );

  --------------------------------------------------------------
  -- Clock generator: 20 ns period (50 MHz)
  --------------------------------------------------------------
  clk_process : process
  begin
    clk <= '0';
    wait for 10 ns;
    clk <= '1';
    wait for 10 ns;
  end process;

  --------------------------------------------------------------
  -- Stimulus process
  --------------------------------------------------------------
  stim_proc : process
  begin
    -- global reset
    rst    <= '1';
    enable <= '0';  -- ignore button presses during reset
    btn_in <= '0';  -- button not pressed
    wait for 40 ns; -- hold reset for 2 clock cycles

    rst    <= '0';
    enable <= '1';  -- allow button presses

    ----------------------------------------------------------
    -- 1) Short press: 2 clock cycles  -> bit_out = '0'
    ----------------------------------------------------------
    wait for 20 ns;      -- wait some clocks
    btn_in <= '1';
    wait for 40 ns;      -- 2 cycles
    btn_in <= '0';
    wait for 80 ns;      -- observe bit_valid & bit_out

    ----------------------------------------------------------
    -- 2) Long press: 5 clock cycles -> bit_out = '1'
    ----------------------------------------------------------
    btn_in <= '1';
    wait for 100 ns;     -- 5 cycles
    btn_in <= '0';
    wait for 100 ns;

    ----------------------------------------------------------
    -- end simulation
    ----------------------------------------------------------
    wait;
  end process;

end tb;
