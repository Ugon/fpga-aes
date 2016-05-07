library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_prescaler is
	port (
		clk_in      : in    std_logic; --50 000 000
		clk_out     : out   std_logic
	);
end uart_prescaler;

architecture uart_prescaler_impl of uart_prescaler is

	signal tmp : std_logic := '0';

begin

	----9600
	--process (clk_in) 
	--	variable counter : Integer range 0 to 650 := 0;
	--begin	
	--	if(rising_edge(clk_in)) then
	--		case counter is
	--			when 0 =>
	--				clk_out <= '1';
	--				counter := counter + 1;
	--			when 163 =>
	--				clk_out <= '0';
	--				counter := counter + 1;
	--			when 325 =>
	--				clk_out <= '1';
	--				counter := counter + 1;
	--			when 488 =>
	--				clk_out <= '0';
	--				counter := counter + 1;
	--			when 650 =>
	--				counter := 0;
	--			when others =>
	--				counter := counter + 1;
	--		end case;
	--	end if;
	--end process;

	--115200
	process (clk_in) 
		variable counter : Integer range 0 to 26 := 0;
	begin	
		if(rising_edge(clk_in)) then
			case counter is
				when 0 =>
					clk_out <= '1';
					counter := counter + 1;
				when 13 =>
					clk_out <= '0';
					counter := counter + 1;
				when 26 =>
					counter := 0;
				when others =>
					counter := counter + 1;
			end case;
		end if;
	end process;

end uart_prescaler_impl;