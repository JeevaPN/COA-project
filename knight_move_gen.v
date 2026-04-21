module knight_move_gen(
    input wire [63:0] knight_pos, // Bitboard with 1s at knight locations
    input wire [63:0] own_pieces, // Bitboard of own pieces to prevent capture
    output wire [63:0] possible_moves
);
    // File masks to prevent wrapping across the board
    // A file: 0000000100000001... -> Not A: 11111110...
    wire [63:0] not_a  = 64'hFEFEFEFEFEFEFEFE;
    wire [63:0] not_ab = 64'hFCFCFCFCFCFCFCFC;
    wire [63:0] not_h  = 64'h7F7F7F7F7F7F7F7F;
    wire [63:0] not_gh = 64'h3F3F3F3F3F3F3F3F;

    // Combinational shifts for all 8 possible knight moves
    // North-North-East (+17), North-East-East (+10), South-East-East (-6), South-South-East (-15)
    // North-North-West (+15), North-West-West (+6), South-West-West (-10), South-South-West (-17)
    wire [63:0] moves = ((knight_pos << 17) & not_a)  |
                        ((knight_pos << 10) & not_ab) |
                        ((knight_pos >>  6) & not_ab) |
                        ((knight_pos >> 15) & not_a)  |
                        ((knight_pos << 15) & not_h)  |
                        ((knight_pos <<  6) & not_gh) |
                        ((knight_pos >> 10) & not_gh) |
                        ((knight_pos >> 17) & not_h);

    // Filter out moves that land on own pieces
    assign possible_moves = moves & ~own_pieces;

endmodule
