`timescale 1ns/1ps

module top_tb;

localparam FREQ = 10;
localparam RATE =  2;

reg clk = 1'b0;
reg rst_n = 1'b1;
reg tb_rdy = 0;

wire STCP;
wire SHCP;
wire DS;
wire OE;
wire i_rx, o_tx, o_rdy;
reg i_vld;
reg [7:0] i_data;

always #1 clk <= ~clk;

assign i_rx = o_tx;

uart_tx #(
    .FREQ (FREQ),
    .RATE (RATE)
) tx_inst (
    .*
);

top #(
    .F_CLOCK        (FREQ),
    .UART_RATE      (RATE),
    .CNT_DISP_WIDTH (4)
) top_inst (
    .clk        (clk),
    .rst_n      (rst_n),
    .i_uart_rx  (i_rx),
    .o_stcp     (STCP),
    .o_shcp     (SHCP),
    .o_ds       (DS),
    .o_oe       (OE)
);

initial begin
    wait(tb_rdy);

    wait(o_rdy);
    repeat(10) begin
        @(negedge clk);
        i_data = 8'($urandom());
        i_vld = 1'b1;
        @(negedge clk);
        i_vld = 1'b0;

        wait(o_rdy);
        repeat (500) @(posedge clk);
    end

    $finish;
end

initial begin
    int random_seed;

    if (!$value$plusargs("RAND_SEED=%d", random_seed))
        random_seed = 0;

    $display("Set random seed to %0d", random_seed);
    void'($urandom(random_seed));
    
    $dumpvars;

    @(negedge clk);
    rst_n = 1'b0;

    i_vld = 1'b0;
    i_data = '0;

    @(negedge clk);
    rst_n = 1'b1;

    @(negedge clk);
    tb_rdy = 1;
end

endmodule
