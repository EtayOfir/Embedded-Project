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

begin
    -- Instantiate the Unit Under Test (UUT)
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

    -- Clock generation: 10 ns period
    clk_process : process
    begin
        loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
    end process;

    -- Test stimulus
    stim_proc: process
        -- Test sequence: first 8 bits correct (00000000), then 8 bits wrong (11110000)
        variable test_seq : std_logic_vector(15 downto 0) := "0000000011110000";
    begin
        -- Reset
        rst <= '1';
        wait for 20 ns;
        rst <= '0';
        wait for 10 ns;

        report "Starting test sequence: first wrong, then correct..." severity note;

        for i in 0 to 15 loop
            bit_in <= test_seq(i);
            valid <= '1';
            wait until rising_edge(clk);
            valid <= '0';
            wait until rising_edge(clk);

            if code_ready = '1' then
                report "---------------------------------------------";
                report "Code ready! Current vector = " & std_logic_vector'image(code_vector);
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
