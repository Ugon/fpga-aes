library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.aes_transformations.all;

entity aes256enc is
	generic (
		byte_bits          : Integer := 8;
		block_bytes        : Integer := 16;
		block_bits         : Integer := 128;
		key_bytes          : Integer := 32;
		key_expansion_bits : Integer := 15 * 128);
	port (
		key_expansion_in   : in  std_logic_vector(key_expansion_bits - 1 downto 0);
		plaintext_in       : in  std_logic_vector(block_bits - 1 downto 0);
		cyphertext_out     : out std_logic_vector(block_bits - 1 downto 0));
end aes256enc;

architecture aes256enc_impl of aes256enc is begin

	--cyphertext_out <= encode256(plaintext_in, key_expansion_in);
	cyphertext_out <= plaintext_in;

end aes256enc_impl;