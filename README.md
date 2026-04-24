# COA Chess Hardware Project

A hardware chess-evaluation prototype in Verilog with a small quantized neural network trained in Python. Classical evaluation runs as pure combinational logic; neural evaluation runs as a sequential multiply-accumulate (MAC) pipeline.

## Layout

```
rtl/         Verilog modules (the "hardware")
sim/         Testbenches
weights/     Trained INT8 weights + biases (.mem files loaded by $readmemh)
training/    Python scripts to train and export weights
Makefile
```

## RTL modules

| File | Kind | Role |
|---|---|---|
| `material_eval.v` | combinational | Piece counts × piece values; white − black. |
| `pst_eval.v` | combinational | Piece-Square Table positional score. |
| `knight_move_gen.v` | combinational | All knight destinations via bitboard shifts + file masks. |
| `make_move.v` | combinational | Board update (move + capture) via `from_mask`/`to_mask`. |
| `nn_mac.v` | sequential | 8×8 INT8 MAC, accumulator, bias, ReLU, `out_valid` handshake. |
| `chess_fsm.v` | sequential | 6-state controller: descend tree → NN at leaves → bubble up. |

## Board representation

Each side has six 64-bit bitboards (`wp, wn, wb, wr, wq, wk`, `bp…bk`). Bit `i` set = that piece on square `i`, where square 0 = A1 and square 63 = H8. This makes evaluation and move generation bit-parallel — one cycle, no loops in hardware.

## Run

Requires [Icarus Verilog](http://iverilog.icarus.com/) (`iverilog`, `vvp`).

```bash
make board    # knight moves + material eval, prints an ASCII board
make proof    # NN proof: material vs. deep score over 3 positions
make clean    # remove sim artifacts
```

`make proof` loads `weights/weights.mem` and `weights/biases.mem`, runs 32 hidden neurons (768 inputs each) through `nn_mac.v` for each of 3 positions, and compares the NN output against the material-only score.

## Training (optional)

`training/train_weights_kaggle.py` trains a 768 → 32 → 1 network on Kaggle chess data and exports INT8 weights as a hex file. After retraining, run:

```bash
make weights   # splits nnue_weights.hex into weights.mem + biases.mem
```

The checked-in `.mem` files come from a previous training run, so `make proof` works out of the box.

## Data flow

```
train_weights_kaggle.py  (on Kaggle)
      ↓  nnue_weights.hex
split_hex.py
      ↓  weights.mem + biases.mem
proof_tb.v  ($readmemh)
      ↓
nn_mac.v  →  deep_score
```
