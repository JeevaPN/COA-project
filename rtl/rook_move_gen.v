module rook_move_gen(
    input  wire [63:0] pos, own, opp,
    output reg  [63:0] moves
);
    localparam [63:0] NOT_A = 64'hFEFEFEFEFEFEFEFE;
    localparam [63:0] NOT_H = 64'h7F7F7F7F7F7F7F7F;

    wire [63:0] empty = ~(own | opp);
    reg  [63:0] n, s, e, w;
    integer i;

    always @* begin
        n = pos; s = pos; e = pos; w = pos;
        moves = 0;
        for (i = 0; i < 7; i = i + 1) begin
            n = (n << 8);         moves = moves | n; n = n & empty;
            s = (s >> 8);         moves = moves | s; s = s & empty;
            e = (e << 1) & NOT_A; moves = moves | e; e = e & empty;
            w = (w >> 1) & NOT_H; moves = moves | w; w = w & empty;
        end
        moves = moves & ~own;
    end
endmodule
