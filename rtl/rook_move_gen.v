module rook_move_gen(
    input  wire [63:0] pos, own, opp,
    output reg  [63:0] moves
);
    wire [63:0] empty = ~(own | opp);
    reg  [63:0] n, s, e, w;
    integer i;

    // Use a combinational for-loop to shift up to 7 steps consecutively
    always @(*) begin
        n = pos; s = pos; e = pos; w = pos;
        moves = 0;
        
        for (i=0; i<7; i=i+1) begin
            // Shift 1 step. Add to available moves. Stop if not empty (clears the bit).
            n = (n << 8);                              moves = moves | n; n = n & empty;
            s = (s >> 8);                              moves = moves | s; s = s & empty;
            e = (e << 1) & 64'hFEFEFEFEFEFEFEFE;       moves = moves | e; e = e & empty;
            w = (w >> 1) & 64'h7F7F7F7F7F7F7F7F;       moves = moves | w; w = w & empty;
        end
        moves = moves & ~own; // Remove squares with own pieces
    end
endmodule