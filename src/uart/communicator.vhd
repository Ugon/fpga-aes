library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utils.all;
use work.aes_utils.all;


entity communicator is
	generic (
		byte_bits    : Integer := 8;
		block_bytes  : Integer := 16;
		block_bits   : Integer := 128;
		key_bytes    : Integer := 32;
		key_bits     : Integer := 256);
	port (
		clk_16                 : in    std_logic; --16x baudrate
		reset_n                : in    std_logic;
		rx                     : in    std_logic;
		tx                     : out   std_logic;


dbg_rx0_byte_out                          : out std_logic_vector(byte_bits - 1 downto 0);
dbg_rx0_start_listening_in                : out std_logic;
dbg_rx0_finished_listening_out            : out std_logic;

dbg_tx0_byte_in                           : out std_logic_vector(byte_bits - 1 downto 0);
dbg_tx0_start_transmitting_in             : out std_logic;
dbg_tx0_finished_transmitting_out         : out std_logic;

dbg_deserializer0_block_out               : out std_logic_vector(block_bits - 1 downto 0);
dbg_deserializer0_start_listening_in      : out std_logic;
dbg_deserializer0_finished_listening_out  : out std_logic;
dbg_deserializer0_correct_out             : out std_logic;

dbg_serializer0_block_in                  : out std_logic_vector(block_bits - 1 downto 0);
dbg_serializer0_start_transmitting_in     : out std_logic;
dbg_serializer0_finished_transmitting_out : out std_logic;

dbg_state                                 : out Integer range 0 to 15;

dbg_cnt_rx                                : out Integer range 0 to 15;
dbg_cnt_tx                                : out Integer range 0 to 15;

dbg_mux_rx0_enable_custom                 : out std_logic;

dbg_serializer0_tx_byte                   : out std_logic_vector(byte_bits - 1 downto 0);

dbg_start_error           : out std_logic;
dbg_stop_error            : out std_logic;
dbg_rx_state              : out Integer range 0 to 3
);
end communicator;

architecture communicator_impl of communicator is
	type fsm is (start, key_high, key_high_ack, key_low, key_low_ack, initialization_vector, initialization_vector_ack, 
		blocks, blocks_r_finished_t_waiting, blocks_r_waiting_t_finished, blocks_ack, acks_r_finished_t_waiting, acks_r_waiting_t_finished, 
		finishing, finishing_ack);
	signal state : fsm := start;

	constant  ACK : std_logic_vector(byte_bits - 1 downto 0) := "01000001"; --ASCII('A')
	constant NACK : std_logic_vector(byte_bits - 1 downto 0) := "01001110"; --ASCII('B')
	constant  FIN : std_logic_vector(byte_bits - 1 downto 0) := "01000110"; --ASCII('F')

	--AES SIGNALS
	signal aes_key                : std_logic_vector(key_bits   - 1 downto 0) := (others => '0');
	signal aes_plaintext          : std_logic_vector(block_bits - 1 downto 0) := (others => '0');
	signal aes_cyphertext         : std_logic_vector(block_bits - 1 downto 0) := (others => '0');

	signal key                    : std_logic_vector(key_bits   - 1 downto 0) := (others => '0');
	signal plaintext              : std_logic_vector(block_bits - 1 downto 0) := (others => '0');
	signal cyphertext             : std_logic_vector(block_bits - 1 downto 0) := (others => '0');
	signal previous_ciphertext    : std_logic_vector(block_bits - 1 downto 0) := (others => '0');

	signal block_zeros            : std_logic_vector(block_bits - 1 downto 0) := (others => '0');

    --ENTITY CONNECTIONS SIGNALS
	signal rx0_byte_out                          : std_logic_vector(byte_bits - 1 downto 0)  := (others => '0');
	signal rx0_start_listening_in                : std_logic                                 := '0';
	signal rx0_finished_listening_out            : std_logic                                 := '0';

	signal deserializer0_rx_byte                 : std_logic_vector(byte_bits - 1 downto 0)  := (others => '0');
	signal deserializer0_rx_start_listening      : std_logic                                 := '0';
	signal deserializer0_rx_finished_listening   : std_logic                                 := '0';
	signal deserializer0_block_out               : std_logic_vector(block_bits - 1 downto 0) := (others => '0');
	signal deserializer0_start_listening_in      : std_logic                                 := '0';
	signal deserializer0_finished_listening_out  : std_logic                                 := '0';
	signal deserializer0_correct_out             : std_logic                                 := '0';

	signal tx0_byte_in                           : std_logic_vector(byte_bits - 1 downto 0)  := (others => '0');
	signal tx0_start_transmitting_in             : std_logic                                 := '0';
	signal tx0_finished_transmitting_out         : std_logic                                 := '0';

	signal serializer0_tx_byte                   : std_logic_vector(byte_bits - 1 downto 0)  := (others => '0');
	signal serialzier0_tx_start_transmitting     : std_logic                                 := '0';
	signal serialzier0_tx_finished_transmitting  : std_logic                                 := '0';
	signal serializer0_block_in                  : std_logic_vector(block_bits - 1 downto 0) := (others => '0');
	signal serializer0_start_transmitting_in     : std_logic                                 := '0';
	signal serializer0_finished_transmitting_out : std_logic                                 := '0';

	--CUSTOM CONNECTION SIGNALS
	signal custom0_rx_byte                  : std_logic_vector(byte_bits - 1 downto 0)  := (others => '0');
	signal custom0_rx_start_listening       : std_logic                                 := '0';
	signal custom0_rx_finished_listening    : std_logic                                 := '0';

	signal custom0_tx_byte                  : std_logic_vector(byte_bits - 1 downto 0)  := (others => '0');
	signal custom0_tx_start_transmitting    : std_logic                                 := '0';
	signal custom0_tx_finished_transmitting : std_logic                                 := '0';

	--RX TX SIGNAL MUX
	signal mux_switch_pulse  : std_logic := '0';
	signal mux_enable_custom : std_logic := '0';
	
	signal next_custom0_tx_byte      : std_logic_vector(byte_bits - 1 downto 0)  := (others => '0');
	signal next_serializer0_block_in : std_logic_vector(block_bits - 1 downto 0) := (others => '0');
	
	signal trigger_mux_switch0_action   : std_logic := '0';
	signal trigger_mux_switch0_reaction : std_logic := '0';

	--START PULSE TRIGGERS
	signal trigger_deserializer0_start_listening_action    : std_logic := '0';
	signal trigger_deserializer0_start_listening_reaction  : std_logic := '0';
	signal trigger_custom0_rx_start_listening_action       : std_logic := '0';
	signal trigger_custom0_rx_start_listening_reaction     : std_logic := '0';
	
	signal trigger_serializer0_start_transmitting_action   : std_logic := '0';
	signal trigger_serializer0_start_transmitting_reaction : std_logic := '0';
	signal trigger_custom0_tx_start_transmitting_action    : std_logic := '0';
	signal trigger_custom0_tx_start_transmitting_reaction  : std_logic := '0';

	--ACK CONTROL SIGNALS
	signal transmit_success : std_logic := '0';
	signal receive_success  : std_logic := '0';

begin

dbg_rx0_byte_out                          <= rx0_byte_out;
dbg_rx0_start_listening_in                <= rx0_start_listening_in;
dbg_rx0_finished_listening_out            <= rx0_finished_listening_out;

dbg_tx0_byte_in                           <= tx0_byte_in;
dbg_tx0_start_transmitting_in             <= tx0_start_transmitting_in;
dbg_tx0_finished_transmitting_out         <= tx0_finished_transmitting_out;

dbg_deserializer0_block_out               <= deserializer0_block_out;
dbg_deserializer0_start_listening_in      <= deserializer0_start_listening_in;
dbg_deserializer0_finished_listening_out  <= deserializer0_finished_listening_out;
dbg_deserializer0_correct_out             <= deserializer0_correct_out;

dbg_serializer0_block_in                  <= serializer0_block_in;
dbg_serializer0_start_transmitting_in     <= serializer0_start_transmitting_in;
dbg_serializer0_finished_transmitting_out <= serializer0_finished_transmitting_out;

dbg_mux_rx0_enable_custom                 <= mux_enable_custom;

dbg_serializer0_tx_byte                   <= serializer0_tx_byte;

	block_zeros   <= (others => '0');
	aes_key       <= reverse_byte_order(key);
	aes_plaintext <= reverse_byte_order(previous_ciphertext) xor reverse_byte_order(plaintext);
	cyphertext    <= reverse_byte_order(aes_cyphertext);

	aes0 : entity work.aes256
		generic map (
			byte_bits                 => byte_bits,
			block_bytes               => block_bytes,
			block_bits                => block_bits,
			key_bytes                 => key_bytes,
			key_bits                  => key_bits)
		port map (
			key                       => aes_key,
			plaintext                 => aes_plaintext,
			cyphertext                => aes_cyphertext
		);

	uart_rx0 : entity work.uart_rx
		generic map (
			byte_bits                 => byte_bits)
		port map (
			reset_n                   => reset_n,
			clk_16                    => clk_16,
			rx                        => rx,
			
			byte_out                  => rx0_byte_out,
			start_listening_in        => rx0_start_listening_in,
			finished_listening_out    => rx0_finished_listening_out,
			
			dbg_cnt                   => dbg_cnt_rx,
			dbg_start_error           => dbg_start_error,
			dbg_stop_error            => dbg_stop_error,
			dbg_rx_state              => dbg_rx_state
		);

	entity_tx0 : entity work.uart_tx
		generic map (
			byte_bits                 => byte_bits)
		port map (
			reset_n                   => reset_n,
			clk_16                    => clk_16,
			tx                        => tx,
			
			byte_in                   => tx0_byte_in,
			start_transmitting_in     => tx0_start_transmitting_in,
			finished_transmitting_out => tx0_finished_transmitting_out,
			dbg_cnt                   => dbg_cnt_tx
		);	

	block_deserializer0 : entity work.block_deserializer
		generic map (
			byte_bits                 => byte_bits,
			block_bytes               => block_bytes,
			block_bits                => block_bits)
		port map (
			reset_n                   => reset_n,
			clk_16                    => clk_16,
			
			--FROM RX
			rx_byte                   => deserializer0_rx_byte,
			rx_start_listening        => deserializer0_rx_start_listening,
			rx_finished_listening     => deserializer0_rx_finished_listening,

			--API
			block_out                 => deserializer0_block_out,
			start_listening_in        => deserializer0_start_listening_in,
			finished_listening_out    => deserializer0_finished_listening_out,
			correct_out               => deserializer0_correct_out
		);

	block_serializer0 : entity work.block_serializer 
		generic map (
			byte_bits                 => byte_bits,
			block_bytes               => block_bytes,
			block_bits                => block_bits)
		port map (
			reset_n                   => reset_n,
			clk_16                    => clk_16,

			--TO TX
			tx_byte                   => serializer0_tx_byte,
			tx_start_transmitting     => serialzier0_tx_start_transmitting,
			tx_finished_transmitting  => serialzier0_tx_finished_transmitting,

			--API
			block_in                  => serializer0_block_in,
			start_transmitting_in     => serializer0_start_transmitting_in,
			finished_transmitting_out => serializer0_finished_transmitting_out
		);

	trigger0 : entity work.trigger
		port map (
			clk_16        => clk_16,
			reset_n       => reset_n,
			action        => trigger_deserializer0_start_listening_action,
			reaction      => trigger_deserializer0_start_listening_reaction,
			pulse_signal  => deserializer0_start_listening_in
		);

	trigger1 : entity work.trigger
		port map (
			clk_16        => clk_16,
			reset_n       => reset_n,
			action        => trigger_custom0_rx_start_listening_action,
			reaction      => trigger_custom0_rx_start_listening_reaction,
			pulse_signal  => custom0_rx_start_listening
		);

	trigger2 : entity work.trigger
		port map (
			clk_16        => clk_16,
			reset_n       => reset_n,
			action        => trigger_serializer0_start_transmitting_action,
			reaction      => trigger_serializer0_start_transmitting_reaction,
			pulse_signal  => serializer0_start_transmitting_in
		);

	trigger3 : entity work.trigger
		port map (
			clk_16        => clk_16,
			reset_n       => reset_n,
			action        => trigger_custom0_tx_start_transmitting_action,
			reaction      => trigger_custom0_tx_start_transmitting_reaction,
			pulse_signal  => custom0_tx_start_transmitting
		);

	trigger4 : entity work.trigger
		port map (
			clk_16        => clk_16,
			reset_n       => reset_n,
			action        => trigger_mux_switch0_action,
			reaction      => trigger_mux_switch0_reaction,
			pulse_signal  => mux_switch_pulse
		);


	mux_rx0 : process (mux_enable_custom, rx0_byte_out, custom0_rx_start_listening, rx0_finished_listening_out, deserializer0_rx_start_listening) begin
		if (mux_enable_custom = '1') then
			custom0_rx_byte                      <= rx0_byte_out;
			rx0_start_listening_in               <= custom0_rx_start_listening;
			custom0_rx_finished_listening        <= rx0_finished_listening_out;
			deserializer0_rx_byte                <= (others => '0');
			deserializer0_rx_finished_listening  <= '0';
		else
			deserializer0_rx_byte                <= rx0_byte_out;
			rx0_start_listening_in               <= deserializer0_rx_start_listening;
			deserializer0_rx_finished_listening  <= rx0_finished_listening_out;
			custom0_rx_byte                      <= (others => '0');
			custom0_rx_finished_listening        <= '0';
		end if;
	end process;

	mux_tx0 : process (mux_enable_custom, tx0_finished_transmitting_out, custom0_tx_byte, custom0_tx_start_transmitting, serializer0_tx_byte, serialzier0_tx_start_transmitting) begin
		if (mux_enable_custom = '1') then
			tx0_byte_in                            <= custom0_tx_byte;
			tx0_start_transmitting_in              <= custom0_tx_start_transmitting;
			custom0_tx_finished_transmitting       <= tx0_finished_transmitting_out;
			serialzier0_tx_finished_transmitting   <= '0';
		else
			tx0_byte_in                            <= serializer0_tx_byte;
			tx0_start_transmitting_in              <= serialzier0_tx_start_transmitting;
			serialzier0_tx_finished_transmitting   <= tx0_finished_transmitting_out;
			custom0_tx_finished_transmitting       <= '0';
		end if;
	end process;

	mux_switch0 : process (reset_n, mux_switch_pulse) begin
		if(reset_n = '0') then
			mux_enable_custom <= '0';
		elsif(rising_edge(mux_switch_pulse)) then
			mux_enable_custom <= not mux_enable_custom;
		end if;
	end process;

	tx_byte_set : process (reset_n, custom0_tx_start_transmitting) begin
		if (reset_n = '0') then
			custom0_tx_byte <= (others => '0');
		elsif (rising_edge(custom0_tx_start_transmitting)) then
			custom0_tx_byte <= next_custom0_tx_byte;
		end if;
	end process;

	serializer_byte_set : process (reset_n, serializer0_start_transmitting_in) begin
		if (reset_n = '0') then
			serializer0_block_in <= (others => '0');
		elsif (rising_edge(serializer0_start_transmitting_in)) then
			serializer0_block_in <= next_serializer0_block_in;
		end if;
	end process;

	communication_flow : process (clk_16, reset_n)
		variable received_correct_block : std_logic := '0';
		variable finished               : std_logic := '0';

		procedure handle_deserializer_finished (
			signal p_deserializer0_block_out      : in  std_logic_vector;
			signal p_received_block               : out std_logic_vector;
			signal p_next_custom0_tx_byte         : out std_logic_vector;
			p_received_correct_block              : out std_logic;
			p_deserializer0_correct_out           : in  std_logic) is
			variable p_tmp_received_correct_block :     std_logic := '0';
		begin
			--read receiver output
			p_received_block                    <= p_deserializer0_block_out;
			p_tmp_received_correct_block        := p_deserializer0_correct_out;
			p_received_correct_block            := p_tmp_received_correct_block;
				
			--set transmitter input
			if (p_tmp_received_correct_block = '1') then
				p_next_custom0_tx_byte          <= ACK;
			else 
				p_next_custom0_tx_byte          <= NACK;
			end if;
		end;

		procedure handle_custom_rx_finished (
			signal p_block_future                 : in    std_logic_vector;
			signal p_block_current                : in    std_logic_vector;
			signal p_block_old                    : inout std_logic_vector;
			signal p_next_serializer0_block_in    : out   std_logic_vector;
			signal p_custom0_rx_byte              : in    std_logic_vector;
			p_received_correct_block              : in    std_logic) is
			variable p_tmp_received_correct_block :       std_logic := '0';
		begin
			--read receiver output and set transmitter input
			if (p_received_correct_block = '1' and (p_custom0_rx_byte = ACK or p_custom0_rx_byte = FIN)) then
				p_next_serializer0_block_in     <= p_block_future;
				p_block_old                     <= p_block_current;
			else 
				p_next_serializer0_block_in     <= p_block_current;
				p_block_old                     <= p_block_old;
			end if;
		end;

	begin
		if (reset_n = '0') then
			state                                         <= start;
			finished                                      := '0';
			received_correct_block                        := '0';
			next_custom0_tx_byte                          <= (others => '0');
			next_serializer0_block_in                     <= (others => '0');
			plaintext                                     <= (others => '0');
			previous_ciphertext                           <= (others => '0');
			trigger_mux_switch0_action                    <= '0';
			trigger_custom0_rx_start_listening_action     <= '0';
			trigger_deserializer0_start_listening_action  <= '0';
			trigger_custom0_tx_start_transmitting_action  <= '0';
			trigger_serializer0_start_transmitting_action <= '0';

		elsif (rising_edge(clk_16)) then
			case state is
				when start =>
					state <= key_high;
					
					trigger(trigger_deserializer0_start_listening_action, trigger_deserializer0_start_listening_reaction);
	

				when key_high =>
					if (deserializer0_finished_listening_out = '1') then
						state <= key_high_ack;

						handle_deserializer_finished(
							p_deserializer0_block_out   => deserializer0_block_out,
							p_received_block            => key(key_bits - 1 downto key_bits - block_bits),
							p_deserializer0_correct_out => deserializer0_correct_out,
							p_received_correct_block    => received_correct_block,
							p_next_custom0_tx_byte      => next_custom0_tx_byte);

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_custom0_tx_start_transmitting_action, trigger_custom0_tx_start_transmitting_reaction);
					end if;


				when key_high_ack =>
					if (custom0_tx_finished_transmitting = '1' and received_correct_block = '1') then
						state <= key_low;
					
						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_deserializer0_start_listening_action, trigger_deserializer0_start_listening_reaction);

					elsif (custom0_tx_finished_transmitting = '1' and received_correct_block = '0') then
						state <= key_high;
					
						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_deserializer0_start_listening_action, trigger_deserializer0_start_listening_reaction);
					end if;


				when key_low =>
					if (deserializer0_finished_listening_out = '1') then
						state <= key_low_ack;

						handle_deserializer_finished(
							p_deserializer0_block_out   => deserializer0_block_out,
							p_received_block            => key(block_bits - 1 downto 0),
							p_deserializer0_correct_out => deserializer0_correct_out,
							p_received_correct_block    => received_correct_block,
							p_next_custom0_tx_byte      => next_custom0_tx_byte);

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_custom0_tx_start_transmitting_action, trigger_custom0_tx_start_transmitting_reaction);
					end if;				


				when key_low_ack =>
					if (custom0_tx_finished_transmitting = '1' and received_correct_block = '1') then
						state <= initialization_vector;

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_deserializer0_start_listening_action, trigger_deserializer0_start_listening_reaction);

					elsif (custom0_tx_finished_transmitting = '1' and received_correct_block = '0') then
						state <= key_low;
						
						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_deserializer0_start_listening_action, trigger_deserializer0_start_listening_reaction);
					end if;


				when initialization_vector =>
					if (deserializer0_finished_listening_out = '1') then
						state <= initialization_vector_ack;

						handle_deserializer_finished(
							p_deserializer0_block_out   => deserializer0_block_out,
							p_received_block            => previous_ciphertext,
							p_deserializer0_correct_out => deserializer0_correct_out,
							p_received_correct_block    => received_correct_block,
							p_next_custom0_tx_byte      => next_custom0_tx_byte);

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_custom0_tx_start_transmitting_action, trigger_custom0_tx_start_transmitting_reaction);
					end if;				


				when initialization_vector_ack =>
					if (custom0_tx_finished_transmitting = '1' and received_correct_block = '1') then
						state <= blocks_r_waiting_t_finished;
					
						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_deserializer0_start_listening_action, trigger_deserializer0_start_listening_reaction);

					elsif (custom0_tx_finished_transmitting = '1' and received_correct_block = '0') then
						state <= initialization_vector;
					
						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_deserializer0_start_listening_action, trigger_deserializer0_start_listening_reaction);
					end if;


				when blocks =>
 					--if receiver and transmitter finished at the same time
 					if (deserializer0_finished_listening_out = '1' and serializer0_finished_transmitting_out = '1') then
						state <= blocks_ack;

						handle_deserializer_finished(
							p_deserializer0_block_out   => deserializer0_block_out,
							p_received_block            => plaintext,
							p_deserializer0_correct_out => deserializer0_correct_out,
							p_received_correct_block    => received_correct_block,
							p_next_custom0_tx_byte      => next_custom0_tx_byte);

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_custom0_rx_start_listening_action, trigger_custom0_rx_start_listening_reaction);
						trigger(trigger_custom0_tx_start_transmitting_action, trigger_custom0_tx_start_transmitting_reaction);

					--if receiver finished first
					elsif (deserializer0_finished_listening_out = '1') then
						state <= blocks_r_finished_t_waiting;

						handle_deserializer_finished(
							p_deserializer0_block_out   => deserializer0_block_out,
							p_received_block            => plaintext,
							p_deserializer0_correct_out => deserializer0_correct_out,
							p_received_correct_block    => received_correct_block,
							p_next_custom0_tx_byte      => next_custom0_tx_byte);

					--if transmitter finished first
					elsif (serializer0_finished_transmitting_out = '1') then
						state <= blocks_r_waiting_t_finished;
					end if;


				when blocks_r_finished_t_waiting =>
					if (serializer0_finished_transmitting_out = '1') then
						state <= blocks_ack;

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_custom0_rx_start_listening_action, trigger_custom0_rx_start_listening_reaction);
						trigger(trigger_custom0_tx_start_transmitting_action, trigger_custom0_tx_start_transmitting_reaction);
					end if;


				when blocks_r_waiting_t_finished =>
					if (deserializer0_finished_listening_out = '1') then
						state <= blocks_ack;

						handle_deserializer_finished(
							p_deserializer0_block_out   => deserializer0_block_out,
							p_received_block            => plaintext,
							p_deserializer0_correct_out => deserializer0_correct_out,
							p_received_correct_block    => received_correct_block,
							p_next_custom0_tx_byte      => next_custom0_tx_byte);

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_custom0_rx_start_listening_action, trigger_custom0_rx_start_listening_reaction);
						trigger(trigger_custom0_tx_start_transmitting_action, trigger_custom0_tx_start_transmitting_reaction);
					end if;


				when blocks_ack =>
 					--if receiver and transmitter finished at the same time
					if(custom0_rx_finished_listening = '1' and custom0_tx_finished_transmitting = '1' and custom0_rx_byte = FIN) then
						state <= finishing;

						handle_custom_rx_finished (
							p_block_future              => cyphertext,
							p_block_current             => serializer0_block_in,
							p_block_old                 => previous_ciphertext,
							p_next_serializer0_block_in => next_serializer0_block_in,
							p_custom0_rx_byte           => custom0_rx_byte,
							p_received_correct_block    => received_correct_block);

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_serializer0_start_transmitting_action, trigger_serializer0_start_transmitting_reaction);

					elsif(custom0_rx_finished_listening = '1' and custom0_tx_finished_transmitting = '1') then
						state <= blocks;

						handle_custom_rx_finished (
							p_block_future              => cyphertext,
							p_block_current             => serializer0_block_in,
							p_block_old                 => previous_ciphertext,
							p_next_serializer0_block_in => next_serializer0_block_in,
							p_custom0_rx_byte           => custom0_rx_byte,
							p_received_correct_block    => received_correct_block);

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_deserializer0_start_listening_action, trigger_deserializer0_start_listening_reaction);
						trigger(trigger_serializer0_start_transmitting_action, trigger_serializer0_start_transmitting_reaction);

					--if receiver finished first
					elsif (custom0_rx_finished_listening = '1') then
						state <= acks_r_finished_t_waiting;

						handle_custom_rx_finished (
							p_block_future              => cyphertext,
							p_block_current             => serializer0_block_in,
							p_block_old                 => previous_ciphertext,
							p_next_serializer0_block_in => next_serializer0_block_in,
							p_custom0_rx_byte           => custom0_rx_byte,
							p_received_correct_block    => received_correct_block);

						if (custom0_rx_byte = FIN) then
							finished := '1';
						else
							finished := '0';
						end if;

					--if transmitter finished first
					elsif (custom0_tx_finished_transmitting = '1') then
						state <= acks_r_waiting_t_finished;
					end if;

				
				when acks_r_finished_t_waiting =>
					if (custom0_tx_finished_transmitting = '1' and finished = '1') then
						state <= finishing;

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_serializer0_start_transmitting_action, trigger_serializer0_start_transmitting_reaction);

					elsif (custom0_tx_finished_transmitting = '1') then
						state <= blocks;

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_deserializer0_start_listening_action, trigger_deserializer0_start_listening_reaction);
						trigger(trigger_serializer0_start_transmitting_action, trigger_serializer0_start_transmitting_reaction);
					end if;


				when acks_r_waiting_t_finished =>
					if (custom0_rx_finished_listening = '1' and custom0_rx_byte = FIN) then
						state <= finishing;

						handle_custom_rx_finished (
							p_block_future              => cyphertext,
							p_block_current             => serializer0_block_in,
							p_block_old                 => previous_ciphertext,
							p_next_serializer0_block_in => next_serializer0_block_in,
							p_custom0_rx_byte           => custom0_rx_byte,
							p_received_correct_block    => received_correct_block);

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_serializer0_start_transmitting_action, trigger_serializer0_start_transmitting_reaction);

					elsif (custom0_rx_finished_listening = '1') then
						state <= blocks;

						handle_custom_rx_finished (
							p_block_future              => cyphertext,
							p_block_current             => serializer0_block_in,
							p_block_old                 => previous_ciphertext,
							p_next_serializer0_block_in => next_serializer0_block_in,
							p_custom0_rx_byte           => custom0_rx_byte,
							p_received_correct_block    => received_correct_block);

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_deserializer0_start_listening_action, trigger_deserializer0_start_listening_reaction);
						trigger(trigger_serializer0_start_transmitting_action, trigger_serializer0_start_transmitting_reaction);
					end if;


				when finishing =>
					if (serializer0_finished_transmitting_out = '1') then
						state <= finishing_ack;

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_custom0_rx_start_listening_action, trigger_custom0_rx_start_listening_reaction);
					end if;


				when finishing_ack =>
					if (custom0_rx_finished_listening = '1' and (custom0_rx_byte = ACK or custom0_rx_byte = FIN)) then
						state <= key_high;
						
						handle_custom_rx_finished (
							p_block_future              => block_zeros,
							p_block_current             => serializer0_block_in,
							p_block_old                 => previous_ciphertext,
							p_next_serializer0_block_in => next_serializer0_block_in,
							p_custom0_rx_byte           => custom0_rx_byte,
							p_received_correct_block    => received_correct_block);

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_deserializer0_start_listening_action, trigger_deserializer0_start_listening_reaction);
						
					elsif (custom0_rx_finished_listening = '1') then
						state <= finishing;

						handle_custom_rx_finished (
							p_block_future              => block_zeros,
							p_block_current             => serializer0_block_in,
							p_block_old                 => previous_ciphertext,
							p_next_serializer0_block_in => next_serializer0_block_in,
							p_custom0_rx_byte           => custom0_rx_byte,
							p_received_correct_block    => received_correct_block);

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_serializer0_start_transmitting_action, trigger_serializer0_start_transmitting_reaction);
					end if;					

			end case;
		end if;
	end process;

	process (state) begin
		case state is
			when start                       => dbg_state <= 0;
			when key_high                    => dbg_state <= 1;
			when key_high_ack                => dbg_state <= 2;
			when key_low                     => dbg_state <= 3;
			when key_low_ack                 => dbg_state <= 4;
			when initialization_vector       => dbg_state <= 5;
			when initialization_vector_ack   => dbg_state <= 6;
			when blocks                      => dbg_state <= 7;
			when blocks_r_finished_t_waiting => dbg_state <= 8;
			when blocks_r_waiting_t_finished => dbg_state <= 9;
			when blocks_ack                  => dbg_state <= 10;
			when acks_r_finished_t_waiting   => dbg_state <= 11;
			when acks_r_waiting_t_finished   => dbg_state <= 12;
			when finishing                   => dbg_state <= 13;
			when finishing_ack               => dbg_state <= 14;
		end case;
	end process;

end communicator_impl;