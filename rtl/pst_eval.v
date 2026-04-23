module pst_eval (
    // White pieces
    input wire [63:0] wp, wn, wb, wr, wq, wk,
    // Black pieces
    input wire [63:0] bp, bn, bb, br, bq, bk,
    // Positional Score Output (+ for white advantage, - for black advantage)
    output reg signed [15:0] pst_score
);

    // -------------------------------------------------------------------------
    // PIECE-SQUARE TABLES (PST) - Combinational LUTs
    // -------------------------------------------------------------------------
    // These arrays define the positional bonus/penalty for a piece on each of the 64 squares.
    // Index 0 = A1, Index 7 = H1, Index 56 = A8, Index 63 = H8.
    // Values are roughly based on standard chess engine heuristics (e.g., PeSTO's evaluation).

    // KNIGHT PST: Knights are terrible on the edges/corners, strong in the center.
    integer knight_pst[0:63];
    initial begin
        // Rank 1 (Indexes 0-7)
        knight_pst[0]=-50; knight_pst[1]=-40; knight_pst[2]=-30; knight_pst[3]=-30; knight_pst[4]=-30; knight_pst[5]=-30; knight_pst[6]=-40; knight_pst[7]=-50;
        // Rank 2 (Indexes 8-15)
        knight_pst[8]=-40; knight_pst[9]=-20; knight_pst[10]=  0; knight_pst[11]=  0; knight_pst[12]=  0; knight_pst[13]=  0; knight_pst[14]=-20; knight_pst[15]=-40;
        // Rank 3 (Indexes 16-23)
        knight_pst[16]=-30; knight_pst[17]=  0; knight_pst[18]= 10; knight_pst[19]= 15; knight_pst[20]= 15; knight_pst[21]= 10; knight_pst[22]=  0; knight_pst[23]=-30;
        // Rank 4 (Indexes 24-31)
        knight_pst[24]=-30; knight_pst[25]=  5; knight_pst[26]= 15; knight_pst[27]= 20; knight_pst[28]= 20; knight_pst[29]= 15; knight_pst[30]=  5; knight_pst[31]=-30;
        // Rank 5 (Indexes 32-39)
        knight_pst[32]=-30; knight_pst[33]=  0; knight_pst[34]= 15; knight_pst[35]= 20; knight_pst[36]= 20; knight_pst[37]= 15; knight_pst[38]=  0; knight_pst[39]=-30;
        // Rank 6 (Indexes 40-47)
        knight_pst[40]=-30; knight_pst[41]=  5; knight_pst[42]= 10; knight_pst[43]= 15; knight_pst[44]= 15; knight_pst[45]= 10; knight_pst[46]=  5; knight_pst[47]=-30;
        // Rank 7 (Indexes 48-55)
        knight_pst[48]=-40; knight_pst[49]=-20; knight_pst[50]=  0; knight_pst[51]=  5; knight_pst[52]=  5; knight_pst[53]=  0; knight_pst[54]=-20; knight_pst[55]=-40;
        // Rank 8 (Indexes 56-63)
        knight_pst[56]=-50; knight_pst[57]=-40; knight_pst[58]=-30; knight_pst[59]=-30; knight_pst[60]=-30; knight_pst[61]=-30; knight_pst[62]=-40; knight_pst[63]=-50;
    end

    // PAWN PST: Pawns want to advance toward promotion.
    integer pawn_pst[0:63];
    initial begin
        // Ranks 1 to 8 
        /* R1 */ pawn_pst[0]=  0; pawn_pst[1]=  0; pawn_pst[2]=  0; pawn_pst[3]=  0; pawn_pst[4]=  0; pawn_pst[5]=  0; pawn_pst[6]=  0; pawn_pst[7]=  0;
        /* R2 */ pawn_pst[8]=  5; pawn_pst[9]= 10; pawn_pst[10]= 10; pawn_pst[11]=-20; pawn_pst[12]=-20; pawn_pst[13]= 10; pawn_pst[14]= 10; pawn_pst[15]=  5;
        /* R3 */ pawn_pst[16]=  5; pawn_pst[17]=-5; pawn_pst[18]=-10; pawn_pst[19]=  0; pawn_pst[20]=  0; pawn_pst[21]=-10; pawn_pst[22]= -5; pawn_pst[23]=  5;
        /* R4 */ pawn_pst[24]=  0; pawn_pst[25]=  0; pawn_pst[26]=  0; pawn_pst[27]= 20; pawn_pst[28]= 20; pawn_pst[29]=  0; pawn_pst[30]=  0; pawn_pst[31]=  0;
        /* R5 */ pawn_pst[32]=  5; pawn_pst[33]=  5; pawn_pst[34]= 10; pawn_pst[35]= 25; pawn_pst[36]= 25; pawn_pst[37]= 10; pawn_pst[38]=  5; pawn_pst[39]=  5;
        /* R6 */ pawn_pst[40]= 10; pawn_pst[41]= 10; pawn_pst[42]= 20; pawn_pst[43]= 30; pawn_pst[44]= 30; pawn_pst[45]= 20; pawn_pst[46]= 10; pawn_pst[47]= 10;
        /* R7 */ pawn_pst[48]= 50; pawn_pst[49]= 50; pawn_pst[50]= 50; pawn_pst[51]= 50; pawn_pst[52]= 50; pawn_pst[53]= 50; pawn_pst[54]= 50; pawn_pst[55]= 50;
        /* R8 */ pawn_pst[56]=  0; pawn_pst[57]=  0; pawn_pst[58]=  0; pawn_pst[59]=  0; pawn_pst[60]=  0; pawn_pst[61]=  0; pawn_pst[62]=  0; pawn_pst[63]=  0;
    end

    // -------------------------------------------------------------------------
    // PARALLEL COMBINATIONAL ADDER TREE
    // -------------------------------------------------------------------------
    // In hardware synthesis, this `for` loop in an `always @*` block is fully 
    // unrolled by the synthesizer into a massive, 1-cycle Parallel Adder Tree.
    // It maps directly to FPGA LUTs (Look-Up Tables) and Adders without using any clock cycles.

    integer i;
    integer temp_score;

    always @* begin
        temp_score = 0;

        for (i = 0; i < 64; i = i + 1) begin
            // --- WHITE PIECES (Add to score) ---
            if (wn[i]) temp_score = temp_score + knight_pst[i];
            if (wp[i]) temp_score = temp_score + pawn_pst[i];
            // Provide a flip logic for remaining pieces as needed...
            
            // --- BLACK PIECES (Subtract from score) ---
            // For black pieces, the board is mirrored vertically.
            // A black pawn on true rank 7 (index 48-55) is equivalent to a white pawn on rank 2.
            // We calculate the mirrored index: mirrored_i = (7 - (i / 8)) * 8 + (i % 8)
            if (bn[i]) temp_score = temp_score - knight_pst[(7 - (i / 8)) * 8 + (i % 8)];
            if (bp[i]) temp_score = temp_score - pawn_pst[(7 - (i / 8)) * 8 + (i % 8)];
        end

        pst_score = temp_score;
    end

endmodule