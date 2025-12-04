library ieee;
use ieee.std_logic_1164.all;

entity Code_register_TB is
end Code_register_TB;

architecture sim of Code_register_TB is
    constant N : integer := 8;

    signal clk         : std_logic := '0';
    signal rst         : std_logic := '0';
    signal bit_in      : std_logic := '0';
    signal valid       : std_logic := '0';
    signal code_ready  : std_logic;
    signal code_match  : std_logic;
    signal code_vector : std_logic_vector(N-1 downto 0);

    -------------------------------------------------------------------------
    -- Convert std_logic_vector ? string
    -------------------------------------------------------------------------
    function slv_to_string(slv : std_logic_vector) return string is
        variable result : string(1 to slv'length);
        variable idx    : integer := 1;
    begin
        for i in slv'range loop
            result(idx) := std_logic'image(slv(i))(2); -- gets '0', '1', etc.
            idx := idx + 1;
        end loop;
        return result;
    end function;

    -------------------------------------------------------------------------
    -- Reverse a std_logic_vector for printing (to match your input order)
    -------------------------------------------------------------------------
    function reverse_slv(slv : std_logic_vector) return std_logic_vector is
        variable r : std_logic_vector(slv'range);
    begin
        for i in slv'range loop
            r(i) := slv(slv'left + slv'right - i);
        end loop;
        return r;
    end function;

begin
    -------------------------------------------------------------------------
    -- Instantiate UUT
    -------------------------------------------------------------------------
    UUT: entity work.Code_register
        port map(
            clk => clk,
            rst => rst,
            bit_in => bit_in,
            valid => valid,
            code_ready => code_ready,
            code_match => code_match,
            code_vector => code_vector
        );

    -------------------------------------------------------------------------
    -- Clock: 10 ns period
    -------------------------------------------------------------------------
    clk_process : process
    begin
        loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
    end process;

    -------------------------------------------------------------------------
    -- Test stimulus
    -------------------------------------------------------------------------
    stim_proc: process
        -- First 8 bits: 00000000  (correct)
        -- Next  8 bits: 11110000  (wrong)
        variable test_seq : std_logic_vector(15 downto 0) := "1111000000000000";
    begin
        -- Reset
        rst <= '1';
        wait for 20 ns;
        rst <= '0';
        wait for 10 ns;

        report "Starting test sequence: first correct, then wrong..." severity note;

        for i in 0 to 15 loop
            bit_in <= test_seq(i);
            valid  <= '1';
            wait until rising_edge(clk);
            valid  <= '0';
            wait until rising_edge(clk);

            if code_ready = '1' then
                report "---------------------------------------------";
                report "Code ready! Current vector = "
                       & slv_to_string(reverse_slv(code_vector));

                if code_match = '1' then
                    report " Code MATCHED!" severity note;
                else
                    report " Code did NOT match" severity note;
                end if;
            end if;
        end loop;

        report "Simulation finished successfully." severity note;
        wait;
    end process;

end sim;