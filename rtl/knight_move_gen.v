module knight_move_gen(
    input wire [63:0] knight_pos,
    input wire [63:0] own_pieces,
    output wire [63:0] possible_moves
);
    wire [63:0] not_a  = 64'hFEFEFEFEFEFEFEFE;
    wire [63:0] not_ab = 64'hFCFCFCFCFCFCFCFC;
    wire [63:0] not_h  = 64'h7F7F7F7F7F7F7F7F;
    wire [63:0] not_gh = 64'h3F3F3F3F3F3F3F3F;

    wire [63:0] moves = ((knight_pos << 17) & not_a)  |
                        ((knight_pos << 10) & not_ab) |
                        ((knight_pos >>  6) & not_ab) |
                        ((knight_pos >> 15) & not_a)  |
                        ((knight_pos << 15) & not_h)  |
                        ((knight_pos <<  6) & not_gh) |
                        ((knight_pos >> 10) & not_gh) |
                        ((knight_pos >> 17) & not_h);

    assign possible_moves = moves & ~own_pieces;

endmodule
