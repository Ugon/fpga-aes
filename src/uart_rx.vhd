library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--no parity bits
--1 start bit
--1 stop bit
--LSB first

entity uart_rx is
	generic (
		number_of_bits : Integer := 8
	);
	port (
		reset_n     : in    std_logic;
		clk         : in    std_logic; --16x baud rate
		rx          : in    std_logic;
		
		data        : out   std_logic_vector(number_of_bits - 1 downto 0);
		available   : out   std_logic; --available on rising edge
		cnt         : out   Integer range 0 to 15
	);
end uart_rx;

architecture uart_rx_impl of uart_rx is
	type fsm is (await_start, confirm_start, receive_bits, await_stop);
	signal state : fsm;

	signal data_buffer : std_logic_vector(7 downto 0);

	function vote(samples : in std_logic_vector(2 downto 0)) return std_logic is begin
		return ((samples(0) and samples(1)) or (samples(1) and samples(2)) or (samples(0) and samples(2)));
	end function;
begin

	process (clk, reset_n) 
		variable bit_position         : Integer range 0 to 7    := 0;
		variable counter              : Integer range 0 to 15;
		variable oversample_buffer    : std_logic_vector(2 downto 0) := (others => '0');
	begin
		if (reset_n = '0') then
			state <= await_start;
			available <= '0';
			data <= (others => '0');
			bit_position := 0;
			oversample_buffer := (others => '0');
			counter := 0;
		elsif(rising_edge(clk)) then
			case state is
				when await_start =>
					available <= '0';
					if (rx = '0') then
						state <= confirm_start;
						counter := 1;
					else
					 	counter := 0;
					end if;

				when confirm_start =>
					case counter is
						when 7  => oversample_buffer(0) := rx;
						when 8  => oversample_buffer(1) := rx;
						when 9  => oversample_buffer(2) := rx;
						when 15 => 
							if (vote(oversample_buffer) = '0') then
								state <= receive_bits;
								bit_position := 0;
							else
								state <= await_start;
							end if;
						when others =>
					end case;

					if (counter < 15) then 
						counter := counter + 1;
					else 
						counter := 0;
					end if;
				
				when receive_bits =>
					case counter is
						when 7  => oversample_buffer(0) := rx;
						when 8  => oversample_buffer(1) := rx;
						when 9  => oversample_buffer(2) := rx;
						when 15 => 
							data_buffer(bit_position) <= vote(oversample_buffer);
							if (bit_position < 7) then
								bit_position := bit_position + 1;
								state <= receive_bits;
							else 
								state <= await_stop;
							end if;
						when others =>
					end case;

					if (counter < 15) then 
						counter := counter + 1;
					else 
						counter := 0;
					end if;
				
				when await_stop =>
					case counter is		
						when 7  => oversample_buffer(0) := rx;
						when 8  => oversample_buffer(1) := rx;
						when 9  => oversample_buffer(2) := rx;
						when 14 => 
							if (vote(oversample_buffer) = '1') then
								data <= data_buffer;
							else 
								state <= await_start;
							end if;
						when 15 => 
							available <= '1';
							state <= await_start;
						when others =>
					end case;
					
					if (counter < 15) then 
						counter := counter + 1;
					else 
						counter := 0;
					end if;

				end case;
			end if;
		cnt <= counter;
	end process;

end uart_rx_impl;