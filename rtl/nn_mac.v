module nn_mac (
    input wire clk,
    input wire reset,
    input wire start,
    input wire last_element,
    input wire signed [7:0] act_in,
    input wire signed [7:0] weight_in,
    input wire signed [31:0] bias,
    output reg signed [31:0] neuron_out,
    output reg out_valid
);

    reg signed [31:0] accumulator;
    wire signed [15:0] mult_result = act_in * weight_in;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            accumulator <= 0;
            neuron_out <= 0;
            out_valid <= 0;
        end else begin
            out_valid <= 0;
            if (start) begin
                accumulator <= mult_result;
            end else begin
                accumulator <= accumulator + mult_result;
            end
            if (last_element) begin
                integer pre_activation;
                pre_activation = (start ? 0 : accumulator) + mult_result + bias;
                if (pre_activation > 0) begin
                    neuron_out <= pre_activation;
                end else begin
                    neuron_out <= 0;
                end
                out_valid <= 1'b1;
            end
        end
    end
endmodule