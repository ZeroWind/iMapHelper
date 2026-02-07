#!/bin/bash

# --- 配置区：你的中心化存储根目录 ---
VAULT="/mnt/models"

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

show_header() {
    echo -e "${BLUE}====================================================${NC}"
    echo -e "🧠  ${GREEN} AI 模型存储管理助手 (安全加固版)${NC}"
    echo -e "${BLUE}====================================================${NC}"
}

# 1. 目录结构输出与健康检查
show_tree() {
    echo -e "${YELLOW}[当前仓库物理结构]${NC}"
    if [ ! -d "$VAULT" ]; then
        echo -e "${RED}⚠️ 警告: 根目录 $VAULT 不存在！${NC}"
        return
    fi
    
    # 检查核心子目录完整性
    local missing=0
    for dir in "base/llm" "base/diffusion" "base/vlm" "lora" "tensorrt" "cache"; do
        if [ ! -d "$VAULT/$dir" ]; then
            echo -e "${RED}[缺失] $dir${NC}"
            missing=1
        fi
    done

    if [ $missing -eq 1 ]; then
        echo -e "${RED}👉 检测到目录结构不完整，请运行选项 [1] 修复（不会影响已有模型）。${NC}"
    fi

    # 输出目录树
    if command -v tree >/dev/null 2>&1; then
        tree -d -L 3 "$VAULT"
    else
        find "$VAULT" -maxdepth 3 -not -path '*/.*' -type d | sed -e "s/[^-][^\/]*\// |/g" -e "s/|\([^ ]\)/|-- \1/"
    fi
    
    # 额外场景：缓存占用统计
    if [ -d "$VAULT/cache" ]; then
        local cache_size=$(du -sh "$VAULT/cache" 2>/dev/null | cut -f1)
        echo -e "${BLUE}💡 缓存提示: 当前 cache 目录占用 $cache_size。若空间不足可手动清理此目录。${NC}"
    fi
    echo -e "${BLUE}----------------------------------------------------${NC}"
}

# 2. 安全初始化（不覆盖原则）
init_vault() {
    echo -e "${YELLOW}[检测并初始化仓库结构...]${NC}"
    
    # 安全创建：mkdir -p 天然支持“存在则跳过”，不会删除任何文件
    sudo mkdir -p "$VAULT/base/llm" "$VAULT/base/diffusion" "$VAULT/base/vlm" \
                "$VAULT/lora" "$VAULT/tensorrt" "$VAULT/cache"
    
    # 仅修复权限，不更改文件内容
    sudo chown -R $USER:$USER "$VAULT"
    sudo chmod -R 775 "$VAULT"
    sudo find "$VAULT" -type d -exec chmod g+s {} +
    
    echo -e "${GREEN}✅ 结构修复/初始化完成。已有模型文件安全无损。${NC}"

    # 注入环境变量（带幂等检查）
    if ! grep -q "HF_HOME" ~/.bashrc; then
        echo -e "\n# AI Model Cache Redirect\nexport HF_HOME=\"$VAULT/cache\"\nexport MODELSCOPE_CACHE=\"$VAULT/cache\"" >> ~/.bashrc
        echo -e "${GREEN}✅ 环境变量已配置，请 source ~/.bashrc 生效。${NC}"
    fi
}

# 3. 映射路径生成
generate_mapping() {
    if [ ! -d "$VAULT/base" ]; then
        echo -e "${RED}❌ 错误: 核心目录缺失。请先运行选项 [1] 修复环境。${NC}"
        return
    fi

    echo -e "\n${YELLOW}[路径映射配置]${NC}"
    read -p "请输入预期引用路径: " INPUT_PATH
    echo -e "\n选择分类: [1]LLM [2]Diff [3]VLM [4]LoRA [5]TRT"
    read -p "编号 [1-5]: " TYPE_NUM

    BASE_NAME=$(basename "$INPUT_PATH")
    case $TYPE_NUM in
        1) SUB="base/llm" ;; 2) SUB="base/diffusion" ;; 3) SUB="base/vlm" ;;
        4) SUB="lora" ;; 5) SUB="tensorrt" ;; *) return ;;
    esac

    TARGET_PATH="$VAULT/$SUB/$BASE_NAME"

    echo -e "\n${BLUE}----------------------------------------------------${NC}"
    echo -e "${YELLOW}方案 A (本地):${NC} ln -s \"$TARGET_PATH\" \"$INPUT_PATH\""
    echo -e "${YELLOW}方案 B (Docker):${NC} -v \"$TARGET_PATH\":\"$INPUT_PATH\" -v \"$VAULT/cache\":\"/root/.cache/huggingface\""
    
    if [ ! -e "$TARGET_PATH" ]; then
        echo -e "\n${RED}⚠️ 注意: 物理路径下暂无模型文件，请下载至:${NC}"
        echo -e "${GREEN}$TARGET_PATH${NC}"
    fi
    echo -e "${BLUE}----------------------------------------------------${NC}"
}

# --- 主逻辑 ---
show_header
show_tree

echo "操作: 1)修复/初始化仓库  2)映射指令  3)刷新  q)退出"
read -p ">>> " MAIN_OPT
case $MAIN_OPT in
    1) init_vault ;; 2) generate_mapping ;; 3) clear; show_header; show_tree ;; q) exit 0 ;;
esac