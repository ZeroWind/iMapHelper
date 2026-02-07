#!/bin/bash

# --- CONFIGURATION: Centralized Storage Root ---
# Change this to your actual mount point (e.g., /mnt/models)
VAULT="/mnt/models"

# Color Definitions for UI
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

show_header() {
    echo -e "${BLUE}====================================================${NC}"
    echo -e "🧠  ${GREEN} AI Storage Manager (Global Edition)${NC}"
    echo -e "${BLUE}====================================================${NC}"
}

# 1. Directory Structure & Health Check
show_tree() {
    echo -e "${YELLOW}[Current Vault Structure]${NC}"
    if [ ! -d "$VAULT" ]; then
        echo -e "${RED}⚠️  Warning: Root directory $VAULT not found!${NC}"
        return
    fi
    
    # Check for missing core subdirectories
    local missing=0
    for dir in "base/llm" "base/diffusion" "base/vlm" "lora" "tensorrt" "cache"; do
        if [ ! -d "$VAULT/$dir" ]; then
            echo -e "${RED}[Missing] $dir${NC}"
            missing=1
        fi
    done

    [ $missing -eq 1 ] && echo -e "${RED}👉 Run option [1] to repair (existing files will be safe).${NC}"

    # Display Directory Tree
    if command -v tree >/dev/null 2>&1; then
        tree -d -L 3 "$VAULT"
    else
        find "$VAULT" -maxdepth 3 -not -path '*/.*' -type d | sed -e "s/[^-][^\/]*\// |/g" -e "s/|\([^ ]\)/|-- \1/"
    fi
    
    # Storage Insight: Cache Usage
    if [ -d "$VAULT/cache" ]; then
        local cache_size=$(du -sh "$VAULT/cache" 2>/dev/null | cut -f1)
        echo -e "${BLUE}💡 Cache Info: $VAULT/cache is using $cache_size.${NC}"
    fi
    echo -e "${BLUE}----------------------------------------------------${NC}"
}

# 2. Secure Initialization (Non-Destructive)
init_vault() {
    echo -e "${YELLOW}[Initializing/Repairing Vault Structure...]${NC}"
    
    # Create directories (mkdir -p is safe and won't overwrite existing files)
    sudo mkdir -p "$VAULT/base/llm" "$VAULT/base/diffusion" "$VAULT/base/vlm" \
                "$VAULT/lora" "$VAULT/tensorrt" "$VAULT/cache"
    
    # Fix Permissions: Set ownership and group-write access for Docker compatibility
    sudo chown -R $USER:$USER "$VAULT"
    sudo chmod -R 775 "$VAULT"
    # Set GID bit so new files inherit the folder's group
    sudo find "$VAULT" -type d -exec chmod g+s {} +
    
    echo -e "${GREEN}✅ Vault initialized. Existing models remain untouched.${NC}"

    # Inject Environment Variables to protect System Disk
    if ! grep -q "HF_HOME" ~/.bashrc; then
        echo -e "\n# AI Model Cache Redirect\nexport HF_HOME=\"$VAULT/cache\"\nexport MODELSCOPE_CACHE=\"$VAULT/cache\"" >> ~/.bashrc
        echo -e "${GREEN}✅ Environment variables added to ~/.bashrc.${NC}"
        echo -e "${BLUE}Please run 'source ~/.bashrc' to apply changes.${NC}"
    fi
}

# 3. Path Mapping Logic
generate_mapping() {
    if [ ! -d "$VAULT/base" ]; then
        echo -e "${RED}❌ Error: Vault not initialized. Run option [1] first.${NC}"
        return
    fi

    echo -e "\n${YELLOW}[Path Mapping Generator]${NC}"
    read -p "Enter intended reference path (e.g., /home/user/app/models/m.sft): " INPUT_PATH
    echo -e "\nSelect Category: [1]LLM [2]Diffusion [3]VLM [4]LoRA [5]TensorRT"
    read -p "Enter number [1-5]: " TYPE_NUM

    BASE_NAME=$(basename "$INPUT_PATH")
    case $TYPE_NUM in
        1) SUB="base/llm" ;; 2) SUB="base/diffusion" ;; 3) SUB="base/vlm" ;;
        4) SUB="lora" ;; 5) SUB="tensorrt" ;; *) return ;;
    esac

    TARGET_PATH="$VAULT/$SUB/$BASE_NAME"

    echo -e "\n${BLUE}----------------------------------------------------${NC}"
    echo -e "📍 ${GREEN}Commands (Copy & Paste):${NC}"
    
    # Option A: Symbolic Link (Local/Venv)
    echo -e "\n${YELLOW}Option A: Symbolic Link (Local Service)${NC}"
    echo "mkdir -p \$(dirname \"$INPUT_PATH\") && ln -s \"$TARGET_PATH\" \"$INPUT_PATH\""

    # Option B: Docker Volume Mount
    echo -e "\n${YELLOW}Option B: Docker Mount Flags${NC}"
    echo "-v \"$TARGET_PATH\":\"$INPUT_PATH\" \\"
    echo "-v \"$VAULT/cache\":\"/root/.cache/huggingface\""
    
    # Check if physical file exists
    if [ ! -e "$TARGET_PATH" ]; then
        echo -e "\n${RED}⚠️ Note: Target file does not exist yet. Download it to:${NC}"
        echo -e "${GREEN}$TARGET_PATH${NC}"
    fi
    echo -e "${BLUE}----------------------------------------------------${NC}"
}

# --- Main Menu ---
show_header
show_tree

echo "Action: 1)Init/Repair  2)Map Path  3)Refresh  q)Quit"
read -p ">>> " MAIN_OPT
case $MAIN_OPT in
    1) init_vault ;; 2) generate_mapping ;; 3) clear; show_header; show_tree ;; q) exit 0 ;;
esac