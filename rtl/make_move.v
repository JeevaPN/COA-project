module make_move (
    // Current board state (Inputs)
    input wire [63:0] wp_in, wn_in, wb_in, wr_in, wq_in, wk_in,
    input wire [63:0] bp_in, bn_in, bb_in, br_in, bq_in, bk_in,
    
    // Move parameters
    input wire [63:0] from_mask, // 64-bit one-hot mask of the starting square
    input wire [63:0] to_mask,   // 64-bit one-hot mask of the destination square
    input wire [2:0] piece_type, // 0=Pawn, 1=Knight, 2=Bishop, 3=Rook, 4=Queen, 5=King
    input wire white_to_move,    // 1 if White is moving, 0 if Black is moving
    
    // Next board state (Outputs)
    output wire [63:0] wp_out, wn_out, wb_out, wr_out, wq_out, wk_out,
    output wire [63:0] bp_out, bn_out, bb_out, br_out, bq_out, bk_out
);

    // ------------------------------------------------------------------------
    // INTERMEDIATE SIGNALS FOR FRIENDLY PIECE MOVEMENT
    // ------------------------------------------------------------------------
    // These compute the new bitboard for the piece making the move
    wire [63:0] wp_moved = (wp_in & ~from_mask) | to_mask;
    wire [63:0] wn_moved = (wn_in & ~from_mask) | to_mask;
    wire [63:0] wb_moved = (wb_in & ~from_mask) | to_mask;
    wire [63:0] wr_moved = (wr_in & ~from_mask) | to_mask;
    wire [63:0] wq_moved = (wq_in & ~from_mask) | to_mask;
    wire [63:0] wk_moved = (wk_in & ~from_mask) | to_mask;

    wire [63:0] bp_moved = (bp_in & ~from_mask) | to_mask;
    wire [63:0] bn_moved = (bn_in & ~from_mask) | to_mask;
    wire [63:0] bb_moved = (bb_in & ~from_mask) | to_mask;
    wire [63:0] br_moved = (br_in & ~from_mask) | to_mask;
    wire [63:0] bq_moved = (bq_in & ~from_mask) | to_mask;
    wire [63:0] bk_moved = (bk_in & ~from_mask) | to_mask;

    // ------------------------------------------------------------------------
    // INTERMEDIATE SIGNALS FOR CAPTURES (ENEMY PIECES)
    // ------------------------------------------------------------------------
    // Note: If no piece was on to_mask, this safely does nothing.
    wire [63:0] wp_capt = wp_in & ~to_mask;
    wire [63:0] wn_capt = wn_in & ~to_mask;
    wire [63:0] wb_capt = wb_in & ~to_mask;
    wire [63:0] wr_capt = wr_in & ~to_mask;
    wire [63:0] wq_capt = wq_in & ~to_mask;
    wire [63:0] wk_capt = wk_in & ~to_mask;

    wire [63:0] bp_capt = bp_in & ~to_mask;
    wire [63:0] bn_capt = bn_in & ~to_mask;
    wire [63:0] bb_capt = bb_in & ~to_mask;
    wire [63:0] br_capt = br_in & ~to_mask;
    wire [63:0] bq_capt = bq_in & ~to_mask;
    wire [63:0] bk_capt = bk_in & ~to_mask;

    // ------------------------------------------------------------------------
    // OUTPUT ASSIGNMENTS (MUXING)
    // ------------------------------------------------------------------------
    // For each bitboard, it updates if it is the moving piece, 
    // clears the to_square if it belongs to the enemy (getting captured),
    // or remains unchanged.
    
    // Piece Types: P=0, N=1, B=2, R=3, Q=4, K=5

    assign wp_out = (white_to_move && piece_type == 3'd0) ? wp_moved : (!white_to_move ? wp_capt : wp_in);
    assign wn_out = (white_to_move && piece_type == 3'd1) ? wn_moved : (!white_to_move ? wn_capt : wn_in);
    assign wb_out = (white_to_move && piece_type == 3'd2) ? wb_moved : (!white_to_move ? wb_capt : wb_in);
    assign wr_out = (white_to_move && piece_type == 3'd3) ? wr_moved : (!white_to_move ? wr_capt : wr_in);
    assign wq_out = (white_to_move && piece_type == 3'd4) ? wq_moved : (!white_to_move ? wq_capt : wq_in);
    assign wk_out = (white_to_move && piece_type == 3'd5) ? wk_moved : (!white_to_move ? wk_capt : wk_in);

    assign bp_out = (!white_to_move && piece_type == 3'd0) ? bp_moved : (white_to_move ? bp_capt : bp_in);
    assign bn_out = (!white_to_move && piece_type == 3'd1) ? bn_moved : (white_to_move ? bn_capt : bn_in);
    assign bb_out = (!white_to_move && piece_type == 3'd2) ? bb_moved : (white_to_move ? bb_capt : bb_in);
    assign br_out = (!white_to_move && piece_type == 3'd3) ? br_moved : (white_to_move ? br_capt : br_in);
    assign bq_out = (!white_to_move && piece_type == 3'd4) ? bq_moved : (white_to_move ? bq_capt : bq_in);
    assign bk_out = (!white_to_move && piece_type == 3'd5) ? bk_moved : (white_to_move ? bk_capt : bk_in);

endmodule