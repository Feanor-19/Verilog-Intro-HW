module top #(
    parameter CNT_GRND_WIDTH = 26,
    parameter CNT_DISP_WIDTH = 14
) (
    input  wire clk,
    input  wire rst_n,

    output wire o_stcp,
    output wire o_shcp,
    output wire o_ds,
    output wire o_oe
);

wire  [3:0] anodes;
wire  [7:0] segments;

wire shift_done;

wire [15:0] rnd_val;

reg [CNT_GRND_WIDTH-1:0] grnd_cnt;
always @(posedge clk, negedge rst_n) begin
    grnd_cnt <= !rst_n ? {CNT_GRND_WIDTH{1'b0}} : grnd_cnt + 1'b1;
end

lfsr #(
    .WIDTH  (16),
    .P      (15'b110100000000001),
    .INITVAL(16'hBEEF)
) lfsr_inst (
    .clk    (clk),
    .rst_n  (rst_n),
    .i_en   (&grnd_cnt),
    .o_reg  (rnd_val)
);

hex_display #(
    .CNT_WIDTH(CNT_DISP_WIDTH)
) hex_display (
    .clk        (clk),
    .rst_n      (rst_n),
    .i_data     (rnd_val),
    .i_rdy      (shift_done),
    .o_anodes   (anodes),
    .o_segments (segments)
);

ctrl_74hc595 ctrl(
    .clk    (clk                ),
    .rst_n  (rst_n              ),
    .i_data ({segments, anodes} ),
    .o_stcp (o_stcp             ),
    .o_shcp (o_shcp             ),
    .o_ds   (o_ds               ),
    .o_oe   (o_oe               ),
    .o_done (shift_done         )
);

endmodule
