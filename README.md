# 🚀 iMap-Helper (v0.04)
### AI Inference Model Centralized Management Toolkit

A lightweight, efficient tool designed for managing AI model storage. By leveraging **"Centralized Vault + Logical Mapping"**, it solves common pain points like redundant model downloads, OS drive (root) overflow, and complex Docker volume configurations.

---

## 🌟 Core Values
- **🔗 Smart Mapping**: Generate one-click commands for **Local Symlinks** or **Docker Volume Mounts**.
- **🛡️ OS Drive Protection**: Automatically redirects HuggingFace and ModelScope caches to your data disk.
- **🐳 DGX/HPC Optimized**: Tailored Docker templates for DGX (A100/H100/Spark) with optimized `shm-size` and user permissions.
- **🦾 Inference Ready**: Pre-defined structure for LLM, Diffusion, and NVIDIA NIM (TensorRT) engines.
- **✅ Safety First**: Non-destructive initialization and clear "Instruction Preview" logic.

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

## 🛠️ Quick Start

### 1. Installation

Clone or download `imaphelper.sh` and grant execution permissions:

```bash
chmod +x imaphelper.sh

```

### 2. Initialization

Run the script and select Option **[1]**:

* **Action**: Creates directory structure, fixes permissions, and injects ENV variables.
* **Post-Action**: Run `source ~/.bashrc` to activate cache redirection.

### 3. Usage Patterns

* **Importing**: Use Option **[3]** to migrate existing models from scattered paths to the Vault.
* **Mapping**: Use Option **[2]** to link a model in the Vault to your project folder (e.g., `ComfyUI/models`).
* **Deploying**: Use Option **[4]** to get a rock-solid Docker launch command for high-performance training/inference.

---

## ⚠️ Best Practices

| Component | Strategy | Reason |
| --- | --- | --- |
| **Model Weights** | **Symlink / Mount** | Save space, share one weight across multiple projects. |
| **Python venv** | **Physical Path** | Avoid `ModuleNotFoundError` caused by symlink path resolution. |
| **Docker** | **Volume Mapping** | Use `-v` to map the Vault root for consistent pathing. |

---

## 🗑️ Uninstallation

To maintain system safety, this script **never** runs `rm -rf` directly. Selecting the uninstall option will generate the cleanup commands for you to review and execute manually.

---

## 📈 Version History

* **v0.01**: Basic Vault structure & Symlink generation.
* **v0.02**: Added **Model Migration Tool** (rsync-based).
* **v0.03**: Added **DGX Optimized Docker Templates** .

---

Designed for AI Researchers and Beginners. 🚀


![iMap-Helper](https://github.com/user-attachments/assets/1cc1a496-1384-4800-95d9-3d1ce34d67c5) 