library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utils.all;
use work.crc16.all;

entity block_serializer is
	generic (
		byte_bits   : Integer := 8;
		block_bytes : Integer := 4;   --test
		block_bits  : Integer := 32;  --test
		crc_bytes   : Integer := 2;
		crc_bits    : Integer := 16);
	port (
		reset_n                  : in  std_logic;
		clk_16                   : in  std_logic; --16x baud rate

		--TO TX
		tx_byte                  : out std_logic_vector(byte_bits - 1 downto 0)  := (others => 'X');
		tx_start_transmitting    : out std_logic                                 := 'X';
		tx_finished_transmitting : in  std_logic;

		--API
		aes_block                : in  std_logic_vector(block_bits - 1 downto 0);
		start_transmitting       : in  std_logic;
		finished_transmitting    : out std_logic                                 := 'X');
end block_serializer;

architecture block_serializer_impl of block_serializer is
	type fsm is (await_pulse, transmit_block, transmit_crc);
	signal state : fsm;

	signal byte_crc_position                : Integer range 0 to block_bytes + crc_bytes - 1 := 0;
	signal byte_crc_position_latched        : Integer range 0 to block_bytes + crc_bytes - 1 := 0;

	signal forward_start                    : std_logic := '1';
	signal forward_finished                 : std_logic := '0';

	signal tx_start_transmitting_internal   : std_logic := '0';
	
	signal block_buffer                     : std_logic_vector(block_bits - 1 downto 0)            := (others => '0');
	signal crc_buffer                       : std_logic_vector(crc_bits - 1 downto 0)              := (others => '0');
	signal block_crc_buffer                 : std_logic_vector(block_bits + crc_bits - 1 downto 0) := (others => '0');
	signal crc_accumulator                  : std_logic_vector(crc_bits - 1 downto 0)              := (others => '0');

	signal trigger_start_next_byte_action   : std_logic := '0';
	signal trigger_start_next_byte_reaction : std_logic := '0';
	signal start_next_byte                  : std_logic := '0';

begin

	finished_transmitting          <= tx_finished_transmitting and forward_finished;
	tx_start_transmitting_internal <= (start_transmitting and forward_start) or start_next_byte;
	tx_start_transmitting          <= tx_start_transmitting_internal;

	block_crc_buffer(block_bits - 1                        downto 0)                                 <= block_buffer;
	block_crc_buffer(block_bits + crc_bits - 1             downto block_bits + crc_bits - byte_bits) <= crc_buffer(byte_bits - 1 downto 0);
	block_crc_buffer(block_bits + crc_bits - byte_bits - 1 downto block_bits)                        <= crc_buffer(crc_bits - 1 downto byte_bits);

	trigger0 : entity work.trigger
		port map (
			clk_16        => clk_16,
			reset_n       => reset_n,
			action        => trigger_start_next_byte_action,
			reaction      => trigger_start_next_byte_reaction,
			pulse_signal  => start_next_byte
		);
	
	process (start_transmitting, aes_block, block_crc_buffer, byte_crc_position_latched) begin
		if (start_transmitting = '1') then
			tx_byte <= aes_block(byte_bits - 1 downto 0);
		else
			tx_byte <= block_crc_buffer((byte_crc_position_latched + 1) * byte_bits - 1 downto byte_crc_position_latched * byte_bits);
		end if;
	end process;

	process (reset_n, tx_start_transmitting_internal) begin
		if (reset_n = '0') then
			byte_crc_position_latched <= 0;
		elsif (rising_edge(tx_start_transmitting_internal)) then
			byte_crc_position_latched <= byte_crc_position;
		end if;
	end process;

	process (clk_16, reset_n)
		variable delayed_forward_start    : boolean := false;
		variable delayed_forward_finished : boolean := false;
	begin
		if (reset_n = '0') then
			state                          <= await_pulse;
			forward_start                  <= '1';
			forward_finished               <= '0';
			trigger_start_next_byte_action <= '0';
			delayed_forward_start          := false;
			delayed_forward_finished       := false;
			byte_crc_position              <= 0;
			block_buffer                   <= (others => '0');
			crc_buffer                     <= (others => '0');
			crc_accumulator                <= (others => '0');

		elsif(rising_edge(clk_16)) then
			case state is
				when await_pulse =>
					forward_finished <= '0';
					delayed_forward_finished := false;

					if (delayed_forward_start) then
						state <= transmit_block;
						byte_crc_position <= 0;
						forward_start <= '0';
						delayed_forward_start := false;
					elsif (start_transmitting = '1') then
						block_buffer <= aes_block;
						crc_accumulator <= crc_init;
						delayed_forward_start := true;
					end if;

				when transmit_block =>
					if (tx_finished_transmitting = '1') then
						trigger(trigger_start_next_byte_action, trigger_start_next_byte_reaction);

						if (byte_crc_position < block_bytes - 1) then
							crc_accumulator <= crc_add_data(crc_accumulator, block_buffer((byte_crc_position + 1) * byte_bits - 1 downto byte_crc_position * byte_bits));
						else
							state <= transmit_crc;
							crc_buffer <= crc_finish(crc_add_data(crc_accumulator, block_buffer(block_bits - 1 downto block_bits - byte_bits)));
						end if;

						byte_crc_position <= byte_crc_position + 1;
					end if;		

				when transmit_crc =>
					if (tx_finished_transmitting = '1') then
						if (byte_crc_position < block_bytes + crc_bytes - 1) then
							trigger(trigger_start_next_byte_action, trigger_start_next_byte_reaction);
							byte_crc_position <= byte_crc_position + 1;
						else
							state <= await_pulse;
							byte_crc_position <= 0;
							forward_start <= '1';
						end if;
					end if;

					if (delayed_forward_finished) then
						forward_finished <= '1';
					elsif (byte_crc_position = block_bytes + crc_bytes - 1) then
						delayed_forward_finished := true;
					end if;

			end case;
		end if;
	end process;

end block_serializer_impl;