`ifdef BEHAVIORAL

// y is sign extension of x, assuming N>=M 
module signext #(
    parameter N = 8,
    parameter M = 32
) (
    input  wire [N-1:0] i_x,
    output wire [M-1:0] o_y
);

  assign o_y = {{(M-N){i_x[N-1]}},i_x};

endmodule

`else // NOT BEHAVIORAL

module signext #(
    parameter N = 8,
    parameter M = 32
) (
    input  wire [N-1:0] i_x,
    output wire [M-1:0] o_y
);

  // the same as above?? how to construct it from 1-bit signext modules or smth?

  assign o_y = {{(M-N){i_x[N-1]}},i_x};

endmodule

`endif // END BEHAVIORAL
