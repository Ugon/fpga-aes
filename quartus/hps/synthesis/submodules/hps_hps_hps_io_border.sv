// (C) 2001-2015 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera MegaCore Function License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


module hps_hps_hps_io_border(
// gpio_loanio
  output wire [29 - 1 : 0 ] gpio_loanio_loanio0_i
 ,input wire [29 - 1 : 0 ] gpio_loanio_loanio0_oe
 ,input wire [29 - 1 : 0 ] gpio_loanio_loanio0_o
 ,output wire [29 - 1 : 0 ] gpio_loanio_loanio1_i
 ,input wire [29 - 1 : 0 ] gpio_loanio_loanio1_oe
 ,input wire [29 - 1 : 0 ] gpio_loanio_loanio1_o
 ,output wire [9 - 1 : 0 ] gpio_loanio_loanio2_i
 ,input wire [9 - 1 : 0 ] gpio_loanio_loanio2_oe
 ,input wire [9 - 1 : 0 ] gpio_loanio_loanio2_o
// memory
 ,output wire [15 - 1 : 0 ] mem_a
 ,output wire [3 - 1 : 0 ] mem_ba
 ,output wire [1 - 1 : 0 ] mem_ck
 ,output wire [1 - 1 : 0 ] mem_ck_n
 ,output wire [1 - 1 : 0 ] mem_cke
 ,output wire [1 - 1 : 0 ] mem_cs_n
 ,output wire [1 - 1 : 0 ] mem_ras_n
 ,output wire [1 - 1 : 0 ] mem_cas_n
 ,output wire [1 - 1 : 0 ] mem_we_n
 ,output wire [1 - 1 : 0 ] mem_reset_n
 ,inout wire [40 - 1 : 0 ] mem_dq
 ,inout wire [5 - 1 : 0 ] mem_dqs
 ,inout wire [5 - 1 : 0 ] mem_dqs_n
 ,output wire [1 - 1 : 0 ] mem_odt
 ,output wire [5 - 1 : 0 ] mem_dm
 ,input wire [1 - 1 : 0 ] oct_rzqin
// hps_io
 ,inout wire [1 - 1 : 0 ] hps_io_gpio_inst_LOANIO49
 ,inout wire [1 - 1 : 0 ] hps_io_gpio_inst_LOANIO50
 ,inout wire [1 - 1 : 0 ] hps_io_gpio_inst_LOANIO53
 ,inout wire [1 - 1 : 0 ] hps_io_gpio_inst_LOANIO54
);

assign hps_io_gpio_inst_LOANIO49 = intermediate[1] ? intermediate[0] : 'z;
assign hps_io_gpio_inst_LOANIO50 = intermediate[3] ? intermediate[2] : 'z;
assign hps_io_gpio_inst_LOANIO53 = intermediate[5] ? intermediate[4] : 'z;
assign hps_io_gpio_inst_LOANIO54 = intermediate[7] ? intermediate[6] : 'z;

wire [8 - 1 : 0] intermediate;

wire [66 - 1 : 0] floating;

cyclonev_hps_peripheral_gpio gpio_inst(
 .GPIO1_PORTA_I({
    hps_io_gpio_inst_LOANIO54[0:0] // 25:25
   ,hps_io_gpio_inst_LOANIO53[0:0] // 24:24
   ,floating[1:0] // 23:22
   ,hps_io_gpio_inst_LOANIO50[0:0] // 21:21
   ,hps_io_gpio_inst_LOANIO49[0:0] // 20:20
   ,floating[21:2] // 19:0
  })
,.LOANIO1_O({
    gpio_loanio_loanio1_o[28:0] // 28:0
  })
,.LOANIO0_OE({
    gpio_loanio_loanio0_oe[28:0] // 28:0
  })
,.LOANIO0_I({
    gpio_loanio_loanio0_i[28:0] // 28:0
  })
,.GPIO1_PORTA_OE({
    intermediate[7:7] // 25:25
   ,intermediate[5:5] // 24:24
   ,floating[23:22] // 23:22
   ,intermediate[3:3] // 21:21
   ,intermediate[1:1] // 20:20
   ,floating[43:24] // 19:0
  })
,.LOANIO2_O({
    gpio_loanio_loanio2_o[8:0] // 8:0
  })
,.LOANIO1_I({
    gpio_loanio_loanio1_i[28:0] // 28:0
  })
,.LOANIO2_I({
    gpio_loanio_loanio2_i[8:0] // 8:0
  })
,.LOANIO2_OE({
    gpio_loanio_loanio2_oe[8:0] // 8:0
  })
,.GPIO1_PORTA_O({
    intermediate[6:6] // 25:25
   ,intermediate[4:4] // 24:24
   ,floating[45:44] // 23:22
   ,intermediate[2:2] // 21:21
   ,intermediate[0:0] // 20:20
   ,floating[65:46] // 19:0
  })
,.LOANIO1_OE({
    gpio_loanio_loanio1_oe[28:0] // 28:0
  })
,.LOANIO0_O({
    gpio_loanio_loanio0_o[28:0] // 28:0
  })
);


hps_sdram hps_sdram_inst(
 .mem_dq({
    mem_dq[39:0] // 39:0
  })
,.mem_odt({
    mem_odt[0:0] // 0:0
  })
,.mem_ras_n({
    mem_ras_n[0:0] // 0:0
  })
,.mem_dqs_n({
    mem_dqs_n[4:0] // 4:0
  })
,.mem_dqs({
    mem_dqs[4:0] // 4:0
  })
,.mem_dm({
    mem_dm[4:0] // 4:0
  })
,.mem_we_n({
    mem_we_n[0:0] // 0:0
  })
,.mem_cas_n({
    mem_cas_n[0:0] // 0:0
  })
,.mem_ba({
    mem_ba[2:0] // 2:0
  })
,.mem_a({
    mem_a[14:0] // 14:0
  })
,.mem_cs_n({
    mem_cs_n[0:0] // 0:0
  })
,.mem_ck({
    mem_ck[0:0] // 0:0
  })
,.mem_cke({
    mem_cke[0:0] // 0:0
  })
,.oct_rzqin({
    oct_rzqin[0:0] // 0:0
  })
,.mem_reset_n({
    mem_reset_n[0:0] // 0:0
  })
,.mem_ck_n({
    mem_ck_n[0:0] // 0:0
  })
);

endmodule

