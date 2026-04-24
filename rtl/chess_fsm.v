// High-level search finite-state machine
// Orchestrates quick move ordering (fast path) and the NN leaf evaluations
// Comments written in a conversational, human style for readability.
module chess_fsm (
    input wire clk,
    input wire reset,
    input wire start_search,
    input wire [3:0] target_depth, // e.g., Depth 8

    // Interfaces to Move Generator and Fast_Score (Combinational)
    // In a full design, we'd have wires connecting to knight_move_gen, pst_eval, etc.
    input wire [15:0] fast_score,
    // output reg trigger_move_gen,

    // Interfaces to NNUE Leaf Evaluator (Sequential)
    output reg nn_start,
    input wire nn_eval_ready,
    input wire signed [31:0] deep_score,

    // Search output
    output reg search_done,
    output reg signed [31:0] best_move_score
);

    // -------------------------------------------------------------------------
    // FSM state encoding (self-descriptive names)
    // -------------------------------------------------------------------------
    localparam STATE_IDLE             = 3'd0;
    localparam STATE_DESCEND_DECISION = 3'd1; // Use Fast_Score to sort & pick move (simulate Make Move)
    localparam STATE_CHECK_DEPTH      = 3'd2; // Are we at a leaf node?
    localparam STATE_LEAF_EVAL_START  = 3'd3; // Trigger NNUE
    localparam STATE_NNUE_WAIT        = 3'd4; // Wait 15+ cycles for the Deep_Score
    localparam STATE_BUBBLE_UP        = 3'd5; // Unmake move, Minimax compare

    reg [2:0] state, next_state;
    reg [3:0] current_depth;
    reg signed [31:0] current_alpha; // Best score found so far

    // -------------------------------------------------------------------------
    // Sequential logic: state transitions and main registers
    // The big always block below drives the search flow.
    // -------------------------------------------------------------------------
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= STATE_IDLE;
            current_depth <= 4'd0;
            current_alpha <= -32'd1000000; // -Infinity
            search_done <= 1'b0;
            nn_start <= 1'b0;
            best_move_score <= 0;
        end else begin
            case (state)
                
                // =========================================================
                // 1. IDLE - wait for an external "start search" request
                // =========================================================
                STATE_IDLE: begin
                    search_done <= 1'b0;
                    if (start_search) begin
                        state <= STATE_DESCEND_DECISION;
                        current_depth <= 4'd0;
                        current_alpha <= -32'd1000000;
                    end
                end

                // =========================================================
                // 2. DESCEND - pick a promising move using the fast heuristic
                // =========================================================
                STATE_DESCEND_DECISION: begin
                    // In a real design we'd sample material+pst (fast_score)
                    // to pick a move and apply it. Think of this as the
                    // lightweight move ordering that runs in one cycle.
                    current_depth <= current_depth + 1;
                    state <= STATE_CHECK_DEPTH;
                end

                // =========================================================
                // 3. DEPTH CHECK
                // =========================================================
                STATE_CHECK_DEPTH: begin
                    if (current_depth == target_depth) begin
                        // We hit the Leaf Node! Time to use the Heavy ML Engine
                        state <= STATE_LEAF_EVAL_START;
                    end else begin
                        // Keep traversing down the tree at 1 cycle per node
                        state <= STATE_DESCEND_DECISION;
                    end
                end

                // =========================================================
                // 4. Trigger the NN leaf evaluator (slow, but deep)
                // =========================================================
                STATE_LEAF_EVAL_START: begin
                    // Pulse the neural network accelerator to start work.
                    // The accelerator will assert `nn_eval_ready` when done.
                    nn_start <= 1'b1;
                    state <= STATE_NNUE_WAIT;
                end

                // =========================================================
                // 5. Wait for NN result and update our running best (alpha)
                // =========================================================
                STATE_NNUE_WAIT: begin
                    nn_start <= 1'b0; // De-assert start
                    // We literally pause the search tree and do nothing until the 
                    // Neural Network finishes its 15+ cycles of matrix multiplications.
                    if (nn_eval_ready) begin
                        // We got the Kaggle-trained Deep_Score!
                        // Compare it against our Alpha (Minimax Logic)
                        if (deep_score > current_alpha) begin
                            current_alpha <= deep_score;
                        end
                        state <= STATE_BUBBLE_UP;
                    end
                end

                // =========================================================
                // 6. Bubble up the result: undo the move and continue search
                // =========================================================
                STATE_BUBBLE_UP: begin
                    // Restore the board bitboards from 1 move ago (Unmake Move)
                    current_depth <= current_depth - 1;

                    if (current_depth == 4'd1) begin
                        // If we are back at the root, the search is fully complete
                        best_move_score <= current_alpha;
                        search_done <= 1'b1;
                        state <= STATE_IDLE;
                    end else begin
                        // We stepped back, now try the next sibling branch
                        state <= STATE_DESCEND_DECISION;
                    end
                end

                default: state <= STATE_IDLE;
            endcase
        end
    end

endmodule