library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.aes_utils.all;

entity top is
    port (
      --------- CLOCK ---------
    CLOCK_50:                     in    std_logic;
    CLOCK2_50:                    in    std_logic;
    CLOCK3_50:                    in    std_logic;
    CLOCK4_50:                    in    std_logic;

      --------- DRAM ---------
    DRAM_ADDR:                    out   std_logic_vector(12 downto 0);
    DRAM_BA:                      out   std_logic_vector(1 downto 0);
    DRAM_CAS_N:                   out   std_logic;
    DRAM_CKE:                     out   std_logic;
    DRAM_CLK:                     out   std_logic;
    DRAM_CS_N:                    out   std_logic;
    DRAM_DQ:                      inout std_logic_vector(15 downto 0);
    DRAM_LDQM:                    out   std_logic;
    DRAM_RAS_N:                   out   std_logic;
    DRAM_UDQM:                    out   std_logic;
    DRAM_WE_N:                    out   std_logic;

      --------- GPIO ---------
    GPIO_0:                       inout std_logic_vector(35 downto 0);
    GPIO_1:                       inout std_logic_vector(35 downto 0);
 
      --------- HEX ---------
    HEX0:                         out   std_logic_vector(6 downto 0);
    HEX1:                         out   std_logic_vector(6 downto 0);
    HEX2:                         out   std_logic_vector(6 downto 0);
    HEX3:                         out   std_logic_vector(6 downto 0);
    HEX4:                         out   std_logic_vector(6 downto 0);
    HEX5:                         out   std_logic_vector(6 downto 0);
    
      --------- KEY ---------
    KEY:                          in    std_logic_vector(3 downto 0);

      --------- LEDR ---------
    LEDR:                         out   std_logic_vector(9 downto 0);

      --------- SW ---------
    SW:                           in    std_logic_vector(9 downto 0);

      --------- TD ---------
    TD_CLK27:                     in    std_logic;
    TD_DATA:                      in    std_logic_vector(7 downto 0);
    TD_HS:                        in    std_logic;
    TD_RESET_N:                   out   std_logic;
    TD_VS:                        in    std_logic);
end entity top;

architecture rtl of top is
    type fsm is (init, check);

    component inputmem port (
        address     : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
        clock       : IN STD_LOGIC  := '1';
        q           : OUT STD_LOGIC_VECTOR (255 DOWNTO 0));
    end component;
	 
	component pll_0002 is port (
		refclk   : in  std_logic := 'X'; -- clk
		rst      : in  std_logic := 'X'; -- reset
		outclk_0 : out std_logic;        -- clk
		locked   : out std_logic);       -- export
	end component pll_0002;

    signal address_sig : integer range 0 to 16;
    signal clock_sig   : std_logic  := '1';
    signal clk_fast    : std_logic  := '1';
    signal q_sig       : std_logic_vector (255 DOWNTO 0);

    signal aes_in       : std_logic_vector(127 downto 0);
    signal aes_out      : std_logic_vector(127 downto 0);
    signal aes_expected : std_logic_vector(127 downto 0);

    signal aes_key           : std_logic_vector(255 downto 0);
    signal aes_key_expansion : std_logic_vector(15 * 128 - 1 downto 0);

    signal reset_n             : std_logic := '1';
    signal difference_detected : std_logic := '0';

begin
    reset_n <= KEY(0);
    LEDR(0) <= difference_detected;

    aes_key_expansion <= key_expansion256(aes_key);

    pll_inst : component pll_0002 port map (
        refclk   => CLOCK_50,
        rst      => '0',
        --locked   => locked,
        outclk_0 => clk_fast);
     
    inputmem_inst : inputmem PORT MAP (
        address  => std_logic_vector(to_unsigned(address_sig, 5)),
        clock    => clk_fast,
        q        => q_sig);

    aes_enc0 : entity work.aes256enc
        generic map (
            byte_bits                 => 8,
            block_bytes               => 16,
            block_bits                => 128,
            key_bytes                 => 32,
            key_expansion_bits        => 15 * 128)
        port map (
            key_expansion             => aes_key_expansion,
            plaintext                 => aes_in,
            cyphertext                => aes_out
        );

    process (clk_fast, reset_n) 
        variable state: fsm := init;
        variable counter: Integer range 0 to 15 := 0;
    begin
        if (reset_n = '0') then
            state := init;
            difference_detected <= '0';
            counter := 0;
        elsif(rising_edge(clk_fast)) then
            case state is
                when init =>
                    case counter is
                        when 0 to 4 =>
                            address_sig <= 16;
                        when 5 =>
                            address_sig <= 16;
                            aes_key <= q_sig;
                        when 6 to 14 =>
                            address_sig <= counter;         
                        when 15 =>
                            state := check;
                            address_sig <= counter;
                    end case;
                when check =>
                    if (aes_out /= aes_expected) then 
                        difference_detected <= '1';
                    end if;
                    address_sig <= counter;
            end case;
            
            if (counter < 15) then
                counter := counter + 1;
            else 
                counter := 0;
            end if;

            aes_in <= q_sig(255 downto 128);
            aes_expected <= q_sig(127 downto 0);
        end if;
    end process;

end architecture rtl;

