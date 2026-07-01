# 执行计划

## 阶段 0：备份与基线

1. 运行 `scripts/01_backup_current_state.ps1 -Apply`。
2. 保存当前 RTX 5080 的已完成基线：64K 三档旧基线，以及 100K 短基线。
3. 记录：prompt_eval_count/rate、eval_count/rate、首字延迟、总耗时、`ollama ps`、GPU 功耗/温度。
4. 备份 OpenClaw 和 OpenCode 配置。
5. 不在 RTX 5080 上继续跑 45K/100K 长测；该场景已明显 offload，留给 RTX 5090D 默认频率验证。

## 阶段 1：换卡与默认频率验证

1. 正常关机断电，换装 RTX 5090D。
2. 检查供电线、显卡固定与散热空间。
3. 安装/更新 NVIDIA 驱动。只有出现异常时才考虑 DDU；不把 DDU 当强制步骤。
4. 保持显卡默认频率，运行：
   - `nvidia-smi`
   - 3D/显存稳定性测试
   - 至少 30 分钟持续 LLM 推理
5. 默认频率未通过，不得进入超频阶段。

## 阶段 2：配置 Ollama

以管理员或当前用户 PowerShell 运行 Dry Run：

```powershell
.\scripts\02_configure_ollama_env.ps1
```

确认输出无误后：

```powershell
.\scripts\02_configure_ollama_env.ps1 -Apply
```

目标环境变量：

```text
OLLAMA_FLASH_ATTENTION=1
OLLAMA_KV_CACHE_TYPE=q8_0
OLLAMA_MODELS=G:\ollama
OLLAMA_HOST=127.0.0.1:11700
```

修改用户环境变量后，完全退出并重新启动 Ollama。

## 阶段 3：创建模型入口

先确认基础模型真实 ID：

```powershell
ollama list
ollama show --modelfile qwen3.6:35b
```

若基础模型不是 `qwen3.6:35b`，把真实 ID 传给脚本：

```powershell
.\scripts\03_create_models.ps1 -BaseModel "真实模型ID" -Apply
```

默认创建：

- `qwen3.6-35b-normal`
- `qwen3.6-35b-unrestricted`

当前换卡前额外工作入口：

- `qwen3.6-35b-100k`
- `qwen3.6-27b-100k`

最大上下文验证入口：

- `qwen3.6-35b-256k`
- `qwen3.6-27b-256k`

创建 100K/256K 无 SYSTEM 模型：

```powershell
.\scripts\08_create_context_models.ps1
.\scripts\08_create_context_models.ps1 -Apply
```

## 阶段 4：接入 OpenClaw

1. 当前实测 OpenClaw 版本使用 OpenAI 兼容 provider：

```text
api=openai-completions
baseUrl=http://127.0.0.1:11700/v1
```

2. 早期 `api=ollama` / 不带 `/v1` 的模板在当前环境推理路径报错：

```text
No API provider registered for api: ollama
```

3. 当前默认模型为 `ollama5090d/qwen3.6-35b-100k`，`thinking=false`。
4. 运行：

```powershell
curl.exe http://127.0.0.1:11700/api/tags
openclaw models list --provider ollama5090d
openclaw models status
openclaw infer model run --model ollama5090d/qwen3.6-35b-100k --prompt "Reply with exactly: ok"
```

5. 执行真实工具调用烟雾测试。

## 阶段 5：接入 OpenCode

优先在 WSL 中运行 OpenCode。OpenCode 官方建议 Windows 用户使用 WSL，以获得更好的文件系统性能和终端兼容性。

1. OpenCode 的 Ollama URL 必须带 `/v1`：

```text
http://127.0.0.1:11700/v1
```

2. 当前桌面入口保留四个选择：
   - 35B Normal 100K：`qwen3.6-35b-100k`，`reasoning=false`
   - 35B Think 100K：`qwen3.6-35b-100k`，`reasoning=true`
   - 27B Review 100K：`qwen3.6-27b-100k`，`reasoning=false`
   - 27B Think 100K：`qwen3.6-27b-100k`，`reasoning=true`
3. 在一个可丢弃测试仓库内完成：读取、修改、运行测试、撤销。

## 阶段 6：性能与上下文晋升

### 100K 换卡对比基准

```powershell
.\scripts\07_run_swap_benchmark.ps1 -Label 5090d_default
.\scripts\07_run_swap_benchmark.ps1 -Label 5090d_default -Long
```

5080 换卡前只跑短基线；45K 长基线留给 5090D 默认频率后执行。

### 256K 晋升条件

只有同时满足以下条件才把生产入口切到 256K：

- 100K 运行无 OOM、驱动复位和异常输出。
- `ollama ps` 显示模型接近 100% GPU，或 offload 对性能影响可接受。
- OpenClaw 完整任务成功率不下降。
- 45K 上下文的 eval rate 与 prompt eval 延迟达到验收目标。

## 阶段 7：超频验证

1. 所有默认频率测试通过后，加载 +320 核心 / +2600 显存配置。
2. 重复完全相同的 100K 基准和真实 OpenClaw/OpenCode 任务。
3. 至少进行 2 小时持续代理负载。
4. 任何黑屏、TDR、CUDA 错误、乱码、静默错误、速度异常回退，均视为超频不稳定。
5. 稳定性优先于峰值 tok/s；失败时回默认频率或降低显存超频。
