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

    reg clk = 0;
    reg reset = 0;
    always #5 clk = ~clk;

    reg signed [7:0]  weight_rom [0:32*768-1];
    reg signed [31:0] bias_rom   [0:31];

    reg signed [7:0]  act_in, weight_in;
    reg signed [31:0] bias_in;
    reg start, last_element;
    wire signed [31:0] neuron_out;
    wire out_valid;

    nn_mac dut_mac (
        .clk(clk), .reset(reset),
        .start(start), .last_element(last_element),
        .act_in(act_in), .weight_in(weight_in), .bias(bias_in),
        .neuron_out(neuron_out), .out_valid(out_valid)
    );

    reg [767:0] act_vector;
    reg signed [63:0] deep_score;
    reg signed [63:0] baseline_deep;
    integer n_idx;

    task run_neuron(input integer neuron);
        integer k;
        begin
            bias_in = bias_rom[neuron];
            for (k = 0; k < 768; k = k + 1) begin
                @(negedge clk);
                act_in       = act_vector[k] ? 8'sd1 : 8'sd0;
                weight_in    = weight_rom[neuron*768 + k];
                start        = (k == 0);
                last_element = (k == 767);
            end
            @(posedge clk);
            @(posedge clk);
            deep_score = deep_score + neuron_out;
        end
    endtask

    task eval_nn;
        begin
            act_vector = {bk, bq, br, bb, bn, bp, wk, wq, wr, wb, wn, wp};
            deep_score = 0;
            for (n_idx = 0; n_idx < 32; n_idx = n_idx + 1)
                run_neuron(n_idx);
        end
    endtask

    task display_board;
        integer r, f, b;
        integer eval_cp, abs_cp, filled;
        reg [63:0] mask;
        reg [7:0]  c;
        begin
            #1;
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
            $display("   A B C D E F G H");

            eval_nn;
            eval_cp = material_score + ((deep_score - baseline_deep) / 10);
            if (eval_cp >  500) eval_cp =  500;
            if (eval_cp < -500) eval_cp = -500;
            abs_cp = (eval_cp < 0) ? -eval_cp : eval_cp;
            filled = 10 + eval_cp / 25;
            if (filled < 0)  filled = 0;
            if (filled > 20) filled = 20;

            $write("Eval ");
            if (eval_cp < 0) $write("-%0d.%02d  [", abs_cp/100, abs_cp%100);
            else             $write("+%0d.%02d  [", abs_cp/100, abs_cp%100);
            for (b = 0; b < 20; b = b + 1)
                $write("%c", (b < filled) ? "#" : ".");
            $display("]   (Mat:%0d  NN:%0d)", material_score, deep_score - baseline_deep);
            $display("__PAUSE__");
        end
    endtask

    initial begin
        $dumpfile("chess.vcd");
        $dumpvars(0, chess_tb);

        $readmemh("weights/weights.mem", weight_rom);
        $readmemh("weights/biases.mem",  bias_rom);

        reset = 1; start = 0; last_element = 0;
        act_in = 0; weight_in = 0; bias_in = 0;
        #20; reset = 0; #10;

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

        eval_nn;
        baseline_deep = deep_score;

        $display("======= Initial State =======");
        display_board();

        // 1. c4
        wp = 64'h000000000400FB00; wn = 64'h0000000000000042; wb = 64'h0000000000000024; wr = 64'h0000000000000081; wq = 64'h0000000000000008; wk = 64'h0000000000000010;
        bp = 64'h00FF000000000000; bn = 64'h4200000000000000; bb = 64'h2400000000000000; br = 64'h8100000000000000; bq = 64'h0800000000000000; bk = 64'h1000000000000000;
        own_pieces = wp | wn | wb | wr | wq | wk;
        $display("\n======= After 1. c4 =======");
        display_board();

        // 1... c6
        wp = 64'h000000000400FB00; wn = 64'h0000000000000042; wb = 64'h0000000000000024; wr = 64'h0000000000000081; wq = 64'h0000000000000008; wk = 64'h0000000000000010;
        bp = 64'h00FB040000000000; bn = 64'h4200000000000000; bb = 64'h2400000000000000; br = 64'h8100000000000000; bq = 64'h0800000000000000; bk = 64'h1000000000000000;
        own_pieces = wp | wn | wb | wr | wq | wk;
        $display("\n======= After 1... c6 =======");
        display_board();

        // 2. Nf3
        wp = 64'h000000000400FB00; wn = 64'h0000000000200002; wb = 64'h0000000000000024; wr = 64'h0000000000000081; wq = 64'h0000000000000008; wk = 64'h0000000000000010;
        bp = 64'h00FB040000000000; bn = 64'h4200000000000000; bb = 64'h2400000000000000; br = 64'h8100000000000000; bq = 64'h0800000000000000; bk = 64'h1000000000000000;
        own_pieces = wp | wn | wb | wr | wq | wk;
        $display("\n======= After 2. Nf3 =======");
        display_board();

        // 2... d5
        wp = 64'h000000000400FB00; wn = 64'h0000000000200002; wb = 64'h0000000000000024; wr = 64'h0000000000000081; wq = 64'h0000000000000008; wk = 64'h0000000000000010;
        bp = 64'h00F3040800000000; bn = 64'h4200000000000000; bb = 64'h2400000000000000; br = 64'h8100000000000000; bq = 64'h0800000000000000; bk = 64'h1000000000000000;
        own_pieces = wp | wn | wb | wr | wq | wk;
        $display("\n======= After 2... d5 =======");
        display_board();

        // 3. g3
        wp = 64'h000000000440BB00; wn = 64'h0000000000200002; wb = 64'h0000000000000024; wr = 64'h0000000000000081; wq = 64'h0000000000000008; wk = 64'h0000000000000010;
        bp = 64'h00F3040800000000; bn = 64'h4200000000000000; bb = 64'h2400000000000000; br = 64'h8100000000000000; bq = 64'h0800000000000000; bk = 64'h1000000000000000;
        own_pieces = wp | wn | wb | wr | wq | wk;
        $display("\n======= After 3. g3 =======");
        display_board();

        // 3... Bg4
        wp = 64'h000000000440BB00; wn = 64'h0000000000200002; wb = 64'h0000000000000024; wr = 64'h0000000000000081; wq = 64'h0000000000000008; wk = 64'h0000000000000010;
        bp = 64'h00F3040800000000; bn = 64'h4200000000000000; bb = 64'h2000000040000000; br = 64'h8100000000000000; bq = 64'h0800000000000000; bk = 64'h1000000000000000;
        own_pieces = wp | wn | wb | wr | wq | wk;
        $display("\n======= After 3... Bg4 =======");
        display_board();

        // 4. Ne5
        wp = 64'h000000000440BB00; wn = 64'h0000001000000002; wb = 64'h0000000000000024; wr = 64'h0000000000000081; wq = 64'h0000000000000008; wk = 64'h0000000000000010;
        bp = 64'h00F3040800000000; bn = 64'h4200000000000000; bb = 64'h2000000040000000; br = 64'h8100000000000000; bq = 64'h0800000000000000; bk = 64'h1000000000000000;
        own_pieces = wp | wn | wb | wr | wq | wk;
        $display("\n======= After 4. Ne5 =======");
        display_board();

        // 4... Bf5
        wp = 64'h000000000440BB00; wn = 64'h0000001000000002; wb = 64'h0000000000000024; wr = 64'h0000000000000081; wq = 64'h0000000000000008; wk = 64'h0000000000000010;
        bp = 64'h00F3040800000000; bn = 64'h4200000000000000; bb = 64'h2000002000000000; br = 64'h8100000000000000; bq = 64'h0800000000000000; bk = 64'h1000000000000000;
        own_pieces = wp | wn | wb | wr | wq | wk;
        $display("\n======= After 4... Bf5 =======");
        display_board();

        // 5. Qb3
        wp = 64'h000000000440BB00; wn = 64'h0000001000000002; wb = 64'h0000000000000024; wr = 64'h0000000000000081; wq = 64'h0000000000020000; wk = 64'h0000000000000010;
        bp = 64'h00F3040800000000; bn = 64'h4200000000000000; bb = 64'h2000002000000000; br = 64'h8100000000000000; bq = 64'h0800000000000000; bk = 64'h1000000000000000;
        own_pieces = wp | wn | wb | wr | wq | wk;
        $display("\n======= After 5. Qb3 =======");
        display_board();

        // 5... Qb6
        wp = 64'h000000000440BB00; wn = 64'h0000001000000002; wb = 64'h0000000000000024; wr = 64'h0000000000000081; wq = 64'h0000000000020000; wk = 64'h0000000000000010;
        bp = 64'h00F3040800000000; bn = 64'h4200000000000000; bb = 64'h2000002000000000; br = 64'h8100000000000000; bq = 64'h0000020000000000; bk = 64'h1000000000000000;
        own_pieces = wp | wn | wb | wr | wq | wk;
        $display("\n======= After 5... Qb6 =======");
        display_board();

        // 6. cxd5
        wp = 64'h000000080040BB00; wn = 64'h0000001000000002; wb = 64'h0000000000000024; wr = 64'h0000000000000081; wq = 64'h0000000000020000; wk = 64'h0000000000000010;
        bp = 64'h00F3040000000000; bn = 64'h4200000000000000; bb = 64'h2000002000000000; br = 64'h8100000000000000; bq = 64'h0000020000000000; bk = 64'h1000000000000000;
        own_pieces = wp | wn | wb | wr | wq | wk;
        $display("\n======= After 6. cxd5 =======");
        display_board();

        // 6... Qxb3
        wp = 64'h000000080040BB00; wn = 64'h0000001000000002; wb = 64'h0000000000000024; wr = 64'h0000000000000081; wq = 64'h0000000000000000; wk = 64'h0000000000000010;
        bp = 64'h00F3040000000000; bn = 64'h4200000000000000; bb = 64'h2000002000000000; br = 64'h8100000000000000; bq = 64'h0000000000020000; bk = 64'h1000000000000000;
        own_pieces = wp | wn | wb | wr | wq | wk;
        $display("\n======= After 6... Qxb3 =======");
        display_board();

        // 7. axb3
        wp = 64'h000000080042BA00; wn = 64'h0000001000000002; wb = 64'h0000000000000024; wr = 64'h0000000000000081; wq = 64'h0000000000000000; wk = 64'h0000000000000010;
        bp = 64'h00F3040000000000; bn = 64'h4200000000000000; bb = 64'h2000002000000000; br = 64'h8100000000000000; bq = 64'h0000000000000000; bk = 64'h1000000000000000;
        own_pieces = wp | wn | wb | wr | wq | wk;
        $display("\n======= After 7. axb3 =======");
        display_board();

        // 7... Be4
        wp = 64'h000000080042BA00; wn = 64'h0000001000000002; wb = 64'h0000000000000024; wr = 64'h0000000000000081; wq = 64'h0000000000000000; wk = 64'h0000000000000010;
        bp = 64'h00F3040000000000; bn = 64'h4200000000000000; bb = 64'h2000000010000000; br = 64'h8100000000000000; bq = 64'h0000000000000000; bk = 64'h1000000000000000;
        own_pieces = wp | wn | wb | wr | wq | wk;
        $display("\n======= After 7... Be4 =======");
        display_board();

        // 8. dxc6
        wp = 64'h000004000042BA00; wn = 64'h0000001000000002; wb = 64'h0000000000000024; wr = 64'h0000000000000081; wq = 64'h0000000000000000; wk = 64'h0000000000000010;
        bp = 64'h00F3000000000000; bn = 64'h4200000000000000; bb = 64'h2000000010000000; br = 64'h8100000000000000; bq = 64'h0000000000000000; bk = 64'h1000000000000000;
        own_pieces = wp | wn | wb | wr | wq | wk;
        $display("\n======= After 8. dxc6 =======");
        display_board();

        // 8... Bxh1
        wp = 64'h000004000042BA00; wn = 64'h0000001000000002; wb = 64'h0000000000000024; wr = 64'h0000000000000001; wq = 64'h0000000000000000; wk = 64'h0000000000000010;
        bp = 64'h00F3000000000000; bn = 64'h4200000000000000; bb = 64'h2000000000000080; br = 64'h8100000000000000; bq = 64'h0000000000000000; bk = 64'h1000000000000000;
        own_pieces = wp | wn | wb | wr | wq | wk;
        $display("\n======= After 8... Bxh1 =======");
        display_board();

        // 9. Rxa7
        wp = 64'h000004000042BA00; wn = 64'h0000001000000002; wb = 64'h0000000000000024; wr = 64'h0001000000000000; wq = 64'h0000000000000000; wk = 64'h0000000000000010;
        bp = 64'h00F2000000000000; bn = 64'h4200000000000000; bb = 64'h2000000000000080; br = 64'h8100000000000000; bq = 64'h0000000000000000; bk = 64'h1000000000000000;
        own_pieces = wp | wn | wb | wr | wq | wk;
        $display("\n======= After 9. Rxa7 =======");
        display_board();

        $finish;
    end
endmodule
