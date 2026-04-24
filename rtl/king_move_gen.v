module king_move_gen(
    input  wire [63:0] pos,
    input  wire [63:0] own,
    output wire [63:0] moves
);
    localparam [63:0] NOT_A = 64'hFEFEFEFEFEFEFEFE;
    localparam [63:0] NOT_H = 64'h7F7F7F7F7F7F7F7F;

    wire [63:0] up_down = (pos << 8) | (pos >> 8);
    wire [63:0] rights  = ((pos << 1) | (pos << 9) | (pos >> 7)) & NOT_A;
    wire [63:0] lefts   = ((pos >> 1) | (pos >> 9) | (pos << 7)) & NOT_H;

    assign moves = (up_down | rights | lefts) & ~own;
endmodule
