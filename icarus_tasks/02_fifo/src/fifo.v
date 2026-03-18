module fifo #(
    parameter DATA_WIDTH = 32,
    parameter LOG2_DEPTH = 3,

    localparam DATAW = DATA_WIDTH,
    localparam ADDRW = LOG2_DEPTH,
    localparam DEPTH = 2**LOG2_DEPTH
) (
    input  wire             clk,
    input  wire             rst_n,

    input  wire             i_wr_en,
    input  wire [DATAW-1:0] i_wr_data,
    output wire             o_wr_full,

    input  wire             i_rd_en,
    output wire [DATAW-1:0] o_rd_data, //vld if !o_rd_empty
    output wire             o_rd_empty
);

reg [DATAW-1:0] r[DEPTH];

reg [ADDRW:0] rd_ptr, wr_ptr;

assign o_rd_empty = (rd_ptr[ADDRW-1:0] == wr_ptr[ADDRW-1:0])
                 && (rd_ptr[ADDRW]     == wr_ptr[ADDRW]);

assign o_wr_full = (rd_ptr[ADDRW-1:0] == wr_ptr[ADDRW-1:0])
                && (rd_ptr[ADDRW]     != wr_ptr[ADDRW]);

assign o_rd_data = r[rd_ptr[ADDRW-1:0]];

always @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
        for (int i = 0; i < DEPTH; i++) begin
            r[i] <= '0;
        end
        rd_ptr <= '0;
        wr_ptr <= '0;
    end else begin
        if (i_wr_en && !o_wr_full) begin
            r[wr_ptr[ADDRW-1:0]] <= i_wr_data;
            wr_ptr <= wr_ptr + 1; 
        end

        if (i_rd_en && !o_rd_empty) begin
            rd_ptr <= rd_ptr + 1;
        end 
    end
end

endmodule
