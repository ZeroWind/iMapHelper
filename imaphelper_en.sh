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
    echo -e "🧠  ${GREEN} AI Storage Manager ${NC}"
    echo -e "${BLUE}====================================================${NC}"
}

# 1. Directory Structure & Health Check
show_tree() {
    echo -e "${YELLOW}[Current Vault Structure]${NC}"
    if [ ! -d "$VAULT" ]; then
        echo -e "${RED}⚠️  Warning: Root directory $VAULT not found! Run option [1] ${NC}"
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

# --- NEW: UNINSTALL FUNCTION ---
generate_uninstall_cmd() {
    echo -e "\n${RED}‼️  DANGER ZONE: UNINSTALL iMapHelper${NC}"
    echo -e "${YELLOW}This will generate commands to REMOVE ALL MODELS and configuration.${NC}"
    echo -e "Are you absolutely sure? (y/n)"
    read -p ">>> " CONFIRM
    
    if [ "$CONFIRM" == "y" ]; then
        echo -e "\n${BLUE}----------------------------------------------------${NC}"
        echo -e "${RED}Copy and execute the following commands to UNINSTALL:${NC}\n"
        
        echo -e "# 1. Remove all physical model files (IRREVERSIBLE!)"
        echo "sudo rm -rf \"$VAULT\""
        
        echo -e "\n# 2. Clean up environment variables (Manual step)"
        echo "sed -i '/HF_HOME/d' ~/.bashrc"
        echo "sed -i '/MODELSCOPE_CACHE/d' ~/.bashrc"
        echo "sed -i '/# AI Model Cache Redirect/d' ~/.bashrc"
        
        echo -e "\n${YELLOW}Note: After execution, run 'source ~/.bashrc' to refresh environment.${NC}"
        echo -e "${BLUE}----------------------------------------------------${NC}"
    else
        echo -e "${GREEN}Uninstall cancelled.${NC}"
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

# --- Main Logic Loop ---
# Use a loop to keep the script running until the user chooses to quit
# --- Main Logic Loop ---
while true; do
    clear
    show_header
    show_tree

    echo -e "Select Action:"
    echo "1) Init/Repair Vault"
    echo "2) Generate Mapping Command"
    echo "3) Generate Uninstall Command (Danger)"
    echo "q) Quit"
    read -p ">>> " MAIN_OPT

    case $MAIN_OPT in
        1) init_vault; read -p "Press Enter...";;
        2) generate_mapping; read -p "Press Enter...";;
        3) generate_uninstall_cmd; read -p "Press Enter...";;
        q) echo "Goodbye!"; exit 0;;
        *) echo "Invalid option"; sleep 1;;
    esac
done