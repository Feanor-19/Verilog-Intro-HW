module io_subsystem_core1 #(
    parameter DISP_7SEG_CNT_WIDTH = 0,

    parameter [29:0] ADDR_DISP_7SEG  = 30'h0000,
    parameter [29:0] ADDR_FIFO_DATA  = 30'h0000,
    parameter [29:0] ADDR_FIFO_EMPTY = 30'h0000,
    parameter [29:0] ADDR_CORE_ID    = 30'h0000
) (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [29:0] i_mmio_addr,
    input  wire [31:0] i_mmio_data,
    input  wire        i_mmio_wren,
    input  wire        i_mmio_rden,
    input  wire [3:0]  i_mmio_mask,
    output wire [31:0] o_mmio_data,

    output wire        o_afifo_rdreq,
    input  wire [31:0] i_afifo_q,
    input  wire        i_afifo_rdempty,

    output wire        o_7seg_disp_stcp,
    output wire        o_7seg_disp_shcp,
    output wire        o_7seg_disp_ds,
    output wire        o_7seg_disp_oe
);

reg  [31:0] mmio_data_out_nxt;
reg  [31:0] mmio_data_out_q;

reg  afifo_override_q;
wire afifo_override_nxt;

wire [31:0] afifo_data_out;

always @(*) begin
    mmio_data_out_nxt = 32'bx;

    if (i_mmio_rden) begin
        case (i_mmio_addr)
            ADDR_FIFO_EMPTY: mmio_data_out_nxt = {31'b0, i_afifo_rdempty};
            ADDR_CORE_ID:    mmio_data_out_nxt = 32'd1;
            default:         mmio_data_out_nxt = 32'bx;
        endcase
    end
end

always @(posedge clk) begin
    mmio_data_out_q <= mmio_data_out_nxt;
end

assign o_mmio_data = (~afifo_override_q) ? mmio_data_out_q : afifo_data_out;

// =============
// --- AFIFO ---
// =============

assign afifo_data_out = i_afifo_q;

assign afifo_override_nxt = (i_mmio_addr == ADDR_FIFO_DATA) & i_mmio_rden;

assign o_afifo_rdreq = afifo_override_nxt;

always @(posedge clk) begin 
    afifo_override_q <= afifo_override_nxt;
end

// =============
// --- DISP7 ---
// =============

wire [15:0] disp_7seg_data;
wire        disp_7seg_wren;
wire [1:0]  disp_7seg_mask;

assign disp_7seg_wren = (i_mmio_addr == ADDR_DISP_7SEG) ? i_mmio_wren       : 1'b0;
assign disp_7seg_data = (i_mmio_addr == ADDR_DISP_7SEG) ? i_mmio_data[15:0] : 16'hx;
assign disp_7seg_mask = (i_mmio_addr == ADDR_DISP_7SEG) ? i_mmio_mask[1:0]  : 2'bx;

ctrl_7_seg_disp #(
    .CNT_WIDTH (DISP_7SEG_CNT_WIDTH)
) ctrl_7_seg_disp_inst (
    .clk    (clk),
    .rst_n  (rst_n),
    .i_data (disp_7seg_data),
    .i_wren (disp_7seg_wren),
    .i_mask (disp_7seg_mask),
    .o_stcp (o_7seg_disp_stcp),
    .o_shcp (o_7seg_disp_shcp),
    .o_ds   (o_7seg_disp_ds),
    .o_oe   (o_7seg_disp_oe)
);

endmodule
