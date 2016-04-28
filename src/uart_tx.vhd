library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--no parity bits
--1 start bit
--1 stop bit
--LSB first

entity uart_tx is
	generic (
		number_of_bits : Integer := 8);
	port (
		reset_n     : in    std_logic;
		clk         : in    std_logic; --16x baud rate
		data        : in    std_logic_vector(number_of_bits - 1 downto 0);
		available   : in    std_logic; --available on rising edge
		tx          : out   std_logic);
end uart_tx;

architecture uart_tx_impl of uart_tx is
	type fsm is (await_start, start, bits, stop);
	signal state : fsm := await_start;

	signal data_buffer : std_logic_vector(7 downto 0) := (others => '0');

	signal available1 : std_logic := '0';
	signal available2 : std_logic := '0';
begin

	process (available, reset_n) begin
		if (reset_n = '0') then
			data_buffer <= (others => '0');
			available1 <= '0';
		elsif (rising_edge(available)) then
			if (state = await_start) then
				data_buffer <= data;
				available1 <= not available2;
			end if;
		end if;
	end process;

	process (clk, data_buffer, reset_n) 
		variable bit_position         : Integer range 0 to 7    := 0;
		variable counter              : Integer range 0 to 15;
	begin
		if (reset_n = '0') then
			state <= await_start;
			available2 <= '0';
			bit_position := 0;
			counter := 0;
			tx <= '1';
		elsif(rising_edge(clk)) then
			case state is
				when await_start =>
					if (available1 /= available2) then
						available2 <= available1;
						counter := 0;
						tx <= '0';
						state <= start;
					end if;

				when start =>
					if (counter = 15) then
						counter := 0;
						bit_position := 0;
						tx <= data_buffer(0);
						state <= bits;
					else 
						counter := counter + 1;
					end if;
				
				when bits =>
					if (counter = 15) then
						counter := 0;
						if (bit_position < 7) then
							bit_position := bit_position + 1;
							tx <= data_buffer(bit_position);
						else
							tx <= '1';
							state <= stop;
						end if;
					else 
						counter := counter + 1;
					end if;

				when stop =>
					if (counter =  15) then 
						counter := 0;
						state <= await_start;
					else 
						counter := counter + 1;
					end if;

				end case;
			end if;
	end process;

end uart_tx_impl;