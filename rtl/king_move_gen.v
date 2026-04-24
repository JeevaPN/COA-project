module king_move_gen(
    input  wire [63:0] pos,
    input  wire [63:0] own,
    output wire [63:0] moves
);
    wire [63:0] not_a = 64'hFEFEFEFEFEFEFEFE;
    wire [63:0] not_h = 64'h7F7F7F7F7F7F7F7F;

    // Shift 1 step in all 8 directions. 
    // Mask files A/H to prevent wrap-around bugs.
    wire [63:0] up_down = (pos << 8) | (pos >> 8);
    wire [63:0] rights  = ((pos << 1) | (pos << 9) | (pos >> 7)) & not_a;
    wire [63:0] lefts   = ((pos >> 1) | (pos >> 9) | (pos << 7)) & not_h;

    assign moves = (up_down | rights | lefts) & ~own;

endmodule