`timescale 1ns/1ps

module chess_tb;
    
    // Testbench Variables for Bitboards
    reg [63:0] wp, wn, wb, wr, wq, wk;
    reg [63:0] bp, bn, bb, br, bq, bk;
    reg [63:0] own_pieces;

    // Outputs
    wire [63:0] possible_knight_moves;
    wire signed [15:0] material_score;

    // Instantiate Knight Move Generator
    knight_move_gen kmg (
        .knight_pos(wn),       // White knights
        .own_pieces(own_pieces), // Own pieces bitboard to avoid capturing own team
        .possible_moves(possible_knight_moves)
    );

    // Instantiate Material Evaluation Engine
    material_eval me (
        // White pieces
        .wp(wp), .wn(wn), .wb(wb), .wr(wr), .wq(wq), .wk(wk),
        // Black pieces
        .bp(bp), .bn(bn), .bb(bb), .br(br), .bq(bq), .bk(bk),
        // Output Score
        .material_score(material_score)
    );

    // ASCII Renderer Task
    task display_board;
        integer r, f;
        reg [63:0] square_mask;
        reg [7:0] piece_char;
        begin
            $display("   A B C D E F G H");
            $display("  -----------------");
            // Loop through ranks 8 down to 1
            for (r = 7; r >= 0; r = r - 1) begin
                $write("%0d |", r + 1);
                // Loop through files A to H
                for (f = 0; f < 8; f = f + 1) begin
                    square_mask = 64'b1 << (r * 8 + f);
                    piece_char = ".";

                    // Determine if any bitboard has a piece on this square
                    if      (wp & square_mask) piece_char = "P";
                    else if (wn & square_mask) piece_char = "N";
                    else if (wb & square_mask) piece_char = "B";
                    else if (wr & square_mask) piece_char = "R";
                    else if (wq & square_mask) piece_char = "Q";
                    else if (wk & square_mask) piece_char = "K";
                    else if (bp & square_mask) piece_char = "p";
                    else if (bn & square_mask) piece_char = "n";
                    else if (bb & square_mask) piece_char = "b";
                    else if (br & square_mask) piece_char = "r";
                    else if (bq & square_mask) piece_char = "q";
                    else if (bk & square_mask) piece_char = "k";
                    
                    $write("%c ", piece_char);
                end
                $display("| %0d", r + 1);
            end
            $display("  -----------------");
            $display("   A B C D E F G H\n");
        end
    endtask

    // Simulation Sequence
    initial begin
        $dumpfile("chess.vcd");
        $dumpvars(0, chess_tb);

        // Standard Starting Position Initialization
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

        // Populate white's own pieces mask
        own_pieces = wp | wn | wb | wr | wq | wk;

        $display("======= Initial State =======");
        display_board();
        #10;
        $display("Material Score: %0d (Positive=White Edge, Negative=Black Edge)", material_score);
        $display("Possible Knight Moves Bitboard: %h", possible_knight_moves);

        // Move a white knight to F3 (square 21) from G1 (square 6)
        wn = (wn & ~64'h0000000000000040) | 64'h0000000000200000;
        own_pieces = wp | wn | wb | wr | wq | wk;
        
        $display("\n======= After 1. Nf3 =======");
        display_board();
        #10;
        $display("Material Score: %0d", material_score);
        $display("Possible Knight Moves Bitboard: %h\n", possible_knight_moves);
        
        $finish;
    end
endmodule
