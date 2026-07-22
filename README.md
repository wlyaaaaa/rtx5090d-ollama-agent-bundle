# RTX 5090D Ollama 本地代理配置备份

这是一个**公开安全版**配置仓库，用来备份 RTX 5090D 32GB 上的 Ollama / OpenClaw / OpenCode / Chatbox 本地代理配置。

本仓库最重要的内容不是换卡流程本身，而是换卡完成后的最终 Ollama 配置、模型别名策略、256K/128K 上下文决策和公开可复现模板。

## 当前状态

项目状态：**已完成 / PASS**，保留 1 个非阻断 WARN。

- 显卡：RTX 5090D 32GB，已完成验证。
- Ollama 端口：`127.0.0.1:32100`。
- 主力模型：`qwen-main-v1`，`num_ctx=262144`。
- 复核模型：`qwen-review-v1`，`num_ctx=131072`。
- Chatbox / OpenClaw / OpenCode 均使用版本化 v1 别名。
- `qwen-main-v1` 256K 两小时稳定性验证：`219/219` 通过，`0` 失败。
- 顶级模型的数据工厂调用已改由 `llm-backend-toolkit` / aicli 管理；本仓库只拥有 GPU、Ollama 端点与模型别名事实，不自行选择智能体。
- 非阻断 WARN：旧 `ollama.exe` 入站防火墙 Allow 规则可能仍存在；当前 Ollama 仅监听 loopback。

## 最终模型策略

| 显示入口 | 底座模型 | 上下文 | 用途 |
| --- | --- | ---: | --- |
| `qwen-main-v1` | `qwen3.6:35b` | `262144` | 默认本地代理主力 |
| `qwen-review-v1` | `qwen3.6:27b` | `131072` | 复核 / 第二意见 |
| `gemma-chat-v1` | `gemma4-31b-chat:latest` | `262144` | Chatbox 通用备用 |
| `north-code-v1` | `north-mini-code-opencode:latest` | `262144` | OpenCode 代码实验备用 |

`qwen-review-v1` 没有继续使用 256K，是因为 27B dense 模型在 150K/200K 上下文下明显变慢。它现在固定为 128K，更适合作为快速复核模型。

## 顶级模型调用结论（2026-07-22）

相同 `qwen-main-v1`、相同 PersonalOS 风格数据清洗题实测后，稳定别名 `data_factory` 选择 **Codex CLI**：21/21、exit 0、47.343 秒、18 个真实 action items，另有 1 条模型元数据警告。Claude Code 也生成 21/21 产物，但约 101.7 秒后 exit 1；Qwen Code 与 OpenCode 未通过结果门槛。

因此 OpenCode 仍是 GUI/实验客户端，但不再被上层工具当作默认数据智能体。具体路由、沙箱、上下文压缩和能力边界由 `llm-backend-toolkit` 拥有；CLI Profile 和 machine run 由 `ai-cli-profile-manager` 拥有。三者不做重复路由，也不自动 fallback。

## 关键配置

```text
OLLAMA_HOST=127.0.0.1:32100
OLLAMA_MODELS=D:\ollama-models
OLLAMA_FLASH_ATTENTION=1
OLLAMA_KV_CACHE_TYPE=q8_0
```

真实机器上可把 `OLLAMA_MODELS` 换成自己的模型目录；公开仓库里只保留示例路径。

## 主要文档

- [public_config_backup/README.md](public_config_backup/README.md)：公开安全的 Ollama / GUI 配置备份。
- [public_config_backup/benchmark-summary.md](public_config_backup/benchmark-summary.md)：最终速度与稳定性摘要。
- [GUI_MODEL_DISPLAY_POLICY.md](GUI_MODEL_DISPLAY_POLICY.md)：GUI 显示哪些模型、隐藏哪些模型。
- [results/final_report.md](results/final_report.md)：项目最终报告和验证证据。
- [03_ACCEPTANCE_TESTS.md](03_ACCEPTANCE_TESTS.md)：验收清单。

## 仓库包含什么

- Ollama `32100` 启停脚本。
- 公开安全的 v1 Modelfile。
- OpenClaw / OpenCode / Chatbox 示例配置。
- 最终 benchmark 摘要。
- 清理过的执行与验收文档。

## 仓库不包含什么

本仓库不应提交以下内容：

- Ollama `blobs/` 模型权重。
- Ollama `manifests/` 本机 manifest。
- 真实 GUI 配置文件。
- logs、backups、`.bak`、临时目录。
- API Key、token、私钥、账号路径。

## 定期备份

公开备份任务只允许提交白名单文件，脚本在提交前会跑敏感信息扫描：

```powershell
.\scripts\10_public_config_backup_to_github.ps1 -Apply
```

默认目标分支是 `codex/public-config-backup`。这个分支可通过 GitHub PR 合并到 `main`。
