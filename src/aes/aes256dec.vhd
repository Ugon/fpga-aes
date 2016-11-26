library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.aes_transformations.all;

entity aes256dec is
	generic (
		byte_bits          : Integer := 8;
		block_bytes        : Integer := 16;
		block_bits         : Integer := 128;
		key_bytes          : Integer := 32;
		key_expansion_bits : Integer := 15 * 128);
	port (
		key_expansion : in  std_logic_vector(key_expansion_bits - 1 downto 0);
		cyphertext    : in  std_logic_vector(block_bits - 1 downto 0);
		plaintext     : out std_logic_vector(block_bits - 1 downto 0));
end aes256dec;

architecture aes256dec_impl of aes256dec is begin

	plaintext <= decode256(cyphertext, key_expansion);
--	plaintext <= cyphertext;

end aes256dec_impl;