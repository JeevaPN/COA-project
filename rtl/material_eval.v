module material_eval(
    // White piece bitboards
    input wire [63:0] wp, wn, wb, wr, wq, wk,
    // Black piece bitboards
    input wire [63:0] bp, bn, bb, br, bq, bk,
    // Output: material score (positive -> white advantage)
    output wire signed [15:0] material_score
);

    // Simple material weights used by many engines
    // Pawn=100, Knight/Bishop=300, Rook=500, Queen=900
    // $countones() maps cleanly to fast synthesizable popcount logic.

    // Sum white material
    wire signed [15:0] white_score;
    assign white_score = ($countones(wp) * 16'd100) +
                         ($countones(wn) * 16'd300) +
                         ($countones(wb) * 16'd300) +
                         ($countones(wr) * 16'd500) +
                         ($countones(wq) * 16'd900);

    // Sum black material
    wire signed [15:0] black_score;
    assign black_score = ($countones(bp) * 16'd100) +
                         ($countones(bn) * 16'd300) +
                         ($countones(bb) * 16'd300) +
                         ($countones(br) * 16'd500) +
                         ($countones(bq) * 16'd900);

    // Material evaluation: white minus black
    assign material_score = white_score - black_score;

endmodule
