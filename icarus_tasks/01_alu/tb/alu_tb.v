`timescale 1ns/1ps

`include "defines.vh"

// TODO rewrite $random

module alu_tb;

reg  [`ALU_OP_WIDTH-1:0] i_op;
reg  [`DATA_WIDTH-1:0]   i_a;
reg  [`DATA_WIDTH-1:0]   i_b;
wire [`DATA_WIDTH-1:0]   o_res;
reg  [`DATA_WIDTH-1:0] expected;

alu dut(.*);

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
        i_a = $urandom();
        i_b = $urandom();
        i_op = `ALU_OP_ADD;
        expected = $signed(i_a) + $signed(i_b);
        #5;
        check();

        #5;
        i_a = $urandom();
        i_b = $urandom();
        i_op = `ALU_OP_SUB;
        expected = $signed(i_a) - $signed(i_b);
        #5;
        check();

        #5;
        i_a = $urandom();
        i_b = $urandom();
        i_op = `ALU_OP_XOR;
        expected = i_a ^ i_b;
        #5;
        check();

        #5;
        i_a = $urandom();
        i_b = $urandom();
        i_op = `ALU_OP_OR;
        expected = i_a | i_b;
        #5;
        check();

        #5;
        i_a = $urandom();
        i_b = $urandom();
        i_op = `ALU_OP_AND;
        expected = i_a & i_b;
        #5;
        check();

        #5;
        i_a = $urandom();
        i_b = $urandom();
        i_op = `ALU_OP_SLT;
        expected = ($signed(i_a) < $signed(i_b)) ? {{31{1'b0}}, 1'b1} : 32'b0;
        #5;
        check();

        #5;
        i_a = $urandom();
        i_b = $urandom();
        i_op = `ALU_OP_SLTU;
        expected = ($unsigned(i_a) < $unsigned(i_b)) ? {{31{1'b0}}, 1'b1} : 32'b0;
        #5;
        check();
    
        #5;
        i_a = $urandom();
        i_b = $urandom();
        i_op = `ALU_OP_SLL;
        expected = i_a << i_b[4:0];
        #5;
        check();

        #5;
        i_a = $urandom();
        i_b = $urandom();
        i_op = `ALU_OP_SRL;
        expected = i_a >> i_b[4:0];
        #5;
        check();

        #5;
        i_a = $urandom();
        i_b = $urandom();
        i_op = `ALU_OP_SRA;
        i_a[`DATA_WIDTH-1] = 1'b0; // force to be positive
        expected = $signed(i_a) >>> i_b[4:0];
        #5;
        check();

        #5;
        i_a[`DATA_WIDTH-1] = 1'b1; // negative bit, the same other bits & i_b
        i_op = `ALU_OP_SRA;
        expected = $signed(i_a) >>> i_b[4:0];
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

    $display("Set random seed to %d", random_seed);
    void'($urandom(random_seed));

    $dumpvars;
    $display("[%0t] Start", $realtime);

    #10000;
    $display("[%0t] Time-out finish", $realtime);
    $finish;
end

endmodule
