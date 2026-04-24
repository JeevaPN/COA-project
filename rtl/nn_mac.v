module nn_mac (
    input  wire               clk,
    input  wire               reset,
    input  wire               start,
    input  wire               last_element,
    input  wire signed [7:0]  act_in,
    input  wire signed [7:0]  weight_in,
    input  wire signed [31:0] bias,
    output reg  signed [31:0] neuron_out,
    output reg                out_valid
);
    reg  signed [31:0] acc;
    wire signed [15:0] prod      = act_in * weight_in;
    wire signed [31:0] sum       = start ? prod : acc + prod;
    wire signed [31:0] final_val = sum + bias;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            acc        <= 0;
            neuron_out <= 0;
            out_valid  <= 0;
        end else begin
            acc       <= sum;
            out_valid <= last_element;
            if (last_element)
                neuron_out <= (final_val > 0) ? final_val : 32'sd0;
        end
    end
endmodule
