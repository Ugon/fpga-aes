library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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

begin

end architecture rtl;
