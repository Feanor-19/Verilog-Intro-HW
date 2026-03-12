`timescale 1ns/1ps

module mux4_tb;

localparam WIDTH = 4;

reg  [1:0] 		 i_sel;
reg  [WIDTH-1:0] i_0 = '0;
reg  [WIDTH-1:0] i_1 = '0;
reg  [WIDTH-1:0] i_2 = '0;
reg  [WIDTH-1:0] i_3 = '0;
reg  [WIDTH-1:0] o_out;

bit all_ok = 1'b1;

mux4 #(.WIDTH(WIDTH)) dut(.*);

function void error();
    $display("Error: i_sel=%b, i_0=%0x, i_1=%0x, i_2=%0x, i_3=%0x, o_out=%0x",
            i_sel, i_0, i_1, i_2, i_3, o_out);
    all_ok = 1'b0;
endfunction

initial begin
    #5;

    i_0 = WIDTH'($urandom());
    i_1 = WIDTH'($urandom());
    i_2 = WIDTH'($urandom());
    i_3 = WIDTH'($urandom());

    #5;
    i_sel = 2'b00;
    #5;
    if (o_out != i_0)
        error();

    #5;    
    i_sel = 2'b01;
    #5;
    if (o_out != i_1)
        error();

    #5;
    i_sel = 2'b10;
    #5;
    if (o_out != i_2)
        error();

    #5;
    i_sel = 2'b11;
    #5;
    if (o_out != i_3)
        error();
    
    #5;
    if (all_ok) $display("[%0t] ALL OK", $realtime);
    else        $display("[%0t] SOME FAILED", $realtime);
    $finish;
end

initial begin
    int random_seed;

    if (!$value$plusargs("RAND_SEED=%d", random_seed))
        random_seed = 0;

    $display("Set random seed to %d", random_seed);
    void'($urandom(random_seed));

    $dumpvars;
    $display("[%0t] Start", $realtime);

    #10000;
    $display("[%0t] Time-out finish", $realtime);
    $finish;
end

endmodule
