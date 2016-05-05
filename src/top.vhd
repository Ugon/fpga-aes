library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
	port (
		iCLK_50                 : in    std_logic;
		iCLK_50_2               : in    std_logic;
		iCLK_50_3               : in    std_logic;
		iCLK_50_4               : in    std_logic;

		GPIO_1                  : inout std_logic_vector(35 downto 0);
 
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

	signal probe     : std_logic_vector(7 downto 0);
	signal probe_gnd : std_logic_vector(1 downto 0);
	
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

	signal block_from_aes : std_logic_vector(127 downto 0);
	signal block_to_aes : std_logic_vector(127 downto 0);

	signal test_block : std_logic_vector(127 downto 0);

	signal dbg_start_error : std_logic;
	signal dbg_stop_error : std_logic;
	signal dbg_cnt_rx : Integer range 0 to 15;
	
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

	communicator0 : entity work.communicator
		port map (
			reset_n                => reset_n,
			clk_16                 => uart_clk,
			rx                     => uart_rx,
			tx                     => uart_tx,
			block_modification_in  => block_from_aes,
			block_modification_out => block_to_aes,
			
			dbg_cnt_rx             => dbg_cnt_rx,
			dbg_start_error        => dbg_start_error,
			dbg_stop_error         => dbg_stop_error
		);

	oLEDR(9) <= dbg_start_error;
	oLEDR(8) <= dbg_stop_error;

	oLEDR(7 downto 0) <= block_from_aes((to_integer(unsigned(iSW(4 downto 0))) + 1) * 8 - 1 downto to_integer(unsigned(iSW(4 downto 0))) * 8);

	probe(0) <= uart_clk;
	probe(1) <= uart_rx;
	probe(2) <= uart_tx;
	probe(3) <= dbg_start_error or dbg_stop_error;
	probe(7 downto 4) <= std_logic_vector(to_unsigned(dbg_cnt_rx, 4));

	--process (uart_rx_available, uard_rx_data) begin
		--if(rising_edge(uart_rx_available)) then
			--oLEDR(7 downto 0) <= uard_rx_data;
		--end if;
	--end process;

	block_from_aes <= block_to_aes;



	reset_n <= iKEY(0);
	hps_led_signal <= hps_key_signal;

	

	probe_gnd <= (others => '0');

	GPIO_1(27) <= probe(0);
	GPIO_1(26) <= probe(1);
	GPIO_1(29) <= probe(2);
	GPIO_1(28) <= probe(3);
	GPIO_1(31) <= probe(4);
	GPIO_1(30) <= probe(5);
	GPIO_1(33) <= probe(6);
	GPIO_1(32) <= probe(7);

	GPIO_1(35) <= probe_gnd(0);
	GPIO_1(34) <= probe_gnd(1);

end top_impl;