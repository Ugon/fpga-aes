library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.aes_transformations.all;

entity aes256 is
	generic (
		byte_bits    : Integer := 8;
		block_bytes  : Integer := 16;
		block_bits   : Integer := 128;
		key_bytes    : Integer := 32;
		key_bits     : Integer := 256);
	port (
		key        : in  std_logic_vector(key_bits - 1 downto 0);
		plaintext  : in  std_logic_vector(block_bits - 1 downto 0);
		cyphertext : out std_logic_vector(block_bits - 1 downto 0));
end aes256;

architecture aes256_impl of aes256 is begin

	cyphertext <= encode256(plaintext, key);

end aes256_impl;