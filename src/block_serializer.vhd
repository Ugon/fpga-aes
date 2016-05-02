library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utils.all;

entity block_serializer is
	generic (
		byte_bits    : Integer := 8;
		block_bytes  : Integer := 4;   --test
		block_bits   : Integer := 32); --test
		--block_bytes  : Integer := 16;
		--block_bits   : Integer := 128);
	port (
		reset_n                   : in  std_logic;
		clk_16                    : in  std_logic; --16x baud rate

		--TO TX
		tx_byte                   : out std_logic_vector(byte_bits - 1 downto 0)  := (others => 'X');
		tx_start_transmitting     : out std_logic                                 := 'X';
		tx_finished_transmitting  : in  std_logic;

		--API
		block_in                  : in  std_logic_vector(block_bits - 1 downto 0);
		start_transmitting_in     : in  std_logic;
		finished_transmitting_out : out std_logic                                 := 'X';

dbg_byte_position : out Integer range 0 to block_bytes - 1;
dbg_forward_start : out std_logic;
dbg_forward_finished : out std_logic);
end block_serializer;

architecture block_serializer_impl of block_serializer is
	type fsm is (await_pulse, transmit_bytes);
	signal state : fsm;

	signal byte_position    : Integer range 0 to block_bytes - 1        := 0;
	signal byte_prepared    : std_logic_vector(byte_bits - 1 downto 0)  := (others => '0');

	signal forward_start    : std_logic                                 := '1';
	signal forward_finished : std_logic                                 := '0';
	signal block_buffer     : std_logic_vector(block_bits - 1 downto 0) := (others => '0');

	signal tx_start_transmitting_extended   : std_logic_vector(byte_bits - 1 downto 0) := (others => '0');

	signal trigger_start_next_byte_action   : std_logic := '0';
	signal trigger_start_next_byte_reaction : std_logic := '0';
	signal start_next_byte                  : std_logic := '0';

begin

	trigger0 : entity work.trigger
		port map (
			clk_16        => clk_16,
			reset_n       => reset_n,
			action        => trigger_start_next_byte_action,
			reaction_in   => trigger_start_next_byte_reaction,
			reaction_out  => trigger_start_next_byte_reaction,
			pulse_signal  => start_next_byte
		);

	finished_transmitting_out      <= tx_finished_transmitting and forward_finished;

	tx_start_transmitting_extended <= (others => (start_transmitting_in and forward_start) or start_next_byte);
	tx_start_transmitting          <= tx_start_transmitting_extended(0);
	tx_byte                        <= byte_prepared and tx_start_transmitting_extended;

	process (byte_position, block_in, block_buffer) begin
		if (byte_position = 0) then
			byte_prepared <= block_in(byte_bits - 1 downto 0);
		else
			byte_prepared <= block_buffer((byte_position + 1) * byte_bits - 1 downto byte_position * byte_bits);
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
			byte_position                  <= 0;
			block_buffer                   <= (others => '0');

		elsif(rising_edge(clk_16)) then
			case state is
				when await_pulse =>
					forward_finished <= '0';
					delayed_forward_finished := false;

					if (delayed_forward_start) then
						state <= transmit_bytes;
						forward_start <= '0';
						delayed_forward_start := false;
					elsif (start_transmitting_in = '1') then
						block_buffer <= block_in;
						delayed_forward_start := true;
					end if;

				when transmit_bytes =>
					if (tx_finished_transmitting = '1') then
						if (byte_position < block_bytes - 1) then
							byte_position <= byte_position + 1;
							trigger(trigger_start_next_byte_action, trigger_start_next_byte_reaction);
						else
							state <= await_pulse;
							byte_position <= 0;
							forward_start <= '1';
						end if;
					end if;

					if (delayed_forward_finished) then
						forward_finished <= '1';
					elsif (byte_position = block_bytes - 1) then
						delayed_forward_finished := true;
					end if;

			end case;
		end if;
	end process;

dbg_byte_position <= byte_position;
dbg_forward_start <= forward_start;
dbg_forward_finished <= forward_finished;

end block_serializer_impl;