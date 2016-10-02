library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity communicator_test is
	generic (
		byte_bits    : Integer := 8;
		block_bytes  : Integer := 4;
		block_bits   : Integer := 32;
		key_bytes    : Integer := 8;
		key_bits     : Integer := 64;
		key_expansion_bits : Integer := 15 * 32);
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

dbg_state                                 : out Integer range 0 to 17;  

dbg_cnt_rx                                : out Integer range 0 to 15;
dbg_cnt_tx                                : out Integer range 0 to 15;

dbg_mux_rx0_enable_custom                 : out std_logic;
dbg_mux_tx0_enable_custom                 : out std_logic;

dbg_serializer0_tx_byte                   : out std_logic_vector(byte_bits - 1 downto 0);

dbg_key                                   : out std_logic_vector(key_bits   - 1 downto 0) := (others => '0');
dbg_aes_input                             : out std_logic_vector(block_bits - 1 downto 0) := (others => '0');
dbg_aes_enc_prev_ciphertext               : out std_logic_vector(block_bits - 1 downto 0) := (others => '0');
dbg_aec_enc_output                        : out std_logic_vector(block_bits - 1 downto 0) := (others => '0');
dbg_aes_dec_prev_ciphertext               : out std_logic_vector(block_bits - 1 downto 0) := (others => '0');
dbg_aec_dec_output                        : out std_logic_vector(block_bits - 1 downto 0) := (others => '0');

dbg_next_serializer0_block_in  : out std_logic_vector(block_bits - 1 downto 0)

	);
end communicator_test;

architecture communicator_test_impl of communicator_test is

	signal loopback : std_logic_vector(block_bits - 1 downto 0);
	
begin

	communicator0 : entity work.communicator
		generic map (
			byte_bits              => byte_bits,
			block_bytes            => block_bytes,
			block_bits             => block_bits,
			key_bytes              => key_bytes,
			key_bits               => key_bits,
			key_expansion_bits     => key_expansion_bits)
		port map (
			reset_n                => reset_n,
			clk_16                 => clk_16,
			rx                     => rx,
			tx                     => tx,
--			block_modification_in  => loopback,
--			block_modification_out => loopback,

			dbg_rx0_byte_out                          => dbg_rx0_byte_out,
			dbg_rx0_start_listening_in                => dbg_rx0_start_listening_in,
			dbg_rx0_finished_listening_out            => dbg_rx0_finished_listening_out,

			dbg_tx0_byte_in                           => dbg_tx0_byte_in,
			dbg_tx0_start_transmitting_in             => dbg_tx0_start_transmitting_in,
			dbg_tx0_finished_transmitting_out         => dbg_tx0_finished_transmitting_out,

			dbg_deserializer0_block_out               => dbg_deserializer0_block_out,
			dbg_deserializer0_start_listening_in      => dbg_deserializer0_start_listening_in,
			dbg_deserializer0_finished_listening_out  => dbg_deserializer0_finished_listening_out,
			dbg_deserializer0_correct_out             => dbg_deserializer0_correct_out,

			dbg_serializer0_block_in                  => dbg_serializer0_block_in,
			dbg_serializer0_start_transmitting_in     => dbg_serializer0_start_transmitting_in,
			dbg_serializer0_finished_transmitting_out => dbg_serializer0_finished_transmitting_out,

			dbg_state                                 => dbg_state,

			dbg_cnt_rx                                => dbg_cnt_rx,
			dbg_cnt_tx                                => dbg_cnt_tx,

			dbg_mux_rx0_enable_custom                 => dbg_mux_rx0_enable_custom,

			dbg_serializer0_tx_byte                   => dbg_serializer0_tx_byte,

			dbg_key                                   => dbg_key,
			dbg_aes_input                             => dbg_aes_input,
			dbg_aes_enc_prev_ciphertext               => dbg_aes_enc_prev_ciphertext,
			dbg_aec_enc_output                        => dbg_aec_enc_output,
			dbg_aes_dec_prev_ciphertext               => dbg_aes_dec_prev_ciphertext,
			dbg_aec_dec_output                        => dbg_aec_dec_output,
			
			dbg_next_serializer0_block_in             => dbg_next_serializer0_block_in
		);
	
end communicator_test_impl;