module knight_move_gen(
    input wire [63:0] knight_pos, // bitboard: 1s where knights sit
    input wire [63:0] own_pieces, // mask of friendly pieces (can't land there)
    output wire [63:0] possible_moves
);
    // Masks to avoid wrap-around when shifting bitboards across files
    // e.g. moves that would cross from file A to file H are masked off.
    wire [63:0] not_a  = 64'hFEFEFEFEFEFEFEFE;
    wire [63:0] not_ab = 64'hFCFCFCFCFCFCFCFC;
    wire [63:0] not_h  = 64'h7F7F7F7F7F7F7F7F;
    wire [63:0] not_gh = 64'h3F3F3F3F3F3F3F3F;

    // Generate all eight knight jumps with safe masking.
    // The numeric shifts correspond to movement on a 0..63 bitboard layout.
    wire [63:0] moves = ((knight_pos << 17) & not_a)  |
                        ((knight_pos << 10) & not_ab) |
                        ((knight_pos >>  6) & not_ab) |
                        ((knight_pos >> 15) & not_a)  |
                        ((knight_pos << 15) & not_h)  |
                        ((knight_pos <<  6) & not_gh) |
                        ((knight_pos >> 10) & not_gh) |
                        ((knight_pos >> 17) & not_h);

    // Remove any destinations occupied by our own pieces
    assign possible_moves = moves & ~own_pieces;

endmodule
