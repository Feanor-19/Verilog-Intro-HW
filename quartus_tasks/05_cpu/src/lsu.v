`include "common.vh"

//NOTE only naturally aligned STs & LDs are supported. OTHERWISE UB
module lsu (
    input  wire [31:0]                i_core_addr,
    input  wire [31:0]                i_core_data,
    output reg  [31:0]                o_core_data,
    input  wire                       i_wren,
    input  wire [`LSU_SIZE_WIDTH-1:0] i_size, 

    output wire [29:0]                o_mem_addr,
    output reg  [31:0]                o_mem_data,
    input  wire [31:0]                i_mem_data,
    output wire                       o_wren,
    output reg  [3:0]                 o_mask
);

wire [1:0] in_addr_offset_byte, in_addr_offset_half; 
wire [4:0] in_word_offset_byte, in_word_offset_half;
wire [7:0] from_mem_byte;
wire [15:0] from_mem_half;
wire [31:0] from_mem_word;

assign in_addr_offset_byte = i_core_addr[1:0];
assign in_addr_offset_half = {i_core_addr[1], 1'b0};

assign in_word_offset_byte = {in_addr_offset_byte, 3'b0};
assign in_word_offset_half = {in_addr_offset_half, 3'b0};

assign from_mem_byte = i_mem_data[in_word_offset_byte +: 8];
assign from_mem_half = i_mem_data[in_word_offset_half +: 16];
assign from_mem_word = i_mem_data;

assign o_wren     = i_wren;
assign o_mem_addr = i_core_addr[31:2];

always @(*) begin
    o_mem_data = 32'b0;
    case (i_size)
        `LSU_SIZE_BYTE:  
        begin 
            o_mask = 4'b0001 << in_addr_offset_byte;
            o_core_data = { {24{from_mem_byte[7]}}, from_mem_byte[7:0] };
            o_mem_data[in_word_offset_byte +: 8] = i_core_data[7:0];
        end  
        `LSU_SIZE_BYTEU: 
        begin 
            o_mask = 4'b0001 << in_addr_offset_byte;
            o_core_data = { {24{1'b0}}, from_mem_byte[7:0] };
            o_mem_data[in_word_offset_byte +: 8] = i_core_data[7:0];
        end 
        `LSU_SIZE_HALF: 
        begin 
            o_mask = 4'b0011 << in_addr_offset_half;
            o_core_data = { {16{from_mem_half[15]}}, from_mem_half[15:0] };
            o_mem_data[in_word_offset_half +: 16] = i_core_data[15:0];
        end
        `LSU_SIZE_HALFU: 
        begin 
            o_mask = 4'b0011 << in_addr_offset_half;
            o_core_data = { {16{1'b0}}, from_mem_half[15:0] };
            o_mem_data[in_word_offset_half +: 16] = i_core_data[15:0];
        end
        `LSU_SIZE_WORD: 
        begin 
            o_mask = 4'b1111;
            o_core_data = from_mem_word;
            o_mem_data = i_core_data;
        end
        default: 
        begin
            o_mask = 4'bx;
            o_core_data = 32'bx;
        end
    endcase
end

endmodule
