module pawn_move_gen(
    input wire [63:0] pawn_pos,
    input wire [63:0] own_pieces,
    input wire [63:0] opp_pieces,
    input wire is_white,
    output wire [63:0] possible_moves
);
    wire [63:0] empty = ~(own_pieces | opp_pieces);
    wire [63:0] not_a = 64'hFEFEFEFEFEFEFEFE;
    wire [63:0] not_h = 64'h7F7F7F7F7F7F7F7F;

    // White pawns move up (<< 8)
    wire [63:0] w_single_push = (pawn_pos << 8) & empty;
    wire [63:0] w_double_push = ((w_single_push & 64'h00000000FF000000) << 8) & empty;
    wire [63:0] w_captures = (((pawn_pos << 7) & not_h) | ((pawn_pos << 9) & not_a)) & opp_pieces;
    wire [63:0] w_moves = w_single_push | w_double_push | w_captures;

    // Black pawns move down (>> 8)
    wire [63:0] b_single_push = (pawn_pos >> 8) & empty;
    wire [63:0] b_double_push = ((b_single_push & 64'h000000FF00000000) >> 8) & empty;
    wire [63:0] b_captures = (((pawn_pos >> 7) & not_a) | ((pawn_pos >> 9) & not_h)) & opp_pieces;
    wire [63:0] b_moves = b_single_push | b_double_push | b_captures;

    assign possible_moves = is_white ? w_moves : b_moves;

endmodule
