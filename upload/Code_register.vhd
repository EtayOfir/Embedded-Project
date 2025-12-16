library ieee;
use ieee.std_logic_1164.all;

entity Code_register is
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        bit_in      : in  std_logic;
        valid       : in  std_logic;
        code_ready  : out std_logic;
        code_match  : out std_logic;
        code_vector : out std_logic_vector(7 downto 0)
    );
end Code_register;

architecture rtl of Code_register is
    constant N : integer := 8;
    constant SECRET_CODE : std_logic_vector(N-1 downto 0) := (others => '0');

    signal code_vector_int : std_logic_vector(N-1 downto 0) := (others => '0');
    signal bit_count       : integer range 0 to N := 0;
    signal code_ready_int  : std_logic := '0';
    signal code_match_int  : std_logic := '0';
begin

    process(clk, rst)
        variable next_code : std_logic_vector(N-1 downto 0);
    begin
        if rst = '1' then
            code_vector_int <= (others => '0');
            bit_count       <= 0;
            code_ready_int  <= '0';
            code_match_int  <= '0';

        elsif rising_edge(clk) then
            -- default: 1-cycle pulse
            code_ready_int <= '0';

            if valid = '1' then
                -- shift left, insert new bit at LSB
                next_code := code_vector_int(N-2 downto 0) & bit_in;
                code_vector_int <= next_code;

                if bit_count = N-1 then
                    bit_count      <= 0;
                    code_ready_int <= '1';

                    if next_code = SECRET_CODE then
                        code_match_int <= '1';
                    else
                        code_match_int <= '0';
                    end if;

                else
                    bit_count <= bit_count + 1;
                end if;
            end if;
        end if;
    end process;

    code_ready  <= code_ready_int;
    code_match  <= code_match_int;
    code_vector <= code_vector_int;

end rtl;
