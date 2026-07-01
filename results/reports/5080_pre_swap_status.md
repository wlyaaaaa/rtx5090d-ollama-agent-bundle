# RTX 5080 换卡前最终状态与基线

时间：2026-07-01 America/Los_Angeles

## 最终结论

- 模型、配置、脚本、文档、GitHub 提交：已完成。
- Ollama / OpenCode / OpenClaw：换卡前已停止，`127.0.0.1:11700` 无监听。
- RTX 5080：已记录 100K 短基线；不再在 5080 上跑 45K 长压测。
- 最终本地备份：已写入 `results/backups/backup-20260701-080422`，该目录被 `.gitignore` 排除，不提交 GitHub。
- 严格安全门禁残留：Windows 防火墙仍存在两条 `ollama.exe` 入站 Allow 规则，当前 Codex 会话无管理员权限，无法代为禁用。若按网络收口门禁执行，需在管理员 PowerShell 运行：

```powershell
netsh advfirewall firewall set rule name="ollama.exe" dir=in new enable=no
```

硬件换卡本身不依赖这两条规则；Ollama 当前已停，后续启动脚本会绑定 `127.0.0.1:11700`。

## 模型入口

当前主动入口均无 SYSTEM 段：

- `qwen3.6-35b-100k`：35B 主力，`num_ctx=100000`。
- `qwen3.6-27b-100k`：27B 复核，`num_ctx=100000`。
- `qwen3.6-35b-256k`：5090D 通过 100K 验收后的晋升候选。
- `qwen3.6-27b-256k`：5090D 通过 100K 验收后的晋升候选。

保留的旧 64K/normal/unrestricted 模型仅作历史兼容，不作为当前 OpenCode/OpenClaw 默认入口。

## OpenClaw / OpenCode 配置

- OpenClaw 使用 Ollama OpenAI 兼容接口：`http://127.0.0.1:11700/v1`，`api=openai-completions`。
- OpenClaw 默认模型：`ollama5090d/qwen3.6-35b-100k`。
- OpenClaw 旧 warning：telegram / parallel / deepseek 配置 warning 已清理。
- OpenCode 桌面 4 个入口已配置为 100K：
  - 35B normal：`qwen3.6-35b-100k`，`reasoning=false`。
  - 35B think：`qwen3.6-35b-100k`，`reasoning=true`。
  - 27B review：`qwen3.6-27b-100k`，`reasoning=false`。
  - 27B think：`qwen3.6-27b-100k`，`reasoning=true`。
- OpenCode 桌面版由用户实测可用；CLI 不作为换卡前阻断项。

## 5080 基线

当前 GPU：`NVIDIA GeForce RTX 5080`，显存约 `16303 MiB`。

用户声明当前 5080 OC：核心 `+300`，显存 `+2000`。本包未自动应用或修改超频。

100K 干净短测：

- 模型：`qwen3.6-35b-100k`。
- 上下文：`num_ctx=100000`。
- 结果文件：`results/benchmarks/bench_5080_preswap_clean_100k_1k_128_20260701-073514.json`。
- 摘要：prompt tokens `647`，prompt eval `14.80 tok/s`，eval `5.96 tok/s`，wall `65.09s`。
- `ollama ps` 当时显示约 `41%/59% CPU/GPU`，说明 RTX 5080 16GB 下 35B + 100K 已明显 offload。

旧 64K 基线保留用于参考：

- `results/benchmarks/bench_5080_64k_1k_128_20260701.json`
- `results/benchmarks/bench_5080_64k_25k_64_20260701.json`
- `results/benchmarks/bench_5080_64k_40k_64_20260701.json`

## 换卡前不再做

- 不在 RTX 5080 上跑 2 小时代理负载；该测试应在 RTX 5090D 默认频率下执行。
- 不在 RTX 5080 上跑 45K 长压测；100K 短测已经证明 16GB 下 offload 明显。
- 不迁移 5080 的 `+300/+2000` 超频到 5090D。

## 换卡后第一轮命令

先默认频率，不上 OC：

```powershell
nvidia-smi
.\scripts\05_start_ollama_11700.ps1 -Apply
ollama ps
openclaw models list --provider ollama5090d
.\scripts\07_run_swap_benchmark.ps1 -Label 5090d_default
.\scripts\07_run_swap_benchmark.ps1 -Label 5090d_default -Long
```

验收通过后，再考虑 256K 晋升和 5090D 超频。
