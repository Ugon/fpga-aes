library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utils.all;

--no parity bits
--1 start bit
--1 stop bit
--LSB first

entity uart_rx is
	generic (
		byte_bits : Integer := 8);
	port (
		reset_n            : in  std_logic;
		clk_16             : in  std_logic; --16x baud rate
		rx                 : in  std_logic;
			
		byte               : out std_logic_vector(byte_bits - 1 downto 0) := (others => '0');
		start_listening    : in  std_logic;
		finished_listening : out std_logic                                := '0';

dbg_cnt                   : out Integer range 0 to 15;
dbg_start_error           : out std_logic;
dbg_stop_error            : out std_logic;
dbg_rx_state              : out Integer range 0 to 3
		);
end uart_rx;

architecture uart_rx_impl of uart_rx is
	type fsm is (await_pulse, await_start, confirm_start, receive_byte, await_stop);
	signal state : fsm;

	signal trigger_finished_action     : std_logic                                := '0';
	signal trigger_finished_reaction   : std_logic                                := '0';
	signal finished_listening_internal : std_logic                                := '0';

	signal byte_buffer                 : std_logic_vector(byte_bits - 1 downto 0) := (others => '0');

	signal oversample_buffer           : std_logic_vector(2 downto 0)             := (others => '0');
	signal vote_result                 : std_logic                                := '0';

	function vote(signal samples : in std_logic_vector(2 downto 0)) return std_logic is begin
		return ((samples(0) and samples(1)) or (samples(1) and samples(2)) or (samples(0) and samples(2)));
	end function;

begin

	finished_listening <= finished_listening_internal;

	vote_result <= vote(oversample_buffer);

	trigger0 : entity work.trigger_toggle
		generic map (
			size               => byte_bits,
			toggle_out_default => '0')
		port map (
			clk_16        => clk_16,
			reset_n       => reset_n,
			action        => trigger_finished_action,
			reaction      => trigger_finished_reaction,
			pulse_signal  => finished_listening_internal,
			toggle_in     => byte_buffer,
			toggle_out    => byte
		);

	process (clk_16, reset_n) 
		variable bit_position      : Integer range 0 to byte_bits - 1 := 0;
		variable counter           : Integer range 0 to 15;
	begin
		if (reset_n = '0') then
			state                   <= await_start;
			bit_position            := 0;
			counter                 := 0;
			oversample_buffer       <= (others => '0');
			byte_buffer             <= (others => '0');
			trigger_finished_action <= '0';
dbg_start_error <= '0';
dbg_stop_error <= '0';
		elsif(rising_edge(clk_16)) then
			case state is
				when await_pulse =>
					if (start_listening = '1' and rx = '0') then
						state <= confirm_start;
						counter := 1;
					elsif (start_listening) then
						state <= await_start;
						counter := 0;
					end if;

				when await_start =>
					if (rx = '0') then
						state <= confirm_start;
						counter := 1;
					end if;

				when confirm_start =>
					if (counter = 7) then
						oversample_buffer(0) <= rx;
						counter := 8;
					elsif (counter = 8) then
						oversample_buffer(1) <= rx;
						counter := 9;
					elsif (counter = 9) then
						oversample_buffer(2) <= rx;
						counter := 10;
					elsif (counter = 15 and vote_result = '0') then 
						state <= receive_byte;
						counter := 0;
						bit_position := 0;
					elsif (counter = 15) then
						--start bit error
dbg_start_error <= '1';
						state <= await_pulse;
						trigger(trigger_finished_action, trigger_finished_reaction);
					else 
						counter := counter + 1;
					end if;
				
				when receive_byte =>
					if (counter = 7) then
						oversample_buffer(0) <= rx;
						counter := 8;
					elsif (counter = 8) then
						oversample_buffer(1) <= rx;
						counter := 9;
					elsif (counter = 9) then
						oversample_buffer(2) <= rx;
						counter := 10;
					elsif (counter = 15 and bit_position = byte_bits - 1) then 
						state <= await_stop;
						byte_buffer(bit_position) <= vote_result;
						counter := 0;
					elsif (counter = 15) then
						byte_buffer(bit_position) <= vote_result;
						bit_position := bit_position + 1;
						counter := 0;
					else 
						counter := counter + 1;
					end if;
				
				when await_stop =>
					if (counter = 7) then
						oversample_buffer(0) <= rx;
						counter := 8;
					elsif (counter = 8) then
						oversample_buffer(1) <= rx;
						counter := 9;
					elsif (counter = 9) then
						oversample_buffer(2) <= rx;
						counter := 10;
					elsif (counter = 10 and vote_result = '1') then 
						state <= await_pulse;
						trigger(trigger_finished_action, trigger_finished_reaction);
						counter := 0;
					elsif (counter = 10) then
						--stop bit error
dbg_stop_error <= '1';
						state <= await_pulse;
						trigger(trigger_finished_action, trigger_finished_reaction);
						counter := 0;
					else 
						counter := counter + 1;
					end if;

			end case;
		end if;

		dbg_cnt <= counter;
	end process;


	process (state) begin
		case state is
			when await_pulse   => dbg_rx_state <= 0;
			when await_start   => dbg_rx_state <= 1; 
			when confirm_start => dbg_rx_state <= 2;
			when receive_byte  => dbg_rx_state <= 3;
			when await_stop    => dbg_rx_state <= 3;
		end case;
	end process;

end uart_rx_impl;