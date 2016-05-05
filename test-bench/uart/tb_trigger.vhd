library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_trigger is 
	generic (runner_cfg : string);
end tb_trigger;

use work.utils.all;

architecture behavioral of tb_trigger is

	component trigger is
		port (
			clk_16       : in    std_logic;
			reset_n      : in    std_logic; 
			action       : in    std_logic;
			reaction     : out   std_logic;
			pulse_signal : out   std_logic);
	end component;

	constant clk_period : time := 10 ns;
	
	signal clk_16       : std_logic := '0';
	signal reset_n      : std_logic := '0'; 
	signal action       : std_logic := '0';
	signal reaction     : std_logic := '0';
	signal pulse_signal : std_logic := '0';

	signal clk_chk               : std_logic := '0';
	signal expected_pulse_signal : std_logic := '0';

	signal high : std_logic := '1';
	signal low  : std_logic := '0';
	signal test : std_logic := '1';

begin

	uut : component trigger
		port map(
			clk_16       => clk_16,
			reset_n      => reset_n,
			action       => action,
			reaction     => reaction,
			pulse_signal => pulse_signal
		);

	clk_16  <= not clk_16 after clk_period / 2;
	reset_n <= '1' after 1 ns;

	test <= not (expected_pulse_signal xor pulse_signal);
	check_stable(clk_chk, high, high, low, test, active_clock_edge => both_edges);

	process begin 
		wait for clk_period / 8;
		loop
			clk_chk <= not clk_chk;
			wait for clk_period / 4;
		end loop;
	end process;

	process begin
		test_runner_setup(runner, runner_cfg);
		
		wait until reset_n = '1';

		for i in 0 to 2 loop

			wait until clk_16'event and clk_16 = '0';
			wait until clk_16'event and clk_16 = '1';

			work.utils.trigger(action, reaction);
	
			wait until clk_16'event and clk_16 = '0';
			expected_pulse_signal <= '1';
	
			wait until clk_16'event and clk_16 = '0';
			expected_pulse_signal <= '0';

		end loop;

		test_runner_cleanup(runner);
	end process;
	
end behavioral;