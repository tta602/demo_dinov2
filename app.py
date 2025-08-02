from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
import numpy as np
from io import BytesIO
from model import index, img_paths
from utils import extract_embedding
from fastapi.responses import FileResponse

import os
os.environ["KMP_DUPLICATE_LIB_OK"] = "TRUE"

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # hoặc cụ thể như ["http://localhost:5000"]
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def root():
    return {"msg": "DINOv2 Image Search API is running!"}

@app.get("/images/{image_path:path}")
def get_image(image_path: str):
    full_path = os.path.join("collection/images", os.path.basename(image_path))
    return FileResponse(full_path)

@app.post("/search")
async def search(file: UploadFile = File(...), top_k: int = 5):
    image = Image.open(BytesIO(await file.read()))
    embedding = extract_embedding(image)
    D, I = index.search(embedding, k=top_k)
    results = [{"image_path": img_paths[i], "distance": float(D[0][j])} for j, i in enumerate(I[0])]
    return JSONResponse(content={"results": results})
