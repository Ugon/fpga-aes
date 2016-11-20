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
		tx      : out   std_logic;


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

dbg_state                                 : out Integer range 0 to 17;

dbg_cnt_rx                                : out Integer range 0 to 15;
dbg_cnt_tx                                : out Integer range 0 to 15;

dbg_mux_rx0_enable_custom                 : out std_logic;

dbg_serializer0_tx_byte                   : out std_logic_vector(byte_bits - 1 downto 0);

dbg_start_error           : out std_logic;
dbg_stop_error            : out std_logic;
dbg_rx_state              : out Integer range 0 to 3;

dbg_key                                   : out std_logic_vector(key_bits   - 1 downto 0) := (others => '0');
dbg_aes_input                             : out std_logic_vector(block_bits - 1 downto 0) := (others => '0');
dbg_aes_enc_prev_ciphertext               : out std_logic_vector(block_bits - 1 downto 0) := (others => '0');
dbg_aec_enc_output                        : out std_logic_vector(block_bits - 1 downto 0) := (others => '0');
dbg_aes_dec_prev_ciphertext               : out std_logic_vector(block_bits - 1 downto 0) := (others => '0');
dbg_aec_dec_output                        : out std_logic_vector(block_bits - 1 downto 0) := (others => '0');

dbg_next_serializer0_block_in  : out std_logic_vector(block_bits - 1 downto 0)

);
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
	signal key                   : std_logic_vector(key_bits           - 1 downto 0) := (others => '0');
	signal initialization_vector : std_logic_vector(block_bits         - 1 downto 0) := (others => '0');
	signal aes_key               : std_logic_vector(key_bits           - 1 downto 0) := (others => '0');
	signal aes_key_expansion     : std_logic_vector(key_expansion_bits - 1 downto 0) := (others => '0');
	signal aes_input             : std_logic_vector(block_bits         - 1 downto 0) := (others => '0');
	signal aes_output            : std_logic_vector(block_bits         - 1 downto 0) := (others => '0');
	signal aes_enc_dec_choice    : std_logic                                         := '0'; --0 if enc; 1 if dec

	--AES ENCODE
	signal aes_enc_plaintext       : std_logic_vector(block_bits - 1 downto 0) := (others => '0');
	signal aes_enc_cyphertext      : std_logic_vector(block_bits - 1 downto 0) := (others => '0');
	signal aes_enc_output          : std_logic_vector(block_bits - 1 downto 0) := (others => '0');
	signal aes_enc_prev_ciphertext : std_logic_vector(block_bits - 1 downto 0) := (others => '0');

	--AES DECODE
	signal aes_dec_plaintext       : std_logic_vector(block_bits - 1 downto 0) := (others => '0');
	signal aes_dec_cyphertext      : std_logic_vector(block_bits - 1 downto 0) := (others => '0');
	signal aes_dec_output          : std_logic_vector(block_bits - 1 downto 0) := (others => '0');
	signal aes_dec_prev_ciphertext : std_logic_vector(block_bits - 1 downto 0) := (others => '0');

	--AUXILIARY SIGNALS
	signal block_zeros       : std_logic_vector(block_bits - 1 downto 0) := (others => '0');
	signal block_to_transmit : std_logic_vector(block_bits - 1 downto 0) := (others => '0');
	signal ack_to_transmit   : std_logic_vector(byte_bits  - 1 downto 0) := (others => '0');

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
	signal custom0_rx_byte                  : std_logic_vector(byte_bits - 1 downto 0) := (others => '0');
	signal custom0_rx_start_listening       : std_logic                                := '0';
	signal custom0_rx_finished_listening    : std_logic                                := '0';

	signal custom0_tx_byte_in               : std_logic_vector(byte_bits - 1 downto 0) := (others => '0');
	signal custom0_tx_start_transmitting    : std_logic                                := '0';
	signal custom0_tx_finished_transmitting : std_logic                                := '0';

	--RX TX SIGNAL MUX
	signal mux_switch_pulse             : std_logic := '0';
 	signal mux_enable_custom            : std_logic := '1';
	
	signal next_ack_to_transmit         : std_logic_vector(byte_bits  - 1 downto 0) := (others => '0');
	signal next_block_to_transmit       : std_logic_vector(block_bits - 1 downto 0) := (others => '0');
	
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

dbg_serializer0_block_in                  <= block_to_transmit;
dbg_serializer0_start_transmitting_in     <= serializer0_start_transmitting_in;
dbg_serializer0_finished_transmitting_out <= serializer0_finished_transmitting_out;

dbg_mux_rx0_enable_custom                 <= mux_enable_custom;

dbg_serializer0_tx_byte                   <= serializer0_tx_byte;

dbg_key <= key;
dbg_aes_input <= aes_input;

dbg_aes_enc_prev_ciphertext <= aes_enc_prev_ciphertext;
dbg_aec_enc_output <= aes_enc_output;

dbg_aes_dec_prev_ciphertext <= aes_dec_prev_ciphertext;
dbg_aec_dec_output <= aes_dec_output;

dbg_next_serializer0_block_in                  <= next_block_to_transmit;

	aes_key              <= key;
	aes_key_expansion    <= key_expansion256(aes_key);
--	aes_key_expansion    <= (others => '0');

	aes_enc_plaintext    <= aes_enc_prev_ciphertext xor aes_input;
	aes_enc_output       <= aes_enc_cyphertext;

	aes_dec_cyphertext   <= aes_input;
	aes_dec_output       <= aes_dec_prev_ciphertext xor aes_dec_plaintext;

	serializer0_block_in <= block_to_transmit;
	custom0_tx_byte_in   <= ack_to_transmit;
	block_zeros          <= (others => '0');

	aes_enc0 : entity work.aes256enc
		generic map (
			byte_bits                 => byte_bits,
			block_bytes               => block_bytes,
			block_bits                => block_bits,
			key_bytes                 => key_bytes,
			key_expansion_bits        => key_expansion_bits)
		port map (
			key_expansion_in          => aes_key_expansion,
			plaintext_in              => aes_enc_plaintext,
			cyphertext_out            => aes_enc_cyphertext
		);

	aes_dec0: entity work.aes256dec
		generic map (
			byte_bits                 => byte_bits,
			block_bytes               => block_bytes,
			block_bits                => block_bits,
			key_bytes                 => key_bytes,
			key_expansion_bits        => key_expansion_bits)
		port map (
			key_expansion_in          => aes_key_expansion,
			cyphertext_in             => aes_dec_cyphertext,
			plaintext_out             => aes_dec_plaintext
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

	uart_tx0 : entity work.uart_tx
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
			clk_16       => clk_16,
			reset_n      => reset_n,
			action       => trigger_deserializer0_start_listening_action,
			reaction     => trigger_deserializer0_start_listening_reaction,
			pulse_signal => deserializer0_start_listening_in
		);

	trigger1 : entity work.trigger
		port map (
			clk_16       => clk_16,
			reset_n      => reset_n,
			action       => trigger_custom0_rx_start_listening_action,
			reaction     => trigger_custom0_rx_start_listening_reaction,
			pulse_signal => custom0_rx_start_listening
		);

	trigger2 : entity work.trigger
		port map (
			clk_16       => clk_16,
			reset_n      => reset_n,
			action       => trigger_serializer0_start_transmitting_action,
			reaction     => trigger_serializer0_start_transmitting_reaction,
			pulse_signal => serializer0_start_transmitting_in
		);

	trigger3 : entity work.trigger
		port map (
			clk_16       => clk_16,
			reset_n      => reset_n,
			action       => trigger_custom0_tx_start_transmitting_action,
			reaction     => trigger_custom0_tx_start_transmitting_reaction,
			pulse_signal => custom0_tx_start_transmitting
		);

	trigger4 : entity work.trigger
		port map (
			clk_16       => clk_16,
			reset_n      => reset_n,
			action       => trigger_mux_switch0_action,
			reaction     => trigger_mux_switch0_reaction,
			pulse_signal => mux_switch_pulse
		);

	mux_output : process (aes_enc_dec_choice, aes_enc_output, aes_dec_output) begin
		if (aes_enc_dec_choice = AES_ENC) then
			aes_output <= aes_enc_output;
		else 
			aes_output <= aes_dec_output;
		end if;
	end process;

	mux_rx0 : process (mux_enable_custom, rx0_byte_out, custom0_rx_start_listening, rx0_finished_listening_out, deserializer0_rx_start_listening) begin
		if (mux_enable_custom = '1') then
			custom0_rx_byte                     <= rx0_byte_out;
			rx0_start_listening_in              <= custom0_rx_start_listening;
			custom0_rx_finished_listening       <= rx0_finished_listening_out;
			deserializer0_rx_byte               <= (others => '0');
			deserializer0_rx_finished_listening <= '0';
		else
			deserializer0_rx_byte               <= rx0_byte_out;
			rx0_start_listening_in              <= deserializer0_rx_start_listening;
			deserializer0_rx_finished_listening <= rx0_finished_listening_out;
			custom0_rx_byte                     <= (others => '0');
			custom0_rx_finished_listening       <= '0';
		end if;
	end process;

	mux_tx0 : process (mux_enable_custom, tx0_finished_transmitting_out, custom0_tx_byte_in, custom0_tx_start_transmitting, serializer0_tx_byte, serialzier0_tx_start_transmitting) begin
		if (mux_enable_custom = '1') then
			tx0_byte_in                          <= custom0_tx_byte_in;
			tx0_start_transmitting_in            <= custom0_tx_start_transmitting;
			custom0_tx_finished_transmitting     <= tx0_finished_transmitting_out;
			serialzier0_tx_finished_transmitting <= '0';
		else
			tx0_byte_in                          <= serializer0_tx_byte;
			tx0_start_transmitting_in            <= serialzier0_tx_start_transmitting;
			serialzier0_tx_finished_transmitting <= tx0_finished_transmitting_out;
			custom0_tx_finished_transmitting     <= '0';
		end if;
	end process;

	mux_switch0 : process (reset_n, mux_switch_pulse) begin
		if(reset_n = '0') then
			mux_enable_custom <= '1';
		elsif(rising_edge(mux_switch_pulse)) then
			mux_enable_custom <= not mux_enable_custom;
		end if;
	end process;

	tx_byte_set : process (reset_n, custom0_tx_start_transmitting) begin
		if (reset_n = '0') then
			ack_to_transmit <= (others => '0');
		elsif (rising_edge(custom0_tx_start_transmitting)) then
			ack_to_transmit <= next_ack_to_transmit;
		end if;
	end process;

	serializer_byte_set : process (reset_n, serializer0_start_transmitting_in) begin
		if (reset_n = '0') then
			block_to_transmit <= (others => '0');
		elsif (rising_edge(serializer0_start_transmitting_in)) then
			block_to_transmit <= next_block_to_transmit;
		end if;
	end process;

	communication_flow : process (clk_16, reset_n)
		variable finished : std_logic := '0';

		procedure handle_deserializer_finished (
			signal p_deserializer0_block_out   : in  std_logic_vector;
			signal p_deserializer0_correct_out : in  std_logic;
			signal p_received_block            : out std_logic_vector;
			signal p_next_ack_to_transmit      : out std_logic_vector) is

		begin
			--read receiver output
			p_received_block <= p_deserializer0_block_out;
				
			--set transmitter input
			if (p_deserializer0_correct_out = '1') then
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
					if (deserializer0_finished_listening_out = '1') then
						state <= key_low_ack;

						handle_deserializer_finished(
							p_deserializer0_block_out   => deserializer0_block_out,
							p_deserializer0_correct_out => deserializer0_correct_out,
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
					if (deserializer0_finished_listening_out = '1') then
						state <= key_high_ack;

						handle_deserializer_finished(
							p_deserializer0_block_out   => deserializer0_block_out,
							p_deserializer0_correct_out => deserializer0_correct_out,
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
					if (deserializer0_finished_listening_out = '1') then
						state <= init_vector_ack;

						handle_deserializer_finished(
							p_deserializer0_block_out   => deserializer0_block_out,
							p_deserializer0_correct_out => deserializer0_correct_out,
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


				when first_block => 
					if (deserializer0_finished_listening_out = '1') then
						state <= blocks_ack;

						handle_deserializer_finished(
							p_deserializer0_block_out   => deserializer0_block_out,
							p_deserializer0_correct_out => deserializer0_correct_out,
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
 					if (deserializer0_finished_listening_out = '1' and serializer0_finished_transmitting_out = '1') then
						state <= blocks_ack;

						handle_deserializer_finished(
							p_deserializer0_block_out   => deserializer0_block_out,
							p_deserializer0_correct_out => deserializer0_correct_out,
							p_received_block            => aes_input,
							p_next_ack_to_transmit      => next_ack_to_transmit);

						aes_enc_prev_ciphertext <= aes_enc_output;
						aes_dec_prev_ciphertext <= aes_input;

						trigger(trigger_mux_switch0_action, trigger_mux_switch0_reaction);
						trigger(trigger_custom0_rx_start_listening_action, trigger_custom0_rx_start_listening_reaction);
						trigger(trigger_custom0_tx_start_transmitting_action, trigger_custom0_tx_start_transmitting_reaction);

					--if receiver finished first
					elsif (deserializer0_finished_listening_out = '1') then
						state <= blocks_r_finished_t_waiting;

						handle_deserializer_finished(
							p_deserializer0_block_out   => deserializer0_block_out,
							p_deserializer0_correct_out => deserializer0_correct_out,
							p_received_block            => aes_input,
							p_next_ack_to_transmit      => next_ack_to_transmit);

						aes_enc_prev_ciphertext <= aes_enc_output;
						aes_dec_prev_ciphertext <= aes_input;

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
							p_deserializer0_correct_out => deserializer0_correct_out,
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
					if (serializer0_finished_transmitting_out = '1') then
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

	process (state) begin
		case state is
			when start                       => dbg_state <= 0;
			when choice                      => dbg_state <= 1;
			when choice_ack                  => dbg_state <= 2;
			when key_low                    => dbg_state <= 3;
			when key_low_ack                => dbg_state <= 4;
			when key_high                     => dbg_state <= 5;
			when key_high_ack                 => dbg_state <= 6;
			when init_vector                 => dbg_state <= 7;
			when init_vector_ack             => dbg_state <= 8;
			when first_block                 => dbg_state <= 9;
			when blocks                      => dbg_state <= 10;
			when blocks_r_finished_t_waiting => dbg_state <= 11;
			when blocks_r_waiting_t_finished => dbg_state <= 12;
			when blocks_ack                  => dbg_state <= 13;
			when acks_r_finished_t_waiting   => dbg_state <= 14;
			when acks_r_waiting_t_finished   => dbg_state <= 15;
			when finishing                   => dbg_state <= 16;
			when finishing_ack               => dbg_state <= 17;
		end case;
	end process;

end communicator_impl;