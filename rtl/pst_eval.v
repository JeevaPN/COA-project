module pst_eval (
    input wire [63:0] wp, wn, wb, wr, wq, wk,
    input wire [63:0] bp, bn, bb, br, bq, bk,
    output reg signed [15:0] pst_score
);

    integer knight_pst[0:63];
    initial begin
        knight_pst[0]=-50; knight_pst[1]=-40; knight_pst[2]=-30; knight_pst[3]=-30; knight_pst[4]=-30; knight_pst[5]=-30; knight_pst[6]=-40; knight_pst[7]=-50;
        knight_pst[8]=-40; knight_pst[9]=-20; knight_pst[10]=  0; knight_pst[11]=  0; knight_pst[12]=  0; knight_pst[13]=  0; knight_pst[14]=-20; knight_pst[15]=-40;
        knight_pst[16]=-30; knight_pst[17]=  0; knight_pst[18]= 10; knight_pst[19]= 15; knight_pst[20]= 15; knight_pst[21]= 10; knight_pst[22]=  0; knight_pst[23]=-30;
        knight_pst[24]=-30; knight_pst[25]=  5; knight_pst[26]= 15; knight_pst[27]= 20; knight_pst[28]= 20; knight_pst[29]= 15; knight_pst[30]=  5; knight_pst[31]=-30;
        knight_pst[32]=-30; knight_pst[33]=  0; knight_pst[34]= 15; knight_pst[35]= 20; knight_pst[36]= 20; knight_pst[37]= 15; knight_pst[38]=  0; knight_pst[39]=-30;
        knight_pst[40]=-30; knight_pst[41]=  5; knight_pst[42]= 10; knight_pst[43]= 15; knight_pst[44]= 15; knight_pst[45]= 10; knight_pst[46]=  5; knight_pst[47]=-30;
        knight_pst[48]=-40; knight_pst[49]=-20; knight_pst[50]=  0; knight_pst[51]=  5; knight_pst[52]=  5; knight_pst[53]=  0; knight_pst[54]=-20; knight_pst[55]=-40;
        knight_pst[56]=-50; knight_pst[57]=-40; knight_pst[58]=-30; knight_pst[59]=-30; knight_pst[60]=-30; knight_pst[61]=-30; knight_pst[62]=-40; knight_pst[63]=-50;
    end

    integer pawn_pst[0:63];
    initial begin
        pawn_pst[0]=  0; pawn_pst[1]=  0; pawn_pst[2]=  0; pawn_pst[3]=  0; pawn_pst[4]=  0; pawn_pst[5]=  0; pawn_pst[6]=  0; pawn_pst[7]=  0;
        pawn_pst[8]=  5; pawn_pst[9]= 10; pawn_pst[10]= 10; pawn_pst[11]=-20; pawn_pst[12]=-20; pawn_pst[13]= 10; pawn_pst[14]= 10; pawn_pst[15]=  5;
        pawn_pst[16]=  5; pawn_pst[17]=-5; pawn_pst[18]=-10; pawn_pst[19]=  0; pawn_pst[20]=  0; pawn_pst[21]=-10; pawn_pst[22]= -5; pawn_pst[23]=  5;
        pawn_pst[24]=  0; pawn_pst[25]=  0; pawn_pst[26]=  0; pawn_pst[27]= 20; pawn_pst[28]= 20; pawn_pst[29]=  0; pawn_pst[30]=  0; pawn_pst[31]=  0;
        pawn_pst[32]=  5; pawn_pst[33]=  5; pawn_pst[34]= 10; pawn_pst[35]= 25; pawn_pst[36]= 25; pawn_pst[37]= 10; pawn_pst[38]=  5; pawn_pst[39]=  5;
        pawn_pst[40]= 10; pawn_pst[41]= 10; pawn_pst[42]= 20; pawn_pst[43]= 30; pawn_pst[44]= 30; pawn_pst[45]= 20; pawn_pst[46]= 10; pawn_pst[47]= 10;
        pawn_pst[48]= 50; pawn_pst[49]= 50; pawn_pst[50]= 50; pawn_pst[51]= 50; pawn_pst[52]= 50; pawn_pst[53]= 50; pawn_pst[54]= 50; pawn_pst[55]= 50;
        pawn_pst[56]=  0; pawn_pst[57]=  0; pawn_pst[58]=  0; pawn_pst[59]=  0; pawn_pst[60]=  0; pawn_pst[61]=  0; pawn_pst[62]=  0; pawn_pst[63]=  0;
    end

    integer i;
    integer temp_score;

    always @* begin
        temp_score = 0;
        for (i = 0; i < 64; i = i + 1) begin
            if (wn[i]) temp_score = temp_score + knight_pst[i];
            if (wp[i]) temp_score = temp_score + pawn_pst[i];
            if (bn[i]) temp_score = temp_score - knight_pst[(7 - (i / 8)) * 8 + (i % 8)];
            if (bp[i]) temp_score = temp_score - pawn_pst[(7 - (i / 8)) * 8 + (i % 8)];
        end
        pst_score = temp_score;
    end

endmodule