library ieee;
use ieee.std_logic_1164.all;

entity HA_System_TB is
end;

architecture tb of HA_System_TB is
    signal clk, rst : std_logic := '0';

    signal pass_btn : std_logic := '0';
    signal door_raw, window_raw, motion_raw : std_logic := '0';

    signal alarm_siren, system_armed : std_logic;
    signal display_data : std_logic_vector(7 downto 0);
    signal state_code_dbg : std_logic_vector(2 downto 0);

    constant Tclk : time := 10 ns;

    -- ===== Helper procedures =====
    procedure wait_clocks(n : natural) is
    begin
        for i in 1 to n loop
            wait until rising_edge(clk);
        end loop;
        wait for 1 ns; -- לא לבדוק בדיוק על חזית
    end procedure;

    procedure press_short(signal btn : out std_logic) is
	 begin
		  btn <= '1';
		  wait until rising_edge(clk);
		  btn <= '0';
		  wait until rising_edge(clk);
	 end procedure;

    procedure press_long(signal btn : out std_logic) is
	 begin
		  btn <= '1';
		  for i in 1 to 5 loop   -- 5 clocks > K=3
			   wait until rising_edge(clk);
		  end loop;
		  btn <= '0';
		  wait until rising_edge(clk);
	 end procedure;
        -- Wait enough time for:
    -- 8 button presses -> 8 bit_valid pulses -> Code_register -> code_ready -> FSM
    procedure wait_for_fsm_capture is
    begin
        wait_clocks(50);  -- 50 clocks = 500ns (safe margin)
    end procedure;

    procedure send_code_all_zeros(signal btn: out std_logic) is
    begin
        for i in 0 to 7 loop
            press_short(btn);
        end loop;

        wait_for_fsm_capture;
    end procedure;

    procedure send_code_wrong(signal btn: out std_logic) is
	 begin
		 press_long(btn);       -- first bit = 1
		 for i in 0 to 6 loop
			 press_short(btn);  -- next bits = 0
		 end loop;
		 wait_clocks(50);
	 end procedure;

begin
    -- DUT
    dut: entity work.HA_System
        port map (
            clk            => clk,
            rst            => rst,
            pass_btn       => pass_btn,
            door_raw       => door_raw,
            window_raw     => window_raw,
            motion_raw     => motion_raw,
            alarm_siren    => alarm_siren,
            system_armed   => system_armed,
            display_data   => display_data,
            state_code_dbg => state_code_dbg
        );

    -- Clock
    clk <= not clk after Tclk/2;

    stim: process
    begin
        ------------------------------------------------------------
        -- Reset
        ------------------------------------------------------------
        rst <= '1';
        wait for 5*Tclk;
        rst <= '0';
        wait_clocks(3);

        ------------------------------------------------------------
        -- 1) Verify ARMED after reset
        ------------------------------------------------------------
        report "TEST 1: Verify system is ARMED after reset..." severity note;

        if system_armed /= '1' then
            report "FAIL: Expected system_armed='1' after reset" severity error;
        else
            report "PASS: System armed after reset." severity note;
        end if;

        ------------------------------------------------------------
        -- 2) Trigger intrusion (door+window) -> ALARM
        ------------------------------------------------------------
        report "TEST 2: Trigger intrusion (door+window)..." severity note;

        door_raw   <= '1';
        window_raw <= '1';

        -- debounce (3 clocks) + עוד קצת ל-FSM
        wait_clocks(6);

        if alarm_siren /= '1' then
            report "FAIL: Expected alarm_siren='1' after intrusion" severity error;
        else
            report "PASS: Alarm siren ON after intrusion." severity note;
        end if;

        ------------------------------------------------------------
        -- 3) Send WRONG code 3 times -> attempts should rise
        ------------------------------------------------------------
        report "TEST 3: Wrong code #1..." severity note;
        send_code_wrong(pass_btn);

        report "TEST 4: Wrong code #2..." severity note;
        send_code_wrong(pass_btn);

        report "TEST 5: Wrong code #3 (should LOCK)..." severity note;
        send_code_wrong(pass_btn);

        -- עכשיו אתה אמור לראות attempts=3 ו-state_code=011 ב-Wave
        wait_clocks(5);

        ------------------------------------------------------------
        -- 4) Wait for LOCKED release (LOCK_CYCLES=5) then disarm with correct code
        ------------------------------------------------------------
        report "TEST 6: Waiting for LOCKED release..." severity note;
        wait_clocks(10); -- מרווח בטיחות

        report "TEST 7: Correct code -> DISARM..." severity note;
        send_code_all_zeros(pass_btn);

        wait_clocks(5);

        if alarm_siren /= '0' then
            report "FAIL: Expected alarm_siren='0' after correct code (disarm)" severity error;
        else
            report "PASS: Alarm turned off." severity note;
        end if;

        if system_armed /= '0' then
            report "FAIL: Expected system_armed='0' after disarm" severity error;
        else
            report "PASS: System disarmed." severity note;
        end if;

        report "=== END OF HA_System_TB ===" severity note;
        wait;
    end process;

end tb;
