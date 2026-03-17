module lfsr_tb;

reg clk = 1'b0;
reg rst_n = 1'b1;

reg i_en = 1'b1;
reg o_bit;

always #1 clk <= ~clk;

lfsr lfsr_inst(.*);

initial begin
    if($test$plusargs("RAND_SEED"))
        $display("NOTE: RAND_SEED is not used in this tb.");

    $dumpvars;

    @(negedge clk);
    rst_n = 1'b0;
    @(negedge clk);
    rst_n = 1'b1;

    @(posedge clk);
    $display("[%0t] Start", $realtime);
    
    repeat (1000) @(posedge clk);

    $finish;
end

endmodule
