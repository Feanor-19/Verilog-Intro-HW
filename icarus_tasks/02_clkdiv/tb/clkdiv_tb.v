`timescale 1ps / 1ps

module clkdiv_tb;

// In Hz
localparam F0 = 50_000_000;
// localparam F1 = 9_600;
// localparam F1 = 38_400;
localparam F1 = 115_200;

localparam realtime T0 = 1_000_000_000_000/F0 * 1ps;
localparam realtime T1 = 1_000_000_000_000/F1 * 1ps;

reg clk = 1'b0;
reg rst_n = 1'b1;
reg out;

always begin
    #(T0/2) clk = ~clk;
end

clkdiv #(
    .F_INP(F0),
    .F_OUT(F1)
) clkdiv_inst (
    .clk    (clk),
    .rst_n  (rst_n),
    .out    (out)
);

initial begin
    @(posedge out);

    if (4*F1 >= F0)
        #(T0/2);
    else
        #(T1/4);

    forever begin
        if (!(out == 1'b1)) $display("[%0t] ERROR: out isn't HIGH", $realtime);
        #(T1/2);
        if (!(out == 1'b0)) $display("[%0t] ERROR: out isn't LOW", $realtime);
        #(T1/2);
    end
end

initial begin
    if($test$plusargs("RAND_SEED"))
        $display("NOTE: RAND_SEED is not used directly in this tb.");

    $dumpvars;

    @(negedge clk);
    rst_n = 1'b0;
    @(negedge clk);
    rst_n = 1'b1;

    @(posedge clk);
    $display("[%0t] Start", $realtime);

    repeat (100) @(posedge out);

    $display("[%0t] Finish", $realtime);
    $finish;
end

endmodule
