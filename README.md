# 🔍 DINOv2 Image Retrieval Demo (Oxford Buildings Dataset)

This is a demo system for image similarity search using **DINOv2 embeddings**, **FAISS** for indexing, and a frontend built with **Flutter Web**, served alongside a **FastAPI** backend.

---

## 📁 1. Download the Oxford Building Dataset

Run the following commands to download and extract the dataset:

```bash
# Download image data and groundtruth
wget https://www.robots.ox.ac.uk/~vgg/data/oxbuildings/oxbuild_images.tgz
wget https://www.robots.ox.ac.uk/~vgg/data/oxbuildings/gt_files_170407.tgz

# Extract contents
tar -xvzf oxbuild_images.tgz
tar -xvzf gt_files_170407.tgz

# Create folders
mkdir -p collection/images
mkdir -p collection/gtruth

# Move the extracted files
mv *.jpg collection/images/
mv *.txt collection/gtruth/
```

---

## 🧠 2. Build Embeddings with DINOv2

Use the provided notebook to extract image embeddings:

```bash
jupyter notebook extract_embedding.ipynb
```

> You can also convert the notebook to `.py` and run it as a script.

### Output:
- `core/oxford_embeddings.json`: Metadata of image paths and embeddings.
- `core/oxford_index.bin`: FAISS index file built from embeddings.

---

## 🖼️ 3. Build the Flutter Web Interface

To compile the Flutter Web frontend:

```bash
cd ui_app
flutter build web
cd ..
```

This will generate the `build/web/` folder to be served by Nginx inside Docker.

---

## 🐳 4. Run with Docker Compose

Make sure the following files exist under the `docker/` directory:
- `Dockerfile.backend`: For the FastAPI backend.
- `Dockerfile.frontend`: For the Nginx + Flutter Web frontend.
- `nginx.conf`: Custom Nginx configuration to forward `/search` and `/images`.

Start the system using Docker Compose:

```bash
docker-compose up --build
```

---

## 🌐 5. Access the System

- **Flutter Web UI**: [http://localhost:5173](http://localhost:5173)  
- **FastAPI Backend**: [http://localhost:8000/search](http://localhost:8000/search)

---

## 🧪 6. Testing the Search

1. Open the web UI.
2. Upload a query image.
3. The backend will return the `top_k` most similar images from `collection/images/`.
4. The result will be displayed on the right panel in a responsive grid layout.

---

## 📂 Project Structure

```
project/
├── app.py                         # FastAPI backend
├── build_embeddings.ipynb         # Embedding builder using DINOv2
├── collection/
│   ├── images/                    # Original image dataset
│   └── gtruth/                    # Groundtruth text files
├── core/
│   ├── oxford_embeddings.json     # Embedding metadata
│   ├── oxford_index.bin           # FAISS index
│   └── model.py                   # Embedding + search logic
├── ui_app/
│   └── build/web/                 # Compiled Flutter Web app
├── docker/
│   ├── Dockerfile.backend         # Backend Dockerfile
│   ├── Dockerfile.frontend        # Frontend Dockerfile
│   └── nginx.conf                 # Nginx config with proxy_pass
├── docker-compose.yml             # Docker Compose configuration
├── requirements.txt               # Python dependencies
├── evaluate_metrics.ipynb         # Evaluate MAP@k, Precision@k for retrieval
├── extract_embedding.ipynb        # Generate and save image embeddings using DINOv2
└── README.md
```

---

## ✅ Notes

- You can adjust the number of returned images via the `k` parameter (e.g., `/search?k=10`).
- If you change the dataset, make sure to re-run the embedding script to rebuild `oxford_index.bin`.