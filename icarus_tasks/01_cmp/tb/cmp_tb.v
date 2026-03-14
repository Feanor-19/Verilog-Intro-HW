`timescale 1ns/1ps

`include "defines.vh"

module cmp_tb;

localparam DATA_WIDTH = 16;

reg  [`CMP_OP_WIDTH-1:0] i_op;
reg  [DATA_WIDTH-1:0]    i_a;
reg  [DATA_WIDTH-1:0]    i_b;

wire o_res;
reg  expected;

cmp #(.DATA_WIDTH(DATA_WIDTH)) dut(
    .i_op(i_op),
    .i_a(i_a),
    .i_b(i_b),
    .o_taken(o_res)
);

bit all_ok = 1'b1;

function void check();
    if (o_res != expected) begin
        $display("Error: i_op=%b, i_a=%0x, i_b=%0x, o_res=%0x, expected=%0x",
                i_op, i_a, i_b, o_res, expected);
        all_ok = 1'b0;
    end
endfunction

initial begin
    repeat(10) begin
        #5;
        i_a = DATA_WIDTH'($urandom());
        i_b = DATA_WIDTH'($urandom());
        i_op = `CMP_OP_BEQ;
        expected = (i_a == i_b);
        #5;
        check();

        #5;
        i_a = DATA_WIDTH'($urandom());
        i_b = DATA_WIDTH'($urandom());
        i_op = `CMP_OP_BNE;
        expected = (i_a != i_b);
        #5;
        check();

        #5;
        i_a = DATA_WIDTH'($urandom());
        i_b = DATA_WIDTH'($urandom());
        i_op = `CMP_OP_BLT;
        expected = ($signed(i_a) <  $signed(i_b));
        #5;
        check();

        #5;
        i_a = DATA_WIDTH'($urandom());
        i_b = DATA_WIDTH'($urandom());
        i_op = `CMP_OP_BGE;
        expected = ($signed(i_a) >= $signed(i_b));
        #5;
        check();

        #5;
        i_a = DATA_WIDTH'($urandom());
        i_b = DATA_WIDTH'($urandom());
        i_op = `CMP_OP_BLTU;
        expected = ($unsigned(i_a) <  $unsigned(i_b));
        #5;
        check();

        #5;
        i_a = DATA_WIDTH'($urandom());
        i_b = DATA_WIDTH'($urandom());
        i_op = `CMP_OP_BGEU;
        expected = ($unsigned(i_a) >= $unsigned(i_b));
        #5;
        check();

    end

    if (all_ok) $display("[%0t] ALL OK", $realtime);
    else        $display("[%0t] SOME FAILED", $realtime);
    $finish;
end

initial begin
    int random_seed;

    if (!$value$plusargs("RAND_SEED=%d", random_seed))
        random_seed = 0;

    $display("Set random seed to %0d", random_seed);
    void'($urandom(random_seed));

    $dumpvars;
    $display("[%0t] Start", $realtime);

    #10000;
    $display("[%0t] Time-out finish", $realtime);
    $finish;
end


endmodule
