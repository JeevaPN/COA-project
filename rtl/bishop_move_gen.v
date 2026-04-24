module bishop_move_gen(
    input  wire [63:0] pos, own, opp,
    output reg  [63:0] moves
);
    wire [63:0] empty = ~(own | opp);
    reg  [63:0] ne, nw, se, sw;
    integer i;

    // Use a combinational for-loop to shift diagonally up to 7 steps consecutively
    always @(*) begin
        ne = pos; nw = pos; se = pos; sw = pos;
        moves = 0;
        
        for (i=0; i<7; i=i+1) begin
            // Shift 1 step. Add to available moves. Stop if not empty (masking the bit).
            ne = (ne << 9) & 64'hFEFEFEFEFEFEFEFE;  moves = moves | ne; ne = ne & empty;
            nw = (nw << 7) & 64'h7F7F7F7F7F7F7F7F;  moves = moves | nw; nw = nw & empty;
            se = (se >> 7) & 64'hFEFEFEFEFEFEFEFE;  moves = moves | se; se = se & empty;
            sw = (sw >> 9) & 64'h7F7F7F7F7F7F7F7F;  moves = moves | sw; sw = sw & empty;
        end
        moves = moves & ~own; // Remove squares with own pieces
    end
endmodule