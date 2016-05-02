library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utils.all;

entity uart_communicator is
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
		block_modification_in  : in    std_logic_vector(block_bits - 1 downto 0);
		block_modification_out : out   std_logic_vector(block_bits - 1 downto 0);

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

dbg_receiver_state                        : out Integer range 0 to 3;  
dbg_transmitter_state                          : out Integer range 0 to 3;

dbg_cnt_rx                                : out Integer range 0 to 15;
dbg_cnt_tx                                : out Integer range 0 to 15

);
end uart_communicator;

architecture uart_communicator_impl of uart_communicator is
	type r_fsm is (r_start, r_exchange_block, r_exchange_ack, r_sync2);
	signal receiver_state : r_fsm := r_start;

	type t_fsm is (t_start, t_exchange_block, t_sync1, t_exchange_ack, t_sync2);
	--signal transmitter_state   : s_fsm := t_exchange_block;
	signal transmitter_state : t_fsm := t_start;

	constant  ACK : std_logic_vector(7 downto 0) := "01000001";
	constant NACK : std_logic_vector(7 downto 0) := "01001110";


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
	signal custom0_rx_byte                       : std_logic_vector(byte_bits - 1 downto 0)  := (others => '0');
	signal custom0_rx_start_listening            : std_logic                                 := '0';
	signal custom0_rx_finished_listening         : std_logic                                 := '0';

	signal custom0_tx_byte                       : std_logic_vector(byte_bits - 1 downto 0)  := (others => '0');
	signal custom0_tx_start_transmitting         : std_logic                                 := '0';
	signal custom0_tx_finished_transmitting      : std_logic                                 := '0';


	--RX TX SIGNAL MUX
	signal mux_rx0_enable_custom : std_logic := '0';
	signal mux_tx0_enable_custom : std_logic := '0';

	signal mux_rx_switch_combined : std_logic := '1';
	signal mux_tx_switch_combined : std_logic := '0';


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
	signal transmit_success    : std_logic := '0';
	signal receive_success : std_logic := '0';

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
			dbg_cnt                   => dbg_cnt_rx
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
			reaction_in   => trigger_deserializer0_start_listening_reaction,
			reaction_out  => trigger_deserializer0_start_listening_reaction,
			pulse_signal  => deserializer0_start_listening_in
		);

	trigger1 : entity work.trigger
		port map (
			clk_16        => clk_16,
			reset_n       => reset_n,
			action        => trigger_custom0_rx_start_listening_action,
			reaction_in   => trigger_custom0_rx_start_listening_reaction,
			reaction_out  => trigger_custom0_rx_start_listening_reaction,
			pulse_signal  => custom0_rx_start_listening
		);

	trigger2 : entity work.trigger
		port map (
			clk_16        => clk_16,
			reset_n       => reset_n,
			action        => trigger_serializer0_start_transmitting_action,
			reaction_in   => trigger_serializer0_start_transmitting_reaction,
			reaction_out  => trigger_serializer0_start_transmitting_reaction,
			pulse_signal  => serializer0_start_transmitting_in
		);

	trigger3 : entity work.trigger
		port map (
			clk_16        => clk_16,
			reset_n       => reset_n,
			action        => trigger_custom0_tx_start_transmitting_action,
			reaction_in   => trigger_custom0_tx_start_transmitting_reaction,
			reaction_out  => trigger_custom0_tx_start_transmitting_reaction,
			pulse_signal  => custom0_tx_start_transmitting
		);

	mux_rx0 : process (mux_rx0_enable_custom, rx0_byte_out, custom0_rx_start_listening, rx0_finished_listening_out, deserializer0_rx_start_listening) begin
		if (mux_rx0_enable_custom = '1') then
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

	mux_tx0 : process (mux_tx0_enable_custom, tx0_finished_transmitting_out, custom0_tx_byte, custom0_tx_start_transmitting, serializer0_tx_byte, serialzier0_tx_start_transmitting) begin
		if (mux_tx0_enable_custom = '1') then
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

	mux_rx_switch_combined <= deserializer0_start_listening_in or custom0_rx_start_listening;

	mux_rx0_switch : process (reset_n, deserializer0_start_listening_in, custom0_rx_start_listening) begin
		if(reset_n = '0') then
			mux_rx0_enable_custom <= '1';
		elsif(rising_edge(mux_rx_switch_combined)) then
			mux_rx0_enable_custom <= not mux_rx0_enable_custom;
		end if;
	end process;

	mux_tx_switch_combined <= serializer0_start_transmitting_in or custom0_tx_start_transmitting;

	mux_tx0_switch : process (reset_n, mux_tx_switch_combined) begin
		if(reset_n = '0') then
			mux_tx0_enable_custom <= '0';
		elsif(rising_edge(mux_tx_switch_combined)) then
			mux_tx0_enable_custom <= not mux_tx0_enable_custom;
		end if;
	end process;



	receiver_flow : process (clk_16, reset_n) 
		variable process_started : boolean                := false;
	begin
		if (reset_n = '0') then
			receiver_state                                <= r_start;
			process_started                               := false;
			transmit_success                                  <= '0';
			receive_success                               <= '0';
			--mux_rx0_enable_custom                         <= '0';
			trigger_custom0_rx_start_listening_action     <= '0';
			trigger_deserializer0_start_listening_action  <= '0';
			block_modification_out                        <= (others => '0');

		elsif (rising_edge(clk_16)) then

			case receiver_state is
				when r_start =>
					receiver_state <= r_exchange_block;

					--trigger block receive
					--mux_rx0_enable_custom             <= '0';
					trigger(trigger_deserializer0_start_listening_action, trigger_deserializer0_start_listening_reaction);
				

				when r_exchange_block =>
					if (deserializer0_finished_listening_out = '1') then
						--next state
						receiver_state                    <= r_exchange_ack;

						--read block
						block_modification_out            <= deserializer0_block_out;
						receive_success                   <= deserializer0_correct_out;

						--trigger ack receive
						--mux_rx0_enable_custom             <= '1';
						trigger(trigger_custom0_rx_start_listening_action, trigger_custom0_rx_start_listening_reaction);
					end if;


				when r_exchange_ack =>
					if(custom0_rx_finished_listening = '1') then
						--read ack
						if (custom0_rx_byte = ACK) then
							transmit_success                  <= '1';
						else
							transmit_success                  <= '0';
						end if;

						--if transmitter already synced or both finished at the same time then skip sync2 state
						--else wait for sync2
						if(transmitter_state = t_sync2 or custom0_tx_finished_transmitting = '1') then
							--next state
							receiver_state                <= r_exchange_block;
	
							--trigger block receive
							--mux_rx0_enable_custom         <= '0';
							trigger(trigger_deserializer0_start_listening_action, trigger_deserializer0_start_listening_reaction);
						else
							--next state
							receiver_state                <= r_sync2;
						end if;
					end if;


				when r_sync2 =>
					if(transmitter_state = t_sync2 or custom0_tx_finished_transmitting = '1') then
						--next state
						receiver_state                    <= r_exchange_block;

						--trigger block receive
						--mux_rx0_enable_custom             <= '0';
						trigger(trigger_deserializer0_start_listening_action, trigger_deserializer0_start_listening_reaction);
					end if;

			end case;

		end if;
	end process;
	

	transmitter_flow : process (clk_16, reset_n) 
		variable process_started      : boolean   := false;
		variable tmp_receive_success  : std_logic := '0';
		variable tmp_transmit_success : std_logic := '0';
	begin
		if (reset_n = '0') then
			--transmitter_state                                  <= t_exchange_block;                      
			transmitter_state                                  <= t_sync1;                      
			process_started                               := false;                                                      
			tmp_receive_success                           := '0';
			tmp_transmit_success                          := '0';
			--mux_tx0_enable_custom                         <= '0';
			trigger_custom0_tx_start_transmitting_action  <= '0';
			trigger_serializer0_start_transmitting_action <= '0';
			custom0_tx_byte                               <= (others => '0');
			serializer0_block_in                          <= (others => '0');

		elsif (rising_edge(clk_16)) then

			case transmitter_state is

				when t_start =>
					transmitter_state <= t_sync1;	
					
					serializer0_block_in              <= (others => '0');
					--trigger block send
					--mux_tx0_enable_custom             <= '0';
					--trigger(trigger_serializer0_start_transmitting_action, trigger_serializer0_start_transmitting_reaction);


				when t_exchange_block =>
					if (serializer0_finished_transmitting_out = '1') then
						--if receiver finished first or both finished at the same time then skip sync1
						--else wait for sync1
						--NOTE: receiver probably could not have finished first (not proven yet)
						if (receiver_state = r_exchange_ack or receiver_state = r_sync2 or deserializer0_finished_listening_out = '1') then
							--next state
							transmitter_state                      <= t_exchange_ack;
							
							--if finished at same time then take success straight from deserializer
							if (deserializer0_finished_listening_out = '1') then
								tmp_receive_success := deserializer0_correct_out;
							else
								tmp_receive_success := receive_success;
							end if;

							--write ack
							if (tmp_receive_success = '1') then
								custom0_tx_byte               <= ACK;
							else 
								custom0_tx_byte               <= NACK;
							end if;

							--trigger ack send
							--mux_tx0_enable_custom             <= '1';
							trigger(trigger_custom0_tx_start_transmitting_action, trigger_custom0_tx_start_transmitting_reaction);
						else
							--next state
							transmitter_state                      <= t_sync1;
						end if;						
					end if;


				when t_sync1 =>
					--wait for received block
					if (receiver_state = r_exchange_ack or receiver_state = r_sync2 or deserializer0_finished_listening_out = '1') then
						--next state
						transmitter_state                      <= t_exchange_ack;
						
						--if finished at same time then take success straight from deserializer
						if (deserializer0_finished_listening_out = '1') then
							tmp_receive_success := deserializer0_correct_out;
						else
							tmp_receive_success := receive_success;
						end if;

						--write ack
						if (tmp_receive_success = '1') then
							custom0_tx_byte               <= ACK;
						else 
							custom0_tx_byte               <= NACK;
						end if;

						--trigger ack send
						--mux_tx0_enable_custom             <= '1';
						trigger(trigger_custom0_tx_start_transmitting_action, trigger_custom0_tx_start_transmitting_reaction);			
					end if;


				when t_exchange_ack =>
					if(custom0_tx_finished_transmitting = '1') then
						--if receiver finished first or both finished at the same time then skip sync2
						--else wait for sync2
						if(receiver_state = r_sync2 or custom0_rx_finished_listening = '1') then
							--next state
							transmitter_state                      <= t_exchange_block;
							
							--if finished at same time then take success straight from custom
							if (custom0_rx_finished_listening = '1') then
								if (custom0_rx_byte = ACK) then
									tmp_transmit_success                  := '1';
								else
									tmp_transmit_success                  := '0';
								end if;
							else 
								tmp_transmit_success := transmit_success;
							end if;

							--write block
							--if exchange successful then discard old block and latch new
							--else discard new block and repeat exchange
							if (tmp_transmit_success = '1' and receive_success = '1') then
								serializer0_block_in          <= block_modification_in;
							else
								serializer0_block_in          <= serializer0_block_in;
							end if;
	
							--trigger block send	
							--mux_tx0_enable_custom             <= '0';
							trigger(trigger_serializer0_start_transmitting_action, trigger_serializer0_start_transmitting_reaction);
						else
							--next state
							transmitter_state                      <= t_sync2;
						end if;
					end if;


				when t_sync2 =>
					if(receiver_state = r_sync2 or custom0_rx_finished_listening = '1') then
						--next state
						transmitter_state                      <= t_exchange_block;

						--if finished at same time then take success straight from custom
						if (custom0_rx_finished_listening = '1') then
							if (custom0_rx_byte = ACK) then
								tmp_transmit_success                  := '1';
							else
								tmp_transmit_success                  := '0';
							end if;
						else 
							tmp_transmit_success := transmit_success;
						end if;

						--write block
						--if exchange successful then discard old block and latch new
						--else discard new block and repeat exchange
						if (tmp_transmit_success = '1' and receive_success = '1') then
							serializer0_block_in          <= block_modification_in;
						else
							serializer0_block_in          <= serializer0_block_in;
						end if;

						--trigger block send	
						--mux_tx0_enable_custom             <= '0';
						trigger(trigger_serializer0_start_transmitting_action, trigger_serializer0_start_transmitting_reaction);
					end if;

			end case;

		end if;
	end process;


	process (transmitter_state) begin
		case transmitter_state is
			when t_exchange_block =>
				dbg_transmitter_state <= 0;
			when t_sync1 =>
				dbg_transmitter_state <= 1;
			when t_exchange_ack =>
				dbg_transmitter_state <= 2;
			when t_sync2 =>
				dbg_transmitter_state <= 3;
			when others =>
		end case;
	end process;

	process (receiver_state) begin
		case receiver_state is
			when r_exchange_block =>
				dbg_receiver_state <= 0;
			when r_exchange_ack =>
				dbg_receiver_state <= 2;
			when r_sync2 =>
				dbg_receiver_state <= 3;
			when others =>
		end case;
	end process;

end uart_communicator_impl;