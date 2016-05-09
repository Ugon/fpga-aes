library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.aes_utils.all;

package aes_transformations is

	type aes_state is array (0 to 3, 0 to 3) of std_logic_vector(7 downto 0);

	function sub_bytes (constant state_in : aes_state) return aes_state;

	function shift_rows (constant state_in : aes_state) return aes_state;

	function mix_columns (constant state_in : aes_state) return aes_state;

end aes_transformations;

package body aes_transformations is

	function sub_bytes (constant state_in : aes_state) return aes_state is 
		variable state_out : aes_state;
	begin
		for r in 0 to 3 loop
			for c in 0 to 3 loop
				state_out(r, c) := lookup_sub(state_in(r, c));
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

	function mix_columns (constant state_in : aes_state) return aes_state is
	 	variable state_out : aes_state;
	begin
		for c in 0 to 3 loop
			state_out(0, c) :=     multiply(x"02", state_in(0, c)) xor multiply(x"03", state_in(1, c))
                               xor                 state_in(2, c)  xor                 state_in(3, c);
			
			state_out(1, c) :=                     state_in(0, c)  xor multiply(x"02", state_in(1, c)) 
                               xor multiply(x"03", state_in(2, c)) xor                 state_in(3, c);
			
			state_out(2, c) :=                     state_in(0, c)  xor                 state_in(1, c)
                               xor multiply(x"02", state_in(2, c)) xor multiply(x"03", state_in(3, c));
            			
			state_out(3, c) :=     multiply(x"03", state_in(0, c)) xor                 state_in(1, c)
			                   xor                 state_in(2, c)  xor multiply(x"02", state_in(3, c));
		end loop;
		return state_out;
	end;

end aes_transformations;