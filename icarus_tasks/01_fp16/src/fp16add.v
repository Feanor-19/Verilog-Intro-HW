// DenormalAsZero, FlushToZero, roundTiesToEven (almost)
module fp16add #(
    localparam FP16_BITS = 16
) (
    input  wire [FP16_BITS-1:0] i_a,
    input  wire [FP16_BITS-1:0] i_b,

    output reg  [FP16_BITS-1:0] o_res
);

localparam MANT_BITS = 10;
localparam BEXP_BITS = 5;

localparam MANT_BEG = 0;
localparam MANT_END = MANT_BEG + MANT_BITS - 1;
localparam BEXP_BEG = MANT_END + 1;
localparam BEXP_END = BEXP_BEG + BEXP_BITS - 1;
localparam SIGN_BIT = 15;

localparam BEXP_DIFF_BITS = BEXP_BITS + 1;

localparam MANTT_OFFSET = 3; // three extra bits: G, R, S
localparam MANTT_BITS = 2+MANT_BITS+MANTT_OFFSET;
localparam MANTT_G_BIT = 2;
localparam MANTT_R_BIT = 1;
localparam MANTT_S_BIT = 0;
localparam MANTT_C_BIT = MANTT_BITS-1; 
localparam MANTT_POS_BITS = $clog2(MANTT_BITS);

localparam BEXPT_BITS = BEXP_BITS+2;
localparam BEXPT_UNDFL_BIT = BEXPT_BITS-1;
localparam BEXPT_OVRFL_BIT = BEXPT_BITS-2;

localparam [BEXPT_BITS-1:0] BIAS_EXP = BEXPT_BITS'('b01111);

reg [FP16_BITS-1:0] a;
reg [FP16_BITS-1:0] b;
reg [FP16_BITS-1:0] swap_tmp;

reg [MANT_BITS-1:0] mant_a;
reg [BEXP_BITS-1:0] bexp_a;
reg                 sign_a;

reg [MANT_BITS-1:0] mant_b;
reg [BEXP_BITS-1:0] bexp_b;
reg                 sign_b;

reg signed [BEXP_DIFF_BITS-1:0] bexp_diff;

reg [MANTT_BITS-1:0] mantt_a;
reg [MANTT_BITS-1:0] mantt_b;
reg [MANTT_BITS-1:0] mantt_b_shifted;
reg [MANTT_BITS-1:0] mantt1;
reg [MANTT_BITS-1:0] mantt2;
reg [MANTT_POS_BITS-1:0] lead1_pos;
reg [BEXPT_BITS-1:0] bexpt;
reg                  lead1_pos_vld;
reg                  ready4lead1detect;

reg [MANTT_BITS-1:0] mantt_a_dbg1;
reg [MANTT_BITS-1:0] mantt_b_dbg1;
reg [MANTT_BITS-1:0] mantt1_dbg;

reg sign_res1;
reg [BEXP_BITS-1:0] bexp_res1;
reg [MANT_BITS-1:0] mant_res1;

reg sign_res2;
reg [BEXP_BITS-1:0] bexp_res2;
reg [MANT_BITS-1:0] mant_res2;

// doesn't change NaNs and Infs
function [FP16_BITS-1:0] daz(input [FP16_BITS-1:0] x);
    if (x[BEXP_END:BEXP_BEG] == '0)
        return {x[SIGN_BIT], x[BEXP_END:BEXP_BEG], {MANT_BITS{1'b0}}};

    return x;
endfunction

function automatic bit is_nan(input [FP16_BITS-1:0] x);
    reg [MANT_BITS-1:0] x_mant = x[MANT_END:MANT_BEG];
    reg [BEXP_BITS-1:0] x_bexp = x[BEXP_END:BEXP_BEG];
    if (x_bexp == {BEXP_BITS{1'b1}} && x_mant != '0)
        return 1;

    return 0;
endfunction

function automatic bit is_inf(input [FP16_BITS-1:0] x);
    reg [MANT_BITS-1:0] x_mant = x[MANT_END:MANT_BEG];
    reg [BEXP_BITS-1:0] x_bexp = x[BEXP_END:BEXP_BEG];
    if (x_bexp == {BEXP_BITS{1'b1}} && x_mant == '0)
        return 1;

    return 0;
endfunction

function automatic bit is_zero(input [FP16_BITS-1:0] x);
    reg [MANT_BITS-1:0] x_mant = x[MANT_END:MANT_BEG];
    reg [BEXP_BITS-1:0] x_bexp = x[BEXP_END:BEXP_BEG];
    if (x_bexp == '0 && x_mant == '0)
        return 1;

    return 0;
endfunction

lead1detect #(
    .DATA_WIDTH(MANTT_BITS)
) lead1detect_inst (
    .i_data (mantt1),
    .o_pos  (lead1_pos),
    .o_vld  (lead1_pos_vld)
);

always @(*) begin
    a = i_a;
    b = i_b;

    a = daz(a);
    b = daz(b);

    // the only left denormal is zero itself

    mant_a = a[MANT_END:MANT_BEG];
    bexp_a = a[BEXP_END:BEXP_BEG];
    sign_a = a[SIGN_BIT];

    mant_b = b[MANT_END:MANT_BEG];
    bexp_b = b[BEXP_END:BEXP_BEG];
    sign_b = b[SIGN_BIT];

    mantt_a = '0;
    mantt_b = '0;
    mantt_b_shifted = '0;
    mantt1 = '0;
    bexp_diff = '0;
    bexpt = '0;
    swap_tmp = '0;
    ready4lead1detect = '0;

    mantt_a_dbg1 = '0;
    mantt_b_dbg1 = '0;
    mantt1_dbg = '0;

    sign_res1 = 0;
    bexp_res1 = '0;
    mant_res1 = '0;

    if (is_nan(a) || is_nan(b)) begin
        sign_res1 = 1'b0;
        bexp_res1 = {BEXP_BITS{1'b1}};
        mant_res1 = {MANT_BITS{1'b1}}; // NaN
    end else if (is_inf(a) && is_inf(b) && sign_a != sign_b) begin
        sign_res1 = 0;
        bexp_res1 = {BEXP_BITS{1'b1}};
        mant_res1 = {MANT_BITS{1'b1}}; // NaN
    end else if (is_inf(a) && is_inf(b) && sign_a == sign_b) begin
        sign_res1 = sign_a;
        bexp_res1 = {BEXP_BITS{1'b1}};
        mant_res1 = '0; // the result equals inf
    end else if (is_zero(a) && is_zero(b)) begin //+0 + (-0) must be +0 smh
        sign_res1 = sign_a & sign_b;
        bexp_res1 = '0;
        mant_res1 = '0;
    end else if (is_zero(a) || is_inf(b)) begin
        sign_res1 = sign_b;
        bexp_res1 = bexp_b;
        mant_res1 = mant_b; // the result equals b
    end else if (is_zero(b) || is_inf(a)) begin
        sign_res1 = sign_a;
        bexp_res1 = bexp_a;
        mant_res1 = mant_a; // the result equals a
    end else begin
        // no denormals, infs or nans at this point

        bexp_diff = bexp_a - bexp_b;
        if (bexp_diff < 0) begin
            // swap so that bexp_a >= bexp_b & bexp_diff >= 0
            swap_tmp = {sign_a, bexp_a, mant_a};
            {sign_a, bexp_a, mant_a} = {sign_b, bexp_b, mant_b};
            {sign_b, bexp_b, mant_b} = swap_tmp;
            bexp_diff = -bexp_diff;
        end

        mantt_a = {2'b01, mant_a, {MANTT_OFFSET{1'b0}}};
        mantt_b = {2'b01, mant_b, {MANTT_OFFSET{1'b0}}};

        mantt_b_shifted = mantt_b >> $unsigned(bexp_diff);
        if (bexp_diff >= 4)
            for (reg [MANTT_POS_BITS-1:0] ind = MANTT_OFFSET; ind < MANTT_BITS; ind++)
                mantt_b_shifted[MANTT_S_BIT] |= (BEXP_DIFF_BITS'(ind) < bexp_diff) & mantt_b[ind]; 

        mantt_a_dbg1 = mantt_a;
        mantt_b_dbg1 = mantt_b;

        mantt_b = mantt_b_shifted;

        if (sign_a == sign_b) begin
            sign_res1 = sign_a;
            mantt1 = mantt_a + mantt_b;
        end else if ((mantt_a <= mantt_b)) begin
            sign_res1 = sign_b;
            mantt1 = mantt_b - mantt_a;
        end else begin
            sign_res1 = sign_a;
            mantt1 = mantt_a - mantt_b;
        end

        mantt1_dbg = mantt1;

        ready4lead1detect = 1;
    end
end

always @(*) begin
     
    mantt2 = '0;
    bexpt = '0;

    sign_res2 = '0;
    bexp_res2 = '0;
    mant_res2 = '0;
    
    if (ready4lead1detect) begin
        mantt2 = mantt1;
        sign_res2 = sign_res1;

        if (lead1_pos_vld) begin
            if (lead1_pos == MANTT_C_BIT) begin
                // after ">> 1" old R bit will be in the place of S bit
                // we need to shift and simultaneously update S bit:
                // S_new = S_old | R_old   
                mantt2[MANTT_R_BIT] |= mantt2[MANTT_S_BIT];
                
                mantt2 = mantt2 >> 1'b1;
                bexpt = BEXPT_BITS'(bexp_a) + 1;
            end else if (lead1_pos < MANTT_BITS-2) begin
                mantt2 = mantt2 << ((MANTT_BITS-2) - lead1_pos);
                bexpt = BEXPT_BITS'(bexp_a) - ((MANTT_BITS-2) - BEXPT_BITS'(lead1_pos));
            end else begin
                // mantt2 isn't changed
                bexpt = {{(BEXPT_BITS-BEXP_BITS){1'b0}}, bexp_a};
            end

            if (mantt2[MANTT_G_BIT] & (mantt2[MANTT_R_BIT] | mantt2[MANTT_S_BIT] | mantt2[MANTT_OFFSET]))
                mantt2 = mantt2 + MANTT_BITS'({1'b1, {MANTT_OFFSET{1'b0}}});

            if (mantt2[MANTT_C_BIT] == 1'b1) begin
                mantt2 = mantt2 >> 1'b1;
                bexpt += 1;
            end

            if (bexpt[BEXPT_UNDFL_BIT] == 1'b1) begin //underflow, bexpt < 0
                bexp_res2 = '0;
                mant_res2 = '0; // zero
            end else if (bexpt[BEXPT_OVRFL_BIT] == 1'b1
                    || bexpt[BEXP_BITS-1:0] == {BEXP_BITS{1'b1}}) begin //overflow
                bexp_res2 = {BEXP_BITS{1'b1}};
                mant_res2 = '0; // inf
            end else begin
                bexp_res2 = bexpt[BEXP_BITS-1:0];
                mant_res2 = mantt2[MANT_BITS+MANTT_OFFSET-1:MANTT_OFFSET];
            end
        end else begin 
            //lead1pos not valid -> mantt2 == '0 -> the final result is zero
            bexp_res2 = '0;
            mant_res2 = '0;
            sign_res2 = 0;
        end
    end
end

always @(*) begin
    if (ready4lead1detect) begin
        o_res = {sign_res2, bexp_res2, mant_res2};
    end else begin
        o_res = {sign_res1, bexp_res1, mant_res1};
    end

    o_res = daz(o_res); // FTZ
end

endmodule