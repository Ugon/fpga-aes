library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity block_deserializer is
	generic (
		data_bits    : Integer := 8;
		block_bytes  : Integer := 16;
		block_length : Integer := 128);
	port (
		clk           : in    std_logic;
		reset_n       : in    std_logic;
		data_in       : in    std_logic_vector(data_bits - 1 downto 0);
		available_in  : in    std_logic; --available on rising edge
		block_out     : out   std_logic_vector(block_length - 1 downto 0);
		available_out : out   std_logic);--available on rising edge
end block_deserializer;

architecture block_deserializer_impl of block_deserializer is
	type fsm is (first, remaining);
	signal state : fsm;

	signal available_pre_delay1 : std_logic := '0';
	signal available_pre_delay2 : std_logic := '0';
	signal block_buffer         : std_logic_vector(block_length - data_bits - 1 downto 0);

begin

	process (available_in, reset_n, data_in) 
		variable byte_position : Integer range 0 to block_bytes - 1 := 0;
	begin
		if (reset_n = '0') then
			byte_position        := 0;
			block_out            <= (others => '0');
			block_buffer         <= (others => '0');
			state                <= first;
			available_pre_delay1 <= '0';

		elsif(rising_edge(available_in)) then
			case state is
				when first =>
					block_buffer(data_bits - 1 downto 0) <= data_in;
					byte_position := 1;
					state <= remaining;
				 
				when remaining =>
					if (byte_position < block_bytes - 1) then
						block_buffer((byte_position + 1) * data_bits - 1 downto byte_position * data_bits) <= data_in;
						byte_position := byte_position + 1;
					else 
						byte_position := 0;
						state <= first;
						available_pre_delay1 <= not available_pre_delay2;
						block_out(block_length - data_bits - 1 downto 0) <= block_buffer;
						block_out(block_length - 1 downto block_length - data_bits) <= data_in;
					end if;

			end case;
		end if;
	end process;

	process(clk, reset_n, available_pre_delay1, available_pre_delay2)
	begin
		if (reset_n = '0') then
			available_out        <= '0';
			available_pre_delay2 <= '0';
		elsif(rising_edge(clk)) then
			if (available_pre_delay1 = not available_pre_delay2) then
				available_pre_delay2 <= available_pre_delay1;
				available_out <= '1';
			else 
				available_out <= '0';
			end if;
		end if;
	end process;

end block_deserializer_impl;