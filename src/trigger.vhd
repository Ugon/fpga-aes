library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity trigger is
	port (
		clk_16       : in    std_logic;
		reset_n      : in    std_logic; 
		action       : in    std_logic;
		reaction_in  : in    std_logic;
		reaction_out : out   std_logic;
		pulse_signal : out   std_logic);
end trigger;

architecture trigger_impl of trigger is begin

	process (clk_16, reset_n) 
		variable feedback : std_logic := '0';
	begin
		if (reset_n = '0') then
			pulse_signal     <= '0';
			reaction_out     <= '0';
			feedback         := '0';
		elsif (falling_edge(clk_16)) then
			if (reaction_in = not action) then
				pulse_signal <= '1';
				feedback     := '1';
			elsif (feedback = '1') then
				pulse_signal <= '0';
				feedback     := '0';
			end if;
			reaction_out     <= action;
		end if;
	end process;
	
end trigger_impl;