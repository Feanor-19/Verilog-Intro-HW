// DenormalAsZero, FlushToZero, roundTiesToEven (an attempt)
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

// localparam MANT_TMP_OFFSET = 3; // three extra bits: G, R, S

// localparam MANT_EFF_BITS = MANT_BITS + MANT_TMP_OFFSET; // mant + {G, R, S}

localparam MANT_TMP_BITS = (MANT_BITS+1)*2;
// localparam MANT_TMP_G_BIT = 2;
// localparam MANT_TMP_R_BIT = 1;
// localparam MANT_TMP_S_BIT = 0;
localparam MANT_TMP_C_BIT = MANT_BITS+1;


localparam BEXP_TMP_BITS = BEXP_BITS+1+1;
localparam BEXP_TMP_UNDFL_BIT = BEXP_TMP_BITS-1;
localparam BEXP_TMP_OVRFL_BIT = BEXP_TMP_BITS-2;

localparam [BEXP_TMP_BITS-1:0] BIAS_EXP = BEXP_TMP_BITS'('b01111);

localparam [MANT_TMP_BITS-1:0] EXP_OFF_TRESHOLD1 = 1 << (2*MANT_BITS+1);
localparam [MANT_TMP_BITS-1:0] EXP_OFF_TRESHOLD0 = 1 << (2*MANT_BITS+0);

reg [FP16_BITS-1:0] a;
reg [FP16_BITS-1:0] b;

reg [MANT_BITS-1:0] mant_a;
reg [BEXP_BITS-1:0] bexp_a;
reg                 sign_a;

reg [MANT_BITS-1:0] mant_b;
reg [BEXP_BITS-1:0] bexp_b;
reg                 sign_b;

reg [MANT_TMP_BITS-1:0] mant_tmp;
reg [MANT_TMP_BITS-1:0] M_res;
reg [BEXP_TMP_BITS-1:0] bexp_tmp;

reg G;
reg R;
reg S;

reg [MANT_TMP_BITS-1:0] mant_tmp_dbg;
reg [BEXP_TMP_BITS-1:0] bexp_tmp_dbg;
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

    bexp_tmp = '0;
    mant_tmp = '0;
    M_res = '0;
    G = '0;
    R = '0;
    S = '0;

    bexp_tmp_dbg = '0;
    mant_tmp_dbg = '0;
    M_res_dbg1 = '0;

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
        bexp_tmp = BEXP_TMP_BITS'(bexp_a) + BEXP_TMP_BITS'(bexp_b) - BIAS_EXP;
        mant_tmp = {1'b1, mant_a} * {1'b1, mant_b};
        
        bexp_tmp_dbg = bexp_tmp;
        mant_tmp_dbg = mant_tmp;

        if (mant_tmp < EXP_OFF_TRESHOLD1) begin
            G = mant_tmp[MANT_BITS-1];
            R = mant_tmp[MANT_BITS-2];
            S = |mant_tmp[MANT_BITS-3:0];
            mant_tmp -= EXP_OFF_TRESHOLD0;

            M_res = mant_tmp >> (MANT_BITS+0);

            bexp_tmp = bexp_tmp;
        end else begin
            G = mant_tmp[MANT_BITS];
            R = mant_tmp[MANT_BITS-1];
            S = |mant_tmp[MANT_BITS-2:0];
            mant_tmp -= EXP_OFF_TRESHOLD1;

            M_res = mant_tmp >> (MANT_BITS+1);            

            bexp_tmp = bexp_tmp+1;
        end

        M_res_dbg1 = M_res;

        M_res += 1 << MANT_BITS;

        if (G & (R | S | M_res[0]))
            M_res += 1;

        if (M_res[MANT_TMP_C_BIT] == 1'b1) begin
            M_res = M_res >> 1'b1;
            bexp_tmp += 1;
        end

        if (bexp_tmp[BEXP_TMP_UNDFL_BIT] == 1'b1) begin
            // underflow, res is zero
            M_res = '0;
            bexp_tmp = '0;
        end else if (bexp_tmp[BEXP_TMP_OVRFL_BIT] == 1'b1
                  || bexp_tmp[BEXP_BITS-1:0] == {BEXP_BITS{1'b1}}) begin
            // overflow, res is inf
            M_res = '0;
            bexp_tmp = BEXP_TMP_BITS'({BEXP_BITS{1'b1}});
        end

        mant_res = M_res[MANT_BITS-1:0];
        bexp_res = bexp_tmp[BEXP_BITS-1:0];
    end

    sign_res = sign_a ^ sign_b;

    o_res = {sign_res, bexp_res, mant_res};

    o_res = daz(o_res); // FTZ
end

endmodule
