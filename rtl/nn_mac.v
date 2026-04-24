module nn_mac (
    input wire clk,
    input wire reset,
    input wire start,           // pulse for the first MAC in a neuron
    input wire last_element,    // pulse for the final MAC in a neuron

    // Quantized memory inputs from trained weights/biases
    input wire signed [7:0] act_in,    // activation bit (quantized)
    input wire signed [7:0] weight_in, // weight value
    input wire signed [31:0] bias,     // neuron bias

    // Result handshake
    output reg signed [31:0] neuron_out, // output after activation
    output reg out_valid                 // asserted when neuron_out is valid
);

    // Running accumulator sized to hold intermediate sums
    reg signed [31:0] accumulator;

    // Multiply small ints; maps to FPGA DSP blocks cleanly
    wire signed [15:0] mult_result = act_in * weight_in;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            accumulator <= 0;
            neuron_out <= 0;
            out_valid <= 0;
        end else begin
            out_valid <= 0; // default low each cycle

            // Multiply-accumulate behavior
            if (start) begin
                // First element: seed the accumulator
                accumulator <= mult_result;
            end else begin
                // Otherwise accumulate
                accumulator <= accumulator + mult_result;
            end

            // When this was the last element, finalize the neuron
            if (last_element) begin
                integer pre_activation;
                pre_activation = (start ? 0 : accumulator) + mult_result + bias;

                // ReLU: simple clamp at zero
                if (pre_activation > 0) begin
                    neuron_out <= pre_activation;
                end else begin
                    neuron_out <= 0;
                end

                // Tell whoever's waiting that the result is ready
                out_valid <= 1'b1;
            end
        end
    end
endmodule