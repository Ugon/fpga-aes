library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package utils is

	procedure trigger (
		signal action       : out std_logic;
		signal reaction     : in std_logic);

end utils;

package body utils is

	procedure trigger (signal action : out std_logic; signal reaction : in std_logic) is begin
		action <= not reaction;
	end procedure;

end utils;