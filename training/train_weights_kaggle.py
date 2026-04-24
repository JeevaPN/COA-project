import pandas as pd
import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
import chess
import os

DATA_PATH = "/kaggle/input/chess-evaluations/chessData.csv"
OUTPUT_HEX = "/kaggle/working/nnue_weights.hex"
SUBSET_SIZE = 200000
EPOCHS = 10
BATCH_SIZE = 1024

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f"Using device: {device}")

def fen_to_bitboards(fen):
    board = chess.Board(fen)
    bitboards = np.zeros(768, dtype=np.float32)
    offset_map = {
        (chess.WHITE, chess.PAWN): 0, (chess.WHITE, chess.KNIGHT): 1, (chess.WHITE, chess.BISHOP): 2,
        (chess.WHITE, chess.ROOK): 3, (chess.WHITE, chess.QUEEN): 4,  (chess.WHITE, chess.KING): 5,
        (chess.BLACK, chess.PAWN): 6, (chess.BLACK, chess.KNIGHT): 7, (chess.BLACK, chess.BISHOP): 8,
        (chess.BLACK, chess.ROOK): 9, (chess.BLACK, chess.QUEEN): 10, (chess.BLACK, chess.KING): 11,
    }
    for square, piece in board.piece_map().items():
        offset = offset_map[(piece.color, piece.piece_type)]
        bitboards[offset * 64 + square] = 1.0
    return bitboards

def parse_score(score_str):
    s = str(score_str).strip()
    if '#' in s:
        num = s.replace('#', '').replace('+', '').replace('-', '')
        sign = -1 if '-' in s else 1
        return sign * 10000.0
    try:
        return float(s)
    except Exception:
        return 0.0

class ChessNNUE(nn.Module):
    def __init__(self):
        super().__init__()
        self.fc1 = nn.Linear(768, 32)
        self.relu = nn.ReLU()
        self.fc2 = nn.Linear(32, 1)

    def forward(self, x):
        return self.fc2(self.relu(self.fc1(x)))

def train_model(data_path=DATA_PATH, epochs=EPOCHS, batch_size=BATCH_SIZE):
    print(f"Loading dataset from {data_path}...")
    if not os.path.exists(data_path):
        raise FileNotFoundError(data_path)
    df = pd.read_csv(data_path, nrows=SUBSET_SIZE)
    print(f"Loaded {len(df)} rows")
    print("Converting FENs to bitboards...")
    X = np.stack([fen_to_bitboards(fen) for fen in df['FEN'].values])
    y = np.array([parse_score(s) for s in df['Evaluation'].values], dtype=np.float32).reshape(-1, 1)
    X_tensor = torch.tensor(X, dtype=torch.float32)
    y_tensor = torch.tensor(y, dtype=torch.float32)
    dataset = torch.utils.data.TensorDataset(X_tensor, y_tensor)
    dataloader = torch.utils.data.DataLoader(
        dataset, batch_size=batch_size, shuffle=True,
        num_workers=2, pin_memory=(device.type == "cuda"),
    )
    model = ChessNNUE().to(device)
    criterion = nn.MSELoss()
    optimizer = optim.Adam(model.parameters(), lr=0.001)
    print("Training...")
    for epoch in range(epochs):
        epoch_loss = 0.0
        for batch_X, batch_y in dataloader:
            batch_X = batch_X.to(device, non_blocking=True)
            batch_y = batch_y.to(device, non_blocking=True)
            optimizer.zero_grad()
            predictions = model(batch_X)
            loss = criterion(predictions, batch_y)
            loss.backward()
            optimizer.step()
            epoch_loss += loss.item()
        print(f"Epoch {epoch+1}/{epochs}, Loss: {epoch_loss/len(dataloader):.4f}")
    print("Training complete.")
    return model

def export_to_verilog(model, filename=OUTPUT_HEX):
    print(f"Exporting quantized weights to {filename}...")
    model = model.cpu()
    weights = model.fc1.weight.detach().numpy()
    biases = model.fc1.bias.detach().numpy()
    scaling_factor = 64.0
    q_weights = np.clip(np.round(weights * scaling_factor), -128, 127).astype(np.int8)
    q_biases = np.round(biases * scaling_factor).astype(np.int32)
    with open(filename, "w") as f:
        f.write("// Verilog Hex File for Chess NNUE MAC Unit\n")
        f.write("// Format: 8-bit two's complement hex\n\n")
        for neuron_idx in range(32):
            f.write(f"// --- Neuron {neuron_idx} Weights (768 inputs) ---\n")
            for input_idx in range(768):
                val = int(q_weights[neuron_idx, input_idx])
                f.write(f"{val & 0xFF:02X}\n")
            f.write(f"// Bias for Neuron {neuron_idx} (32-bit)\n")
            f.write(f"{int(q_biases[neuron_idx]) & 0xFFFFFFFF:08X}\n\n")
    print(f"Done. File saved at {filename}")

if __name__ == "__main__":
    model = train_model()
    export_to_verilog(model)