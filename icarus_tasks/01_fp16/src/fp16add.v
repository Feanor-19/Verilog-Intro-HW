// DenormalAsZero, FlushToZero, roundTiesToEven (an attempt)
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

localparam MANT_TMP_OFFSET = 3; // three extra bits: G, R, S
localparam MANT_TMP_BITS = 2+MANT_BITS+MANT_TMP_OFFSET;
localparam MANT_TMP_G_BIT = 2;
localparam MANT_TMP_R_BIT = 1;
localparam MANT_TMP_S_BIT = 0;
localparam MANT_TMP_C_BIT = MANT_TMP_BITS-1; 
localparam MANT_TMP_POS_BITS = $clog2(MANT_TMP_BITS);

localparam BEXP_TMP_BITS = BEXP_BITS+2;
localparam BEXP_TMP_UNDFL_BIT = BEXP_TMP_BITS-1;
localparam BEXP_TMP_OVRFL_BIT = BEXP_TMP_BITS-2;

localparam [BEXP_TMP_BITS-1:0] BIAS_EXP = BEXP_TMP_BITS'('b01111);

reg [FP16_BITS-1:0] a;
reg [FP16_BITS-1:0] b;
reg [FP16_BITS-1:0] tmp;

reg [MANT_BITS-1:0] mant_a;
reg [BEXP_BITS-1:0] bexp_a;
reg                 sign_a;

reg [MANT_BITS-1:0] mant_b;
reg [BEXP_BITS-1:0] bexp_b;
reg                 sign_b;

reg signed [BEXP_DIFF_BITS-1:0] bexp_diff;

reg [MANT_TMP_BITS-1:0] M_a;
reg [MANT_TMP_BITS-1:0] M_b;
reg [MANT_TMP_BITS-1:0] M_b_shifted;
reg [MANT_TMP_BITS-1:0] M_res;
reg [MANT_TMP_POS_BITS-1:0] lead1_pos;
reg [BEXP_TMP_BITS-1:0] bexp_tmp;

reg [MANT_TMP_BITS-1:0] M_a_dbg1;
reg [MANT_TMP_BITS-1:0] M_b_dbg1;
reg [MANT_TMP_BITS-1:0] M_res_dbg1;

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

function automatic [MANT_TMP_POS_BITS-1:0] lead1detect(input [MANT_TMP_BITS-1:0] i_m);
    reg [MANT_TMP_POS_BITS-1:0] o_pos;
    bit vld = 1'b0;

    for (int i=MANT_TMP_BITS-1; i >= 0; i=i-1) begin
        if (!vld && i_m[i]) begin
            o_pos = MANT_TMP_POS_BITS'(i);
            vld = 1'b1;
        end
    end

    if (vld)
        return o_pos;

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

    M_a = '0;
    M_b = '0;
    M_b_shifted = '0;
    M_res = '0;
    bexp_tmp = '0;
    bexp_diff = '0;
    tmp = '0;
    lead1_pos = '0;

    M_a_dbg1 = '0;
    M_b_dbg1 = '0;
    M_res_dbg1 = '0;

    if (is_nan(a) || is_nan(b)) begin
        sign_res = 1'b0;
        bexp_res = {BEXP_BITS{1'b1}};
        mant_res = {MANT_BITS{1'b1}}; // NaN
    end else if (is_inf(a) && is_inf(b) && sign_a != sign_b) begin
        sign_res = 0;
        bexp_res = {BEXP_BITS{1'b1}};
        mant_res = {MANT_BITS{1'b1}}; // NaN
    end else if (is_inf(a) && is_inf(b) && sign_a == sign_b) begin
        sign_res = sign_a;
        bexp_res = {BEXP_BITS{1'b1}};
        mant_res = '0; // the result equals inf
    end else if (is_zero(a) && is_zero(b)) begin //+0 + (-0) must be +0 smh
        sign_res = sign_a & sign_b;
        bexp_res = '0;
        mant_res = '0;
    end else if (is_zero(a) || is_inf(b)) begin
        sign_res = sign_b;
        bexp_res = bexp_b;
        mant_res = mant_b; // the result equals b
    end else if (is_zero(b) || is_inf(a)) begin
        sign_res = sign_a;
        bexp_res = bexp_a;
        mant_res = mant_a; // the result equals a
    end else begin
        // no denormals, infs or nans at this point

        bexp_diff = bexp_a - bexp_b;
        if (bexp_diff < 0) begin
            // swap so that bexp_a >= bexp_b & bexp_diff >= 0
            tmp = {sign_a, bexp_a, mant_a};
            {sign_a, bexp_a, mant_a} = {sign_b, bexp_b, mant_b};
            {sign_b, bexp_b, mant_b} = tmp;
            bexp_diff = -bexp_diff;
        end

        M_a = {2'b01, mant_a, {MANT_TMP_OFFSET{1'b0}}};
        M_b = {2'b01, mant_b, {MANT_TMP_OFFSET{1'b0}}};

        M_b_shifted = M_b >> $unsigned(bexp_diff);
        if (bexp_diff >= 4)
            for (reg [MANT_TMP_POS_BITS-1:0] ind = MANT_TMP_OFFSET; ind < MANT_TMP_BITS; ind++)
                M_b_shifted[MANT_TMP_S_BIT] |= (BEXP_DIFF_BITS'(ind) < bexp_diff) & M_b[ind]; 

        M_a_dbg1 = M_a;
        M_b_dbg1 = M_b;

        M_b = M_b_shifted;

        if (sign_a == sign_b) begin
            sign_res = sign_a;
            M_res = M_a + M_b;
        end else if ((M_a <= M_b)) begin
            sign_res = sign_b;
            M_res = M_b - M_a;
        end else begin
            sign_res = sign_a;
            M_res = M_a - M_b;
        end

        M_res_dbg1 = M_res;

        lead1_pos = lead1detect(M_res);

        if (lead1_pos == MANT_TMP_C_BIT) begin
            // after ">> 1" old R bit will be in the place of S bit
            // we need to shift and simultaneously update S bit:
            // S_new = S_old | R_old   
            M_res[MANT_TMP_R_BIT] |= M_res[MANT_TMP_S_BIT];
            
            M_res = M_res >> 1'b1;
            bexp_tmp = BEXP_TMP_BITS'(bexp_a) + 1;
        end else if (lead1_pos < MANT_TMP_BITS-2) begin
            M_res = M_res << ((MANT_TMP_BITS-2) - lead1_pos);
            bexp_tmp = BEXP_TMP_BITS'(bexp_a) - ((MANT_TMP_BITS-2) - BEXP_TMP_BITS'(lead1_pos));
        end else begin
            // M_res isn't changed
            bexp_tmp = {{(BEXP_TMP_BITS-BEXP_BITS){1'b0}}, bexp_a};
        end

        if (M_res[MANT_TMP_G_BIT] 
         & (M_res[MANT_TMP_R_BIT] | M_res[MANT_TMP_S_BIT] | M_res[MANT_TMP_OFFSET]))
            M_res = M_res + MANT_TMP_BITS'({1'b1, {MANT_TMP_OFFSET{1'b0}}});

        if (M_res[MANT_TMP_C_BIT] == 1'b1) begin
            M_res = M_res >> 1'b1;
            bexp_tmp += 1;
        end

        if (bexp_tmp[BEXP_TMP_UNDFL_BIT] == 1'b1) begin //underflow, bexp_tmp < 0
            bexp_res = '0;
            mant_res = '0; // zero
        end else if (bexp_tmp[BEXP_TMP_OVRFL_BIT] == 1'b1
                  || bexp_tmp[BEXP_BITS-1:0] == {BEXP_BITS{1'b1}}) begin //overflow
            bexp_res = {BEXP_BITS{1'b1}};
            mant_res = '0; // inf
        end else begin
            bexp_res = bexp_tmp[BEXP_BITS-1:0];
            mant_res = M_res[MANT_BITS+MANT_TMP_OFFSET-1:MANT_TMP_OFFSET];
        end
    end

    o_res = {sign_res, bexp_res, mant_res};

    o_res = daz(o_res); // FTZ
end

endmodule