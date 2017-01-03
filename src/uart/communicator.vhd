library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utils.all;
use work.aes_utils.all;


entity communicator is
	generic (
		byte_bits          : Integer := 8;
		block_bytes        : Integer := 16;
		block_bits         : Integer := 128;
		key_bytes          : Integer := 32;
		key_bits           : Integer := 256;
		key_expansion_bits : Integer := 15 * 128);
	port (
		clk_16  : in    std_logic; --16x baudrate
		reset_n : in    std_logic;
		rx      : in    std_logic;
		tx      : out   std_logic);
end communicator;

architecture communicator_impl of communicator is
	type fsm is (
		start,
		choice,
		choice_ack,
		key_low,
		key_low_ack,
		key_high,
		key_high_ack,
		init_vector,
		init_vector_ack,
		first_block,
		blocks,
		blocks_r_finished_t_waiting,
		blocks_r_waiting_t_finished,
		blocks_ack,
		acks_r_finished_t_waiting,
		acks_r_waiting_t_finished,
		finishing,
		finishing_ack);

	signal state : fsm := start;

	constant AES_ENC : std_logic := '0';
	constant AES_DEC : std_logic := '1';

	constant  ACK : std_logic_vector(byte_bits - 1 downto 0) := "01000001"; --ASCII('A')
	constant NACK : std_logic_vector(byte_bits - 1 downto 0) := "01001110"; --ASCII('N')
	constant  FIN : std_logic_vector(byte_bits - 1 downto 0) := "01000110"; --ASCII('F')
	constant  ENC : std_logic_vector(byte_bits - 1 downto 0) := "01000101"; --ASCII('E')
	constant  DEC : std_logic_vector(byte_bits - 1 downto 0) := "01000100"; --ASCII('D')

	--AES SIGNALS
	signal key                                             : std_logic_vector(key_bits           - 1 downto 0) := (others => '0');
	signal initialization_vector                           : std_logic_vector(block_bits         - 1 downto 0) := (others => '0');
	signal aes_key                                         : std_logic_vector(key_bits           - 1 downto 0) := (others => '0');
	signal aes_key_expansion                               : std_logic_vector(key_expansion_bits - 1 downto 0) := (others => '0');
	signal aes_input                                       : std_logic_vector(block_bits         - 1 downto 0) := (others => '0');
	signal aes_output                                      : std_logic_vector(block_bits         - 1 downto 0) := (others => '0');
	signal aes_enc_dec_choice                              : std_logic                                         := '0'; --0 if enc; 1 if dec

	--AES ENCODE
	signal aes_enc_plaintext                               : std_logic_vector(block_bits - 1 downto 0)         := (others => '0');
	signal aes_enc_cyphertext                              : std_logic_vector(block_bits - 1 downto 0)         := (others => '0');
	signal aes_enc_output                                  : std_logic_vector(block_bits - 1 downto 0)         := (others => '0');
	signal aes_enc_prev_ciphertext                         : std_logic_vector(block_bits - 1 downto 0)         := (others => '0');

	--AES DECODE
	signal aes_dec_plaintext                               : std_logic_vector(block_bits - 1 downto 0)         := (others => '0');
	signal aes_dec_cyphertext                              : std_logic_vector(block_bits - 1 downto 0)         := (others => '0');
	signal aes_dec_output                                  : std_logic_vector(block_bits - 1 downto 0)         := (others => '0');
	signal aes_dec_prev_ciphertext                         : std_logic_vector(block_bits - 1 downto 0)         := (others => '0');

	--AUXILIARY SIGNALS
	signal block_zeros                                     : std_logic_vector(block_bits - 1 downto 0)         := (others => '0');
	signal block_to_transmit                               : std_logic_vector(block_bits - 1 downto 0)         := (others => '0');
	signal ack_to_transmit                                 : std_logic_vector(byte_bits  - 1 downto 0)         := (others => '0');

    --ENTITY CONNECTIONS SIGNALS
	signal rx0_byte                                        : std_logic_vector(byte_bits - 1 downto 0)          := (others => '0');
	signal rx0_start_listening                             : std_logic                                         := '0';
	signal rx0_finished_listening                          : std_logic                                         := '0';

	signal deserializer0_rx_byte                           : std_logic_vector(byte_bits - 1 downto 0)          := (others => '0');
	signal deserializer0_rx_start_listening                : std_logic                                         := '0';
	signal deserializer0_rx_finished_listening             : std_logic                                         := '0';
	signal deserializer0_block                             : std_logic_vector(block_bits - 1 downto 0)         := (others => '0');
	signal deserializer0_start_listening                   : std_logic                                         := '0';
	signal deserializer0_finished_listening                : std_logic                                         := '0';
	signal deserializer0_correct                           : std_logic                                         := '0';

	signal tx0_byte                                        : std_logic_vector(byte_bits - 1 downto 0)          := (others => '0');
	signal tx0_start_transmitting                          : std_logic                                         := '0';
	signal tx0_finished_transmitting                       : std_logic                                         := '0';

	signal serializer0_tx_byte                             : std_logic_vector(byte_bits - 1 downto 0)          := (others => '0');
	signal serialzier0_tx_start_transmitting               : std_logic                                         := '0';
	signal serialzier0_tx_finished_transmitting            : std_logic                                         := '0';
	signal serializer0_block                               : std_logic_vector(block_bits - 1 downto 0)         := (others => '0');
	signal serializer0_start_transmitting                  : std_logic                                         := '0';
	signal serializer0_finished_transmitting               : std_logic                                         := '0';

	--CUSTOM CONNECTION SIGNALS
	signal custom0_rx_byte                                 : std_logic_vector(byte_bits - 1 downto 0)          := (others => '0');
	signal custom0_rx_start_listening                      : std_logic                                         := '0';
	signal custom0_rx_finished_listening                   : std_logic                                         := '0';

	signal custom0_tx_byte                                 : std_logic_vector(byte_bits - 1 downto 0)          := (others => '0');
	signal custom0_tx_start_transmitting                   : std_logic                                         := '0';
	signal custom0_tx_finished_transmitting                : std_logic                                         := '0';

	--RX TX SIGNAL MUX
	signal mux_switch_pulse                                : std_logic                                         := '0';
 	signal mux_enable_custom                               : std_logic                                         := '1';
 	signal mux_enable_custom_vec                           : std_logic_vector(0 downto 0)                      := (others => '1');
	
	signal next_ack_to_transmit                            : std_logic_vector(byte_bits  - 1 downto 0)         := (others => '0');
	signal next_block_to_transmit                          : std_logic_vector(block_bits - 1 downto 0)         := (others => '0');
	
	signal trigger_mux_switch0_action                      : std_logic                                         := '0';
	signal trigger_mux_switch0_reaction                    : std_logic                                         := '0';

	--START PULSE TRIGGERS
	signal trigger_deserializer0_start_listening_action     : std_logic                                         := '0';
	signal trigger_deserializer0_start_listening_reaction   : std_logic                                         := '0';
	signal trigger_custom0_rx_start_listening_action       : std_logic                                         := '0';
	signal trigger_custom0_rx_start_listening_reaction     : std_logic                                         := '0';
	
	signal trigger_serializer0_start_transmitting_action   : std_logic                                         := '0';
	signal trigger_serializer0_start_transmitting_reaction : std_logic                                         := '0';
	signal trigger_custom0_tx_start_transmitting_action    : std_logic                                         := '0';
	signal trigger_custom0_tx_start_transmitting_reaction  : std_logic                                         := '0';

	--ACK CONTROL SIGNALS
	signal transmit_success                                : std_logic                                         := '0';
	signal receive_success                                 : std_logic                                         := '0';

begin

	aes_key            <= key;
	aes_key_expansion  <= key_expansion256(aes_key);
--	aes_key_expansion  <= (others => '0');

	aes_enc_plaintext  <= aes_enc_prev_ciphertext xor aes_input;
	aes_enc_output     <= aes_enc_cyphertext;

	aes_dec_cyphertext <= aes_input;
	aes_dec_output     <= aes_dec_prev_ciphertext xor aes_dec_plaintext;

	serializer0_block  <= block_to_transmit;
	custom0_tx_byte    <= ack_to_transmit;
	block_zeros        <= (others => '0');

	mux_enable_custom  <= mux_enable_custom_vec(0);

	aes_enc0 : entity work.aes256enc
		generic map (
			byte_bits                 => byte_bits,
			block_bytes               => block_bytes,
			block_bits                => block_bits,
			key_bytes                 => key_bytes,
			key_expansion_bits        => key_expansion_bits)
		port map (
			key_expansion             => aes_key_expansion,
			plaintext                 => aes_enc_plaintext,
			cyphertext                => aes_enc_cyphertext
		);

	aes_dec0: entity work.aes256dec
		generic map (
			byte_bits                 => byte_bits,
			block_bytes               => block_bytes,
			block_bits                => block_bits,
			key_bytes                 => key_bytes,
			key_expansion_bits        => key_expansion_bits)
		port map (
			key_expansion             => aes_key_expansion,
			cyphertext                => aes_dec_cyphertext,
			plaintext                 => aes_dec_plaintext
		);

	uart_rx0 : entity work.uart_rx
		generic map (
			byte_bits                 => byte_bits)
		port map (
			reset_n                   => reset_n,
			clk_16                    => clk_16,
			rx                        => rx,
			
			byte                      => rx0_byte,
			start_listening           => rx0_start_listening,
			finished_listening        => rx0_finished_listening
		);

	uart_tx0 : entity work.uart_tx
		generic map (
			byte_bits                 => byte_bits)
		port map (
			reset_n                   => reset_n,
			clk_16                    => clk_16,
			tx                        => tx,
			
			byte                      => tx0_byte,
			start_transmitting        => tx0_start_transmitting,
			finished_transmitting     => tx0_finished_transmitting
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
			aes_block                 => deserializer0_block,
			start_listening           => deserializer0_start_listening,
			finished_listening        => deserializer0_finished_listening,
			correct                   => deserializer0_correct
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
			aes_block                 => serializer0_block,
			start_transmitting        => serializer0_start_transmitting,
			finished_transmitting     => serializer0_finished_transmitting
		);

	trigger0 : entity work.trigger
		port map (
			clk_16       => clk_16,
			reset_n      => reset_n,
			action       => trigger_deserializer0_start_listening_action,
			reaction     => trigger_deserializer0_start_listening_reaction,
			pulse_signal => deserializer0_start_listening
		);

	trigger1 : entity work.trigger
		port map (
			clk_16       => clk_16,
			reset_n      => reset_n,
			action       => trigger_custom0_rx_start_listening_action,
			reaction     => trigger_custom0_rx_start_listening_reaction,
			pulse_signal => custom0_rx_start_listening
		);

	trigger2 : entity work.trigger_toggle
		generic map (
			size               => block_bits,
			toggle_out_default => '0')
		port map (
			clk_16       => clk_16,
			reset_n      => reset_n,
			action       => trigger_serializer0_start_transmitting_action,
			reaction     => trigger_serializer0_start_transmitting_reaction,
			pulse_signal => serializer0_start_transmitting,
			toggle_in    => next_block_to_transmit,
			toggle_out   => block_to_transmit
		);

	trigger3 : entity work.trigger_toggle
		generic map (
			size               => byte_bits,
			toggle_out_default => '0')
		port map (
			clk_16       => clk_16,
			reset_n      => reset_n,
			action       => trigger_custom0_tx_start_transmitting_action,
			reaction     => trigger_custom0_tx_start_transmitting_reaction,
			pulse_signal => custom0_tx_start_transmitting,
			toggle_in    => next_ack_to_transmit,
			toggle_out   => ack_to_transmit
		);

	trigger4 : entity work.trigger_toggle
		generic map (
			size               =>  1,
			toggle_out_default => '1')
		port map (
			clk_16       => clk_16,
			reset_n      => reset_n,
			action       => trigger_mux_switch0_action,
			reaction     => trigger_mux_switch0_reaction,
			pulse_signal => mux_switch_pulse,
			toggle_in    => (others => not mux_enable_custom),
			toggle_out   => mux_enable_custom_vec
		);

	mux_output : process (aes_enc_dec_choice, aes_enc_output, aes_dec_output) begin
		if (aes_enc_dec_choice = AES_ENC) then
			aes_output <= aes_enc_output;
		else 
			aes_output <= aes_dec_output;
		end if;
	end process;

	mux_rx0 : process (mux_enable_custom, rx0_byte, custom0_rx_start_listening, rx0_finished_listening, deserializer0_rx_start_listening) begin
		if (mux_enable_custom = '1') then
			custom0_rx_byte                     <= rx0_byte;
			rx0_start_listening                 <= custom0_rx_start_listening;
			custom0_rx_finished_listening       <= rx0_finished_listening;
			deserializer0_rx_byte               <= (others => '0');
			deserializer0_rx_finished_listening <= '0';
		else
			deserializer0_rx_byte               <= rx0_byte;
			rx0_start_listening                 <= deserializer0_rx_start_listening;
			deserializer0_rx_finished_listening <= rx0_finished_listening;
			custom0_rx_byte                     <= (others => '0');
			custom0_rx_finished_listening       <= '0';
		end if;
	end process;

	mux_tx0 : process (mux_enable_custom, tx0_finished_transmitting, custom0_tx_byte, custom0_tx_start_transmitting, serializer0_tx_byte, serialzier0_tx_start_transmitting) begin
		if (mux_enable_custom = '1') then
			tx0_byte                             <= custom0_tx_byte;
			tx0_start_transmitting               <= custom0_tx_start_transmitting;
			custom0_tx_finished_transmitting     <= tx0_finished_transmitting;
			serialzier0_tx_finished_transmitting <= '0';
		else
			tx0_byte                             <= serializer0_tx_byte;
			tx0_start_transmitting               <= serialzier0_tx_start_transmitting;
			serialzier0_tx_finished_transmitting <= tx0_finished_transmitting;
			custom0_tx_finished_transmitting     <= '0';
		end if;
	end process;

	communication_flow : process (clk_16, reset_n)
		variable finished : std_logic := '0';

		procedure handle_deserializer_finished (
			signal p_deserializer0_block       : in  std_logic_vector;
			signal p_deserializer0_correct     : in  std_logic;
			signal p_received_block            : out std_logic_vector;
			signal p_next_ack_to_transmit      : out std_logic_vector) is

		begin
			--read receiver output
			p_received_block <= p_deserializer0_block;
				
			--set transmitter input
			if (p_deserializer0_correct = '1') then
				p_next_ack_to_transmit <= ACK;
			else 
				p_next_ack_to_transmit <= NACK;
			end if;
		end;

		procedure handle_custom_rx_finished (
			signal p_custom0_rx_byte              : in  std_logic_vector;
			signal p_ack_to_transmit              : in  std_logic_vector;
			signal p_block_to_transmit_if_success : in  std_logic_vector;
			signal p_block_to_transmit_if_failure : in  std_logic_vector;
			signal p_next_block_to_transmit       : out std_logic_vector) is 
		begin
			--read receiver output and set transmitter input
			if (ack_to_transmit = ACK and (p_custom0_rx_byte = ACK or p_custom0_rx_byte = FIN)) then
				p_next_block_to_transmit <= p_block_to_transmit_if_success;
			else 
				p_next_block_to_transmit <= p_block_to_transmit_if_failure;
			end if;
		end;

	begin
		if (reset_n = '0') then
			state                                         <= start;
			finished                                      := '0';
			next_ack_to_transmit                          <= (others => '0');
			next_block_to_transmit                        <= (others => '0');
			aes_input                                     <= (others => '0');
			aes_enc_prev_ciphertext                       <= (others => '0');
			trigger_mux_switch0_action                    <= '0';
			trigger_custom0_rx_start_listening_action     <= '0';
			trigger_deserializer0_start_listening_action  <= '0';
			trigger_custom0_tx_start_transmitting_action  <= '0';
			trigger_serializer0_start_transmitting_action <= '0';

		elsif (rising_edge(clk_16)) then
			case state is
				when start =>
					state <= choice;
					
					trigger(trigger_custom0_rx_start_listening_action, trigger_custom0_rx_start_listening_reaction);


				when choice =>
					if (custom0_rx_finished_listening = '1' and custom0_rx_byte = ENC) then
						state <= choice_ack;
						aes_enc_dec_choice <= AES_ENC;
						next_ack_to_transmit <= ACK;
						trigger(trigger_custom0_tx_start_transmitting_action, trigger_custom0_tx_start_transmitting_reaction);

					elsif (custom0_rx_finished_listening = '1' and custom0_rx_byte = DEC) then
						state <= choice_ack;
						aes_enc_dec_choice <= AES_DEC;
						next_ack_to_transmit <= ACK;
						trigger(trigger_custom0_tx_start_transmitting_action, trigger_custom0_tx_start_transmitting_reaction);

					elsif (custom0_rx_finished_listening = '1') then
						state <= choice_ack;
						aes_enc_dec_choice <= '0';
						next_ack_to_transmit <= NACK;
						trigger(trigger_custom0_tx_start_transmitting_action, trigger_custom0_tx_start_transmitting_reaction);
					end if;


				when choice_ack =>
					if (custom0_tx_finished_transmitting = '1' and ack_to_transmit = ACK) then
						state <= key_low;
						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_deserializer0_start_listening_action, trigger_deserializer0_start_listening_reaction);

					elsif (custom0_tx_finished_transmitting = '1') then
						state <= choice;
						trigger(trigger_custom0_rx_start_listening_action, trigger_custom0_rx_start_listening_reaction);
					end if;


				when key_low =>
					if (deserializer0_finished_listening= '1') then
						state <= key_low_ack;

						handle_deserializer_finished(
							p_deserializer0_block       => deserializer0_block,
							p_deserializer0_correct     => deserializer0_correct,
							p_received_block            => key(block_bits - 1 downto 0),
							p_next_ack_to_transmit      => next_ack_to_transmit);

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_custom0_tx_start_transmitting_action, trigger_custom0_tx_start_transmitting_reaction);
					end if;


				when key_low_ack =>
					if (custom0_tx_finished_transmitting = '1' and ack_to_transmit = ACK) then
						state <= key_high;
					
						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_deserializer0_start_listening_action, trigger_deserializer0_start_listening_reaction);

					elsif (custom0_tx_finished_transmitting = '1') then
						state <= key_low;
					
						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_deserializer0_start_listening_action, trigger_deserializer0_start_listening_reaction);
					end if;


				when key_high =>
					if (deserializer0_finished_listening= '1') then
						state <= key_high_ack;

						handle_deserializer_finished(
							p_deserializer0_block       => deserializer0_block,
							p_deserializer0_correct     => deserializer0_correct,
							p_received_block            => key(key_bits - 1 downto key_bits - block_bits),
							p_next_ack_to_transmit      => next_ack_to_transmit);

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_custom0_tx_start_transmitting_action, trigger_custom0_tx_start_transmitting_reaction);
					end if;				


				when key_high_ack =>
					if (custom0_tx_finished_transmitting = '1' and ack_to_transmit = ACK) then
						state <= init_vector;

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_deserializer0_start_listening_action, trigger_deserializer0_start_listening_reaction);

					elsif (custom0_tx_finished_transmitting = '1') then
						state <= key_high;
						
						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_deserializer0_start_listening_action, trigger_deserializer0_start_listening_reaction);
					end if;


				when init_vector =>
					if (deserializer0_finished_listening= '1') then
						state <= init_vector_ack;

						handle_deserializer_finished(
							p_deserializer0_block       => deserializer0_block,
							p_deserializer0_correct     => deserializer0_correct,
							p_received_block            => initialization_vector,
							p_next_ack_to_transmit      => next_ack_to_transmit);

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_custom0_tx_start_transmitting_action, trigger_custom0_tx_start_transmitting_reaction);
					end if;				


				when init_vector_ack =>
					if (custom0_tx_finished_transmitting = '1' and ack_to_transmit = ACK) then
						state <= first_block;
					
						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_deserializer0_start_listening_action, trigger_deserializer0_start_listening_reaction);

					elsif (custom0_tx_finished_transmitting = '1') then
						state <= init_vector;
					
						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_deserializer0_start_listening_action, trigger_deserializer0_start_listening_reaction);
					end if;


				when first_block=> 
					if (deserializer0_finished_listening= '1') then
						state <= blocks_ack;

						handle_deserializer_finished(
							p_deserializer0_block       => deserializer0_block,
							p_deserializer0_correct     => deserializer0_correct,
							p_received_block            => aes_input,
							p_next_ack_to_transmit      => next_ack_to_transmit);

						aes_enc_prev_ciphertext <= initialization_vector;
						aes_dec_prev_ciphertext <= initialization_vector;

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_custom0_rx_start_listening_action, trigger_custom0_rx_start_listening_reaction);
						trigger(trigger_custom0_tx_start_transmitting_action, trigger_custom0_tx_start_transmitting_reaction);
					end if;


				when blocks =>
 					--if receiver and transmitter finished at the same time
 					if (deserializer0_finished_listening= '1' and serializer0_finished_transmitting= '1') then
						state <= blocks_ack;

						handle_deserializer_finished(
							p_deserializer0_block       => deserializer0_block,
							p_deserializer0_correct     => deserializer0_correct,
							p_received_block            => aes_input,
							p_next_ack_to_transmit      => next_ack_to_transmit);

						aes_enc_prev_ciphertext <= aes_enc_output;
						aes_dec_prev_ciphertext <= aes_input;

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_custom0_rx_start_listening_action, trigger_custom0_rx_start_listening_reaction);
						trigger(trigger_custom0_tx_start_transmitting_action, trigger_custom0_tx_start_transmitting_reaction);

					--if receiver finished first
					elsif (deserializer0_finished_listening= '1') then
						state <= blocks_r_finished_t_waiting;

						handle_deserializer_finished(
							p_deserializer0_block       => deserializer0_block,
							p_deserializer0_correct     => deserializer0_correct,
							p_received_block            => aes_input,
							p_next_ack_to_transmit      => next_ack_to_transmit);

						aes_enc_prev_ciphertext <= aes_enc_output;
						aes_dec_prev_ciphertext <= aes_input;

					--if transmitter finished first
					elsif (serializer0_finished_transmitting= '1') then
						state <= blocks_r_waiting_t_finished;
					end if;


				when blocks_r_finished_t_waiting =>
					if (serializer0_finished_transmitting= '1') then
						state <= blocks_ack;

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_custom0_rx_start_listening_action, trigger_custom0_rx_start_listening_reaction);
						trigger(trigger_custom0_tx_start_transmitting_action, trigger_custom0_tx_start_transmitting_reaction);
					end if;


				when blocks_r_waiting_t_finished =>
					if (deserializer0_finished_listening= '1') then
						state <= blocks_ack;

						handle_deserializer_finished(
							p_deserializer0_block       => deserializer0_block,
							p_deserializer0_correct     => deserializer0_correct,
							p_received_block            => aes_input,
							p_next_ack_to_transmit      => next_ack_to_transmit);

						aes_enc_prev_ciphertext <= aes_enc_output;
						aes_dec_prev_ciphertext <= aes_input;

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_custom0_rx_start_listening_action, trigger_custom0_rx_start_listening_reaction);
						trigger(trigger_custom0_tx_start_transmitting_action, trigger_custom0_tx_start_transmitting_reaction);
					end if;


				when blocks_ack =>
 					--if receiver and transmitter finished at the same time
					if(custom0_rx_finished_listening = '1' and custom0_tx_finished_transmitting = '1' and custom0_rx_byte = FIN) then
						state <= finishing;

						handle_custom_rx_finished (
							p_custom0_rx_byte              => custom0_rx_byte,
							p_ack_to_transmit              => ack_to_transmit,
							p_block_to_transmit_if_success => aes_output,
							p_block_to_transmit_if_failure => block_to_transmit,
							p_next_block_to_transmit       => next_block_to_transmit);

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_serializer0_start_transmitting_action, trigger_serializer0_start_transmitting_reaction);

					elsif(custom0_rx_finished_listening = '1' and custom0_tx_finished_transmitting = '1') then
						state <= blocks;

						handle_custom_rx_finished (
							p_custom0_rx_byte              => custom0_rx_byte,
							p_ack_to_transmit              => ack_to_transmit,
							p_block_to_transmit_if_success => aes_output,
							p_block_to_transmit_if_failure => block_to_transmit,
							p_next_block_to_transmit       => next_block_to_transmit);

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_deserializer0_start_listening_action, trigger_deserializer0_start_listening_reaction);
						trigger(trigger_serializer0_start_transmitting_action, trigger_serializer0_start_transmitting_reaction);

					--if receiver finished first
					elsif (custom0_rx_finished_listening = '1') then
						state <= acks_r_finished_t_waiting;

						handle_custom_rx_finished (
							p_custom0_rx_byte              => custom0_rx_byte,
							p_ack_to_transmit              => ack_to_transmit,
							p_block_to_transmit_if_success => aes_output,
							p_block_to_transmit_if_failure => block_to_transmit,
							p_next_block_to_transmit       => next_block_to_transmit);

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
							p_custom0_rx_byte              => custom0_rx_byte,
							p_ack_to_transmit              => ack_to_transmit,
							p_block_to_transmit_if_success => aes_output,
							p_block_to_transmit_if_failure => block_to_transmit,
							p_next_block_to_transmit       => next_block_to_transmit);

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_serializer0_start_transmitting_action, trigger_serializer0_start_transmitting_reaction);

					elsif (custom0_rx_finished_listening = '1') then
						state <= blocks;

						handle_custom_rx_finished (
							p_custom0_rx_byte              => custom0_rx_byte,
							p_ack_to_transmit              => ack_to_transmit,
							p_block_to_transmit_if_success => aes_output,
							p_block_to_transmit_if_failure => block_to_transmit,
							p_next_block_to_transmit       => next_block_to_transmit);

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_deserializer0_start_listening_action, trigger_deserializer0_start_listening_reaction);
						trigger(trigger_serializer0_start_transmitting_action, trigger_serializer0_start_transmitting_reaction);
					end if;


				when finishing =>
					if (serializer0_finished_transmitting= '1') then
						state <= finishing_ack;

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_custom0_rx_start_listening_action, trigger_custom0_rx_start_listening_reaction);
					end if;


				when finishing_ack =>
					if (custom0_rx_finished_listening = '1' and (custom0_rx_byte = ACK or custom0_rx_byte = FIN)) then
						state <= choice;
						
						handle_custom_rx_finished (
							p_custom0_rx_byte              => custom0_rx_byte,
							p_ack_to_transmit              => ack_to_transmit,
							p_block_to_transmit_if_success => block_zeros,
							p_block_to_transmit_if_failure => block_to_transmit,
							p_next_block_to_transmit       => next_block_to_transmit);

						trigger(trigger_custom0_rx_start_listening_action, trigger_custom0_rx_start_listening_reaction);
						
					elsif (custom0_rx_finished_listening = '1') then
						state <= finishing;

						handle_custom_rx_finished (
							p_custom0_rx_byte              => custom0_rx_byte,
							p_ack_to_transmit              => ack_to_transmit,
							p_block_to_transmit_if_success => block_zeros,
							p_block_to_transmit_if_failure => block_to_transmit,
							p_next_block_to_transmit       => next_block_to_transmit);

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_serializer0_start_transmitting_action, trigger_serializer0_start_transmitting_reaction);
					end if;					

			end case;
		end if;
	end process;

end communicator_impl;