import faiss
import torch
from transformers import AutoImageProcessor, AutoModel

device = "mps" if torch.backends.mps.is_available() else "cpu"

# Load DINOv2 model
processor = AutoImageProcessor.from_pretrained("facebook/dinov2-base")
model = AutoModel.from_pretrained("facebook/dinov2-base").to(device)
model.eval()

# Load FAISS index + embeddings
index = faiss.read_index("core/oxford_index.bin")

import json
with open("core/oxford_embeddings.json") as f:
    all_embeddings = json.load(f)
img_paths = list(all_embeddings.keys())
