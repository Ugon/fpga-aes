library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package utils is

	procedure trigger (
		signal action       : out std_logic;
		signal reaction     : in std_logic);

	--procedure trigger_react (
	--	signal clk_16       : in    std_logic;
	--	signal reset_n      : in    std_logic; 
	--	signal action       : in    std_logic;
	--	signal reaction     : inout std_logic;
	--	signal feedback     : inout std_logic;
	--	signal pulse_signal : out   std_logic);

end utils;

package body utils is

	procedure trigger (signal action : out std_logic; signal reaction : in std_logic) is begin
		action <= not reaction;
	end procedure;

	--procedure trigger_react (
	--	signal clk_16       : in    std_logic;
	--	signal reset_n      : in    std_logic; 
	--	signal action       : in    std_logic;
	--	signal reaction     : inout std_logic;
	--	signal feedback     : inout std_logic;
	--	signal pulse_signal : out   std_logic) is
	--begin
	--	if (reset_n = '0') then
	--		pulse_signal     <= '0';
	--		reaction         <= '0';
	--		feedback         <= '0';
	--	elsif (falling_edge(clk_16)) then
	--		if (reaction = not action) then
	--			pulse_signal <= '1';
	--			feedback     <= '1';
	--		elsif (feedback = '1') then
	--			pulse_signal <= '0';
	--			feedback     <= '0';
	--		end if;
	--		reaction         <= action;
	--	end if;
	--end procedure;

end utils;