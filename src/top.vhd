library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
	port (
		iCLK_50                 : in    std_logic;
		iCLK_50_2               : in    std_logic;
		iCLK_50_3               : in    std_logic;
		iCLK_50_4               : in    std_logic;
 
		HPS_DDR3_ADDR           : out   std_logic_vector(14 downto 0);
		HPS_DDR3_BA             : out   std_logic_vector(2 downto 0);
		HPS_DDR3_CK_P           : out   std_logic;
		HPS_DDR3_CK_N           : out   std_logic;
		HPS_DDR3_CKE            : out   std_logic;
		HPS_DDR3_CS_N           : out   std_logic;
		HPS_DDR3_RAS_N          : out   std_logic;
		HPS_DDR3_CAS_N          : out   std_logic;
		HPS_DDR3_WE_N           : out   std_logic;
		HPS_DDR3_RESET_N        : out   std_logic;
		HPS_DDR3_DQ             : inout std_logic_vector(39 downto 0);
		HPS_DDR3_DQS_P          : inout std_logic_vector(4 downto 0);
		HPS_DDR3_DQS_N          : inout std_logic_vector(4 downto 0);
		HPS_DDR3_ODT            : out   std_logic;
		HPS_DDR3_DM             : out   std_logic_vector(4 downto 0);
		HPS_DDR3_RZQ            : in    std_logic;
		
		HPS_UART_RX             : inout std_logic;
		HPS_UART_TX             : inout std_logic;
		
		HPS_LED                 : inout std_logic;
		HPS_KEY                 : inout std_logic;

		oLEDR                   : out   std_logic_vector(9 downto 0);
		iKEY                    : in    std_logic_vector(3 downto 0);
		iSW                     : in    std_logic_vector(9 downto 0)
	);
end top;

architecture top_impl of top is
	
	component hps is
		port (
			h2f_loan_io_in                   : out   std_logic_vector(66 downto 0);
			h2f_loan_io_out                  : in    std_logic_vector(66 downto 0);
			h2f_loan_io_oe                   : in    std_logic_vector(66 downto 0);
			hps_io_hps_io_gpio_inst_LOANIO49 : inout std_logic;
			hps_io_hps_io_gpio_inst_LOANIO50 : inout std_logic;
			hps_io_hps_io_gpio_inst_LOANIO53 : inout std_logic;
			hps_io_hps_io_gpio_inst_LOANIO54 : inout std_logic;
			memory_mem_a                     : out   std_logic_vector(14 downto 0);
			memory_mem_ba                    : out   std_logic_vector(2 downto 0);
			memory_mem_ck                    : out   std_logic;
			memory_mem_ck_n                  : out   std_logic;
			memory_mem_cke                   : out   std_logic;
			memory_mem_cs_n                  : out   std_logic;
			memory_mem_ras_n                 : out   std_logic;
			memory_mem_cas_n                 : out   std_logic;
			memory_mem_we_n                  : out   std_logic;
			memory_mem_reset_n               : out   std_logic;
			memory_mem_dq                    : inout std_logic_vector(39 downto 0); 
			memory_mem_dqs                   : inout std_logic_vector(4 downto 0);
			memory_mem_dqs_n                 : inout std_logic_vector(4 downto 0);
			memory_mem_odt                   : out   std_logic;
			memory_mem_dm                    : out   std_logic_vector(4 downto 0);
			memory_oct_rzqin                 : in    std_logic
		);
	end component hps;
	
	signal CONNECTED_TO_h2f_loan_io_in  : std_logic_vector(66 downto 0);
	signal CONNECTED_TO_h2f_loan_io_out : std_logic_vector(66 downto 0);
	signal CONNECTED_TO_h2f_loan_io_oe  : std_logic_vector(66 downto 0);

	signal reset_n  : std_logic;

	signal uart_clk          : std_logic;
	signal uart_rx           : std_logic;
	signal uard_rx_data      : std_logic_vector(7 downto 0);
	signal uart_rx_available : std_logic;
	signal uart_tx           : std_logic;
	signal uard_tx_data      : std_logic_vector(7 downto 0);
	signal uart_tx_available : std_logic;
	
	signal hps_key_signal : std_logic;
	signal hps_led_signal : std_logic;
	
begin
	
	CONNECTED_TO_h2f_loan_io_oe(49) <= '0';
	CONNECTED_TO_h2f_loan_io_oe(50) <= '1';
	CONNECTED_TO_h2f_loan_io_oe(53) <= '1';
	CONNECTED_TO_h2f_loan_io_oe(54) <= '0';

	CONNECTED_TO_h2f_loan_io_out(50) <= uart_tx;
	uart_rx <= CONNECTED_TO_h2f_loan_io_in(49);
	CONNECTED_TO_h2f_loan_io_out(53) <= hps_led_signal;
	hps_key_signal <= CONNECTED_TO_h2f_loan_io_in(54);

	hps0 : component hps
		port map (
			h2f_loan_io_in                   => CONNECTED_TO_h2f_loan_io_in,
			h2f_loan_io_out                  => CONNECTED_TO_h2f_loan_io_out,
			h2f_loan_io_oe                   => CONNECTED_TO_h2f_loan_io_oe,
			hps_io_hps_io_gpio_inst_LOANIO49 => HPS_UART_RX,
			hps_io_hps_io_gpio_inst_LOANIO50 => HPS_UART_TX,
			hps_io_hps_io_gpio_inst_LOANIO53 => HPS_LED,
			hps_io_hps_io_gpio_inst_LOANIO54 => HPS_KEY,
			memory_mem_a                     => HPS_DDR3_ADDR,
			memory_mem_ba                    => HPS_DDR3_BA,
			memory_mem_ck                    => HPS_DDR3_CK_P,
			memory_mem_ck_n                  => HPS_DDR3_CK_N,
			memory_mem_cke                   => HPS_DDR3_CKE,
			memory_mem_cs_n                  => HPS_DDR3_CS_N,
			memory_mem_ras_n                 => HPS_DDR3_RAS_N,
			memory_mem_cas_n                 => HPS_DDR3_CAS_N,
			memory_mem_we_n                  => HPS_DDR3_WE_N,
			memory_mem_reset_n               => HPS_DDR3_RESET_N,
			memory_mem_dq                    => HPS_DDR3_DQ,
			memory_mem_dqs                   => HPS_DDR3_DQS_P,
			memory_mem_dqs_n                 => HPS_DDR3_DQS_N,
			memory_mem_odt                   => HPS_DDR3_ODT,
			memory_mem_dm                    => HPS_DDR3_DM,
			memory_oct_rzqin                 => HPS_DDR3_RZQ
		);

	uart_prescaler0 : entity work.uart_prescaler
		port map(
			clk_in  => iCLK_50,
			clk_out => uart_clk
		);

	uart_rx0 : entity work.uart_rx
		port map (
			reset_n     => reset_n,
			clk         => uart_clk,
			rx          => uart_rx,
			data        => uard_rx_data,
			available   => uart_rx_available
		);

	uart_tx0 : entity work.uart_tx
		port map(
			reset_n     => reset_n,
			clk         => uart_clk,
			data        => iSW(7 downto 0),
			available   => not iKEY(3),
			tx          => uart_tx
		);

	process (uart_rx_available, uard_rx_data) begin
		if(rising_edge(uart_rx_available)) then
			oLEDR(7 downto 0) <= uard_rx_data;
		end if;
	end process;

	reset_n <= iKEY(0);
	hps_led_signal <= hps_key_signal;

end top_impl;