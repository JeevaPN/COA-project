module material_eval(
    // White pieces
    input wire [63:0] wp, wn, wb, wr, wq, wk,
    // Black pieces
    input wire [63:0] bp, bn, bb, br, bq, bk,
    // Evaluation score
    output wire signed [15:0] material_score
);
    // Weights: P=100, N/B=300, R=500, Q=900
    // Using $countones() for high-speed bit counting mapping to parallel adder trees in synthesis
    
    // Calculate total score for white
    wire signed [15:0] white_score;
    assign white_score = ($countones(wp) * 16'd100) +
                         ($countones(wn) * 16'd300) +
                         ($countones(wb) * 16'd300) +
                         ($countones(wr) * 16'd500) +
                         ($countones(wq) * 16'd900);
                         // King value generally excluded for material edge, or set to an arbitrarily high value.

    // Calculate total score for black
    wire signed [15:0] black_score;
    assign black_score = ($countones(bp) * 16'd100) +
                         ($countones(bn) * 16'd300) +
                         ($countones(bb) * 16'd300) +
                         ($countones(br) * 16'd500) +
                         ($countones(bq) * 16'd900);

    // Final Material Evaluation (+ for white edge, - for black edge)
    assign material_score = white_score - black_score;

endmodule
