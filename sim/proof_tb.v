`timescale 1ns/1ps

// Proof testbench:
//   Compares material-only evaluator vs NN-based evaluator across test positions
//   where material is equal but the positions differ in quality.
//
//   Expected result: material_score stays ~constant, deep_score VARIES across
//   positions --> the NN distinguishes what the material evaluator cannot.

module proof_tb;

    // Weight/bias ROM loaded from trained .hex files
    reg signed [7:0]  weight_rom [0:32*768-1];
    reg signed [31:0] bias_rom   [0:31];

    // Clock & reset
    reg clk = 0;
    reg reset = 0;
    always #5 clk = ~clk;  // 100 MHz

    // MAC interface
    reg signed [7:0]  act_in;
    reg signed [7:0]  weight_in;
    reg signed [31:0] bias_in;
    reg start;
    reg last_element;
    wire signed [31:0] neuron_out;
    wire out_valid;

    nn_mac dut_mac (
        .clk(clk), .reset(reset),
        .start(start), .last_element(last_element),
        .act_in(act_in), .weight_in(weight_in), .bias(bias_in),
        .neuron_out(neuron_out), .out_valid(out_valid)
    );

    // Material eval interface
    reg [63:0] wp, wn, wb, wr, wq, wk;
    reg [63:0] bp, bn, bb, br, bq, bk;
    wire signed [15:0] material_score;
    material_eval dut_me (
        .wp(wp), .wn(wn), .wb(wb), .wr(wr), .wq(wq), .wk(wk),
        .bp(bp), .bn(bn), .bb(bb), .br(br), .bq(bq), .bk(bk),
        .material_score(material_score)
    );

    // Flat 768-bit activation vector for current position
    reg [767:0] act_vector;

    // Accumulated deep score = sum of 32 ReLU(hidden neuron) outputs
    reg signed [63:0] deep_score;

    integer n_idx;
    integer i_idx;

    task run_neuron(input integer neuron);
        integer k;
        begin
            bias_in = bias_rom[neuron];
            // Feed 768 activations
            for (k = 0; k < 768; k = k + 1) begin
                @(negedge clk);
                act_in    = act_vector[k] ? 8'sd1 : 8'sd0;
                weight_in = weight_rom[neuron*768 + k];
                start        = (k == 0);
                last_element = (k == 767);
            end
            // Wait one more clock for registered out_valid
            @(posedge clk);
            @(posedge clk);
            deep_score = deep_score + neuron_out;
        end
    endtask

    task eval_position(
        input [255*8-1:0] label,
        input [63:0] i_wp, input [63:0] i_wn, input [63:0] i_wb,
        input [63:0] i_wr, input [63:0] i_wq, input [63:0] i_wk,
        input [63:0] i_bp, input [63:0] i_bn, input [63:0] i_bb,
        input [63:0] i_br, input [63:0] i_bq, input [63:0] i_bk,
        input [767:0] flat
    );
        begin
            wp = i_wp; wn = i_wn; wb = i_wb; wr = i_wr; wq = i_wq; wk = i_wk;
            bp = i_bp; bn = i_bn; bb = i_bb; br = i_br; bq = i_bq; bk = i_bk;
            act_vector = flat;

            deep_score = 0;
            for (n_idx = 0; n_idx < 32; n_idx = n_idx + 1) begin
                run_neuron(n_idx);
            end
            #1;
            $display("POSITION: %0s", label);
            $display("  material_score = %0d", material_score);
            $display("  deep_score     = %0d", deep_score);
            $display("");
        end
    endtask

    initial begin
        $dumpfile("sim/proof.vcd");
        $dumpvars(0, proof_tb);

        // Load trained weights (paths relative to where vvp is run — repo root)
        $readmemh("weights/weights.mem", weight_rom);
        $readmemh("weights/biases.mem",  bias_rom);
        $display("Loaded %0d weights, %0d biases", 32*768, 32);

        // Reset
        reset = 1; start = 0; last_element = 0; act_in = 0; weight_in = 0; bias_in = 0;
        #20; reset = 0; #10;

        // ----- Position 1: starting position (material = 0, quiet) -----
        eval_position("start_position",
            64'h000000000000FF00, 64'h0000000000000042, 64'h0000000000000024,
            64'h0000000000000081, 64'h0000000000000008, 64'h0000000000000010,
            64'h00FF000000000000, 64'h4200000000000000, 64'h2400000000000000,
            64'h8100000000000000, 64'h0800000000000000, 64'h1000000000000000,
            768'h0000000000000000000000000000001000000000000000000800000000000000810000000000000024000000000000004200000000000000FF0000000000000000000000000010000000000000000800000000000000810000000000000024000000000000004200000000000000FF00);

        // ----- Position 2: passed pawn endgame (white pawn on a7, KvK) -----
        // White pawn a7 = square 48 -> bit 48 = 0x0001000000000000
        // White king h1 = square 7  -> 0x0000000000000080
        // Black king a1 = square 0  -> 0x0000000000000001
        eval_position("passed_pawn_a7",
            64'h0001000000000000, 64'h0, 64'h0, 64'h0, 64'h0, 64'h0000000000000080,
            64'h0,                64'h0, 64'h0, 64'h0, 64'h0, 64'h0000000000000001,
            // flat: wp bit 48 set, wk bit 7 set (offset 5*64+7=327), bk bit 0 set (offset 11*64+0=704)
            {{(768-705){1'b0}}, 1'b1, {(704-328){1'b0}}, 1'b1, {(327-49){1'b0}}, 1'b1, 48'b0});

        // ----- Position 3: bad knight vs centralized knight -----
        // White knight d4 = square 27 -> wn bit 27
        // Black knight h1 = square 7  -> bn bit 7   (h1 is a white square, terrible for black N)
        // White king a1 (sq 0), Black king h8 (sq 63)
        eval_position("bad_knight_black",
            64'h0, 64'h0000000008000000, 64'h0, 64'h0, 64'h0, 64'h0000000000000001,
            64'h0, 64'h0000000000000080, 64'h0, 64'h0, 64'h0, 64'h8000000000000000,
            // Build flat vector bit-wise for clarity: wn@27, wk@0, bn@64+7=71? NO.
            // offsets: wp=0, wn=1, wb=2, wr=3, wq=4, wk=5, bp=6, bn=7, bb=8, br=9, bq=10, bk=11
            // wn bit 27 -> flat bit 1*64+27 = 91
            // wk bit 0  -> flat bit 5*64+0  = 320
            // bn bit 7  -> flat bit 7*64+7  = 455
            // bk bit 63 -> flat bit 11*64+63 = 767
            {1'b1, {(767-456){1'b0}}, 1'b1, {(455-321){1'b0}}, 1'b1, {(320-92){1'b0}}, 1'b1, 91'b0});

        $display("=== Proof Complete ===");
        $display("If deep_score varies across positions while material_score is");
        $display("nearly constant, the NN is extracting positional features the");
        $display("material-only evaluator cannot see.");
        $finish;
    end

endmodule
