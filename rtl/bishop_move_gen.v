module bishop_move_gen(
    input  wire [63:0] pos, own, opp,
    output reg  [63:0] moves
);
    localparam [63:0] NOT_A = 64'hFEFEFEFEFEFEFEFE;
    localparam [63:0] NOT_H = 64'h7F7F7F7F7F7F7F7F;

    wire [63:0] empty = ~(own | opp);
    reg  [63:0] ne, nw, se, sw;
    integer i;

    always @* begin
        ne = pos; nw = pos; se = pos; sw = pos;
        moves = 0;
        for (i = 0; i < 7; i = i + 1) begin
            ne = (ne << 9) & NOT_A; moves = moves | ne; ne = ne & empty;
            nw = (nw << 7) & NOT_H; moves = moves | nw; nw = nw & empty;
            se = (se >> 7) & NOT_A; moves = moves | se; se = se & empty;
            sw = (sw >> 9) & NOT_H; moves = moves | sw; sw = sw & empty;
        end
        moves = moves & ~own;
    end
endmodule
