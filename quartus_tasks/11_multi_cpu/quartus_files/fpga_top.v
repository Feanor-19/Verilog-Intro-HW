module fpga_top(
    input  wire CLK,
    input  wire RSTN,

    output wire STCP,
    output wire SHCP,
    output wire DS,
    output wire OE
);

wire clk_pll;
wire clk_core0, clk_core1;
reg rst_n, RSTN_d;

wire [31:0] afifo_data;
wire        afifo_rdclk;
wire        afifo_rdreq;
wire        afifo_wrclk;
wire        afifo_wrreq;
wire [31:0] afifo_q;
wire        afifo_rdempty;
wire        afifo_wrfull;

always @(posedge clk_pll) begin
    rst_n  <= RSTN_d;
    RSTN_d <= RSTN;
end

pll pll(
    .inclk0	 (CLK),
    .c0      (clk_pll)
);

assign clk_core0 = CLK;
assign clk_core1 = clk_pll;

assign afifo_wrclk = clk_core0;
assign afifo_rdclk = clk_core1;

afifo afifo_inst (
    .data    (afifo_data),
    .rdclk   (afifo_rdclk),
    .rdreq   (afifo_rdreq),
    .wrclk   (afifo_wrclk),
    .wrreq   (afifo_wrreq),
    .q       (afifo_q),
    .rdempty (afifo_rdempty),
    .wrfull  (afifo_wrfull)
);

system_top_core0 system_top_core0_inst (
    .clk              (clk_core0),
    .rst_n            (rst_n),

    .o_afifo_wrreq    (afifo_wrreq),
    .o_afifo_data     (afifo_data),
    .i_afifo_wrfull   (afifo_wrfull)
);

system_top_core1 #(
    .DISP_7SEG_CNT_WIDTH (14)
) system_top_core1_inst (
    .clk                 (clk_core1),
    .rst_n               (rst_n),
    
    .o_afifo_rdreq       (afifo_rdreq),
    .i_afifo_q           (afifo_q),
    .i_afifo_rdempty     (afifo_rdempty),
    
    .o_7seg_disp_stcp    (STCP),
    .o_7seg_disp_shcp    (SHCP),
    .o_7seg_disp_ds      (DS),
    .o_7seg_disp_oe      (OE)
);

endmodule
