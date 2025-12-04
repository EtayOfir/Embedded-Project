library ieee;
use ieee.std_logic_1164.all;
-- ============================================================
-- Project   : Digital Code Recognition System
-- File Name : Code_register.vhd
-- Author    : Yuval Shahar
-- ID        : 209455112
-- Created   : 28/11/2025
--
-- Description:
-- This module sequentially collects N input bits (bit_in) when
-- valid='1' and stores them in a shift register (code_vector).
-- Once N bits have been received, it asserts code_ready='1' for
-- one clock cycle to indicate that a complete code has been formed.
-- The received code is then compared with a predefined SECRET_CODE.
-- If they match, the output code_match='1' is asserted.
--
-- Notes:
-- * Asynchronous reset.
-- * The generic parameter N defines the code length (number of bits).
-- * The SECRET_CODE constant holds the reference code to compare.
-- * code_ready pulses high for one cycle every time N bits are collected.
-- * code_match remains '1' if the received code equals the secret code.
--
-- Ports:
--   clk         : System clock (rising-edge triggered)
--   rst         : Asynchronous reset
--   bit_in      : Serial bit input
--   valid       : Indicates that bit_in is valid on this clock
--   code_ready  : Output pulse ('1' for one clock when N bits collected)
--   code_match  : High if the collected code matches SECRET_CODE
--   code_vector : The N-bit vector representing the collected code
--
-- Generics:
--   N : integer := 8
--       Defines the number of bits in the code sequence.
--
-- Example behavior:
--   When valid='1', incoming bits are shifted into code_vector.
--   After N valid bits are received, code_ready='1' for one clock,
--   and the module checks if code_vector = SECRET_CODE.
--
-- ============================================================

entity Code_register is

    port (
        clk : in std_logic;
        rst : in std_logic;
        bit_in: in std_logic;
        valid: in std_logic;
        code_ready: out std_logic;
        code_match: out std_logic;
        code_vector: out std_logic_vector(7 downto 0)
    );
end Code_register;

architecture rtl of Code_register is
	 constant N : integer := 8;
	 constant SECRET_CODE : std_logic_vector(N-1 downto 0) := (others => '0');
    signal code_ready_int: std_logic := '0';
    signal code_match_int: std_logic := '0';
    signal code_vector_int: std_logic_vector(N-1 downto 0) := (others => '0');
    signal bit_count       : integer range 0 to N := 0;
    

begin
    process(clk,rst)
       
    begin
        if rst = '1' then 
            code_vector_int <= (others => '0');
            code_ready_int <= '0';
            code_match_int <= '0';
            bit_count <= 0;
        elsif rising_edge(clk) then
            if valid = '1' then
                code_vector_int <= code_vector_int(N-2 downto 0) & bit_in;
                bit_count <= bit_count + 1;

                if bit_count = N-1 then
                    code_ready_int <= '1';
                    bit_count <= 0;
                    if (code_vector_int(N-2 downto 0) & bit_in) = SECRET_CODE then
                        code_match_int <= '1';
                    else
                        code_match_int <= '0';
                    end if;
                end if;
            else
                code_ready_int <= '0';
            end if;

        end if;
    
        
    end process;
      -- assign outputs
    code_ready <= code_ready_int;
    code_match <= code_match_int;
    code_vector <= code_vector_int;

end rtl;