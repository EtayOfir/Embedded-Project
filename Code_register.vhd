library ieee;
use ieee.std_logic_1164.all;

-- ============================================================
-- Project   : Home Alarm System ? Digital Code Recognition
-- File Name : Code_register.vhd
-- Author    : Etay Ofir and Yuval Shahar
-- ID        : 203844261 , 209455112
-- Created   : 28/11/2025
--
-- Description:
-- Sequentially collects N serial bits (bit_in) when valid='1'.
-- After N bits, outputs code_ready='1' for one cycle and compares
-- the collected code against SECRET_CODE. If matched ? code_match='1'.
--
-- Notes:
-- * Asynchronous reset.
-- * N = code length (here fixed to 8 bits).
-- * code_ready pulses high when a full code is received.
-- * code_match indicates whether the received code matches SECRET_CODE.
-- ============================================================

entity Code_register is
    port (
        clk         : in std_logic;
        rst         : in std_logic;
        bit_in      : in std_logic;                      -- Serial input bit
        valid       : in std_logic;                      -- Indicates bit_in is valid
        code_ready  : out std_logic;                     -- Pulses high after N bits
        code_match  : out std_logic;                     -- High when code matches SECRET_CODE
        code_vector : out std_logic_vector(7 downto 0)   -- Collected code
    );
end Code_register;

architecture rtl of Code_register is
    constant N : integer := 8;   -- Code length in bits
    constant SECRET_CODE : std_logic_vector(N-1 downto 0)
        := (others => '0');      -- Expected code (00000000)

    signal code_ready_int  : std_logic := '0';
    signal code_match_int  : std_logic := '0';
    signal code_vector_int : std_logic_vector(N-1 downto 0) := (others => '0');
    signal bit_count       : integer range 0 to N := 0;  -- Number of collected bits

begin
    -------------------------------------------------------------------------
    -- Main sequential process: shift-in bits and detect completion
    -------------------------------------------------------------------------
    process(clk, rst)
    begin
        -- Asynchronous reset clears state
        if rst = '1' then
            code_vector_int <= (others => '0');
            code_ready_int  <= '0';
            code_match_int  <= '0';
            bit_count       <= 0;

        -- Rising-edge processing
        elsif rising_edge(clk) then

            if valid = '1' then
                -- Shift register: insert new bit at LSB
                code_vector_int <= code_vector_int(N-2 downto 0) & bit_in;
                bit_count <= bit_count + 1;

                -- When N bits have been collected
                if bit_count = N-1 then
                    code_ready_int <= '1';     -- Pulse code_ready
                    bit_count <= 0;            -- Reset counter

                    -- Compare full vector with SECRET_CODE
                    if (code_vector_int(N-2 downto 0) & bit_in) = SECRET_CODE then
                        code_match_int <= '1';
                    else
                        code_match_int <= '0';
                    end if;
                end if;

            else
                -- valid='0': no bit collected, ensure code_ready is low
                code_ready_int <= '0';
            end if;

        end if;
    end process;

    -------------------------------------------------------------------------
    -- Output assignments
    -------------------------------------------------------------------------
    code_ready  <= code_ready_int;
    code_match  <= code_match_int;
    code_vector <= code_vector_int;

end rtl;