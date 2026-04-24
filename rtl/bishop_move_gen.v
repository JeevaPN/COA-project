module bishop_move_gen(
    input wire [63:0] bishop_pos,
    input wire [63:0] own_pieces,
    input wire [63:0] opp_pieces,
    output wire [63:0] possible_moves
);
    wire [63:0] empty = ~(own_pieces | opp_pieces);
    wire [63:0] not_a = 64'hFEFEFEFEFEFEFEFE;
    wire [63:0] not_h = 64'h7F7F7F7F7F7F7F7F;

    // North-East (+9)
    wire [63:0] ne1 = (bishop_pos << 9) & not_a;
    wire [63:0] ne2 = ((ne1 & empty) << 9) & not_a;
    wire [63:0] ne3 = ((ne2 & empty) << 9) & not_a;
    wire [63:0] ne4 = ((ne3 & empty) << 9) & not_a;
    wire [63:0] ne5 = ((ne4 & empty) << 9) & not_a;
    wire [63:0] ne6 = ((ne5 & empty) << 9) & not_a;
    wire [63:0] ne7 = ((ne6 & empty) << 9) & not_a;
    wire [63:0] ne = ne1 | ne2 | ne3 | ne4 | ne5 | ne6 | ne7;

    // North-West (+7)
    wire [63:0] nw1 = (bishop_pos << 7) & not_h;
    wire [63:0] nw2 = ((nw1 & empty) << 7) & not_h;
    wire [63:0] nw3 = ((nw2 & empty) << 7) & not_h;
    wire [63:0] nw4 = ((nw3 & empty) << 7) & not_h;
    wire [63:0] nw5 = ((nw4 & empty) << 7) & not_h;
    wire [63:0] nw6 = ((nw5 & empty) << 7) & not_h;
    wire [63:0] nw7 = ((nw6 & empty) << 7) & not_h;
    wire [63:0] nw = nw1 | nw2 | nw3 | nw4 | nw5 | nw6 | nw7;

    // South-East (-7)
    wire [63:0] se1 = (bishop_pos >> 7) & not_a;
    wire [63:0] se2 = ((se1 & empty) >> 7) & not_a;
    wire [63:0] se3 = ((se2 & empty) >> 7) & not_a;
    wire [63:0] se4 = ((se3 & empty) >> 7) & not_a;
    wire [63:0] se5 = ((se4 & empty) >> 7) & not_a;
    wire [63:0] se6 = ((se5 & empty) >> 7) & not_a;
    wire [63:0] se7 = ((se6 & empty) >> 7) & not_a;
    wire [63:0] se = se1 | se2 | se3 | se4 | se5 | se6 | se7;

    // South-West (-9)
    wire [63:0] sw1 = (bishop_pos >> 9) & not_h;
    wire [63:0] sw2 = ((sw1 & empty) >> 9) & not_h;
    wire [63:0] sw3 = ((sw2 & empty) >> 9) & not_h;
    wire [63:0] sw4 = ((sw3 & empty) >> 9) & not_h;
    wire [63:0] sw5 = ((sw4 & empty) >> 9) & not_h;
    wire [63:0] sw6 = ((sw5 & empty) >> 9) & not_h;
    wire [63:0] sw7 = ((sw6 & empty) >> 9) & not_h;
    wire [63:0] sw = sw1 | sw2 | sw3 | sw4 | sw5 | sw6 | sw7;

    assign possible_moves = (ne | nw | se | sw) & ~own_pieces;

endmodule
