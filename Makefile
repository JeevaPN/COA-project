.PHONY: all proof weights clean

all: proof

# Regenerate weights.mem, biases.mem, positions.vh from the trained hex file
weights: weights/nnue_weights.hex
	python3 training/split_hex.py
	python3 training/gen_positions.py

# Build + run the NN proof testbench
proof: weights
	iverilog -g2012 -o sim/proof.out sim/proof_tb.v rtl/nn_mac.v rtl/material_eval.v
	cd . && vvp sim/proof.out

# Original board/material testbench
board:
	iverilog -g2012 -o sim/chess.out sim/chess_tb.v rtl/knight_move_gen.v rtl/material_eval.v
	vvp sim/chess.out

clean:
	rm -f sim/*.out sim/*.vcd
