// DenormalAsZero, FlushToZero, roundTiesToEven (almost)
module fp16mul #(
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

localparam MANTT_BITS = (MANT_BITS+1)*2;
localparam MANTT_C_BIT = MANT_BITS+1;

localparam BEXPT_BITS = BEXP_BITS+1+1;
localparam BEXPT_UNDFL_BIT = BEXPT_BITS-1;
localparam BEXPT_OVRFL_BIT = BEXPT_BITS-2;

localparam [BEXPT_BITS-1:0] BIAS_EXP = BEXPT_BITS'('b01111);

localparam [MANTT_BITS-1:0] EXP_OFF_THRESHOLD1 = 1 << (2*MANT_BITS+1);
localparam [MANTT_BITS-1:0] EXP_OFF_THRESHOLD0 = 1 << (2*MANT_BITS+0);

reg [FP16_BITS-1:0] a;
reg [FP16_BITS-1:0] b;

reg [MANT_BITS-1:0] mant_a;
reg [BEXP_BITS-1:0] bexp_a;
reg                 sign_a;

reg [MANT_BITS-1:0] mant_b;
reg [BEXP_BITS-1:0] bexp_b;
reg                 sign_b;

reg [MANTT_BITS-1:0] mantt1;
reg [MANTT_BITS-1:0] mantt2;
reg [BEXPT_BITS-1:0] bexpt;

reg RND_G;
reg RND_R;
reg RND_S;

reg [MANTT_BITS-1:0] mantt1_dbg;
reg [BEXPT_BITS-1:0] bexpt_dbg;
reg [MANTT_BITS-1:0] mantt2_dbg1;

reg sign_res;
reg [BEXP_BITS-1:0] bexp_res;
reg [MANT_BITS-1:0] mant_res;

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

    bexpt = '0;
    mantt1 = '0;
    mantt2 = '0;
    RND_G = '0;
    RND_R = '0;
    RND_S = '0;

    bexpt_dbg = '0;
    mantt1_dbg = '0;
    mantt2_dbg1 = '0;

    if (is_nan(a) || is_nan(b)) begin
        bexp_res = {BEXP_BITS{1'b1}};
        mant_res = {MANT_BITS{1'b1}}; // NaN
    end else if (is_inf(a) && is_zero(b) || is_zero(a) && is_inf(b)) begin
        bexp_res = {BEXP_BITS{1'b1}};
        mant_res = {MANT_BITS{1'b1}}; // NaN
    end else if (is_zero(a) || is_zero(b)) begin 
        bexp_res = '0;
        mant_res = '0; // zero
    end else if (is_inf(a) || is_inf(b)) begin
        bexp_res = {BEXP_BITS{1'b1}};
        mant_res = '0; // inf
    end else begin
        // no denormals or nans at this point
        bexpt = BEXPT_BITS'(bexp_a) + BEXPT_BITS'(bexp_b) - BIAS_EXP;
        mantt1 = {1'b1, mant_a} * {1'b1, mant_b};
        
        bexpt_dbg = bexpt;
        mantt1_dbg = mantt1;

        if (mantt1 < EXP_OFF_THRESHOLD1) begin
            RND_G = mantt1[MANT_BITS-1];
            RND_R = mantt1[MANT_BITS-2];
            RND_S = |mantt1[MANT_BITS-3:0];
            mantt1 -= EXP_OFF_THRESHOLD0;

            mantt2 = mantt1 >> (MANT_BITS+0);

            bexpt = bexpt;
        end else begin
            RND_G = mantt1[MANT_BITS];
            RND_R = mantt1[MANT_BITS-1];
            RND_S = |mantt1[MANT_BITS-2:0];
            mantt1 -= EXP_OFF_THRESHOLD1;

            mantt2 = mantt1 >> (MANT_BITS+1);            

            bexpt = bexpt+1;
        end

        mantt2_dbg1 = mantt2;

        mantt2 += 1 << MANT_BITS;

        if (RND_G & (RND_R | RND_S | mantt2[0]))
            mantt2 += 1;

        if (mantt2[MANTT_C_BIT] == 1'b1) begin
            mantt2 = mantt2 >> 1'b1;
            bexpt += 1;
        end

        if (bexpt[BEXPT_UNDFL_BIT] == 1'b1) begin
            // underflow, res is zero
            mantt2 = '0;
            bexpt = '0;
        end else if (bexpt[BEXPT_OVRFL_BIT] == 1'b1
                  || bexpt[BEXP_BITS-1:0] == {BEXP_BITS{1'b1}}) begin
            // overflow, res is inf
            mantt2 = '0;
            bexpt = BEXPT_BITS'({BEXP_BITS{1'b1}});
        end

        mant_res = mantt2[MANT_BITS-1:0];
        bexp_res = bexpt[BEXP_BITS-1:0];
    end

    sign_res = sign_a ^ sign_b;

    o_res = {sign_res, bexp_res, mant_res};

    o_res = daz(o_res); // FTZ
end

endmodule
