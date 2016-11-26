library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity communicator_test is
	generic (
		byte_bits   : Integer := 8;
		block_bytes : Integer := 4;
		block_bits  : Integer := 32;
		key_bytes   : Integer := 8;
		key_bits    : Integer := 64;
		key_expansion_bits : Integer := 15 * 32);
	port (
		clk_16  : in    std_logic; --16x baudrate
		reset_n : in    std_logic;
		rx      : in    std_logic;
		tx      : out   std_logic);
end communicator_test;

architecture communicator_test_impl of communicator_test is

	signal loopback : std_logic_vector(block_bits - 1 downto 0);
	
begin

	communicator0 : entity work.communicator
		generic map (
			byte_bits          => byte_bits,
			block_bytes        => block_bytes,
			block_bits         => block_bits,
			key_bytes          => key_bytes,
			key_bits           => key_bits,
			key_expansion_bits => key_expansion_bits)
		port map (
			reset_n            => reset_n,
			clk_16             => clk_16,
			rx                 => rx,
			tx                 => tx
		);
	
end communicator_test_impl;