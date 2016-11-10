library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

package crc16 is
	
	constant crc_polynomial : std_logic_vector(16 downto 0) := '1' & x"8005";
	constant crc_bits       : Integer                       := 16;
	constant crc_init       : std_logic_vector(15 downto 0) := (others => '0');

	function crc_add_data (accumulator : std_logic_vector; next_data : std_logic_vector) return std_logic_vector;

	function crc_finish (accumulator : std_logic_vector) return std_logic_vector;

	function crc_verify (accumulator : std_logic_vector) return std_logic;

end crc16;

package body crc16 is

	function crc_add_data (signal accumulator : std_logic_vector; signal next_data : std_logic_vector) return std_logic_vector is
		variable tmp : std_logic_vector(crc_bits + next_data'length - 1 downto 0);
	begin
		tmp(crc_bits + next_data'length - 1 downto next_data'length) := accumulator;
		tmp(next_data'length - 1 downto 0)                           := next_data;
		
		for i in crc_bits + next_data'length - 1 downto crc_bits loop
			if (tmp(i) = '1') then
				tmp(i downto i - crc_bits) := tmp(i downto i - crc_bits) xor crc_polynomial;
			else
				tmp(i downto i - crc_bits) := tmp(i downto i - crc_bits);
			end if;
		end loop;

		return tmp(crc_bits - 1 downto 0);
	end function;


	function crc_finish (signal accumulator : std_logic_vector) return std_logic_vector is begin
		return crc_add_data(accumulator, crc_init);
	end function;


	function crc_verify (signal accumulator : std_logic_vector) return std_logic is begin
		return not or_reduce(accumulator);
	end function;

end crc16;