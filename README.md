# COA Chess Hardware Project

A hardware-first chess evaluation prototype that combines:

- fast handcrafted evaluators in Verilog (material and piece-square style features), and
- a small NNUE-like neural component (quantized weights, MAC-based inference).

The repository is organized to let you:

1. train/export weights (Python, typically on Kaggle),
2. convert them to Verilog memory files, and
3. run simulation testbenches that compare classic scoring vs neural scoring.

## What This Project Does

This project demonstrates a hybrid chess evaluation pipeline for digital design coursework:

- **Classical path (fast):**
  - `material_eval.v` computes material advantage from bitboards.
  - `pst_eval.v` applies positional bonuses/penalties (piece-square table style).
- **Neural path (deeper):**
  - `nn_mac.v` performs quantized multiply-accumulate per neuron and applies ReLU.
  - `proof_tb.v` feeds multiple positions through 32 hidden neurons and accumulates a deep score.
- **Search/control sketch:**
  - `chess_fsm.v` models how a controller could descend a search tree, trigger NN leaf eval, and backtrack.
- **Bitboard helpers:**
  - `knight_move_gen.v` and `make_move.v` provide move generation/update primitives.

In short: it is a proof-oriented hardware chess evaluation framework, not yet a full legal-move chess engine.

## Repository Layout

```text
.
|-- Makefile
|-- rtl/
|   |-- chess_fsm.v
|   |-- knight_move_gen.v
|   |-- make_move.v
|   |-- material_eval.v
|   |-- nn_mac.v
|   `-- pst_eval.v
|-- sim/
|   |-- chess_tb.v
|   `-- proof_tb.v
|-- training/
|   |-- gen_positions.py
|   |-- split_hex.py
|   `-- train_weights_kaggle.py
`-- weights/
    |-- nnue_weights.hex
    |-- weights.mem
    |-- biases.mem
    `-- positions.vh
```

## Toolchain Requirements

### RTL/Simulation

- Icarus Verilog (`iverilog`, `vvp`)
- `make` (optional but recommended)

### Python (data prep/training)

- Python 3.9+
- For conversion/position generation:
  - `python-chess`
- For training script:
  - `numpy`, `pandas`, `torch`, `python-chess`

Install minimal local Python deps:

```bash
pip install python-chess
```

Install training deps (if training locally):

```bash
pip install numpy pandas torch python-chess
```

## Quick Start

From repository root:

```bash
make proof
```

This target does:

1. `python3 training/split_hex.py`
2. `python3 training/gen_positions.py`
3. compile `sim/proof_tb.v` with required RTL modules
4. run simulation with `vvp`

To run the board/material testbench:

```bash
make board
```

To clean generated simulation outputs:

```bash
make clean
```

## Makefile Targets

- `make all` -> alias to `make proof`
- `make weights` -> regenerate `weights.mem`, `biases.mem`, `positions.vh`
- `make proof` -> run NN proof testbench
- `make board` -> run basic board + knight move/material testbench
- `make clean` -> remove `sim/*.out` and `sim/*.vcd`

## End-to-End Data Flow

1. **Train model and export hex**
   - Script: `training/train_weights_kaggle.py`
   - Output: `weights/nnue_weights.hex`
2. **Split exported hex for Verilog ROM loading**
   - Script: `training/split_hex.py`
   - Outputs:
     - `weights/weights.mem` (32 \* 768 8-bit lines)
     - `weights/biases.mem` (32 32-bit lines)
3. **Generate curated test positions**
   - Script: `training/gen_positions.py`
   - Output: `weights/positions.vh`
4. **Simulate proof testbench**
   - Testbench: `sim/proof_tb.v`
   - Loads `weights/*.mem`
   - Prints `material_score` and `deep_score` for several positions.

## Running Without Make (Manual Commands)

If you do not use `make`, run from repo root:

```bash
python3 training/split_hex.py
python3 training/gen_positions.py
iverilog -g2012 -o sim/proof.out sim/proof_tb.v rtl/nn_mac.v rtl/material_eval.v
vvp sim/proof.out
```

Board testbench manually:

```bash
iverilog -g2012 -o sim/chess.out sim/chess_tb.v rtl/knight_move_gen.v rtl/material_eval.v
vvp sim/chess.out
```

## Windows Notes

- If `make` is unavailable, use the manual command sequence above.
- If `python3` is unavailable, try `py -3`:

```powershell
py -3 training/split_hex.py
py -3 training/gen_positions.py
```

- Icarus Verilog must be on `PATH` so `iverilog` and `vvp` resolve.

## Training Notes

- `training/train_weights_kaggle.py` is configured for Kaggle paths by default:
  - `DATA_PATH = /kaggle/input/chess-evaluations/chessData.csv`
  - `OUTPUT_HEX = /kaggle/working/nnue_weights.hex`
- It trains a small network:
  - input: 768-bit board encoding
  - hidden: 32 neurons + ReLU
  - output: 1 scalar evaluation
- The script exports quantized first-layer weights/biases to hex for RTL inference experiments.

## Expected Proof Behavior

When `sim/proof_tb.v` runs successfully:

- `material_score` may be similar for materially-equal positions.
- `deep_score` should vary more across strategically different positions.

That demonstrates the neural evaluator is capturing positional differences beyond pure material count.

## Known Limitations

- Current inference testbench uses hidden-layer MAC accumulation, not a complete production NNUE pipeline.
- Search FSM is architectural/scaffolding logic, not a full legal move-search implementation.
- Only selected modules are included in active compile targets.

## Troubleshooting

- **`assert len(weights) == 32 * 768` fails**
  - Your `weights/nnue_weights.hex` format/count does not match the expected export.
- **`$readmemh` cannot open file**
  - Run simulation from repo root and ensure `weights/weights.mem` and `weights/biases.mem` exist.
- **`iverilog` command not found**
  - Install Icarus Verilog and add it to your PATH.
- **Python import errors (`chess`, `torch`, etc.)**
  - Install missing packages in the active Python environment.

## Suggested Next Improvements

1. Wire `pst_eval.v` into the proof path and compare material vs material+PST vs NN.
2. Extend inference to include output-layer weights and final scalar prediction in RTL.
3. Add CI checks for `make proof` and basic lint/syntax verification.
4. Add parameterized test vectors using `weights/positions.vh` directly in testbenches.

## License

No license file is currently present in this repository. Add one if you plan to share/distribute this project.
