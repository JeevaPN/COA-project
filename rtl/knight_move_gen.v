module knight_move_gen(
    input  wire [63:0] knight_pos,
    input  wire [63:0] own_pieces,
    output wire [63:0] possible_moves
);
    localparam [63:0] NOT_A  = 64'hFEFEFEFEFEFEFEFE;
    localparam [63:0] NOT_AB = 64'hFCFCFCFCFCFCFCFC;
    localparam [63:0] NOT_H  = 64'h7F7F7F7F7F7F7F7F;
    localparam [63:0] NOT_GH = 64'h3F3F3F3F3F3F3F3F;

    wire [63:0] moves = ((knight_pos << 17) & NOT_A)  |
                        ((knight_pos << 10) & NOT_AB) |
                        ((knight_pos >>  6) & NOT_AB) |
                        ((knight_pos >> 15) & NOT_A)  |
                        ((knight_pos << 15) & NOT_H)  |
                        ((knight_pos <<  6) & NOT_GH) |
                        ((knight_pos >> 10) & NOT_GH) |
                        ((knight_pos >> 17) & NOT_H);

    assign possible_moves = moves & ~own_pieces;
endmodule
