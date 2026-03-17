module lead1detect #(
    parameter DATA_WIDTH = 32,
    localparam POS_WIDTH = $clog2(DATA_WIDTH)
) (
    input  wire [DATA_WIDTH-1:0] i_data,

    output reg  [POS_WIDTH-1:0]  o_pos,
    output reg                   o_vld
);

always @(*) begin
    o_pos = '0;
    o_vld = 1'b0;

    for (int i=DATA_WIDTH-1; i >= 0; i=i-1) begin
        if (!o_vld && i_data[i]) begin
            o_pos = POS_WIDTH'(i);
            o_vld = 1'b1;
        end
    end
end

endmodule
