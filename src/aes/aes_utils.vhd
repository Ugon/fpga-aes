library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package aes_utils is
	
	type t_sub_table is array (0 to 255) of std_logic_vector(7 downto 0);

	constant sub_table : t_sub_table := (
		------|   0      1      2      3      4      5      6      7      8      9      a      b      c      d      e      f
		------|------|------|------|------|------|------|------|------|------|------|------|------|------|------|------|------|
		/* 0 */ x"63", x"7c", x"77", x"7b", x"f2", x"6b", x"6f", x"c5", x"30", x"01", x"67", x"2b", x"fe", x"d7", x"ab", x"76",
		/* 1 */ x"ca", x"82", x"c9", x"7d", x"fa", x"59", x"47", x"f0", x"ad", x"d4", x"a2", x"af", x"9c", x"a4", x"72", x"c0",
		/* 2 */ x"b7", x"fd", x"93", x"26", x"36", x"3f", x"f7", x"cc", x"34", x"a5", x"e5", x"f1", x"71", x"d8", x"31", x"15",
		/* 3 */ x"04", x"c7", x"23", x"c3", x"18", x"96", x"05", x"9a", x"07", x"12", x"80", x"e2", x"eb", x"27", x"b2", x"75",
		/* 4 */ x"09", x"83", x"2c", x"1a", x"1b", x"6e", x"5a", x"a0", x"52", x"3b", x"d6", x"b3", x"29", x"e3", x"2f", x"84",
		/* 5 */ x"53", x"d1", x"00", x"ed", x"20", x"fc", x"b1", x"5b", x"6a", x"cb", x"be", x"39", x"4a", x"4c", x"58", x"cf",
		/* 6 */ x"d0", x"ef", x"aa", x"fb", x"43", x"4d", x"33", x"85", x"45", x"f9", x"02", x"7f", x"50", x"3c", x"9f", x"a8",
		/* 7 */ x"51", x"a3", x"40", x"8f", x"92", x"9d", x"38", x"f5", x"bc", x"b6", x"da", x"21", x"10", x"ff", x"f3", x"d2",
		/* 8 */ x"cd", x"0c", x"13", x"ec", x"5f", x"97", x"44", x"17", x"c4", x"a7", x"7e", x"3d", x"64", x"5d", x"19", x"73",
		/* 9 */ x"60", x"81", x"4f", x"dc", x"22", x"2a", x"90", x"88", x"46", x"ee", x"b8", x"14", x"de", x"5e", x"0b", x"db",
		/* a */ x"e0", x"32", x"3a", x"0a", x"49", x"06", x"24", x"5c", x"c2", x"d3", x"ac", x"62", x"91", x"95", x"e4", x"79",
		/* b */ x"e7", x"c8", x"37", x"6d", x"8d", x"d5", x"4e", x"a9", x"6c", x"56", x"f4", x"ea", x"65", x"7a", x"ae", x"08",
		/* c */ x"ba", x"78", x"25", x"2e", x"1c", x"a6", x"b4", x"c6", x"e8", x"dd", x"74", x"1f", x"4b", x"bd", x"8b", x"8a",
		/* d */ x"70", x"3e", x"b5", x"66", x"48", x"03", x"f6", x"0e", x"61", x"35", x"57", x"b9", x"86", x"c1", x"1d", x"9e",
		/* e */ x"e1", x"f8", x"98", x"11", x"69", x"d9", x"8e", x"94", x"9b", x"1e", x"87", x"e9", x"ce", x"55", x"28", x"df",
		/* f */ x"8c", x"a1", x"89", x"0d", x"bf", x"e6", x"42", x"68", x"41", x"99", x"2d", x"0f", x"b0", x"54", x"bb", x"16"
	);

	--function lookup_sub (constant high : std_logic_vector(3 downto 0); constant low : std_logic_vector(3 downto 0)) return std_logic_vector;
	
	function lookup_sub (constant index : std_logic_vector(7 downto 0)) return std_logic_vector;

	function multiply (constant left : std_logic_vector(7 downto 0); constant right : std_logic_vector(7 downto 0)) return std_logic_vector;

	function key_expansion256 (constant key : std_logic_vector) return std_logic_vector;

	function reverse_byte_order(signal inp : std_logic_vector) return std_logic_vector;

end aes_utils;

package body aes_utils is

	--function lookup_sub (constant high : std_logic_vector(3 downto 0); constant low : std_logic_vector(3 downto 0)) return std_logic_vector is 
		--variable index : std_logic_vector(7 downto 0);
	--begin
		--index := high & low;
		--return sub_table(to_integer(unsigned(index)));
	--end function;
	

	function lookup_sub (constant index : std_logic_vector(7 downto 0)) return std_logic_vector is begin
		return sub_table(to_integer(unsigned(index)));
	end function;


	function multiply (constant left : std_logic_vector(7 downto 0); constant right : std_logic_vector(7 downto 0)) return std_logic_vector is
		constant irred_poly       : std_logic_vector(7 downto 0) := x"1b";
		variable a                : std_logic_vector(7 downto 0) := (others => '0');
		variable b                : std_logic_vector(7 downto 0) := (others => '0');
		variable p                : std_logic_vector(7 downto 0) := (others => '0');
		variable extended_b_lsb   : std_logic_vector(7 downto 0) := (others => '0');
		variable extended_a_carry : std_logic_vector(7 downto 0) := (others => '0');
	begin
		a := left;
		b := right;
		p := (others => '0');

		for i in 0 to 7 loop
			--1
			extended_b_lsb := (others => b(0));
			p := p xor (extended_b_lsb and a);

			--2
			b := '0' & b(7 downto 1);

			--3
			extended_a_carry := (others => a(7));

			--4
			a := a(6 downto 0) & '0';

			--5
			a := a xor (extended_a_carry and irred_poly);
		end loop;
		
		return p;
	end function;


	function key_expansion256 (constant key : std_logic_vector) return std_logic_vector is
		constant word_length : Integer := 4 * 8;
		constant byte_bits   : Integer := 8;
		constant Nk          : Integer := 8;

		variable tmp         : std_logic_vector(word_length - 1 downto 0);
		variable tmp2        : std_logic_vector(word_length - 1 downto 0);
		variable rcon        : std_logic_vector(word_length - 1 downto 0);
		variable result      : std_logic_vector(60 * word_length - 1 downto 0);
	begin
		result(word_length * Nk - 1 downto 0) := key;
		for i in Nk to 59 loop
			tmp := result(word_length * i - 1 downto word_length * (i - 1));
			
			if (i mod Nk = 0) then
				--RotWord
				tmp2 := tmp;
				tmp(word_length - 1 downto word_length - byte_bits) := tmp2(byte_bits - 1 downto 0);
				tmp(word_length - byte_bits - 1 downto 0) := tmp2(word_length - 1 downto byte_bits);


				--SubWord
				for j in 0 to 3 loop
					tmp((j + 1) * byte_bits - 1 downto j * byte_bits) := lookup_sub(tmp((j + 1) * byte_bits - 1 downto j * byte_bits));
				end loop;

				--Rcon XOR
				tmp(byte_bits - 1 downto 0) := tmp(byte_bits - 1 downto 0) xor std_logic_vector(to_unsigned(2 ** (i / Nk - 1), byte_bits));

			elsif (i mod Nk = 4) then
				--SubWord
				for j in 0 to 3 loop
					tmp((j + 1) * byte_bits - 1 downto j * byte_bits) := lookup_sub(tmp((j + 1) * byte_bits - 1 downto j * byte_bits));
				end loop;

			end if;
			
			result(word_length * (i + 1) - 1 downto word_length * i) := 
				tmp xor result(word_length * (i - Nk + 1) - 1 downto word_length * (i - Nk));
		end loop;

		return result;
	end function;


	function reverse_byte_order(signal inp : std_logic_vector) return std_logic_vector is
		constant byte_bits : Integer := 8;	
		constant inp_bytes : Integer := inp'length / byte_bits;
		
		variable result : std_logic_vector(inp'range);
	begin
		for i in 0 to inp_bytes - 1 loop
			result((inp_bytes - i) * byte_bits - 1 downto (inp_bytes - i - 1) * byte_bits) := inp((i + 1) * byte_bits - 1 downto i * byte_bits);
		end loop;

		return result;
	end function;


end aes_utils;