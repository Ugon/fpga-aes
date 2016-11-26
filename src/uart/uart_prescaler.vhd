library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_prescaler is
	port (
		clk_in      : in    std_logic; --50MHz
		clk_out     : out   std_logic  --16 * 115200Hz
	);
end uart_prescaler;

architecture uart_prescaler_impl of uart_prescaler is
	signal clk : std_logic := '0';
begin
	clk_out <= clk;

	process (clk_in) 
		variable counter : Integer range 0 to 13 := 0;
	begin	
		if(rising_edge(clk_in)) then
			case counter is
				when 13 =>
					clk <= not clk;
					counter := 0;
				when others =>
					counter := counter + 1;
			end case;
		end if;
	end process;

end uart_prescaler_impl;