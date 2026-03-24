`timescale 1ns/1ps

module blink_tb;

reg clk = 1'b0;
reg rst_n = 1'b1;
wire out;

always #1 clk <= ~clk;

blink blink_inst (.*);

initial begin
    if($test$plusargs("RAND_SEED"))
        $display("NOTE: RAND_SEED is not used directly in this tb.");
    
    $dumpvars;

    @(negedge clk);
    rst_n = 1'b0;
    @(negedge clk);
    rst_n = 1'b1;

    //repeat(100) @(posedge clk);
    
    wait(out);
    repeat(10) @(posedge clk);

    $finish;
end

endmodule
