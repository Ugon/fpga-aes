library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_prescaler is
	generic (
		clk_in_freq   : Integer := 50000000;
		clk_out_freq  : Integer := 16 * 9600
	);
	port (
		clk_in      : in    std_logic;
		clk_out     : out   std_logic
	);
end uart_prescaler;

architecture uart_prescaler_impl of uart_prescaler is
	constant counter_limit : Integer := clk_in_freq / clk_out_freq;
	constant half          : Integer := counter_limit / 2;
begin

	process (clk_in) 
		variable counter : Integer range 0 to counter_limit := 0;
	begin	
		if(rising_edge(clk_in)) then
			if (counter < half) then
				clk_out <= '0';
				counter := counter + 1;
			elsif (counter < counter_limit) then
				clk_out <= '1';
				counter := counter + 1;
			else 
				counter := 0;		
			end if;	
		end if;	
	end process;

end uart_prescaler_impl;