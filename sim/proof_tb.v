`timescale 1ns/1ps
module proof_tb;
    reg signed [7:0]  weight_rom [0:32*768-1];
    reg signed [31:0] bias_rom   [0:31];
    reg clk = 0;
    reg reset = 0;
    always #5 clk = ~clk;
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
    reg [63:0] wp, wn, wb, wr, wq, wk;
    reg [63:0] bp, bn, bb, br, bq, bk;
    wire signed [15:0] material_score;
    material_eval dut_me (
        .wp(wp), .wn(wn), .wb(wb), .wr(wr), .wq(wq), .wk(wk),
        .bp(bp), .bn(bn), .bb(bb), .br(br), .bq(bq), .bk(bk),
        .material_score(material_score)
    );
    reg [767:0] act_vector;
    reg signed [63:0] deep_score;
    integer n_idx;
    integer i_idx;
    task run_neuron(input integer neuron);
        integer k;
        begin
            bias_in = bias_rom[neuron];
            for (k = 0; k < 768; k = k + 1) begin
                @(negedge clk);
                act_in    = act_vector[k] ? 8'sd1 : 8'sd0;
                weight_in = weight_rom[neuron*768 + k];
                start        = (k == 0);
                last_element = (k == 767);
            end
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
        $readmemh("weights/weights.mem", weight_rom);
        $readmemh("weights/biases.mem",  bias_rom);
        $display("Loaded %0d weights, %0d biases", 32*768, 32);
        reset = 1; start = 0; last_element = 0; act_in = 0; weight_in = 0; bias_in = 0;
        #20; reset = 0; #10;
        eval_position("start_position",
            64'h000000000000FF00, 64'h0000000000000042, 64'h0000000000000024,
            64'h0000000000000081, 64'h0000000000000008, 64'h0000000000000010,
            64'h00FF000000000000, 64'h4200000000000000, 64'h2400000000000000,
            64'h8100000000000000, 64'h0800000000000000, 64'h1000000000000000,
            768'h0000000000000000000000000000001000000000000000000800000000000000810000000000000024000000000000004200000000000000FF0000000000000000000000000010000000000000000800000000000000810000000000000024000000000000004200000000000000FF00);
        eval_position("passed_pawn_a7",
            64'h0001000000000000, 64'h0, 64'h0, 64'h0, 64'h0, 64'h0000000000000080,
            64'h0,                64'h0, 64'h0, 64'h0, 64'h0, 64'h0000000000000001,
            {{(768-705){1'b0}}, 1'b1, {(704-328){1'b0}}, 1'b1, {(327-49){1'b0}}, 1'b1, 48'b0});
        eval_position("bad_knight_black",
            64'h0, 64'h0000000008000000, 64'h0, 64'h0, 64'h0, 64'h0000000000000001,
            64'h0, 64'h0000000000000080, 64'h0, 64'h0, 64'h0, 64'h8000000000000000,
            {1'b1, {(767-456){1'b0}}, 1'b1, {(455-321){1'b0}}, 1'b1, {(320-92){1'b0}}, 1'b1, 91'b0});
        $display("=== Proof Complete ===");
        $display("If deep_score varies while material_score stays similar, the NN");
        $display("is capturing positional features the material evaluator misses.");
        $finish;
    end
endmodule
