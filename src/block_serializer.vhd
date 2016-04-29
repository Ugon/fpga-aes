library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity block_serializer is
	generic (
		data_bits    : Integer := 8;
		block_bytes  : Integer := 16;
		block_length : Integer := 128);
	port (
		provide_next  : in    std_logic; --rising edge triggers preparation. available on falling edge
		reset_n       : in    std_logic;
		data_out      : out   std_logic_vector(data_bits - 1 downto 0);
		available_out : out   std_logic; --available on rising edge
		block_in      : in    std_logic_vector(block_length - 1 downto 0);
		available_in  : in    std_logic);--available on rising edge
end block_serializer;

architecture block_serializer_impl of block_serializer is
	type fsm is (idle, transmit);
	signal state : fsm;

	signal block_latched  : std_logic_vector(block_length - 1 downto 0);
	signal block_new1     : std_logic := '0';
	signal block_new2     : std_logic := '0';

	signal data_available : std_logic := '0';

begin
	available_out <= data_available and not provide_next;

	process (available_in) begin
		if (reset_n = '0') then
			block_latched <= (others => '0');
			block_new2 <= '0';
		elsif (rising_edge(available_in)) then
			block_latched <= block_in;
			block_new2 <= not block_new1;
		end if;
	end process;

	process (provide_next, reset_n, block_in) 
		variable byte_position : Integer range 0 to block_bytes - 1 := 0;
	begin
		if (reset_n = '0') then
			byte_position        := 0;
			data_out             <= (others => '0');
			state                <= idle;
			block_new1           <= '0';

		elsif(rising_edge(provide_next)) then
			if (block_new1 = not block_new2) then
				data_out <= block_latched(data_bits - 1 downto 0);
				byte_position := 1;
				data_available <= '1';
				state <= transmit;
				block_new1 <= block_new2;
			else 
				case state is
					when idle =>
						data_available <= '0';
	
					when transmit =>
						if (byte_position < block_bytes - 1) then
							data_out <= block_latched((byte_position + 1) * data_bits - 1 downto byte_position * data_bits);
							byte_position := byte_position + 1;
						else
							data_out <= block_latched(block_length - 1 downto block_length - data_bits);
							state <= idle;
						end if;

				end case;
			end if;
		end if;
	end process;

end block_serializer_impl;