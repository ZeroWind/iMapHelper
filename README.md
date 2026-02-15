![License: Unlicense](https://img.shields.io/badge/license-Unlicense-blue.svg)
![Status: Public Domain](https://img.shields.io/badge/status-Public%20Domain-green.svg)
# 🚀 iMap-Helper (v0.04)
### AI Inference Model Centralized Management Toolkit

A lightweight, efficient tool designed for managing AI model storage. By leveraging **"Centralized Vault + Logical Mapping"**, it solves common pain points like redundant model downloads, OS drive (root) overflow, and complex Docker volume configurations.

---


## 📂 Vault Architecture
The script initializes your storage based on the following professional hierarchy:

```text
/mnt/models (Vault Root)
├── base/
│   ├── llm          # Language Models (Llama 3, Qwen, etc.)
│   ├── diffusion    # Image Models (SDXL, Flux, etc.)
│   └── vlm          # Vision Language Models
├── lora             # LoRA / Adapter weights
├── tensorrt         # Optimized FP4/FP8 engines for NVIDIA NIM
└── cache            # Unified HuggingFace/ModelScope cache

```

### Installation

Clone or download `imaphelper.sh` and grant execution permissions:

```bash
chmod +x imaphelper.sh

```

