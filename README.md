### 🇺🇸 English Version: iMap-Helper QuickStart
![iMap-Helper](https://github.com/user-attachments/assets/1cc1a496-1384-4800-95d9-3d1ce34d67c5) 

#### **1. Core Concept**

* **Models**: Centralized storage + Logical mapping (Symlink/Volume Mount).
* **Environments**: Keep `venv` physically intact; avoid symlinks for runtime libs.

#### **2. Key Features**

* **Standardized Vault**: Unified structure for LLM, Diffusion, VLM, LoRA, and TensorRT.
* **OS Drive Protection**: Force-redirects HF/ModelScope cache to data disks.
* **Seamless Mapping**: Generates local `ln -s` commands and Docker `-v` parameters.
* **Compute Optimized**: High-performance Docker templates for DGX (A100/H100/Spark).

#### **3. Workflow**

1. **Initialize**: Run Option `[1]` to setup directories and fix permissions.
2. **Activate**: Run `source ~/.bashrc` in your terminal.
3. **Map Models**: Run Option `[2]` and copy-paste the generated commands.
4. **Import**: Run Option `[3]` to migrate existing models into the vault.

#### **4. Directory Structure**

```text
/mnt/models (Vault Root)
├── base		   # Foundation Models
│   ├── llm        # (Llama 3)
│   ├── diffusion  # (Flux, SD3)
│   └── vlm        # (Qwen-VL)
├── lora           # LoRA Weights
├── tensorrt       # Optimized Engines
└── cache          # Unified HF/ModelScope Cache

```
