`ifndef CONFIG_VH
`define CONFIG_VH

// SYSTEM CONFIG

`define IMEM_FILE_TXT   "out_prog/fibc.txt"
`define IMEM_ADDR_WIDTH 6
`define DMEM_ADDR_WIDTH 5
`define XBAR_MMIO_START 30'h0000
`define XBAR_MMIO_LIMIT 30'h03FF
`define XBAR_DMEM_START 30'h0400
`define XBAR_DMEM_LIMIT 30'h0420 //DMEM_ADDR_WIDTH=5 => 32 words of DMEM
`define DISP_7SEG_ADDR  30'h0008 //0x20 if full 32-bit address
`define PC_INIT_VAL     32'h10000

`endif
