.PHONY: all proof board weights clean

all: proof

proof:
	iverilog -g2012 -o sim/proof.out sim/proof_tb.v rtl/nn_mac.v rtl/material_eval.v
	vvp sim/proof.out

board:
	iverilog -g2012 -o sim/chess.out sim/chess_tb.v rtl/knight_move_gen.v rtl/material_eval.v rtl/nn_mac.v
	@vvp sim/chess.out | awk '/__PAUSE__/ { fflush(); system("sleep 2"); next } { print; fflush() }'

weights:
	python3 training/split_hex.py

clean:
	rm -f sim/*.out sim/*.vcd chess.vcd
