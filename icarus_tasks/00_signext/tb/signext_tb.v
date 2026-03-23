`timescale 1ns/1ps

module signext_tb;

localparam N = 5;
localparam M = 16;

reg signed [N-1:0] i_x = {1'b1, {(N-1){1'b0}}};
wire signed [M-1:0] o_y;
bit all_ok = 1'b1;

signext #(
    .N(N),
    .M(M)
) dut (.*);

initial forever begin
    #5;

    if (o_y != M'(i_x)) begin
        $display("FAIL: i_x=%b, o_y=%b, (int)(i_x)=%d, (int)(o_y)=%d",
                        i_x, o_y, signed'(i_x), signed'(o_y));
        all_ok = 1'b0;
    end

    i_x = i_x + 1;
    if (i_x == {1'b1, {(N-1){1'b0}}}) begin
        if (all_ok) $display("ALL OK");
        else        $display("SOME FAILED");
        $finish;
    end
end

initial begin
    $dumpvars;
    $display("[%0t] Start", $realtime);


    #10000 $finish;
end

endmodule
