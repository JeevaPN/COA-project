module queen_move_gen(
    input wire [63:0] queen_pos,
    input wire [63:0] own_pieces,
    input wire [63:0] opp_pieces,
    output wire [63:0] possible_moves
);
    wire [63:0] rook_moves;
    wire [63:0] bishop_moves;

    rook_move_gen r_gen (
        .rook_pos(queen_pos),
        .own_pieces(own_pieces),
        .opp_pieces(opp_pieces),
        .possible_moves(rook_moves)
    );

    bishop_move_gen b_gen (
        .bishop_pos(queen_pos),
        .own_pieces(own_pieces),
        .opp_pieces(opp_pieces),
        .possible_moves(bishop_moves)
    );

    assign possible_moves = rook_moves | bishop_moves;

endmodule
