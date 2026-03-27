`timescale 1ns/1ps

module uart_rx_tb;

localparam FREQ = 10;
localparam RATE =  2;

reg clk = 1'b0;
reg rst_n = 1'b1;
reg tb_rdy = 1'b0;
bit pass = 1'b1;

reg i_vld, o_vld;
reg o_tx, i_rx;
reg o_rdy;

reg  [7:0] i_data, o_data;

always #1 clk <= ~clk;

assign i_rx = o_tx;

uart_tx #(
    .FREQ (FREQ),
    .RATE (RATE)
) tx_inst (
    .*
);

uart_rx #(
    .FREQ (FREQ),
    .RATE (RATE)
) rx_inst (
    .*
);

initial begin
    wait(tb_rdy);

    repeat(100) begin
        wait(o_rdy);
        @(negedge clk);
        i_data = 8'($urandom());
        i_vld = 1'b1;
        @(negedge clk);
        i_vld = 1'b0;

        wait(o_vld);
        if (o_data != i_data) begin
            $display("[%0t] ERROR: i_data=0x%2H, o_data=0x%2H", $time, i_data, o_data);
            pass = 0;
        end
    end

    if (pass)
        $display("[%0t] PASS", $realtime);
    else
        $display("[%0t] FAIL", $realtime);

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

    tb_rdy = 1'b1;
end

endmodule
