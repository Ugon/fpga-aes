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
		reset_n                   : in  std_logic;
		clk_16                    : in  std_logic; --16x baud rate
		rx                        : in  std_logic;
			
		byte_out                  : out std_logic_vector(byte_bits - 1 downto 0) := (others => '0');
		start_listening_in        : in  std_logic;
		finished_listening_out    : out std_logic                                := '0';

dbg_cnt                   : out Integer range 0 to 15;
dbg_start_error           : out std_logic;
dbg_stop_error            : out std_logic
		);
end uart_rx;

architecture uart_rx_impl of uart_rx is
	type fsm is (await_pulse, await_start, confirm_start, receive_byte, await_stop);
	signal state : fsm;

	signal trigger_finished_action   : std_logic := '0';
	signal trigger_finished_reaction : std_logic := '0';
	signal finished_listening        : std_logic := '0';

	signal byte_buffer : std_logic_vector(byte_bits - 1 downto 0) := (others => '0');

	function vote(samples : in std_logic_vector(2 downto 0)) return std_logic is begin
		return ((samples(0) and samples(1)) or (samples(1) and samples(2)) or (samples(0) and samples(2)));
	end function;

begin

	finished_listening_out <= finished_listening;

	trigger0 : entity work.trigger
		port map (
			clk_16        => clk_16,
			reset_n       => reset_n,
			action        => trigger_finished_action,
			reaction      => trigger_finished_reaction,
			pulse_signal  => finished_listening
		);

	process (reset_n, finished_listening) begin
		if (reset_n = '0') then
			byte_out <= (others => '0');
		elsif (rising_edge(finished_listening)) then
			byte_out <= byte_buffer;
		end if;

	end process;

	process (clk_16, reset_n) 
		variable bit_position      : Integer range 0 to byte_bits - 1         := 0;
		variable counter           : Integer range 0 to 15;
		variable oversample_buffer : std_logic_vector(2 downto 0) := (others => '0');
	begin
		if (reset_n = '0') then
			state                   <= await_start;
			bit_position            := 0;
			counter                 := 0;
			oversample_buffer       := (others => '0');
			byte_buffer             <= (others => '0');
			trigger_finished_action <= '0';
dbg_start_error <= '0';
dbg_stop_error <= '0';
		elsif(rising_edge(clk_16)) then
			case state is
				when await_pulse =>
					if (start_listening_in = '1') then
						if (rx = '0') then
							state <= confirm_start;
							counter := 1;
						else 
							state <= await_start;
							counter := 0;
						end if;
					end if;

				when await_start =>
					if (rx = '0') then
						state <= confirm_start;
						counter := 1;
					end if;

				when confirm_start =>
					case counter is
						when 7  => oversample_buffer(0) := rx;
						when 8  => oversample_buffer(1) := rx;
						when 9  => oversample_buffer(2) := rx;
						when 15 => 
							if (vote(oversample_buffer) = '0') then
								state <= receive_byte;
								bit_position := 0;
							else
								--start bit error
dbg_start_error <= '1';
								state <= await_pulse;
								trigger(trigger_finished_action, trigger_finished_reaction);
							end if;
						when others =>
					end case;

					if (counter < 15) then 
						counter := counter + 1;
					else 
						counter := 0;
					end if;
				
				when receive_byte =>
					case counter is
						when 7  => oversample_buffer(0) := rx;
						when 8  => oversample_buffer(1) := rx;
						when 9  => oversample_buffer(2) := rx;
						when 15 => 
							byte_buffer(bit_position) <= vote(oversample_buffer);
							if (bit_position < byte_bits - 1) then
								bit_position := bit_position + 1;
								state <= receive_byte;
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
							trigger(trigger_finished_action, trigger_finished_reaction);

							if (vote(oversample_buffer) = '0') then 
							--	stop bit error
dbg_stop_error <= '1';
							end if;
						when 15 => 
							state <= await_pulse;
						when others =>
					end case;
					
					if (counter < 15) then 
						counter := counter + 1;
					else 
						counter := 0;
					end if;

			end case;
		end if;

		dbg_cnt <= counter;
	end process;

end uart_rx_impl;