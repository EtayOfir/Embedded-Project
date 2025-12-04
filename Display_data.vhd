library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Display_data is
    generic (
        N_bit : integer := 3
    );
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        attempt    : in  std_logic_vector(N_bit downto 0);
        state_code : in  integer range 0 to 7;
        data       : out std_logic_vector(7 downto 0)
    );
end Display_data;

architecture rtl of Display_data is
    constant DISPLAY_SUCCESS  : std_logic_vector(7 downto 0) := x"0F";
    constant DISPLAY_FAILURE  : std_logic_vector(7 downto 0) := x"0A";
    constant DISPLAY_ARMED    : std_logic_vector(7 downto 0) := x"08";
    constant DISPLAY_CONSTANT : std_logic_vector(7 downto 0) := x"00";

    signal alarm_active : std_logic := '0';
begin
    process(clk, rst)
    begin
        -- Asynchronous reset
        if rst = '1' then
            alarm_active <= '0'; -- Reset alarm
            data <= (others => 'Z'); -- High impedance on reset
        --- On clock edge
        elsif rising_edge(clk) then
            -- Update alarm status
            if state_code = 2 or (state_code = 4 and attempt = "0111") then -- Trigger alarm
                alarm_active <= '1';   -- Set alarm
            elsif state_code = 3 then
                alarm_active <= '0';   -- Clear alarm
            end if;

          -- Determine display data
          if state_code = 3 then
              data <= DISPLAY_SUCCESS; 
          -- Display attempt count during code entry
          elsif state_code = 4 then 
              data <= "0000" & attempt(N_bit downto N_bit-3);  -- Show last 4 bits of attempt
          elsif alarm_active = '1' then -- Alarm active
              data <= DISPLAY_FAILURE;  
          else
              -- Normal state display
              case state_code is
                  when 0 =>
                      data <= DISPLAY_CONSTANT;  
                  when 1 =>
                      data <= DISPLAY_ARMED;     
                  when 2 =>
                      data <= DISPLAY_FAILURE;   
                  when others =>
            data <= DISPLAY_CONSTANT;
    end case;
end if;

        end if;
    end process;

end rtl;
