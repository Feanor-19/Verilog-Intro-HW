`timescale 1ns/1ps

module system_top_tb;

reg clk = 1'b0;
reg rst_n = 1'b1;

always #1 clk <= ~clk;

wire [31:0] afifo_data;
wire        afifo_rdreq;
wire        afifo_wrreq;
wire [31:0] afifo_q       = 32'b0;
wire        afifo_rdempty = 1'b0;
wire        afifo_wrfull  = 1'b0;

wire STCP;
wire SHCP;
wire DS;
wire OE;

system_top_core0 system_top_core0_inst (
    .clk              (clk),
    .rst_n            (rst_n),

    .o_afifo_wrreq    (afifo_wrreq),
    .o_afifo_data     (afifo_data),
    .i_afifo_wrfull   (afifo_wrfull)
);

system_top_core1 #(
    .DISP_7SEG_CNT_WIDTH (14)
) system_top_core1_inst (
    .clk                 (clk),
    .rst_n               (rst_n),
    
    .o_afifo_rdreq       (afifo_rdreq),
    .i_afifo_q           (afifo_q),
    .i_afifo_rdempty     (afifo_rdempty),
    
    .o_7seg_disp_stcp    (STCP),
    .o_7seg_disp_shcp    (SHCP),
    .o_7seg_disp_ds      (DS),
    .o_7seg_disp_oe      (OE)
);

initial begin
    if($test$plusargs("RAND_SEED"))
        $display("NOTE: RAND_SEED is not used directly in this tb.");

    $dumpvars;

    @(negedge clk);
    rst_n = 1'b0;

    @(negedge clk);
    rst_n = 1'b1;

    repeat (1000) @(posedge clk);

    $finish;
end

    
endmodule
