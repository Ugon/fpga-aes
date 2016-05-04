library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.utils.all;

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

dbg_state                                 : out Integer range 0 to 2;

dbg_cnt_rx                                : out Integer range 0 to 15;
dbg_cnt_tx                                : out Integer range 0 to 15;

dbg_mux_rx0_enable_custom                 : out std_logic;
dbg_mux_tx0_enable_custom                 : out std_logic;

dbg_serializer0_tx_byte                   : out std_logic_vector(byte_bits - 1 downto 0);

dbg_start_error           : out std_logic;
dbg_stop_error            : out std_logic

);
end communicator;

architecture communicator_impl of communicator is
	type fsm is (start, blocks, acks);
	signal state : fsm := start;

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
	signal custom0_rx_byte                  : std_logic_vector(byte_bits - 1 downto 0)  := (others => '0');
	signal custom0_rx_start_listening       : std_logic                                 := '0';
	signal custom0_rx_finished_listening    : std_logic                                 := '0';

	signal custom0_tx_byte                  : std_logic_vector(byte_bits - 1 downto 0)  := (others => '0');
	signal custom0_tx_start_transmitting    : std_logic                                 := '0';
	signal custom0_tx_finished_transmitting : std_logic                                 := '0';

	--RX TX SIGNAL MUX
	signal mux_rx0_enable_custom : std_logic := '1';
	signal mux_tx0_enable_custom : std_logic := '0';

	signal mux_rx_switch_combined : std_logic := '0';
	signal mux_tx_switch_combined : std_logic := '0';

	signal next_custom0_tx_byte      : std_logic_vector(byte_bits - 1 downto 0)  := (others => '0');
	signal next_serializer0_block_in : std_logic_vector(block_bits - 1 downto 0) := (others => '0');

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

dbg_mux_rx0_enable_custom                 <= mux_rx0_enable_custom;
dbg_mux_tx0_enable_custom                 <= mux_tx0_enable_custom;

dbg_serializer0_tx_byte                   <= serializer0_tx_byte;

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
			dbg_stop_error            => dbg_stop_error
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

	mux_rx0_switch : process (reset_n, mux_rx_switch_combined) begin
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
	begin
		if (reset_n = '0') then
			state                                         <= start;
			received_correct_block                        := '0';
			next_custom0_tx_byte                          <= (others => '0');
			next_serializer0_block_in                     <= (others => '0');
			block_modification_out                        <= (others => '0');
			trigger_custom0_rx_start_listening_action     <= '0';
			trigger_deserializer0_start_listening_action  <= '0';
			trigger_custom0_tx_start_transmitting_action  <= '0';
			trigger_serializer0_start_transmitting_action <= '0';
		elsif (rising_edge(clk_16)) then
			case state is
				when start =>
					state                                 <= blocks;

					--trigger receiver start listening
					trigger(trigger_deserializer0_start_listening_action, trigger_deserializer0_start_listening_reaction);
	
				when blocks =>
 					--if receiver finished (transmitter is guaranteed to finish first or at the same time)
					if (deserializer0_finished_listening_out = '1') then
						state                             <= acks;

						--read receiver output
						block_modification_out            <= deserializer0_block_out;
						received_correct_block            := deserializer0_correct_out;
				
						--set transmitter input
						if (deserializer0_correct_out = '1') then
							next_custom0_tx_byte          <= ACK;
						else 
							next_custom0_tx_byte          <= NACK;
						end if;			

						--trigger receiver start listening
						trigger(trigger_custom0_rx_start_listening_action, trigger_custom0_rx_start_listening_reaction);

						--trigger transmitter start transmitting
						trigger(trigger_custom0_tx_start_transmitting_action, trigger_custom0_tx_start_transmitting_reaction);
					end if;

				when acks =>
 					--if receiver finished (transmitter is guaranteed to finish first or at the same time)
					if(custom0_rx_finished_listening = '1') then
						state                             <= blocks;

						--read receiver output and set transmitter input
						if (received_correct_block = '1' and custom0_rx_byte = ACK) then
							--if both directions successful
							next_serializer0_block_in     <= block_modification_in;					
						else
							--if some direction failed
							next_serializer0_block_in     <= serializer0_block_in;							
						end if;

						--trigger receiver start listening
						trigger(trigger_deserializer0_start_listening_action, trigger_deserializer0_start_listening_reaction);
						
						--trigger transmitter start transmitting
						trigger(trigger_serializer0_start_transmitting_action, trigger_serializer0_start_transmitting_reaction);
					end if;

			end case;
		end if;
	end process;


	process (state) begin
		case state is
			when start =>
				dbg_state <= 0;
			when blocks =>
				dbg_state <= 1;
			when acks =>
				dbg_state <= 2;
		end case;
	end process;

end communicator_impl;
