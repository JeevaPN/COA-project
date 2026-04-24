`timescale 1ns/1ps

module chess_tb;
    reg [63:0] wp, wn, wb, wr, wq, wk;
    reg [63:0] bp, bn, bb, br, bq, bk;
    reg [63:0] own_pieces;

    wire [63:0] possible_knight_moves;
    wire signed [15:0] material_score;

    knight_move_gen kmg (
        .knight_pos(wn),
        .own_pieces(own_pieces),
        .possible_moves(possible_knight_moves)
    );

    material_eval me (
        .wp(wp), .wn(wn), .wb(wb), .wr(wr), .wq(wq), .wk(wk),
        .bp(bp), .bn(bn), .bb(bb), .br(br), .bq(bq), .bk(bk),
        .material_score(material_score)
    );

    task display_board;
        integer r, f;
        reg [63:0] mask;
        reg [7:0]  c;
        begin
            $display("   A B C D E F G H");
            $display("  -----------------");
            for (r = 7; r >= 0; r = r - 1) begin
                $write("%0d |", r + 1);
                for (f = 0; f < 8; f = f + 1) begin
                    mask = 64'b1 << (r * 8 + f);
                    c = ".";
                    if      (wp & mask) c = "P";
                    else if (wn & mask) c = "N";
                    else if (wb & mask) c = "B";
                    else if (wr & mask) c = "R";
                    else if (wq & mask) c = "Q";
                    else if (wk & mask) c = "K";
                    else if (bp & mask) c = "p";
                    else if (bn & mask) c = "n";
                    else if (bb & mask) c = "b";
                    else if (br & mask) c = "r";
                    else if (bq & mask) c = "q";
                    else if (bk & mask) c = "k";
                    $write("%c ", c);
                end
                $display("| %0d", r + 1);
            end
            $display("  -----------------");
            $display("   A B C D E F G H\n");
        end
    endtask

    initial begin
        $dumpfile("chess.vcd");
        $dumpvars(0, chess_tb);

        wp = 64'h000000000000FF00;
        wn = 64'h0000000000000042;
        wb = 64'h0000000000000024;
        wr = 64'h0000000000000081;
        wq = 64'h0000000000000008;
        wk = 64'h0000000000000010;

        bp = 64'h00FF000000000000;
        bn = 64'h4200000000000000;
        bb = 64'h2400000000000000;
        br = 64'h8100000000000000;
        bq = 64'h0800000000000000;
        bk = 64'h1000000000000000;

        own_pieces = wp | wn | wb | wr | wq | wk;

        $display("======= Initial State =======");
        display_board();
        #10;
        $display("Material Score: %0d", material_score);
        $display("Knight Moves Bitboard: %h", possible_knight_moves);

        wn = (wn & ~64'h0000000000000040) | 64'h0000000000200000;
        own_pieces = wp | wn | wb | wr | wq | wk;

        $display("\n======= After 1. Nf3 =======");
        display_board();
        #10;
        $display("Material Score: %0d", material_score);
        $display("Knight Moves Bitboard: %h\n", possible_knight_moves);

        $finish;
    end
endmodule
