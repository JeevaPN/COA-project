module pawn_move_gen(
    input  wire [63:0] pos, own, opp,
    input  wire        is_white,
    output wire [63:0] moves
);
    localparam [63:0] NOT_A  = 64'hFEFEFEFEFEFEFEFE;
    localparam [63:0] NOT_H  = 64'h7F7F7F7F7F7F7F7F;
    localparam [63:0] RANK_3 = 64'h0000000000FF0000;
    localparam [63:0] RANK_6 = 64'h0000FF0000000000;

    wire [63:0] empty = ~(own | opp);

    wire [63:0] w_up1  = (pos << 8) & empty;
    wire [63:0] w_up2  = ((w_up1 & RANK_3) << 8) & empty;
    wire [63:0] w_caps = (((pos << 7) & NOT_H) | ((pos << 9) & NOT_A)) & opp;

    wire [63:0] b_dn1  = (pos >> 8) & empty;
    wire [63:0] b_dn2  = ((b_dn1 & RANK_6) >> 8) & empty;
    wire [63:0] b_caps = (((pos >> 7) & NOT_A) | ((pos >> 9) & NOT_H)) & opp;

    assign moves = is_white ? (w_up1 | w_up2 | w_caps) : (b_dn1 | b_dn2 | b_caps);
endmodule
