module make_move (
    input  wire [63:0] wp_in, wn_in, wb_in, wr_in, wq_in, wk_in,
    input  wire [63:0] bp_in, bn_in, bb_in, br_in, bq_in, bk_in,
    input  wire [63:0] from_mask, to_mask,
    input  wire [2:0]  piece_type,
    input  wire        white_to_move,
    output wire [63:0] wp_out, wn_out, wb_out, wr_out, wq_out, wk_out,
    output wire [63:0] bp_out, bn_out, bb_out, br_out, bq_out, bk_out
);
    function [63:0] update;
        input [63:0] board;
        input        mover;
        input        match;
        begin
            if (mover && match) update = (board & ~from_mask) | to_mask;
            else if (!mover)    update = board & ~to_mask;
            else                update = board;
        end
    endfunction

    wire w = white_to_move;
    wire b = ~white_to_move;

    assign wp_out = update(wp_in, w, piece_type == 3'd0);
    assign wn_out = update(wn_in, w, piece_type == 3'd1);
    assign wb_out = update(wb_in, w, piece_type == 3'd2);
    assign wr_out = update(wr_in, w, piece_type == 3'd3);
    assign wq_out = update(wq_in, w, piece_type == 3'd4);
    assign wk_out = update(wk_in, w, piece_type == 3'd5);

    assign bp_out = update(bp_in, b, piece_type == 3'd0);
    assign bn_out = update(bn_in, b, piece_type == 3'd1);
    assign bb_out = update(bb_in, b, piece_type == 3'd2);
    assign br_out = update(br_in, b, piece_type == 3'd3);
    assign bq_out = update(bq_in, b, piece_type == 3'd4);
    assign bk_out = update(bk_in, b, piece_type == 3'd5);
endmodule
