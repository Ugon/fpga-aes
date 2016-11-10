library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utils.all;
use work.crc16.all;

entity block_deserializer is
	generic (
		byte_bits    : Integer := 8;
		block_bytes  : Integer := 4;   --test
		block_bits   : Integer := 32;  --test
		crc_bytes    : Integer := 2;
		crc_bits     : Integer := 16);
		--block_bytes  : Integer := 16;
		--block_bits   : Integer := 128);
	port (
		reset_n                   : in  std_logic;
		clk_16                    : in  std_logic; --16x baud rate

		--FROM RX
		rx_byte                   : in  std_logic_vector(byte_bits - 1 downto 0);
		rx_start_listening        : out std_logic                                 := 'X';
		rx_finished_listening     : in  std_logic;

		--API
		block_out                 : out std_logic_vector(block_bits - 1 downto 0) := (others => 'X');
		start_listening_in        : in  std_logic;
		finished_listening_out    : out std_logic                                 := 'X';
		correct_out               : out std_logic                                 := 'X';

dbg_forward_start      : out std_logic;
dbg_forward_finished   : out std_logic;
dbg_crc_accumulator    : out std_logic_vector(crc_bits - 1 downto 0)
);
end block_deserializer;

architecture block_deserializer_impl of block_deserializer is
	type fsm is (await_pulse, receive_block, receive_crc);
	signal state : fsm;

	signal forward_start      : std_logic := '1';
	signal forward_finished   : std_logic := '0';
	signal finished_listening : std_logic := '0';
	signal correct_latched    : std_logic := '0';

	signal block_buffer       : std_logic_vector(block_bits - 1 downto 0) := (others => '0');
	signal crc_accumulator    : std_logic_vector(crc_bits - 1 downto 0)   := (others => '0');
	
	signal trigger_start_next_byte_action   : std_logic := '0';
	signal trigger_start_next_byte_reaction : std_logic := '0';
	signal start_next_byte                  : std_logic := '0';

begin

	finished_listening     <= rx_finished_listening and forward_finished;
	finished_listening_out <= finished_listening;
	rx_start_listening     <= (start_listening_in and forward_start) or start_next_byte;

	trigger0 : entity work.trigger
		port map (
			clk_16        => clk_16,
			reset_n       => reset_n,
			action        => trigger_start_next_byte_action,
			reaction      => trigger_start_next_byte_reaction,
			pulse_signal  => start_next_byte
		);

	process (finished_listening, rx_byte, correct_latched, crc_accumulator) begin
		if (finished_listening = '1') then
			correct_out <= crc_verify(crc_add_data(crc_accumulator, rx_byte));
		else
			correct_out <= '0';
		end if;
	end process;

	process (reset_n, finished_listening) begin
		if (reset_n = '0') then
			block_out <= (others => '0');
		elsif (rising_edge(finished_listening)) then
			block_out <= block_buffer;
		end if;
	end process;

	process (clk_16, reset_n) 
		variable byte_position            : Integer range 0 to block_bytes - 1     := 0;
		variable crc_position             : Integer range 0 to crc_bytes   - 1     := 0;
		variable delayed_forward_start    : boolean                                := false;
		variable delayed_forward_finished : boolean                                := false;
	begin
		if (reset_n = '0') then
			state                          <= await_pulse;
			forward_start                  <= '1';
			forward_finished               <= '0';
			trigger_start_next_byte_action <= '0';
			delayed_forward_start          := false;
			delayed_forward_finished       := false;
			byte_position                  := block_bytes - 1;
			crc_position                   := 0;
			block_buffer                   <= (others => '0');
			crc_accumulator                <= (others => '0');

		elsif(rising_edge(clk_16)) then
			case state is
				when await_pulse =>
					forward_finished <= '0';
					delayed_forward_finished := false;

					if (delayed_forward_start) then
						state <= receive_block;
						byte_position := 0;
						crc_accumulator <= crc_init;
						forward_start <= '0';
						delayed_forward_start := false;
					elsif (start_listening_in = '1') then
						delayed_forward_start := true;
					end if;

				when receive_block =>
					if (rx_finished_listening = '1') then
						block_buffer((byte_position + 1) * byte_bits - 1 downto byte_position * byte_bits) <= rx_byte;
						crc_accumulator <= crc_add_data(crc_accumulator, rx_byte);
						trigger(trigger_start_next_byte_action, trigger_start_next_byte_reaction);

						if (byte_position = block_bytes - 1) then
							state <= receive_crc;
							crc_position := crc_bytes - 1;
						else
							byte_position := byte_position + 1;
						end if;
					end if;

				when receive_crc =>
					if (rx_finished_listening = '1') then
						if (crc_position > 0) then
							crc_accumulator <= crc_add_data(crc_accumulator, rx_byte);
							trigger(trigger_start_next_byte_action, trigger_start_next_byte_reaction);
						else 				
							correct_latched <= crc_verify(crc_add_data(crc_accumulator, rx_byte));
							forward_start <= '1';
						end if;

						if (crc_position = 0) then
							state <= await_pulse;
						else
							crc_position := crc_position - 1;
						end if;
					end if;			

					if (delayed_forward_finished) then
						forward_finished <= '1';
					elsif (crc_position = 0) then
						delayed_forward_finished := true;
					end if;

			end case;
		end if;
	end process;

	dbg_forward_start <= forward_start;
	dbg_forward_finished <= forward_finished;
	dbg_crc_accumulator <= crc_finish(crc_accumulator);

end block_deserializer_impl;