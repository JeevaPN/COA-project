module king_move_gen(
    input wire [63:0] king_pos,
    input wire [63:0] own_pieces,
    output wire [63:0] possible_moves
);
    wire [63:0] not_a = 64'hFEFEFEFEFEFEFEFE;
    wire [63:0] not_h = 64'h7F7F7F7F7F7F7F7F;

    wire [63:0] moves = ((king_pos << 8)) |
                        ((king_pos >> 8)) |
                        ((king_pos << 1) & not_a) |
                        ((king_pos >> 1) & not_h) |
                        ((king_pos << 9) & not_a) |
                        ((king_pos >> 7) & not_a) |
                        ((king_pos << 7) & not_h) |
                        ((king_pos >> 9) & not_h);

    assign possible_moves = moves & ~own_pieces;

endmodule
