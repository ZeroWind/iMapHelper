#!/bin/bash

# --- 配置区：你的中心化存储根目录 ---
# 如果你的数据盘挂载点不同，请修改此处
VAULT="/mnt/models"

# 颜色定义（用于提升终端显示效果）
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 显示横幅
show_header() {
    echo -e "${BLUE}====================================================${NC}"
    echo -e "🧠  ${GREEN} AI 模型存储管理助手 (iMapHelper) ${NC}"
    echo -e "${BLUE}====================================================${NC}"
}

# 1. 目录结构输出与健康检查
show_tree() {
    echo -e "${YELLOW}[当前仓库物理结构]${NC}"
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

# 2. 安全初始化函数 (核心修复：环境变量注入在此)
init_vault() {
    echo -e "${YELLOW}[执行初始化/修复任务...]${NC}"
    
    # 创建目录结构：mkdir -p 确保“存在即跳过”，绝对安全
    sudo mkdir -p "$VAULT/base/llm" "$VAULT/base/diffusion" "$VAULT/base/vlm" \
                "$VAULT/lora" "$VAULT/tensorrt" "$VAULT/cache"
    
    # 修复权限：确保当前用户拥有读写权，并设置 SGID 以便多用户/容器共享
    sudo chown -R $USER:$USER "$VAULT"
    sudo chmod -R 775 "$VAULT"
    sudo find "$VAULT" -type d -exec chmod g+s {} +
    
    echo -e "${GREEN}✅ 物理目录结构已就绪。${NC}"

    # --- 注入环境变量（仅在不存在时添加） ---
    if ! grep -q "HF_HOME" ~/.bashrc; then
        echo -e "\n# AI Model Cache Redirect\nexport HF_HOME=\"$VAULT/cache\"\nexport MODELSCOPE_CACHE=\"$VAULT/cache\"" >> ~/.bashrc
        echo -e "${GREEN}✅ 环境变量已写入 ~/.bashrc${NC}"
        echo -e "${YELLOW}请稍后手动执行: source ~/.bashrc 使缓存重定向立即生效。${NC}"
    else
        echo -e "${BLUE}ℹ️  环境变量已存在，无需重复配置。${NC}"
    fi
}

# 3. 映射路径生成
generate_mapping() {
    if [ ! -d "$VAULT/base" ]; then
        echo -e "${RED}❌ 错误: 核心目录缺失。请先运行选项 [1] 修复环境。${NC}"
        return
    fi

    echo -e "\n${YELLOW}[路径映射配置]${NC}"
    read -p "请输入在应用中预期的引用路径 (如 /home/user/models/Llama3.safetensors): " INPUT_PATH
    echo -e "\n选择物理分类: [1]LLM [2]Diff [3]VLM [4]LoRA [5]TRT"
    read -p "编号 [1-5]: " TYPE_NUM

    BASE_NAME=$(basename "$INPUT_PATH")
    case $TYPE_NUM in
        1) SUB="base/llm" ;; 
        2) SUB="base/diffusion" ;; 
        3) SUB="base/vlm" ;;
        4) SUB="lora" ;; 
        5) SUB="tensorrt" ;; 
        *) echo "无效选择"; return ;;
    esac

    TARGET_PATH="$VAULT/$SUB/$BASE_NAME"

    echo -e "\n${BLUE}----------------------------------------------------${NC}"
    echo -e "📍 ${GREEN}请复制并执行以下指令：${NC}"
    echo -e "\n${YELLOW}方案 A (本地开发/原生环境):${NC}"
    echo "mkdir -p \$(dirname \"$INPUT_PATH\") && ln -s \"$TARGET_PATH\" \"$INPUT_PATH\""
    
    echo -e "\n${YELLOW}方案 B (Docker 容器部署参数):${NC}"
    echo "-v \"$TARGET_PATH\":\"$INPUT_PATH\" \\"
    echo "-v \"$VAULT/cache\":\"/root/.cache/huggingface\""
    
    if [ ! -e "$TARGET_PATH" ]; then
        echo -e "\n${RED}⚠️ 注意: 物理路径下暂无模型文件。${NC}"
        echo -e "请将模型放入: ${GREEN}$TARGET_PATH${NC}"
    fi
    echo -e "${BLUE}----------------------------------------------------${NC}"
}

# 4. 生成卸载指令 (危险操作，仅生成指令)
generate_uninstall_cmd() {
    echo -e "\n${RED}‼️  危险区域: 卸载 iMapHelper 管理环境${NC}"
    echo -e "${YELLOW}本操作将生成删除所有模型文件及清理配置的指令。${NC}"
    read -p "确定要继续吗？(y/n): " CONFIRM
    
    if [ "$CONFIRM" == "y" ]; then
        echo -e "\n${BLUE}----------------------------------------------------${NC}"
        echo -e "${RED}请手动复制以下指令并在终端执行以完成卸载：${NC}\n"
        
        echo -e "# 1. 删除物理模型仓库 (不可逆！)"
        echo "sudo rm -rf \"$VAULT\""
        
        echo -e "\n# 2. 清理环境变量配置"
        echo "sed -i '/HF_HOME/d' ~/.bashrc"
        echo "sed -i '/MODELSCOPE_CACHE/d' ~/.bashrc"
        echo "sed -i '/# AI Model Cache Redirect/d' ~/.bashrc"
        
        echo -e "\n${YELLOW}提示: 执行完后请运行 'source ~/.bashrc' 刷新当前会话。${NC}"
        echo -e "${BLUE}----------------------------------------------------${NC}"
    else
        echo -e "${GREEN}已取消卸载。${NC}"
    fi
}

# --- 主循环逻辑 (确保执行完后回到菜单) ---
while true; do
    clear
    show_header
    show_tree

    echo -e "请选择操作:"
    echo "1) 🚀 初始化 / 修复仓库结构 (含环境变量)"
    echo "2) 🔗 生成模型路径映射指令 (本地/Docker)"
    echo "3) 🗑️  生成卸载指令 (清理环境)"
    echo "q) 退出脚本"
    read -p ">>> " MAIN_OPT

    case $MAIN_OPT in
        1) 
            init_vault 
            read -p "按回车键返回主菜单..." 
            ;;
        2) 
            generate_mapping 
            read -p "按回车键返回主菜单..." 
            ;;
        3) 
            generate_uninstall_cmd 
            read -p "按回车键返回主菜单..." 
            ;;
        q) 
            echo -e "${GREEN}感谢使用，再见！${NC}"
            exit 0 
            ;;
        *) 
            echo -e "${RED}无效选项，请重新输入。${NC}"
            sleep 1
            ;;
    esac
done