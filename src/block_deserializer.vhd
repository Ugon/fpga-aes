library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utils.all;

entity block_deserializer is
	generic (
		byte_bits    : Integer := 8;
		block_bytes  : Integer := 4;   --test
		block_bits   : Integer := 32); --test
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
dbg_forward_finished   : out std_logic);
end block_deserializer;

architecture block_deserializer_impl of block_deserializer is
	type fsm is (await_pulse, receive_bytes);
	signal state : fsm;

	signal forward_start    : std_logic                                             := '1';
	signal forward_finished : std_logic                                             := '0';
	signal block_buffer     : std_logic_vector(block_bits - byte_bits - 1 downto 0) := (others => '0');

	signal finished_listening_out_extended  : std_logic_vector(block_bits - 1 downto 0) := (others => '0');

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

	finished_listening_out_extended <= (others => rx_finished_listening and forward_finished);
	finished_listening_out          <= finished_listening_out_extended(0);
	rx_start_listening              <= (start_listening_in and forward_start) or start_next_byte;
----------------TMP
	correct_out <= finished_listening_out;
----------------TMP
	block_out(block_bits - 1 downto block_bits - byte_bits) <= rx_byte and 
		finished_listening_out_extended(block_bits - 1 downto block_bits - byte_bits);

	block_out(block_bits - byte_bits - 1 downto 0) <= block_buffer and
		finished_listening_out_extended(block_bits - byte_bits - 1 downto 0);

	process (clk_16, reset_n) 
		variable byte_position            : Integer range 0 to block_bytes - 1 := 0;
		variable delayed_forward_start    : boolean                            := false;
		variable delayed_forward_finished : boolean                            := false;
	begin
		if (reset_n = '0') then
			state                          <= await_pulse;
			forward_start                  <= '1';
			forward_finished               <= '0';
			trigger_start_next_byte_action <= '0';
			delayed_forward_start          := false;
			delayed_forward_finished       := false;
			byte_position                  := 0;
			block_buffer                   <= (others => '0');

		elsif(rising_edge(clk_16)) then
			case state is
				when await_pulse =>
					forward_finished <= '0';
					delayed_forward_finished := false;

					if (delayed_forward_start) then
						state <= receive_bytes;
						byte_position := 0;
						forward_start <= '0';
						delayed_forward_start := false;
					elsif (start_listening_in = '1') then
						delayed_forward_start := true;
					end if;

				when receive_bytes =>
					if (rx_finished_listening = '1') then
						if (byte_position < block_bytes - 1) then
							block_buffer((byte_position + 1) * byte_bits - 1 downto byte_position * byte_bits) <= rx_byte;
							byte_position := byte_position + 1;
							trigger(trigger_start_next_byte_action, trigger_start_next_byte_reaction);
						else 
							state <= await_pulse;
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

	dbg_forward_start <= forward_start;
	dbg_forward_finished <= forward_finished;

end block_deserializer_impl;