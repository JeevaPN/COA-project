module rook_move_gen(
    input wire [63:0] rook_pos,
    input wire [63:0] own_pieces,
    input wire [63:0] opp_pieces,
    output wire [63:0] possible_moves
);
    wire [63:0] empty = ~(own_pieces | opp_pieces);
    wire [63:0] not_a = 64'hFEFEFEFEFEFEFEFE;
    wire [63:0] not_h = 64'h7F7F7F7F7F7F7F7F;

    // North (+8)
    wire [63:0] n1 = (rook_pos << 8);
    wire [63:0] n2 = (n1 & empty) << 8;
    wire [63:0] n3 = (n2 & empty) << 8;
    wire [63:0] n4 = (n3 & empty) << 8;
    wire [63:0] n5 = (n4 & empty) << 8;
    wire [63:0] n6 = (n5 & empty) << 8;
    wire [63:0] n7 = (n6 & empty) << 8;
    wire [63:0] north = n1 | n2 | n3 | n4 | n5 | n6 | n7;

    // South (-8)
    wire [63:0] s1 = (rook_pos >> 8);
    wire [63:0] s2 = (s1 & empty) >> 8;
    wire [63:0] s3 = (s2 & empty) >> 8;
    wire [63:0] s4 = (s3 & empty) >> 8;
    wire [63:0] s5 = (s4 & empty) >> 8;
    wire [63:0] s6 = (s5 & empty) >> 8;
    wire [63:0] s7 = (s6 & empty) >> 8;
    wire [63:0] south = s1 | s2 | s3 | s4 | s5 | s6 | s7;

    // East (+1)
    wire [63:0] e1 = (rook_pos << 1) & not_a;
    wire [63:0] e2 = ((e1 & empty) << 1) & not_a;
    wire [63:0] e3 = ((e2 & empty) << 1) & not_a;
    wire [63:0] e4 = ((e3 & empty) << 1) & not_a;
    wire [63:0] e5 = ((e4 & empty) << 1) & not_a;
    wire [63:0] e6 = ((e5 & empty) << 1) & not_a;
    wire [63:0] e7 = ((e6 & empty) << 1) & not_a;
    wire [63:0] east = e1 | e2 | e3 | e4 | e5 | e6 | e7;

    // West (-1)
    wire [63:0] w1 = (rook_pos >> 1) & not_h;
    wire [63:0] w2 = ((w1 & empty) >> 1) & not_h;
    wire [63:0] w3 = ((w2 & empty) >> 1) & not_h;
    wire [63:0] w4 = ((w3 & empty) >> 1) & not_h;
    wire [63:0] w5 = ((w4 & empty) >> 1) & not_h;
    wire [63:0] w6 = ((w5 & empty) >> 1) & not_h;
    wire [63:0] w7 = ((w6 & empty) >> 1) & not_h;
    wire [63:0] west = w1 | w2 | w3 | w4 | w5 | w6 | w7;

    assign possible_moves = (north | south | east | west) & ~own_pieces;

endmodule
