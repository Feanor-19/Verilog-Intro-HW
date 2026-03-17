module rf_2r1w #(
    parameter DATA_WIDTH  = 32,
    parameter REG_NUM     = 32,
    localparam ADDR_WIDTH = $clog2(REG_NUM)
) (
    input  wire        clk,
    input  wire        rst_n,

    input  wire  [ADDR_WIDTH-1:0] i_rd1_addr,
    output wire  [DATA_WIDTH-1:0] o_rd1_data,

    input  wire  [ADDR_WIDTH-1:0] i_rd2_addr,
    output wire  [DATA_WIDTH-1:0] o_rd2_data,

    input  wire  [ADDR_WIDTH-1:0] i_wr_addr,
    input  wire  [DATA_WIDTH-1:0] i_wr_data,
    input  wire                   i_wr_en
);

reg [DATA_WIDTH-1:0] r[REG_NUM];

assign o_rd1_data = r[i_rd1_addr];
assign o_rd2_data = r[i_rd2_addr];

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        for (int i = 0; i < REG_NUM; i++) begin
            r[i] = '0;
        end
    end
    if (i_wr_en) begin
        r[i_wr_addr] <= i_wr_data;
    end
end

endmodule
