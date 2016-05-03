library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utils.all;

--no parity bits
--1 start bit
--1 stop bit
--LSB first

entity uart_tx is
	generic (
		byte_bits : Integer := 8);
	port (
		reset_n                   : in  std_logic;
		clk_16                    : in  std_logic; --16x baud rate
		tx                        : out std_logic                                := 'X';

		byte_in                   : in  std_logic_vector(byte_bits - 1 downto 0);
		start_transmitting_in     : in  std_logic;
		finished_transmitting_out : out std_logic                                := 'X';

		dbg_cnt                   : out Integer range 0 to 15;
		dbg_state                 : out Integer range 0 to 3);
end uart_tx;

architecture uart_tx_impl of uart_tx is
	type fsm is (await_pulse, start, bits, stop);
	signal state : fsm := await_pulse;

	signal trigger_finished_action   : std_logic := '0';
	signal trigger_finished_reaction : std_logic := '0';

	signal byte_buffer : std_logic_vector(byte_bits - 1 downto 0) := (others => '0');

begin

	trigger0 : entity work.trigger
		port map (
			clk_16        => clk_16,
			reset_n       => reset_n,
			action        => trigger_finished_action,
			reaction      => trigger_finished_reaction,
			pulse_signal  => finished_transmitting_out
		);

	process (clk_16, byte_buffer, reset_n) 
		variable bit_position         : Integer range 0 to byte_bits - 1    := 0;
		variable counter              : Integer range 0 to 15;
	begin
		if (reset_n = '0') then
			state                   <= await_pulse;
			bit_position            := 0;
			counter                 := 0;
			byte_buffer             <= (others => '0');
			tx                      <= '1';
			trigger_finished_action <= '0';
		elsif(rising_edge(clk_16)) then
			case state is
				when await_pulse =>
					if (start_transmitting_in = '1') then
						tx <= '0';
						counter := 1;
						byte_buffer <= byte_in;
						state <= start;
					end if;

				when start =>
					if (counter = 15) then
						counter := 0;
						bit_position := 0;
						tx <= byte_buffer(0);
						state <= bits;
					else 
						counter := counter + 1;
					end if;
				
				when bits =>
					if (counter = 15) then
						counter := 0;
						if (bit_position < byte_bits - 1) then
							bit_position := bit_position + 1;
							tx <= byte_buffer(bit_position);
						else
							tx <= '1';
							state <= stop;
						end if;
					else 
						counter := counter + 1;
					end if;

				when stop =>
					if (counter = 14) then
						counter := 15;
						trigger(trigger_finished_action, trigger_finished_reaction);
					elsif (counter = 15) then
						counter := 0;
						state <= await_pulse;
					else 
						counter := counter + 1;
					end if;

			end case;
		end if;

		dbg_cnt <= counter;
	end process;

	process (state) begin
		case state is
			when await_pulse =>
				dbg_state <= 0;
			when start =>
				dbg_state <= 1;
			when bits =>
				dbg_state <= 2;
			when stop =>
				dbg_state <= 3;
		end case;
	end process;
end uart_tx_impl;