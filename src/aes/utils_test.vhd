library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.aes_utils.all;

entity utils_test is
	port (
		block_in  : in  std_logic_vector(127 downto 0);
		block_out : out std_logic_vector(127 downto 0)
	);
end utils_test;

architecture utils_test_impl of utils_test is
	
	signal state_in  : aes_state;
	signal state_out : aes_state;
	
begin

	process (block_in, state_out) begin
		for r in 0 to 3 loop
			for c in 0 to 3 loop
				state_in(r, c) <= block_in((r + 4 * c + 1) * 8 - 1 downto (r + 4 * c) * 8);
				block_out((r + 4 * c + 1) * 8 - 1 downto (r + 4 * c) * 8) <= state_out(r, c);
			end loop;
		end loop;
	end process;

	process (block_in) 
		variable state : aes_state;
	begin
		state := state_in;
		state_out <= sub_bytes(state);
	end process;


	
end utils_test_impl;