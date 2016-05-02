library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity integration_test is
	generic (
		data_bits    : Integer := 8;
		block_bytes  : Integer := 16;
		block_length : Integer := 128);
	port (
		clk           : in    std_logic;
		reset_n       : in    std_logic;
		rx            : in    std_logic;
		tx            : out   std_logic;

		dbg_data_from_rx       : out std_logic_vector(data_bits - 1 downto 0);
		dbg_data_to_tx         : out std_logic_vector(data_bits - 1 downto 0);
		dbg_available_from_rx  : out std_logic;
		dbg_available_to_tx    : out std_logic;
		dbg_available_between  : out std_logic;

		dbg_block_signal        : out std_logic_vector(block_length - 1 downto 0);
		dbg_provide_next_signal : out std_logic
		);
end integration_test;

architecture integration_test_impl of integration_test is

	signal data_from_rx       : std_logic_vector(data_bits - 1 downto 0);
	signal data_to_tx         : std_logic_vector(data_bits - 1 downto 0);
	signal available_from_rx  : std_logic;
	signal available_to_tx    : std_logic;
	signal available_between  : std_logic;

	signal block_signal        : std_logic_vector(block_length - 1 downto 0);
	signal provide_next_signal : std_logic;

begin

	dbg_data_from_rx        <= data_from_rx;
	dbg_data_to_tx          <= data_to_tx;
	dbg_available_from_rx   <= available_from_rx;
	dbg_available_to_tx     <= available_to_tx;
	dbg_available_between   <= available_between;

	dbg_block_signal        <= block_signal;
	dbg_provide_next_signal <= provide_next_signal;

	--uart_rx0 : entity work.uart_rx
	--	port map (
	--		reset_n   => reset_n,
	--		clk       => clk,
	--		data      => data_from_rx,
	--		available => available_from_rx,
	--		rx        => rx
	--	);

	--entity_tx0 : entity work.uart_tx
	--	port map (
	--		reset_n      => reset_n,
	--		clk          => clk,
	--		data         => data_to_tx,
	--		available    => available_to_tx, 
	--		tx           => tx,
	--		provide_next => provide_next_signal
	--	);

	--block_deserializer0 : entity work.block_deserializer
	--	port map (
	--		clk           => clk,
	--		reset_n       => reset_n,
	--		data_in       => data_from_rx,
	--		available_in  => available_from_rx,
	--		block_out     => block_signal,
	--		available_out => available_between
	--	);

	--block_serializer0 : entity work.block_serializer 
	--	port map (
	--		provide_next  => provide_next_signal,
	--		reset_n       => reset_n,
	--		data_out      => data_to_tx,
	--		available_out => available_to_tx,
	--		block_in      => block_signal,
	--		available_in  => available_between
	--	);



end integration_test_impl;