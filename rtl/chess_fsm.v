module chess_fsm (
    input  wire        clk,
    input  wire        reset,
    input  wire        start_search,
    input  wire [3:0]  target_depth,
    input  wire [15:0] fast_score,
    output reg         nn_start,
    input  wire        nn_eval_ready,
    input  wire signed [31:0] deep_score,
    output reg         search_done,
    output reg  signed [31:0] best_move_score
);
    localparam IDLE    = 3'd0,
               DESCEND = 3'd1,
               CHECK   = 3'd2,
               LEAF    = 3'd3,
               WAIT_NN = 3'd4,
               BUBBLE  = 3'd5;

    localparam signed [31:0] NEG_INF = -32'sd1000000;

    reg [2:0] state;
    reg [3:0] depth;
    reg signed [31:0] alpha;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state           <= IDLE;
            depth           <= 0;
            alpha           <= NEG_INF;
            nn_start        <= 0;
            search_done     <= 0;
            best_move_score <= 0;
        end else begin
            case (state)
                IDLE: begin
                    search_done <= 0;
                    if (start_search) begin
                        depth <= 0;
                        alpha <= NEG_INF;
                        state <= DESCEND;
                    end
                end

                DESCEND: begin
                    depth <= depth + 1;
                    state <= CHECK;
                end

                CHECK: state <= (depth == target_depth) ? LEAF : DESCEND;

                LEAF: begin
                    nn_start <= 1;
                    state    <= WAIT_NN;
                end

                WAIT_NN: begin
                    nn_start <= 0;
                    if (nn_eval_ready) begin
                        if (deep_score > alpha) alpha <= deep_score;
                        state <= BUBBLE;
                    end
                end

                BUBBLE: begin
                    depth <= depth - 1;
                    if (depth == 4'd1) begin
                        best_move_score <= alpha;
                        search_done     <= 1;
                        state           <= IDLE;
                    end else begin
                        state <= DESCEND;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
