library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
	port (
      --------- ADC ---------
	ADC_CS_N:                     inout std_logic;
	ADC_DIN:                      out   std_logic;
	ADC_DOUT:                     in    std_logic;
	ADC_SCLK:                     out   std_logic;

      --------- AUD ---------
	AUD_ADCDAT:                   in    std_logic;
	AUD_ADCLRCK:                  inout std_logic;
	AUD_BCLK:                     inout std_logic;
	AUD_DACDAT:                   out   std_logic;
	AUD_DACLRCK:                  inout std_logic;
	AUD_XCK:                      out   std_logic;

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

      --------- FAN ---------
	FAN_CTRL:                     out   std_logic;

      --------- FPGA ---------
	FPGA_I2C_SCLK:                out   std_logic;
	FPGA_I2C_SDAT:                inout std_logic;

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

      --------- HPS ---------
	HPS_CONV_USB_N:               inout std_logic;
	HPS_DDR3_ADDR:                out   std_logic_vector(14 downto 0);
	HPS_DDR3_BA:                  out   std_logic_vector(2 downto 0);
	HPS_DDR3_CAS_N:               out   std_logic;
	HPS_DDR3_CKE:                 out   std_logic;
	HPS_DDR3_CK_N:                out   std_logic;
	HPS_DDR3_CK_P:                out   std_logic;
	HPS_DDR3_CS_N:                out   std_logic;
	HPS_DDR3_DM:                  out   std_logic_vector(3 downto 0);
	HPS_DDR3_DQ:                  inout std_logic_vector(31 downto 0);
	HPS_DDR3_DQS_N:               inout std_logic_vector(3 downto 0);
	HPS_DDR3_DQS_P:               inout std_logic_vector(3 downto 0);
	HPS_DDR3_ODT:                 out   std_logic;
	HPS_DDR3_RAS_N:               out   std_logic;
	HPS_DDR3_RESET_N:             out   std_logic;
	HPS_DDR3_RZQ:                 in    std_logic;
	HPS_DDR3_WE_N:                out   std_logic;
	HPS_ENET_GTX_CLK:             out   std_logic;
	HPS_ENET_INT_N:               inout std_logic;
	HPS_ENET_MDC:                 out   std_logic;
	HPS_ENET_MDIO:                inout std_logic;
	HPS_ENET_RX_CLK:              in    std_logic;
	HPS_ENET_RX_DATA:             in    std_logic_vector(3 downto 0);
	HPS_ENET_RX_DV:               in    std_logic;
	HPS_ENET_TX_DATA:             out   std_logic_vector(3 downto 0);
	HPS_ENET_TX_EN:               out   std_logic;
	HPS_FLASH_DATA:               inout std_logic_vector(3 downto 0);
	HPS_FLASH_DCLK:               out   std_logic;
	HPS_FLASH_NCSO:               out   std_logic;
	HPS_GSENSOR_INT:              inout std_logic;
	HPS_I2C1_SCLK:                inout std_logic;
	HPS_I2C1_SDAT:                inout std_logic;
	HPS_I2C2_SCLK:                inout std_logic;
	HPS_I2C2_SDAT:                inout std_logic;
	HPS_I2C_CONTROL:              inout std_logic;
	HPS_KEY:                      inout std_logic;
	HPS_LED:                      inout std_logic;
	HPS_LTC_GPIO:                 inout std_logic;
	HPS_SD_CLK:                   out   std_logic;
	HPS_SD_CMD:                   inout std_logic;
	HPS_SD_DATA:                  inout std_logic_vector(3 downto 0);
	HPS_SPIM_CLK:                 out   std_logic;
	HPS_SPIM_MISO:                in    std_logic;
	HPS_SPIM_MOSI:                out   std_logic;
	HPS_SPIM_SS:                  inout std_logic;
	HPS_UART_RX:                  inout std_logic; --in
	HPS_UART_TX:                  inout std_logic; --out
	HPS_USB_CLKOUT:               in    std_logic;
	HPS_USB_DATA:                 inout std_logic_vector(7 downto 0);
	HPS_USB_DIR:                  in    std_logic;
	HPS_USB_NXT:                  in    std_logic;
	HPS_USB_STP:                  out   std_logic;

      --------- IRDA ---------
	IRDA_RXD:                     in    std_logic;
	IRDA_TXD:                     out   std_logic;

      --------- KEY ---------
	KEY:                          in    std_logic_vector(3 downto 0);

      --------- LEDR ---------
	LEDR:                         out   std_logic_vector(9 downto 0);

      --------- PS2 ---------
	PS2_CLK:                      inout std_logic;
	PS2_CLK2:                     inout std_logic;
	PS2_DAT:                      inout std_logic;
	PS2_DAT2:                     inout std_logic;

      --------- SW ---------
	SW:                           in    std_logic_vector(9 downto 0);

      --------- TD ---------
	TD_CLK27:                     in    std_logic;
	TD_DATA:                      in    std_logic_vector(7 downto 0);
	TD_HS:                        in    std_logic;
	TD_RESET_N:                   out   std_logic;
	TD_VS:                        in    std_logic;

      --------- VGA ---------
	VGA_B:                        out   std_logic_vector(7 downto 0);
	VGA_BLANK_N:                  out   std_logic;
	VGA_CLK:                      out   std_logic;
	VGA_G:                        out   std_logic_vector(7 downto 0);
	VGA_HS:                       out   std_logic;
	VGA_R:                        out   std_logic_vector(7 downto 0);
	VGA_SYNC_N:                   out   std_logic;
	VGA_VS:                       out   std_logic);
end entity top;

architecture rtl of top is

	signal probe                              : std_logic_vector(7 downto 0);
	signal probe_gnd                          : std_logic_vector(1 downto 0);
	
	signal CONNECTED_TO_hps_0_h2f_loan_io_in  : std_logic_vector(66 downto 0);
	signal CONNECTED_TO_hps_0_h2f_loan_io_out : std_logic_vector(66 downto 0);
	signal CONNECTED_TO_hps_0_h2f_loan_io_oe  : std_logic_vector(66 downto 0);

	signal reset_n                            : std_logic;

	signal uart_clk                           : std_logic;
	signal uart_rx_async                      : std_logic;
	signal uart_rx                            : std_logic;
	signal uard_rx_data                       : std_logic_vector(7 downto 0);
	signal uart_rx_available                  : std_logic;
	signal uart_tx                            : std_logic;
	signal uard_tx_data                       : std_logic_vector(7 downto 0);
	signal uart_tx_available                  : std_logic;
	
	signal hps_key_signal                     : std_logic;
	signal hps_led_signal                     : std_logic;

	signal block_from_aes                     : std_logic_vector(127 downto 0);
	signal block_to_aes                       : std_logic_vector(127 downto 0);

	signal test_block                         : std_logic_vector(127 downto 0);

	signal dbg_start_error                    : std_logic;
	signal dbg_stop_error                     : std_logic;
	signal dbg_cnt_rx                         : Integer range 0 to 15;
	signal dbg_rx0_start_listening            : std_logic;
	signal dbg_rx0_finished_listening     : std_logic;
	signal dbg_tx0_start_transmitting         : std_logic;
	signal dbg_tx0_finished_transmitting      : std_logic;
	signal dbg_state                          : Integer range 0 to 15;
	signal dbg_rx_state                       : Integer range 0 to 3;

	component soc_system is
		port (
			clk_clk                                : in    std_logic                     := 'X';
			reset_reset_n                          : in    std_logic                     := 'X';
	
			hps_0_f2h_cold_reset_req_reset_n       : in    std_logic                     := 'X';
			hps_0_f2h_debug_reset_req_reset_n      : in    std_logic                     := 'X';
			hps_0_f2h_stm_hw_events_stm_hwevents   : in    std_logic_vector(27 downto 0) := (others => 'X');
			hps_0_f2h_warm_reset_req_reset_n       : in    std_logic                     := 'X';
				
			--HPS DDR3
			memory_mem_a                           : out   std_logic_vector(14 downto 0);
			memory_mem_ba                          : out   std_logic_vector(2 downto 0);
			memory_mem_ck                          : out   std_logic;
			memory_mem_ck_n                        : out   std_logic;
			memory_mem_cke                         : out   std_logic;
			memory_mem_cs_n                        : out   std_logic;
			memory_mem_ras_n                       : out   std_logic;
			memory_mem_cas_n                       : out   std_logic;
			memory_mem_we_n                        : out   std_logic;
			memory_mem_reset_n                     : out   std_logic;
			memory_mem_dq                          : inout std_logic_vector(31 downto 0) := (others => 'X');
			memory_mem_dqs                         : inout std_logic_vector(3 downto 0)  := (others => 'X');
			memory_mem_dqs_n                       : inout std_logic_vector(3 downto 0)  := (others => 'X');
			memory_mem_odt                         : out   std_logic;
			memory_mem_dm                          : out   std_logic_vector(3 downto 0);
			memory_oct_rzqin                       : in    std_logic                     := 'X';
	
			--HPS ethernet		
			hps_0_hps_io_hps_io_emac1_inst_TX_CLK  : out   std_logic;
			hps_0_hps_io_hps_io_emac1_inst_TXD0    : out   std_logic;
			hps_0_hps_io_hps_io_emac1_inst_TXD1    : out   std_logic;
			hps_0_hps_io_hps_io_emac1_inst_TXD2    : out   std_logic;
			hps_0_hps_io_hps_io_emac1_inst_TXD3    : out   std_logic;
			hps_0_hps_io_hps_io_emac1_inst_RXD0    : in    std_logic                     := 'X';
			hps_0_hps_io_hps_io_emac1_inst_MDIO    : inout std_logic                     := 'X';
			hps_0_hps_io_hps_io_emac1_inst_MDC     : out   std_logic;
			hps_0_hps_io_hps_io_emac1_inst_RX_CTL  : in    std_logic                     := 'X';
			hps_0_hps_io_hps_io_emac1_inst_TX_CTL  : out   std_logic;
			hps_0_hps_io_hps_io_emac1_inst_RX_CLK  : in    std_logic                     := 'X';
			hps_0_hps_io_hps_io_emac1_inst_RXD1    : in    std_logic                     := 'X';
			hps_0_hps_io_hps_io_emac1_inst_RXD2    : in    std_logic                     := 'X';
			hps_0_hps_io_hps_io_emac1_inst_RXD3    : in    std_logic                     := 'X';
			
			--HPS QSPI
			hps_0_hps_io_hps_io_qspi_inst_IO0      : inout std_logic                     := 'X';
			hps_0_hps_io_hps_io_qspi_inst_IO1      : inout std_logic                     := 'X';
			hps_0_hps_io_hps_io_qspi_inst_IO2      : inout std_logic                     := 'X';
			hps_0_hps_io_hps_io_qspi_inst_IO3      : inout std_logic                     := 'X';
			hps_0_hps_io_hps_io_qspi_inst_SS0      : out   std_logic;
			hps_0_hps_io_hps_io_qspi_inst_CLK      : out   std_logic;
			
			--HPS SD card
			hps_0_hps_io_hps_io_sdio_inst_CMD      : inout std_logic                     := 'X';
			hps_0_hps_io_hps_io_sdio_inst_D0       : inout std_logic                     := 'X';
			hps_0_hps_io_hps_io_sdio_inst_D1       : inout std_logic                     := 'X';
			hps_0_hps_io_hps_io_sdio_inst_CLK      : out   std_logic;
			hps_0_hps_io_hps_io_sdio_inst_D2       : inout std_logic                     := 'X';
			hps_0_hps_io_hps_io_sdio_inst_D3       : inout std_logic                     := 'X';
			
			--HPS USB
			hps_0_hps_io_hps_io_usb1_inst_D0       : inout std_logic                     := 'X';
			hps_0_hps_io_hps_io_usb1_inst_D1       : inout std_logic                     := 'X';
			hps_0_hps_io_hps_io_usb1_inst_D2       : inout std_logic                     := 'X';
			hps_0_hps_io_hps_io_usb1_inst_D3       : inout std_logic                     := 'X';
			hps_0_hps_io_hps_io_usb1_inst_D4       : inout std_logic                     := 'X';
			hps_0_hps_io_hps_io_usb1_inst_D5       : inout std_logic                     := 'X';
			hps_0_hps_io_hps_io_usb1_inst_D6       : inout std_logic                     := 'X';
			hps_0_hps_io_hps_io_usb1_inst_D7       : inout std_logic                     := 'X';
			hps_0_hps_io_hps_io_usb1_inst_CLK      : in    std_logic                     := 'X';
			hps_0_hps_io_hps_io_usb1_inst_STP      : out   std_logic;
			hps_0_hps_io_hps_io_usb1_inst_DIR      : in    std_logic                     := 'X';
			hps_0_hps_io_hps_io_usb1_inst_NXT      : in    std_logic                     := 'X';

			--HPS SPI
			hps_0_hps_io_hps_io_spim1_inst_CLK     : out   std_logic;
			hps_0_hps_io_hps_io_spim1_inst_MOSI    : out   std_logic;
			hps_0_hps_io_hps_io_spim1_inst_MISO    : in    std_logic                     := 'X';
			hps_0_hps_io_hps_io_spim1_inst_SS0     : out   std_logic;
			
			--HPS I2C
			hps_0_hps_io_hps_io_i2c0_inst_SDA      : inout std_logic                     := 'X';
			hps_0_hps_io_hps_io_i2c0_inst_SCL      : inout std_logic                     := 'X';
			hps_0_hps_io_hps_io_i2c1_inst_SDA      : inout std_logic                     := 'X';
			hps_0_hps_io_hps_io_i2c1_inst_SCL      : inout std_logic                     := 'X';
			
			--HPS GPIO
			hps_0_hps_io_hps_io_gpio_inst_GPIO09   : inout std_logic                     := 'X';
			hps_0_hps_io_hps_io_gpio_inst_GPIO35   : inout std_logic                     := 'X';
			hps_0_hps_io_hps_io_gpio_inst_GPIO40   : inout std_logic                     := 'X';
			hps_0_hps_io_hps_io_gpio_inst_GPIO48   : inout std_logic                     := 'X';

			--HPS LOANIO
			hps_0_h2f_loan_io_in                   : out   std_logic_vector(66 downto 0);
			hps_0_h2f_loan_io_out                  : in    std_logic_vector(66 downto 0) := (others => 'X');
			hps_0_h2f_loan_io_oe                   : in    std_logic_vector(66 downto 0) := (others => 'X');
			hps_0_h2f_reset_reset_n                : out   std_logic;
			hps_0_hps_io_hps_io_gpio_inst_LOANIO49 : inout std_logic                     := 'X';
			hps_0_hps_io_hps_io_gpio_inst_LOANIO50 : inout std_logic                     := 'X';
			hps_0_hps_io_hps_io_gpio_inst_LOANIO53 : inout std_logic                     := 'X';
			hps_0_hps_io_hps_io_gpio_inst_LOANIO54 : inout std_logic                     := 'X';
		
			--HPS UART
			hps_0_uart0_cts                        : in    std_logic                     := 'X';
			hps_0_uart0_dsr                        : in    std_logic                     := 'X';
			hps_0_uart0_dcd                        : in    std_logic                     := 'X';
			hps_0_uart0_ri                         : in    std_logic                     := 'X';
			hps_0_uart0_dtr                        : out   std_logic;
			hps_0_uart0_rts                        : out   std_logic;
			hps_0_uart0_out1_n                     : out   std_logic;
			hps_0_uart0_out2_n                     : out   std_logic;
			hps_0_uart0_rxd                        : in    std_logic                     := 'X';
			hps_0_uart0_txd                        : out   std_logic
		);
	end component soc_system;

begin

	CONNECTED_TO_hps_0_h2f_loan_io_oe(49) <= '0';
	CONNECTED_TO_hps_0_h2f_loan_io_oe(50) <= '1';
	CONNECTED_TO_hps_0_h2f_loan_io_oe(53) <= '1';
	CONNECTED_TO_hps_0_h2f_loan_io_oe(54) <= '0';

	CONNECTED_TO_hps_0_h2f_loan_io_out(50) <= uart_tx;
	uart_rx_async <= CONNECTED_TO_hps_0_h2f_loan_io_in(49);
	CONNECTED_TO_hps_0_h2f_loan_io_out(53) <= hps_led_signal;
	hps_key_signal <= CONNECTED_TO_hps_0_h2f_loan_io_in(54);
	
	u0 : component soc_system
		port map (
			clk_clk                                => CLOCK_50,
			reset_reset_n                          => '1',

			hps_0_f2h_cold_reset_req_reset_n       => '1',
			hps_0_f2h_debug_reset_req_reset_n      => '1',
			hps_0_f2h_stm_hw_events_stm_hwevents   => (others => '1'),
			--hps_0_f2h_warm_reset_req_reset_n        => CONNECTED_TO_hps_0_f2h_warm_reset_req_reset_n,

			--HPS DDR3
			memory_mem_a                           => HPS_DDR3_ADDR,
			memory_mem_ba                          => HPS_DDR3_BA,
			memory_mem_ck                          => HPS_DDR3_CK_P,
			memory_mem_ck_n                        => HPS_DDR3_CK_N,
			memory_mem_cke                         => HPS_DDR3_CKE,
			memory_mem_cs_n                        => HPS_DDR3_CS_N,
			memory_mem_ras_n                       => HPS_DDR3_RAS_N,
			memory_mem_cas_n                       => HPS_DDR3_CAS_N,
			memory_mem_we_n                        => HPS_DDR3_WE_N,
			memory_mem_reset_n                     => HPS_DDR3_RESET_N,
			memory_mem_dq                          => HPS_DDR3_DQ,
			memory_mem_dqs                         => HPS_DDR3_DQS_P,
			memory_mem_dqs_n                       => HPS_DDR3_DQS_N,
			memory_mem_odt                         => HPS_DDR3_ODT,
			memory_mem_dm                          => HPS_DDR3_DM,
			memory_oct_rzqin                       => HPS_DDR3_RZQ,

			--HPS ethernet		
			hps_0_hps_io_hps_io_emac1_inst_TX_CLK  => HPS_ENET_GTX_CLK,
			hps_0_hps_io_hps_io_emac1_inst_TXD0    => HPS_ENET_TX_DATA(0),
			hps_0_hps_io_hps_io_emac1_inst_TXD1    => HPS_ENET_TX_DATA(1),
			hps_0_hps_io_hps_io_emac1_inst_TXD2    => HPS_ENET_TX_DATA(2),
			hps_0_hps_io_hps_io_emac1_inst_TXD3    => HPS_ENET_TX_DATA(3),
			hps_0_hps_io_hps_io_emac1_inst_RXD0    => HPS_ENET_RX_DATA(0),
			hps_0_hps_io_hps_io_emac1_inst_MDIO    => HPS_ENET_MDIO,
			hps_0_hps_io_hps_io_emac1_inst_MDC     => HPS_ENET_MDC,
			hps_0_hps_io_hps_io_emac1_inst_RX_CTL  => HPS_ENET_RX_DV,
			hps_0_hps_io_hps_io_emac1_inst_TX_CTL  => HPS_ENET_TX_EN,
			hps_0_hps_io_hps_io_emac1_inst_RX_CLK  => HPS_ENET_RX_CLK,
			hps_0_hps_io_hps_io_emac1_inst_RXD1    => HPS_ENET_RX_DATA(1),
			hps_0_hps_io_hps_io_emac1_inst_RXD2    => HPS_ENET_RX_DATA(2),
			hps_0_hps_io_hps_io_emac1_inst_RXD3    => HPS_ENET_RX_DATA(3),
			
			--HPS QSPI
			hps_0_hps_io_hps_io_qspi_inst_IO0      => HPS_FLASH_DATA(0),
			hps_0_hps_io_hps_io_qspi_inst_IO1      => HPS_FLASH_DATA(1),
			hps_0_hps_io_hps_io_qspi_inst_IO2      => HPS_FLASH_DATA(2),
			hps_0_hps_io_hps_io_qspi_inst_IO3      => HPS_FLASH_DATA(3),
			hps_0_hps_io_hps_io_qspi_inst_SS0      => HPS_FLASH_NCSO,
			hps_0_hps_io_hps_io_qspi_inst_CLK      => HPS_FLASH_DCLK,
			
			--HPS SD card
			hps_0_hps_io_hps_io_sdio_inst_CMD      => HPS_SD_CMD,
			hps_0_hps_io_hps_io_sdio_inst_D0       => HPS_SD_DATA(0),
			hps_0_hps_io_hps_io_sdio_inst_D1       => HPS_SD_DATA(1),
			hps_0_hps_io_hps_io_sdio_inst_CLK      => HPS_SD_CLK,
			hps_0_hps_io_hps_io_sdio_inst_D2       => HPS_SD_DATA(2),
			hps_0_hps_io_hps_io_sdio_inst_D3       => HPS_SD_DATA(3),
			
			--HPS USB
			hps_0_hps_io_hps_io_usb1_inst_D0       => HPS_USB_DATA(0),
			hps_0_hps_io_hps_io_usb1_inst_D1       => HPS_USB_DATA(1),
			hps_0_hps_io_hps_io_usb1_inst_D2       => HPS_USB_DATA(2),
			hps_0_hps_io_hps_io_usb1_inst_D3       => HPS_USB_DATA(3),
			hps_0_hps_io_hps_io_usb1_inst_D4       => HPS_USB_DATA(4),
			hps_0_hps_io_hps_io_usb1_inst_D5       => HPS_USB_DATA(5),
			hps_0_hps_io_hps_io_usb1_inst_D6       => HPS_USB_DATA(6),
			hps_0_hps_io_hps_io_usb1_inst_D7       => HPS_USB_DATA(7),
			hps_0_hps_io_hps_io_usb1_inst_CLK      => HPS_USB_CLKOUT,
			hps_0_hps_io_hps_io_usb1_inst_STP      => HPS_USB_STP,
			hps_0_hps_io_hps_io_usb1_inst_DIR      => HPS_USB_DIR,
			hps_0_hps_io_hps_io_usb1_inst_NXT      => HPS_USB_NXT,
			
			--HPS SPI
			hps_0_hps_io_hps_io_spim1_inst_CLK     => HPS_SPIM_CLK,
			hps_0_hps_io_hps_io_spim1_inst_MOSI    => HPS_SPIM_MOSI,
			hps_0_hps_io_hps_io_spim1_inst_MISO    => HPS_SPIM_MISO,
			hps_0_hps_io_hps_io_spim1_inst_SS0     => HPS_SPIM_SS,

			--HPS I2C
			hps_0_hps_io_hps_io_i2c0_inst_SDA      => HPS_I2C1_SDAT,
			hps_0_hps_io_hps_io_i2c0_inst_SCL      => HPS_I2C1_SCLK,
			hps_0_hps_io_hps_io_i2c1_inst_SDA      => HPS_I2C2_SDAT,
			hps_0_hps_io_hps_io_i2c1_inst_SCL      => HPS_I2C2_SCLK,

			--HPS GPIO
			hps_0_hps_io_hps_io_gpio_inst_GPIO09   => HPS_CONV_USB_N,
			hps_0_hps_io_hps_io_gpio_inst_GPIO35   => HPS_ENET_INT_N,
			hps_0_hps_io_hps_io_gpio_inst_GPIO40   => HPS_LTC_GPIO,
			hps_0_hps_io_hps_io_gpio_inst_GPIO48   => HPS_I2C_CONTROL,

			--HPS LOANIO
			hps_0_h2f_loan_io_in                   => CONNECTED_TO_hps_0_h2f_loan_io_in,
			hps_0_h2f_loan_io_out                  => CONNECTED_TO_hps_0_h2f_loan_io_out,
			hps_0_h2f_loan_io_oe                   => CONNECTED_TO_hps_0_h2f_loan_io_oe,
			--hps_0_h2f_reset_reset_n                 => CONNECTED_TO_hps_0_h2f_reset_reset_n,
			hps_0_hps_io_hps_io_gpio_inst_LOANIO49 => HPS_UART_RX,
			hps_0_hps_io_hps_io_gpio_inst_LOANIO50 => HPS_UART_TX,
			hps_0_hps_io_hps_io_gpio_inst_LOANIO53 => HPS_LED,
			hps_0_hps_io_hps_io_gpio_inst_LOANIO54 => HPS_KEY,

			--HPS UART
			hps_0_uart0_cts                        => '1',
			hps_0_uart0_dsr                        => '1',
			hps_0_uart0_dcd                        => '1',
			hps_0_uart0_ri                         => '1',
			--hps_0_uart0_dtr                        => CONNECTED_TO_hps_0_uart0_dtr
			--hps_0_uart0_rts                        => CONNECTED_TO_hps_0_uart0_rts
			--hps_0_uart0_out1_n                     => CONNECTED_TO_hps_0_uart0_out1_n
			--hps_0_uart0_out2_n                     => CONNECTED_TO_hps_0_uart0_out2_n
			hps_0_uart0_rxd                        => '1'
			--hps_0_uart0_txd                        => 'CONNECTED_TO_hps_0_uart0_txd
		);


	sync_2ff0 : entity work.sync_2ff
		generic map (
			idle => '1')
		port map (
		    async_in                               => uart_rx_async,
		    clk                                    => uart_clk,
		    reset_n                                => reset_n,
		    sync_out                               => uart_rx
		);

	uart_prescaler0 : entity work.uart_prescaler
		port map(
			clk_in                                 => CLOCK_50,
			clk_out                                => uart_clk
		);

	communicator0 : entity work.communicator
		port map (
			reset_n                                => reset_n,
			clk_16                                 => uart_clk,
			rx                                     => uart_rx,
			tx                                     => uart_tx,
			
			dbg_cnt_rx                             => dbg_cnt_rx,
			dbg_start_error                        => dbg_start_error,
			dbg_stop_error                         => dbg_stop_error,
			dbg_rx0_start_listening             => dbg_rx0_start_listening,
			dbg_tx0_start_transmitting          => dbg_tx0_start_transmitting,
			dbg_tx0_finished_transmitting      => dbg_tx0_finished_transmitting,
			dbg_rx0_finished_listening         => dbg_rx0_finished_listening,
			dbg_state                              => dbg_state,
			dbg_rx_state                           => dbg_rx_state
			--dbg_deserializer0_finished_listening => probe(6),
			--dbg_deserializer0_start_listening => probe(7)
		);

	LEDR(9) <= dbg_start_error or dbg_stop_error;
	--LEDR(8) <= dbg_funky_state_reached;

	--LEDR(7 downto 0) <= block_from_aes((to_integer(unsigned(iSW(4 downto 0))) + 1) * 8 - 1 downto to_integer(unsigned(iSW(4 downto 0))) * 8);
	LEDR(3 downto 0) <= std_logic_vector(to_unsigned(dbg_state, 4));

	--probe(0) <= uart_clk;
	probe(0) <= uart_rx;
	probe(1) <= uart_tx;
	--probe(1) <= uart_tx;
	--probe(3 downto 2) <= std_logic_vector(to_unsigned(dbg_rx_state, 2));
	probe(2) <= dbg_tx0_finished_transmitting;
	probe(3) <= dbg_tx0_start_transmitting;
	--probe(4) <= dbg_tx0_start_transmitting;
	--probe(5) <= dbg_tx0_finished_transmitting;
	--probe(3) <= dbg_start_error or dbg_stop_error;
	probe(7 downto 4) <= std_logic_vector(to_unsigned(dbg_state, 4));
	--probe(4) <= dbg_rx0_finished_listening;
	--probe(5) <= dbg_rx0_start_listening;
	--probe(7) <= std_logic_vector(to_unsigned(dbg_state, 4));
	--probe(7) <= std_logic_vector(to_unsigned(dbg_state, 4));
	--probe(7 downto 6) <= std_logic_vector(to_unsigned(dbg_state, 2));

	--process (uart_rx_available, uard_rx_data) begin
		--if(rising_edge(uart_rx_available)) then
			--LEDR(7 downto 0) <= uard_rx_data;
		--end if;
	--end process;

	block_from_aes <= block_to_aes;



	reset_n <= KEY(0);
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

end architecture rtl;
