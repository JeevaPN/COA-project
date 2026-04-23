"""Generate Verilog-ready bitboard hex strings for test positions.

Two positions chosen so material is EQUAL but NN should see a difference:
  1. Starting position (baseline, everything balanced)
  2. Passed-pawn endgame: White pawn on a7, kings only. White is clearly winning
     (pawn one step from queening) but material is +100 either way.
  3. Bad-knight vs good-knight: equal material, white knight centralized, black knight cornered.
"""
import chess

def fen_to_768(fen):
    """Return dict of 12 bitboards (64-bit each) matching training script order."""
    board = chess.Board(fen)
    bbs = {k: 0 for k in ["wp","wn","wb","wr","wq","wk","bp","bn","bb","br","bq","bk"]}
    name_map = {
        (chess.WHITE, chess.PAWN): "wp", (chess.WHITE, chess.KNIGHT): "wn",
        (chess.WHITE, chess.BISHOP): "wb", (chess.WHITE, chess.ROOK): "wr",
        (chess.WHITE, chess.QUEEN): "wq", (chess.WHITE, chess.KING): "wk",
        (chess.BLACK, chess.PAWN): "bp", (chess.BLACK, chess.KNIGHT): "bn",
        (chess.BLACK, chess.BISHOP): "bb", (chess.BLACK, chess.ROOK): "br",
        (chess.BLACK, chess.QUEEN): "bq", (chess.BLACK, chess.KING): "bk",
    }
    for sq, pc in board.piece_map().items():
        bbs[name_map[(pc.color, pc.piece_type)]] |= (1 << sq)
    return bbs

def flat768(bbs):
    """Flat 768-bit vector, neuron order wp..bk, MSB-first in Verilog $readmemb-style.

    train_weights uses: bitboards[offset * 64 + square] = 1.0  where square is 0..63.
    So index 0..63 are wp squares a1..h8, index 64..127 are wn, etc.
    We emit a 768-bit Verilog constant with bit[0] = wp a1.
    """
    order = ["wp","wn","wb","wr","wq","wk","bp","bn","bb","br","bq","bk"]
    v = 0
    for i, key in enumerate(order):
        bb = bbs[key]
        for sq in range(64):
            if (bb >> sq) & 1:
                v |= (1 << (i * 64 + sq))
    return v

positions = [
    ("start",        "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"),
    ("passed_pawn",  "8/P7/8/8/8/8/8/k6K w - - 0 1"),
    ("bad_knight",   "7k/8/8/8/3N4/8/8/K6n w - - 0 1"),
    ("equal_middle", "r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/2N2N2/PPPP1PPP/R1BQK2R w KQkq - 0 1"),
]

print("// Auto-generated bitboards — include in testbench via `include")
for name, fen in positions:
    bbs = fen_to_768(fen)
    print(f"\n// Position: {name}  FEN: {fen}")
    for key in ["wp","wn","wb","wr","wq","wk","bp","bn","bb","br","bq","bk"]:
        print(f"// {name}_{key} = 64'h{bbs[key]:016X};")
    # Also emit flat 768-bit constant
    v = flat768(bbs)
    hex768 = f"{v:0192X}"
    print(f"// {name}_flat768 = 768'h{hex768};")

# Write a Verilog include file with the bitboards
from pathlib import Path
out_path = Path(__file__).resolve().parent.parent / "weights" / "positions.vh"
with open(out_path, "w") as f:
    f.write("// Auto-generated test positions\n")
    for name, fen in positions:
        bbs = fen_to_768(fen)
        f.write(f"\n// {name}: {fen}\n")
        for key in ["wp","wn","wb","wr","wq","wk","bp","bn","bb","br","bq","bk"]:
            f.write(f"  {name}_{key} = 64'h{bbs[key]:016X};\n")
        v = flat768(bbs)
        f.write(f"  {name}_flat = 768'h{v:0192X};\n")

print(f"\nWrote {out_path}")
