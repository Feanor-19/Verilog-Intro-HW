`timescale 1ns/1ps

module top_tb;

reg clk = 1'b0;
reg rst_n = 1'b1;

wire STCP;
wire SHCP;
wire DS;
wire OE;

always #1 clk <= ~clk;

top #(
    .NUM_TO_DISPLAY (4'b1011),
    .CNT_WIDTH      (4)
) top_inst (
    .clk     (clk),
    .rst_n   (rst_n),
    .o_stcp  (STCP),
    .o_shcp  (SHCP),
    .o_ds    (DS),
    .o_oe    (OE)
);
initial begin
    if($test$plusargs("RAND_SEED"))
        $display("NOTE: RAND_SEED is not used directly in this tb.");
    
    $dumpvars;

    @(negedge clk);
    rst_n = 1'b0;
    @(negedge clk);
    rst_n = 1'b1;

    repeat(100) @(posedge clk);

    $finish;
end

endmodule
