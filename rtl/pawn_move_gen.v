module pawn_move_gen(
    input  wire [63:0] pos, own, opp,
    input  wire is_white,
    output wire [63:0] moves
);
    wire [63:0] empty = ~(own | opp);
    wire [63:0] not_a = 64'hFEFEFEFEFEFEFEFE;
    wire [63:0] not_h = 64'h7F7F7F7F7F7F7F7F;

    // --- WHITE PAWNS (Move Upwards: << 8) ---
    wire [63:0] w_up1   = (pos << 8) & empty;
    wire [63:0] w_up2   = ((w_up1 & 64'h00000000FF000000) << 8) & empty; // Double step from rank 2
    wire [63:0] w_caps  = (((pos << 7) & not_h) | ((pos << 9) & not_a)) & opp; // Diagonal captures

    // --- BLACK PAWNS (Move Downwards: >> 8) ---
    wire [63:0] b_dn1   = (pos >> 8) & empty;
    wire [63:0] b_dn2   = ((b_dn1 & 64'h000000FF00000000) >> 8) & empty; // Double step from rank 7
    wire [63:0] b_caps  = (((pos >> 7) & not_a) | ((pos >> 9) & not_h)) & opp; // Diagonal captures

    assign moves = is_white ? (w_up1 | w_up2 | w_caps) : (b_dn1 | b_dn2 | b_caps);

endmodule