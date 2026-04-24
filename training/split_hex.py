from pathlib import Path

root = Path(__file__).resolve().parent.parent
hex_path = root / "weights" / "nnue_weights.hex"
out_dir = root / "weights"

with open(hex_path) as f:
    lines = f.readlines()

weights, biases = [], []
for line in lines:
    s = line.strip()
    if not s or s.startswith("//"):
        continue
    if len(s) == 2:
        weights.append(s)
    elif len(s) == 8:
        biases.append(s)

assert len(weights) == 32 * 768, f"weights={len(weights)}"
assert len(biases) == 32, f"biases={len(biases)}"

(out_dir / "weights.mem").write_text("\n".join(weights) + "\n")
(out_dir / "biases.mem").write_text("\n".join(biases) + "\n")

print(f"weights/weights.mem: {len(weights)} lines (8-bit)")
print(f"weights/biases.mem:  {len(biases)} lines (32-bit)")
