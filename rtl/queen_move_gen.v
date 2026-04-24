module queen_move_gen(
    input  wire [63:0] pos, own, opp,
    output wire [63:0] moves
);
    wire [63:0] rook_moves;
    wire [63:0] bishop_moves;

    // A Queen operates as a combination of a Rook and a Bishop
    rook_move_gen r_gen (
        .pos(pos), .own(own), .opp(opp), .moves(rook_moves)
    );

    bishop_move_gen b_gen (
        .pos(pos), .own(own), .opp(opp), .moves(bishop_moves)
    );

    assign moves = rook_moves | bishop_moves;

endmodule