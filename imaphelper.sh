#!/bin/bash

# --- Configuration: Your centralized storage root ---
VAULT="/mnt/models"

# Color Definitions
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'
WHITE='\033[1;37m'

# Display Banner
show_header() {
    echo -e "${BLUE}====================================================${NC}"
    echo -e "🧠  ${GREEN} AI Model Centralized Management (iMapHelper) ${NC}"
    echo -e "🌐  ${CYAN} Global Version | Hardware Optimized ${NC}"
    echo -e "${BLUE}====================================================${NC}"
}

# 1. Directory Structure & Health Check
show_tree() {
    echo -e "${YELLOW}[Current Vault Physical Structure]${NC}"
    if [ ! -d "$VAULT" ]; then
        echo -e "${RED}⚠️ WARNING: Root directory $VAULT not found! Please run Option [1] to initialize.${NC}"
        return
    fi
    
    # Check core subdirectory integrity
    local missing=0
    for dir in "base/llm" "base/diffusion" "base/vlm" "lora" "tensorrt" "cache"; do
        if [ ! -d "$VAULT/$dir" ]; then
            echo -e "${RED}[Missing] $dir${NC}"
            missing=1
        fi
    done

    if [ $missing -eq 1 ]; then
        echo -e "${RED}👉 Structure incomplete. Run Option [1] to fix.${NC}"
    else
        echo -e "${GREEN}✅ Vault structure is healthy.${NC}"
    fi

    # Display Tree (requires 'tree' pkg, fallback to 'find')
    if command -v tree >/dev/null 2>&1; then
        tree -d -L 3 "$VAULT"
    else
        find "$VAULT" -maxdepth 3 -not -path '*/.*' -type d | sed -e "s/[^-][^\/]*\// |/g" -e "s/|\([^ ]\)/|-- \1/"
    fi
    
    # Show cache size
    if [ -d "$VAULT/cache" ]; then
        echo -e "${BLUE}💡 Cache Usage: $(du -sh "$VAULT/cache" 2>/dev/null | cut -f1)${NC}"
    fi
    echo -e "${BLUE}----------------------------------------------------${NC}"
}

# 2. Safety Initialization
init_vault() {
    echo -e "${YELLOW}[Initializing/Repairing Vault...]${NC}"
    
    # Create directory structure
    sudo mkdir -p "$VAULT/base/llm" "$VAULT/base/diffusion" "$VAULT/base/vlm" \
                "$VAULT/lora" "$VAULT/tensorrt" "$VAULT/cache"
    
    # Set permissions
    sudo chown -R $USER:$USER "$VAULT"
    sudo chmod -R 775 "$VAULT"
    # Set SGID to ensure group inheritance
    sudo find "$VAULT" -type d -exec chmod g+s {} +
    
    # Inject Environment Variables
    if ! grep -q "HF_HOME" ~/.bashrc; then
        echo -e "\n# AI Model Cache Redirect\nexport HF_HOME=\"$VAULT/cache\"\nexport MODELSCOPE_CACHE=\"$VAULT/cache\"" >> ~/.bashrc
        echo -e "${GREEN}✅ Environment variables added to ~/.bashrc${NC}"
    fi
    
    echo -e "${GREEN}✅ Initialization complete. Please run: source ~/.bashrc${NC}"
}

# 3. Path Mapping Helper
generate_mapping() {
    echo -e "\n${YELLOW}[Path Mapping Helper]${NC}"
    read -p "Enter Target Path (e.g., /app/models/my_model): " INPUT_PATH
    echo -e "Category: [1]LLM [2]Diff [3]VLM [4]LoRA [5]TRT"
    read -p "Select [1-5]: " TYPE_NUM

    BASE_NAME=$(basename "$INPUT_PATH")
    case $TYPE_NUM in
        1) SUB="base/llm" ;; 2) SUB="base/diffusion" ;; 3) SUB="base/vlm" ;;
        4) SUB="lora" ;; 5) SUB="tensorrt" ;; *) return ;;
    esac

    TARGET_PATH="$VAULT/$SUB/$BASE_NAME"

    echo -e "\n${BLUE}----------------------------------------------------${NC}"
    echo -e "${GREEN}📍 Command Previews (Copy as needed):${NC}"
    
    echo -e "${YELLOW}Option A (Local Symlink):${NC}"
    echo "mkdir -p \$(dirname \"$INPUT_PATH\") && ln -s \"$TARGET_PATH\" \"$INPUT_PATH\""
    
    echo -e "\n${YELLOW}Option B (Docker Volume Mount):${NC}"
    echo "-v \"$TARGET_PATH\":\"$INPUT_PATH\" \\"
    echo "-v \"$VAULT/cache\":\"/root/.cache/huggingface\""
    
    if [ ! -e "$TARGET_PATH" ]; then
        echo -e "\n${RED}⚠️ Note: Physical file does not exist yet. Please download to:${NC}"
        echo -e "${GREEN}$TARGET_PATH${NC}"
    fi
    echo -e "${BLUE}----------------------------------------------------${NC}"
}

# 4. Model Import/Migration
import_model() {
    echo -e "\n${YELLOW}[Model Migration Tool]${NC}"
    read -e -p "Enter current source path: " SRC_PATH
    [ ! -e "$SRC_PATH" ] && { echo -e "${RED}❌ Source not found.${NC}"; return; }

    echo -e "Target Category: [1]LLM [2]Diff [3]VLM [4]LoRA [5]TRT"
    read -p "Select: " TYPE_NUM
    case $TYPE_NUM in
        1) SUB="base/llm" ;; 2) SUB="base/diffusion" ;; 3) SUB="base/vlm" ;;
        4) SUB="lora" ;; 5) SUB="tensorrt" ;; *) return ;;
    esac

    DEST_DIR="$VAULT/$SUB"
    CMD_COPY="rsync -avP \"$SRC_PATH\" \"$DEST_DIR/\""
    CMD_MOVE="rsync -avP --remove-source-files \"$SRC_PATH\" \"$DEST_DIR/\""

    echo -e "\n${GREEN}🔍 Command Preview:${NC}"
    echo -e "Copy Mode: $CMD_COPY"
    echo -e "Move Mode: $CMD_MOVE"
    
    read -p "Execute now? (y=Move / c=Copy / n=Manual): " MODE
    [ "$MODE" == "y" ] && eval $CMD_MOVE
    [ "$MODE" == "c" ] && eval $CMD_COPY
}

# 5. DGX / High Performance Docker Template
generate_docker_template() {
    echo -e "\n${YELLOW}[DGX / High Performance Docker Template]${NC}"
    read -p "Enter Image Name (Default: nvcr.io/nvidia/pytorch:24.01-py3): " DOCKER_IMAGE
    DOCKER_IMAGE=${DOCKER_IMAGE:-"nvcr.io/nvidia/pytorch:24.01-py3"}
    
    local CURRENT_UID=$(id -u)
    local CURRENT_GID=$(id -g)
    
    echo -e "\n${GREEN}🚀 Optimized Launch Command:${NC}"
    echo -e "${BLUE}----------------------------------------------------${NC}"
    echo "docker run -it --rm \\"
    echo "    --gpus all \\"
    echo "    --shm-size=16g \\"  # Prevents Bus Errors in DataLoader
    echo "    --ulimit memlock=-1 \\"
    echo "    --ulimit stack=67108864 \\"
    echo "    --user $CURRENT_UID:$CURRENT_GID \\"  # Fixes Permission Issues
    echo "    -v \"$VAULT/cache\":\"/root/.cache/huggingface\" \\"
    echo "    -v \"$VAULT\":\"$VAULT\" \\" 
    echo "    -e HF_HOME=\"$VAULT/cache\" \\"
    echo "    -e HF_ENDPOINT=https://hf-mirror.com \\" # Fast mirror for CN users
    echo "    $DOCKER_IMAGE /bin/bash"
    echo -e "${BLUE}----------------------------------------------------${NC}"
    
    echo -e "${CYAN}💡 Optimization Notes:${NC}"
    echo "1. --shm-size: Essential for DGX/Multi-GPU training."
    echo "2. --user: Ensures files created in container are accessible by you on Host."
    echo "3. Consistency: Using identical paths in Host/Container prevents config errors."
}

# --- Main Logic ---
while true; do
    clear
    show_header
    show_tree

    echo -e "Actions:"
    echo "1) 🚀 Initialize / Fix Vault"
    echo "2) 🔗 Generate Mapping Commands"
    echo "3) 📦 Migrate Existing Models"
    echo "4) 🐳 DGX Optimized Docker Template"
    echo "5) 🗑️  Generate Uninstall Command"
    echo "q) Quit"
    read -p ">>> " MAIN_OPT

    case $MAIN_OPT in
        1) init_vault; read -p "Press Enter...";;
        2) generate_mapping; read -p "Press Enter...";;
        3) import_model; read -p "Press Enter...";;
        4) generate_docker_template; read -p "Press Enter...";;
        5) 
            echo -e "\n${RED}To uninstall, run these manually:${NC}"
            echo "sudo rm -rf \"$VAULT\""
            echo "sed -i '/HF_HOME/d' ~/.bashrc"
            read -p "Press Enter..."
            ;;
        q) exit 0;;
        *) sleep 1;;
    esac
done