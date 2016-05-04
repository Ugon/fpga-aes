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



	--process (clk_in) 
	--	variable counter : Integer range 0 to counter_limit := 0;
	--begin	
	--	if(rising_edge(clk_in)) then
	--		if (counter < half) then
	--			clk_out <= '0';
	--			counter := counter + 1;
	--		elsif (counter < counter_limit) then
	--			clk_out <= '1';
	--			counter := counter + 1;
	--		else 
	--			counter := 0;		
	--		end if;	
	--	end if;	
	--end process;


	--process (clk_in) 
	--	variable counter : Integer range 0 to 15624 := 0;
	--begin	
	--	if(rising_edge(clk_in)) then
	--		case counter is
	--			when 0 =>
	--				clk_out <= '1';
	--				counter := counter + 1;
	--			when 2604 =>
	--				clk_out <= '0';
	--				counter := counter + 1;
	--			when 5208 =>
	--				clk_out <= '1';
	--				counter := counter + 1;
	--			when 7812 =>
	--				clk_out <= '0';
	--				counter := counter + 1;
	--			when 10416 =>
	--				clk_out <= '1';
	--				counter := counter + 1;
	--			when 13020 =>
	--				clk_out <= '0';
	--				counter := counter + 1;
	--			when 15623 =>
	--				counter := 0;
	--			when others =>
	--				counter := counter + 1;
	--		end case;
	--	end if;	
	--end process;
	

	--process (clk_in) 
	--	variable counter1 : Integer range 0 to 76803 := 0;
	--	variable counter2 : Integer range 0 to 651 := 0;
	--begin	
	--	if(rising_edge(clk_in)) then
	--		if (counter1 < 76207) then
	--			if (counter2 < 324) then
	--				counter2 := counter2 + 1;
	--				clk_out <= '1';
	--			elsif (counter2 < 650) then
	--				counter2 := counter2 + 1;
	--				clk_out <= '0';
	--			else
	--				counter1 := counter1 + 1;
	--				counter2 := 0;
	--			end if;

	--		else
	--			if (counter2 < 325) then
	--				counter2 := counter2 + 1;
	--				clk_out <= '1';
	--			elsif (counter2 < 651) then
	--				counter2 := counter2 + 1;
	--				clk_out <= '0';
	--			else
	--				if (counter1 < 76803) then 
	--					counter1 := counter1 + 1;
	--				else 
	--					counter1 := 0;
	--				end if;
	--				counter2 := 0;
	--			end if;
	--		end if;
	--	end if;	
	--end process;


	process (clk_in) 
		variable counter : Integer range 0 to 650 := 0;
	begin	
		if(rising_edge(clk_in)) then
			case counter is
				when 0 =>
					clk_out <= '1';
					counter := counter + 1;
				when 163 =>
					clk_out <= '0';
					counter := counter + 1;
				when 325 =>
					clk_out <= '1';
					counter := counter + 1;
				when 488 =>
					clk_out <= '0';
					counter := counter + 1;
				when 650 =>
					counter := 0;
				when others =>
					counter := counter + 1;
			end case;
		end if;
	end process;



end uart_prescaler_impl;