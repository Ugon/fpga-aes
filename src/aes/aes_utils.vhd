library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.aes_sub_table.all;
use work.aes_utils.all;

package aes_utils is

	type aes_state is array (0 to 3, 0 to 3) of std_logic_vector(7 downto 0);

	function sub_bytes (constant state_in : aes_state) return aes_state;

	function shift_rows (constant state_in : aes_state) return aes_state;


end aes_utils;

package body aes_utils is

	function sub_bytes (constant state_in : aes_state) return aes_state is 
		variable state_out : aes_state;
	begin
		for r in 0 to 3 loop
			for c in 0 to 3 loop
				state_out(r, c) := sub_lookup(state_in(r, c));
			end loop;
		end loop;
		
		return state_out;
	end function;

	function shift_rows (constant state_in : aes_state) return aes_state is
	 	variable state_out : aes_state;
	begin
		for r in 0 to 3 loop
			for c in 0 to 3 loop
				state_out(r, c) := state_in(r, (c + r) mod 4);
			end loop;
		end loop;
		
		return state_out;
	end function;

end aes_utils;