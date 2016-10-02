library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.aes_utils.all;

package aes_transformations is

	type aes_state is array (0 to 3, 0 to 3) of std_logic_vector(7 downto 0);

	--common
	function add_round_key (constant state_in : aes_state; constant key_expansion : std_logic_vector; constant round_number : Integer) return aes_state;
	
	--encode
	function sub_bytes (constant state_in : aes_state) return aes_state;

	function shift_rows (constant state_in : aes_state) return aes_state;

	function mix_columns (constant state_in : aes_state) return aes_state;

	function round_0 (constant state_in : aes_state; constant key_expansion : std_logic_vector) return aes_state;
	
	function round_n (constant state_in : aes_state; constant key_expansion : std_logic_vector; constant n : Integer) return aes_state;

	function round_last (constant state_in : aes_state; constant key_expansion : std_logic_vector) return aes_state;
	
	function encode256 (constant plaintext : std_logic_vector; constant key_expansion : std_logic_vector) return std_logic_vector;

	--decode
	function inv_sub_bytes (constant state_in : aes_state) return aes_state;

	function inv_shift_rows (constant state_in : aes_state) return aes_state;

	function inv_mix_columns (constant state_in : aes_state) return aes_state;

	function inv_round_0 (constant state_in : aes_state; constant key_expansion : std_logic_vector) return aes_state;
	
	function inv_round_n (constant state_in : aes_state; constant key_expansion : std_logic_vector; constant n : Integer) return aes_state;

	function inv_round_last (constant state_in : aes_state; constant key_expansion : std_logic_vector) return aes_state;
	
	function decode256 (constant cyphertext : std_logic_vector; constant key_expansion : std_logic_vector) return std_logic_vector;

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


	function inv_sub_bytes (constant state_in : aes_state) return aes_state is 
		variable state_out : aes_state;
	begin
		for r in 0 to 3 loop
			for c in 0 to 3 loop
				state_out(r, c) := lookup_inv_sub(state_in(r, c));
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


	function inv_shift_rows (constant state_in : aes_state) return aes_state is
	 	variable state_out : aes_state;
	begin
		for r in 0 to 3 loop
			for c in 0 to 3 loop
				state_out(r, (c + r) mod 4) := state_in(r, c);
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


	function inv_mix_columns (constant state_in : aes_state) return aes_state is
	 	variable state_out : aes_state;
	begin
		for c in 0 to 3 loop
			state_out(0, c) :=     multiply(x"0e", state_in(0, c)) xor multiply(x"0b", state_in(1, c))
                               xor multiply(x"0d", state_in(2, c)) xor multiply(x"09", state_in(3, c));
			
			state_out(1, c) :=     multiply(x"09", state_in(0, c)) xor multiply(x"0e", state_in(1, c)) 
                               xor multiply(x"0b", state_in(2, c)) xor multiply(x"0d", state_in(3, c));
			
			state_out(2, c) :=     multiply(x"0d", state_in(0, c)) xor multiply(x"09", state_in(1, c))
                               xor multiply(x"0e", state_in(2, c)) xor multiply(x"0b", state_in(3, c));
            			
			state_out(3, c) :=     multiply(x"0b", state_in(0, c)) xor multiply(x"0d", state_in(1, c))
			                   xor multiply(x"09", state_in(2, c)) xor multiply(x"0e", state_in(3, c));
		end loop;

		return state_out;
	end;
 

	function add_round_key (constant state_in : aes_state; constant key_expansion : std_logic_vector; constant round_number : Integer) return aes_state is
		constant byte_bits   : Integer := 8;
		constant word_length : Integer := 4 * 8;
		constant Nb          : Integer := 4;

		variable key_word    : std_logic_vector(word_length - 1 downto 0);
	 	variable state_out   : aes_state;
	begin
		for c in 0 to 3 loop
			key_word := key_expansion((round_number * Nb + 1 + c) * word_length - 1 downto (round_number * Nb + c) * word_length);
			for r in 0 to 3 loop
				state_out(r, c) := state_in(r, c) xor key_word(byte_bits * (r + 1) - 1 downto byte_bits * r);
			end loop;
		end loop;

		return state_out;
	end function;


	function round_0 (constant state_in : aes_state; constant key_expansion : std_logic_vector) return aes_state is begin
		return add_round_key(state_in, key_expansion, 0);
	end function;


	function round_n (constant state_in : aes_state; constant key_expansion : std_logic_vector; constant n : Integer) return aes_state is
		variable state : aes_state;
	begin
		state := state_in;
		state := sub_bytes(state);
		state := shift_rows(state);
		state := mix_columns(state);
		state := add_round_key(state, key_expansion, n);

		return state;
	end function;


	function round_last (constant state_in : aes_state; constant key_expansion : std_logic_vector) return aes_state is
		variable state : aes_state;
	begin
		state := state_in;
		state := sub_bytes(state);
		state := shift_rows(state);
		state := add_round_key(state, key_expansion, 14);

		return state;
	end function;


	function inv_round_0 (constant state_in : aes_state; constant key_expansion : std_logic_vector) return aes_state is begin
		return add_round_key(state_in, key_expansion, 14);
	end function;


	function inv_round_n (constant state_in : aes_state; constant key_expansion : std_logic_vector; constant n : Integer) return aes_state is
		variable state : aes_state;
	begin
		state := state_in;
		state := inv_shift_rows(state);
		state := inv_sub_bytes(state);
		state := add_round_key(state, key_expansion, n);
		state := inv_mix_columns(state);

		return state;
	end function;


	function inv_round_last (constant state_in : aes_state; constant key_expansion : std_logic_vector) return aes_state is
		variable state : aes_state;
	begin
		state := state_in;
		state := inv_shift_rows(state);
		state := inv_sub_bytes(state);
		state := add_round_key(state, key_expansion, 0);

		return state;
	end function;


	function encode256 (constant plaintext : std_logic_vector; constant key_expansion : std_logic_vector) return std_logic_vector is
		variable cyphertext    : std_logic_vector(127 downto 0);
		--variable key_expansion : std_logic_vector(15 * 128 - 1 downto 0);
		variable state         : aes_state;
	begin
		for r in 0 to 3 loop
			for c in 0 to 3 loop
				state(r, c) := plaintext((r + 4 * c + 1) * 8 - 1 downto (r + 4 * c) * 8);
			end loop;
		end loop;

		--key_expansion := key_expansion256(key);

		state := round_0(state, key_expansion);

		for i in 1 to 13 loop
			state := round_n(state, key_expansion, i);
		end loop;

		state := round_last(state, key_expansion);

		for r in 0 to 3 loop
			for c in 0 to 3 loop
				cyphertext((r + 4 * c + 1) * 8 - 1 downto (r + 4 * c) * 8) := state(r, c);
			end loop;
		end loop;

		return cyphertext;
	end function;


	function decode256 (constant cyphertext : std_logic_vector; constant key_expansion : std_logic_vector) return std_logic_vector is
		variable plaintext     : std_logic_vector(127 downto 0);
		--variable key_expansion : std_logic_vector(15 * 128 - 1 downto 0);
		variable state         : aes_state;
	begin
		for r in 0 to 3 loop
			for c in 0 to 3 loop
				state(r, c) := cyphertext((r + 4 * c + 1) * 8 - 1 downto (r + 4 * c) * 8);
			end loop;
		end loop;

		--key_expansion := key_expansion256(key);

		state := inv_round_0(state, key_expansion);

		for i in 13 downto 1 loop
			state := inv_round_n(state, key_expansion, i);
		end loop;

		state := inv_round_last(state, key_expansion);

		for r in 0 to 3 loop
			for c in 0 to 3 loop
				plaintext((r + 4 * c + 1) * 8 - 1 downto (r + 4 * c) * 8) := state(r, c);
			end loop;
		end loop;

		return plaintext;
	end function;

end aes_transformations;