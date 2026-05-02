module io_subsystem_core0 #(
    parameter [29:0] ADDR_FIFO_DATA = 30'h0000,
    parameter [29:0] ADDR_FIFO_FULL = 30'h0000,
    parameter [29:0] ADDR_CORE_ID   = 30'h0000
) (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [29:0] i_mmio_addr,
    input  wire [31:0] i_mmio_data,
    input  wire        i_mmio_wren,
    input  wire        i_mmio_rden,
    input  wire [3:0]  i_mmio_mask,
    output wire [31:0] o_mmio_data,

    output wire        o_afifo_wrreq,
    output wire [31:0] o_afifo_data,
    input  wire        i_afifo_wrfull
);

reg  [31:0] mmio_data_out_nxt;
reg  [31:0] mmio_data_out_q;

always @(*) begin
    mmio_data_out_nxt = 32'bx;

    if (i_mmio_rden) begin
        case (i_mmio_addr)
            ADDR_FIFO_FULL: mmio_data_out_nxt = {31'b0, i_afifo_wrfull};
            ADDR_CORE_ID:   mmio_data_out_nxt = 32'd0;
            default:        mmio_data_out_nxt = 32'bx;
        endcase
    end
end

always @(posedge clk) begin
    mmio_data_out_q <= mmio_data_out_nxt;
end

assign o_mmio_data = mmio_data_out_q;

// =============
// --- AFIFO ---
// =============

// AFIFO doesn't respect mask
assign o_afifo_wrreq = (i_mmio_addr == ADDR_FIFO_DATA) ? i_mmio_wren : 1'b0;
assign o_afifo_data  = (i_mmio_addr == ADDR_FIFO_DATA) ? i_mmio_data : 32'bx;

endmodule
