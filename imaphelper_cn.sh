#!/bin/bash

# --- 配置区：你的中心化存储根目录 ---
VAULT="/mnt/models"

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# 显示横幅
show_header() {
    echo -e "${BLUE}====================================================${NC}"
    echo -e "🧠  ${GREEN} AI 模型中心化存储管理助手 (iMapHelper) ${NC}"
    echo -e "${BLUE}====================================================${NC}"
}

# 1. 目录结构输出与健康检查
show_tree() {
    echo -e "${YELLOW}[当前模型仓库物理结构]${NC}"
    if [ ! -d "$VAULT" ]; then
        echo -e "${RED}⚠️ 警告: 根目录 $VAULT 不存在！请运行选项 [1] 进行初始化。${NC}"
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
        # 若系统没装 tree，则使用 find 模拟
        find "$VAULT" -maxdepth 3 -not -path '*/.*' -type d | sed -e "s/[^-][^\/]*\// |/g" -e "s/|\([^ ]\)/|-- \1/"
    fi
    
    # 统计缓存占用
    if [ -d "$VAULT/cache" ]; then
        local cache_size=$(du -sh "$VAULT/cache" 2>/dev/null | cut -f1)
        echo -e "${BLUE}💡 缓存提示: 当前 cache 目录占用 $cache_size。${NC}"
    fi
    echo -e "${BLUE}----------------------------------------------------${NC}"
}

# 2. 安全初始化
init_vault() {
    echo -e "${YELLOW}[正在初始化模型仓库结构...]${NC}"
    sudo mkdir -p "$VAULT/base/llm" "$VAULT/base/diffusion" "$VAULT/base/vlm" \
                "$VAULT/lora" "$VAULT/tensorrt" "$VAULT/cache"
    sudo chown -R $USER:$USER "$VAULT"
    sudo chmod -R 775 "$VAULT"
    sudo find "$VAULT" -type d -exec chmod g+s {} +
    
    # 注入环境变量
    if ! grep -q "HF_HOME" ~/.bashrc; then
        echo -e "\n# AI Model Cache Redirect\nexport HF_HOME=\"$VAULT/cache\"\nexport MODELSCOPE_CACHE=\"$VAULT/cache\"" >> ~/.bashrc
        echo -e "${GREEN}✅ 环境变量已注入 ~/.bashrc${NC}"
    fi
    echo -e "${GREEN}✅ 初始化完成。请执行刷新指令: source ~/.bashrc${NC}"
}

# 3. 映射路径生成
generate_mapping() {
    echo -e "\n${YELLOW}[路径映射(软链/挂载)助手]${NC}"
    read -p "请输入应用引用的目标路径: " INPUT_PATH
    echo -e "物理分类: [1]LLM [2]Diff [3]VLM [4]LoRA [5]TRT"
    read -p "选择 [1-5]: " TYPE_NUM

    BASE_NAME=$(basename "$INPUT_PATH")
    case $TYPE_NUM in
        1) SUB="base/llm" ;; 2) SUB="base/diffusion" ;; 3) SUB="base/vlm" ;;
        4) SUB="lora" ;; 5) SUB="tensorrt" ;; *) return ;;
    esac

    TARGET_PATH="$VAULT/$SUB/$BASE_NAME"
    echo -e "\n${BLUE}----------------------------------------------------${NC}"
    echo -e "${GREEN}📍 指令预览 (按需复制):${NC}"
    # 方案 A 增加了 mkdir -p 确保本地父目录存在
    echo -e "${YELLOW}方案 A (本地软链接):${NC}"
    echo "mkdir -p \$(dirname \"$INPUT_PATH\") && ln -s \"$TARGET_PATH\" \"$INPUT_PATH\""
    
    echo -e "\n${YELLOW}方案 B (Docker 挂载参数):${NC}"
    echo "-v \"$TARGET_PATH\":\"$INPUT_PATH\" \\"
    echo "-v \"$VAULT/cache\":\"/root/.cache/huggingface\""
    echo -e "${BLUE}----------------------------------------------------${NC}"
}

# 4. 模型入库 (核心更新：输出指令供用户选择)
import_model() {
    echo -e "\n${YELLOW}[模型入库搬运助手]${NC}"
    read -e -p "请输入当前模型的完整路径 (支持 Tab 补全): " SRC_PATH
    
    if [ ! -e "$SRC_PATH" ]; then
        echo -e "${RED}❌ 错误: 找不到源文件或目录。${NC}"; return
    fi

    echo -e "选择入库分类: [1]LLM [2]Diff [3]VLM [4]LoRA [5]TRT"
    read -p "编号 [1-5]: " TYPE_NUM
    case $TYPE_NUM in
        1) SUB="base/llm" ;; 2) SUB="base/diffusion" ;; 3) SUB="base/vlm" ;;
        4) SUB="lora" ;; 5) SUB="tensorrt" ;; *) return ;;
    esac

    DEST_DIR="$VAULT/$SUB"
    
    # 构建底层指令
    CMD_COPY="rsync -avP \"$SRC_PATH\" \"$DEST_DIR/\""
    CMD_MOVE="rsync -avP --remove-source-files \"$SRC_PATH\" \"$DEST_DIR/\""

    echo -e "\n${BLUE}----------------------------------------------------${NC}"
	echo -e "\n${GREEN}🔍 搬运指令预览：${NC}"
    echo -e "复制: $CMD_COPY"
    echo -e "移动: $CMD_MOVE"
    echo -e "${BLUE}----------------------------------------------------${NC}"

    read -p "确认操作？(y=由脚本执行移动 / c=由脚本执行复制 / n=我稍后手动执行): " MODE

	read -p "是否由脚本立即执行？(y=移动 / c=复制 / n=手动执行): " MODE
    [ "$MODE" == "y" ] && eval $CMD_MOVE
    [ "$MODE" == "c" ] && eval $CMD_COPY
}

# 5. 生成卸载指令
generate_uninstall_cmd() {
    # 动态获取当前脚本配置的路径，而不是直接写字符串
    local CURRENT_VAULT="$VAULT"

    echo -e "\n${RED}‼️  危险区域: 卸载 iMapHelper${NC}"
    echo -e "当前脚本配置的管理目录为: ${CYAN}$CURRENT_VAULT${NC}"
    
    # 增加一层路径存在性检查
    if [ ! -d "$CURRENT_VAULT" ]; then
        echo -e "${YELLOW}提示: 目标目录 $CURRENT_VAULT 本就不存在，无需删除。${NC}"
    fi

    read -p "确定要生成针对 $CURRENT_VAULT 的卸载指令吗？(y/n): " CONFIRM
    if [ "$CONFIRM" == "y" ]; then
        echo -e "\n${RED}请手动执行以下操作以完全卸载：${NC}"
        echo -e "${BLUE}----------------------------------------------------${NC}"
        
        # 使用变量构建指令，确保灵活性
        echo -e "# 1. 删除数据目录 (请务必核对路径！)"
        echo "sudo rm -rf \"$CURRENT_VAULT\""
        
        echo -e "\n# 2. 清理环境变量"
        echo "sed -i '/HF_HOME/d' ~/.bashrc && sed -i '/MODELSCOPE_CACHE/d' ~/.bashrc"
        
        echo -e "\n# 3. 刷新环境"
        echo "source ~/.bashrc"
        echo -e "${BLUE}----------------------------------------------------${NC}"
    fi
}

# --- 主循环 ---
while true; do
    clear
    show_header
    show_tree
    echo -e "请选择操作:"
    echo "1) 🚀 修复/初始化仓库与环境"
    echo "2) 🔗 生成软链接与映射指令"
    echo "3) 📦 模型入库 (显示指令/自动搬运)"
    echo "4) 🗑️  生成卸载指令"
    echo "q) 退出"
    read -p ">>> " MAIN_OPT

    case $MAIN_OPT in
        1) init_vault; read -p "按回车返回...";;
        2) generate_mapping; read -p "按回车返回...";;
        3) import_model; read -p "按回车返回...";;
        4) generate_uninstall_cmd; read -p "按回车返回...";;
        q) echo "再见！"; exit 0;;
        *) echo "无效选择"; sleep 1;;
    esac
done