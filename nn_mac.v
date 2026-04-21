module nn_mac (
    input wire clk,
    input wire reset,
    input wire start,           // High for the first element of a neuron's dot product
    input wire last_element,    // High for the final element of the dot product
    
    // Memory fetch inputs (from your Kaggle-trained dataset)
    input wire signed [7:0] act_in,    // 8-bit quantized activation (Input feature)
    input wire signed [7:0] weight_in, // 8-bit quantized weight
    input wire signed [31:0] bias,     // 32-bit bias added at the end

    // Handshaking & Outputs
    output reg signed [31:0] neuron_out, // The final output of the neuron
    output reg out_valid                 // High when neuron_out is ready (eval_ready flag)
);

    // Internal 32-bit accumulator to prevent integer overflow during the dot product
    reg signed [31:0] accumulator;
    
    // Hardware Multiplier: 8-bit * 8-bit = 16-bit
    // This will synthesize into a dedicated DSP Slice on an FPGA
    wire signed [15:0] mult_result = act_in * weight_in;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            accumulator <= 0;
            neuron_out <= 0;
            out_valid <= 0;
        end else begin
            out_valid <= 0; // Automatically pull the ready flag down

            // 1. Multiply & Accumulate (The MAC operation)
            if (start) begin
                // If this is the start of a neuron's calculation, overwrite the accumulator
                accumulator <= mult_result;
            end else begin
                // Otherwise, add the new multiplication to the running total
                accumulator <= accumulator + mult_result;
            end

            // 2. Finalization & Activation Function (ReLU)
            if (last_element) begin
                // We add the final multiplication, plus the trained bias for this neuron
                // Note: Blocking assignment logic used here conceptually to show the final math
                integer pre_activation;
                pre_activation = (start ? 0 : accumulator) + mult_result + bias;
                
                // ReLU (Rectified Linear Unit) Activation: Hardware implementation of max(0, x)
                // If it's positive, pass it through. If it's negative, clamp it to 0.
                if (pre_activation > 0) begin
                    neuron_out <= pre_activation;
                end else begin
                    neuron_out <= 0;
                end
                
                // 3. Signal the FSM!
                // This is the 15-cycle delayed flag that tells the Main Alpha-Beta FSM:
                // "My Neural Network math is done. Here is your Deep_Score for this Leaf Node."
                out_valid <= 1'b1; 
            end
        end
    end
endmodule