import pandas as pd
import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
import chess # pip install python-chess
import os

# ==============================================================================
# 1. FEN TO BITBOARD CONVERTER (Matches our Verilog 768-bit Input)
# ==============================================================================
def fen_to_bitboards(fen):
    """
    Converts a FEN string to a flat 768-element binary array (12 piece types * 64 squares)
    Order: wp, wn, wb, wr, wq, wk, bp, bn, bb, br, bq, bk
    Matches the input expected by our Verilog FSM.
    """
    board = chess.Board(fen)
    bitboards = np.zeros(768, dtype=np.float32)
    
    piece_map = board.piece_map()
    
    # Mapping piece types to our array offset (0 to 11)
    # White: P=0, N=1, B=2, R=3, Q=4, K=5
    # Black: p=6, n=7, b=8, r=9, q=10, k=11
    offset_map = {
        (chess.WHITE, chess.PAWN): 0, (chess.WHITE, chess.KNIGHT): 1, (chess.WHITE, chess.BISHOP): 2,
        (chess.WHITE, chess.ROOK): 3, (chess.WHITE, chess.QUEEN): 4,  (chess.WHITE, chess.KING): 5,
        (chess.BLACK, chess.PAWN): 6, (chess.BLACK, chess.KNIGHT): 7, (chess.BLACK, chess.BISHOP): 8,
        (chess.BLACK, chess.ROOK): 9, (chess.BLACK, chess.QUEEN): 10, (chess.BLACK, chess.KING): 11
    }
    
    for square, piece in piece_map.items():
        offset = offset_map[(piece.color, piece.piece_type)]
        # square is 0-63 (A1 to H8)
        bitboards[offset * 64 + square] = 1.0
        
    return bitboards

def parse_score(score_str):
    """
    Parses Kaggle string scores like '+35', '-105', or '#M4' (Mate in 4).
    Clamps mate scores to a massive advantage (+/- 10000).
    """
    score_str = str(score_str).strip()
    if '#' in score_str:
        # It's a forced mate. e.g. #+4 or #-3
        return 10000.0 if '+' in score_str or int(score_str.replace('#', '')) > 0 else -10000.0
    try:
        return float(score_str)
    except:
        return 0.0

# ==============================================================================
# 2. NEURAL NETWORK ARCHITECTURE (Must be small enough for FPGA)
# ==============================================================================
class ChessNNUE(nn.Module):
    def __init__(self):
        super(ChessNNUE, self).__init__()
        # Input Layer: 768 bits (12 bitboards * 64 squares)
        # Hidden Layer: 32 neurons (Small enough for hardware MAC units)
        self.fc1 = nn.Linear(768, 32)
        self.relu = nn.ReLU()
        # Output Layer: 1 neuron (The Centipawn Evaluation Score)
        self.fc2 = nn.Linear(32, 1)

    def forward(self, x):
        x = self.fc1(x)
        x = self.relu(x)
        x = self.fc2(x)
        return x

# ==============================================================================
# 3. TRAINING LOOP
# ==============================================================================
def train_model(data_path="chess_dataset.parquet", epochs=10, batch_size=64):
    print(f"Loading dataset from {data_path}...")
    if not os.path.exists(data_path):
        print(f"Error: File '{data_path}' not found! Please place your dataset here.")
        return None

    # Read the parquet file
    print("Reading Parquet file into memory...")
    try:
        df = pd.read_parquet(data_path)
    except Exception as e:
        print(f"Failed to read Parquet file. Ensure 'pyarrow' or 'fastparquet' is installed. Error: {e}")
        return None
        
    # Prevent Out-Of-Memory error when converting to 768-bit arrays
    if len(df) > 200000:
        print(f"Dataset has {len(df)} rows. Taking a subset of 200,000 to prevent RAM crash...")
        df = df.head(200000)
        
    # Assume Parquet has columns 'FEN' and 'Evaluation'
    
    print("Converting FENs to Bitboards...")
    X = np.array([fen_to_bitboards(fen) for fen in df['FEN']])
    y = np.array([parse_score(s) for s in df['Evaluation']]).reshape(-1, 1)
    
    X_tensor = torch.tensor(X, dtype=torch.float32)
    y_tensor = torch.tensor(y, dtype=torch.float32)
    
    dataset = torch.utils.data.TensorDataset(X_tensor, y_tensor)
    dataloader = torch.utils.data.DataLoader(dataset, batch_size=batch_size, shuffle=True)
    
    model = ChessNNUE()
    criterion = nn.MSELoss()
    optimizer = optim.Adam(model.parameters(), lr=0.001)
    
    print("Starting Training...")
    for epoch in range(epochs):
        epoch_loss = 0.0
        for batch_X, batch_y in dataloader:
            optimizer.zero_grad()
            predictions = model(batch_X)
            loss = criterion(predictions, batch_y)
            loss.backward()
            optimizer.step()
            epoch_loss += loss.item()
            
        print(f"Epoch {epoch+1}/{epochs}, Loss: {epoch_loss/len(dataloader):.4f}")
        
    print("Training Complete!")
    return model

# ==============================================================================
# 4. HARDWARE EXPORT (Quantization to Verilog .hex format)
# ==============================================================================
def export_to_verilog(model, filename="nnue_weights.hex"):
    """
    Quantizes the trained floating-point weights to 8-bit integers
    and exports them in standard Verilog Hex format for `$readmemh`.
    """
    print(f"Exporting quantized weights for FPGA to {filename}...")
    
    # Grab weights from the first layer 
    weights = model.fc1.weight.detach().numpy() # Shape: (32 neurons, 768 inputs)
    biases = model.fc1.bias.detach().numpy()    # Shape: (32 neurons)
    
    # Very basic quantization: scale up and round to nearest 8-bit int (-128 to 127)
    # In a real pipeline, you find the max absolute value across the tensor to scale properly.
    scaling_factor = 64.0
    q_weights = np.clip(np.round(weights * scaling_factor), -128, 127).astype(np.int8)
    q_biases = np.round(biases * scaling_factor).astype(np.int32)
    
    with open(filename, "w") as f:
        f.write("// Verilog Hex File for Chess NNUE MAC Unit\n")
        f.write("// Format: 8-bit two's complement hex\n\n")
        
        # Write weights neuron by neuron
        for neuron_idx in range(32):
            f.write(f"// --- Neuron {neuron_idx} Weights (768 inputs) ---\n")
            for input_idx in range(768):
                # Convert 8-bit signed int to 2-char hex string
                val = q_weights[neuron_idx, input_idx]
                hex_val = f"{val & 0xFF:02X}"
                f.write(f"{hex_val}\n")
                
            f.write(f"// Bias for Neuron {neuron_idx} (32-bit)\n")
            hex_bias = f"{q_biases[neuron_idx] & 0xFFFFFFFF:08X}"
            f.write(f"{hex_bias}\n\n")
            
    print("Export successful. You can load this into Verilog using: $readmemh(\"nnue_weights.hex\", memory_array);")

if __name__ == "__main__":
    # To run this, place your dataset in the folder, rename it to 'chess_dataset.parquet'
    # Make sure it has 'FEN' and 'Evaluation' headers
    
    print("Starting Training Process...")
    model = train_model("chess_dataset.parquet")
    if model:
        export_to_verilog(model)
