module material_eval(
    input wire [63:0] wp, wn, wb, wr, wq, wk,
    input wire [63:0] bp, bn, bb, br, bq, bk,
    output wire signed [15:0] material_score
);

    wire signed [15:0] white_score;
    assign white_score = ($countones(wp) * 16'd100) +
                         ($countones(wn) * 16'd300) +
                         ($countones(wb) * 16'd300) +
                         ($countones(wr) * 16'd500) +
                         ($countones(wq) * 16'd900);

    wire signed [15:0] black_score;
    assign black_score = ($countones(bp) * 16'd100) +
                         ($countones(bn) * 16'd300) +
                         ($countones(bb) * 16'd300) +
                         ($countones(br) * 16'd500) +
                         ($countones(bq) * 16'd900);

    assign material_score = white_score - black_score;

endmodule
