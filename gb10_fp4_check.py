import torch
import shutil

def gb10_special_check():
    print(f"{'='*20} 💠 DGX Spark GB10 专用预检 (FP4 优化版) {'='*20}")
    
    # 1. 核心架构校验
    major, minor = torch.cuda.get_device_capability(0)
    print(f"📍 硬件架构: SM {major}.{minor} (Blackwell)")
    
    if major < 9:
        print("❌ 警告: 当前设备不是 Blackwell 架构，不支持硬件级 FP4 加速。")
        return

    # 2. 驱动与工具链校验 (FP4 需要极高的软件版本)
    cuda_ver = torch.version.cuda
    print(f"🧪 CUDA 版本: {cuda_ver}")
    if float(cuda_ver) < 12.4:
        print("⚠️ 风险: FP4 硬件加速建议使用 CUDA 12.4 或更高版本。")

    # 3. 显存与带宽逻辑预检
    vram_gb = torch.cuda.get_total_memory(0) / (1024**3)
    print(f"🧠 统一内存: {vram_gb:.2f} GB")
    
    # FP4 模式下的模型占用估算 (参数量 * 0.5 字节)
    # Qwen3-72B 为例: 72 * 0.5 = 36GB，即便加上 KV Cache，128G 绰绰有余
    print("\n📦 模型适配建议 (FP4 模式):")
    models = {
        "Qwen3-72B": 36,
        "Qwen3-Omni-7B": 4,
        "Llama-3.1-405B": 203 # 128G 装不下 405B，即使是 FP4
    }
    
    for name, fp4_size in models.items():
        status = "✅ 可完美运行" if vram_gb > (fp4_size + 20) else "❌ 显存不足"
        print(f" - {name.ljust(15)}: 预估权重 {fp4_size}GB | {status}")

    # 4. FP4 推理库检查
    print("\n🛠️ 软件环境检查:")
    has_trt_llm = shutil.which("nm-vllm") or shutil.which("trtllm-build")
    if has_trt_llm:
        print("✅ 检测到 TensorRT-LLM 环境，可发挥 FP4 最高效能。")
    else:
        print("💡 建议: 安装 TensorRT-LLM 或支持 FP4 的 vLLM 分支以突破带宽瓶颈。")

if __name__ == "__main__":
    gb10_special_check()