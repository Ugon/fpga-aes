library ieee;
use ieee.std_logic_1164.all;

entity sync_2ff is
port (
    async_in : in std_logic;
    clk : in std_logic;
    reset_n : in std_logic;
    sync_out : out std_logic);
end sync_2ff;

architecture sync_2ff_impl of sync_2ff is
	signal ff1, ff2: std_logic;
	
	-- It's nice to let the synthesizer know what you're doing. Altera's way of doing it as follows:
	ATTRIBUTE altera_attribute : string;
	ATTRIBUTE altera_attribute OF ff1 : signal is "-name SYNCHRONIZER_IDENTIFICATION ""FORCED IF ASYNCHRONOUS""";
	ATTRIBUTE altera_attribute OF sync_2ff_impl : architecture is "-name SDC_STATEMENT ""set_false_path -to *|sync_2ff:*|ff1 """;
	
	-- also set the 'preserve' attribute to ff1 and ff2 so the synthesis tool doesn't optimize them away
	ATTRIBUTE preserve: boolean;
	ATTRIBUTE preserve OF ff1: signal IS true;
	ATTRIBUTE preserve OF ff2: signal IS true;

begin

	process (clk, reset_n) begin
		if (reset_n = '0') then
		    ff1 <= '0';
		    ff2 <= '0';
		elsif (rising_edge(clk)) then
		    ff1      <= async_in;
		    ff2      <= ff1;
		    sync_out <= ff2;
		end if;
	end process;

end sync_2ff_impl;