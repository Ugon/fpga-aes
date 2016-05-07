library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.crc16.all;

entity test_crc16 is
	generic (
		byte_bits    : Integer := 8;
		block_bytes  : Integer := 4;
		block_bits   : Integer := 32;
		crc_bytes    : Integer := 2;
		crc_bits     : Integer := 16);
	port (
		block_in           : in  std_logic_vector(block_bits - 1 downto 0);
		crc_to_check       : in  std_logic_vector(crc_bits - 1 downto 0);
		crc_from_calculate : out std_logic_vector(crc_bits - 1 downto 0);
		correct            : out std_logic);
end test_crc16;

architecture test_crc16_impl of test_crc16 is 
	signal crc_from_calculate_internal : std_logic_vector(crc_bits - 1 downto 0);
begin

	crc_from_calculate <= crc_from_calculate_internal;

	--crc_from_calculate_internal <= crc_calculate(block_in);

	--correct <= crc_check(block_in, crc_to_check);
	
end test_crc16_impl;