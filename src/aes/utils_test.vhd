library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.aes_utils.all;
use work.aes_transformations.all;

entity utils_test is
	port (
		block_in  : in  std_logic_vector(127 downto 0);
		block_out : out std_logic_vector(127 downto 0);
		a : in std_logic_vector(7 downto 0);
		b : in std_logic_vector(7 downto 0);
		p : out std_logic_vector(7 downto 0);
		key_in : in  std_logic_vector(255 downto 0);
		key_expanded : out std_logic_vector(60 * 4 * 8 - 1 downto 0)
	);
end utils_test;

architecture utils_test_impl of utils_test is
	
	signal state_in  : aes_state;
	signal state_out : aes_state;
	signal key_expanded_internal : std_logic_vector(60 * 4 * 8 - 1 downto 0);
begin
	key_expanded <= key_expanded_internal;

	key_expanded_internal <= key_expansion256(key_in);
	--state_out <= inv_round_0(state_in, key_expanded_internal);
	--state_out <= inv_shift_rows(state_in);
	--state_out <= inv_sub_bytes(state_in);
	--state_out <= add_round_key(state_in, key_expanded_internal, 13);
	--state_out <= inv_mix_columns(state_in);
	--state_out <= inv_round_last(state_in, key_expanded_internal);
	--state_out <= add_round_key(state_in, key_expanded_internal, 0);
	




	--state_out <= inv_add_round_key(state_in, key_expanded_internal, 14);
	--state_out <= decode256(state_in, key_in);
	--state_out <= mix_columns(state_in);
	--state_out <= sub_bytes(state_in);
	--p <= multiply(a, x"03");
	
--	process (block_in, state_out) begin
--		for r in 0 to 3 loop
--			for c in 0 to 3 loop
--				state_in(r, c) <= block_in((r + 4 * c + 1) * 8 - 1 downto (r + 4 * c) * 8);
--				block_out((r + 4 * c + 1) * 8 - 1 downto (r + 4 * c) * 8) <= state_out(r, c);
--			end loop;
--		end loop;
--	end process;

	block_out <= decode256(block_in, key_in);

	
end utils_test_impl;