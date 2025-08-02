from PIL import Image
import torch
from core.model import processor, model, device

def extract_embedding(image: Image.Image):
    image = image.convert("RGB").resize((224, 224))
    inputs = processor(images=image, return_tensors="pt").to(device)
    with torch.no_grad():
        outputs = model(**inputs)
    return outputs.pooler_output.cpu().numpy()
