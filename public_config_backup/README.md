# 公开安全配置备份

这里保存 RTX 5090D 本地 Ollama 代理栈的**公开安全版配置**。

它不是本机真实配置的完整拷贝，而是可复现模板：可以公开、可以回看、可以给另一台机器参考，但不会泄露真实 GUI 配置、模型权重、manifest、日志、备份、用户名路径或密钥。

## 最终 Ollama 配置

```text
OLLAMA_HOST=127.0.0.1:32100
OLLAMA_MODELS=D:\ollama-models
OLLAMA_FLASH_ATTENTION=1
OLLAMA_KV_CACHE_TYPE=q8_0
```

说明：

- `127.0.0.1:32100` 是最终稳定端口。
- `11700` 不再使用。
- `OLLAMA_MODELS` 在公开模板中使用示例路径，真实机器可自行替换。
- Flash Attention 与 q8_0 KV Cache 是当前推荐组合。

## 最终模型别名

| 别名 | 底座模型 | 上下文 | 用途 |
| --- | --- | ---: | --- |
| `qwen-main-v1` | `qwen3.6:35b` | `262144` | 默认主力代理模型 |
| `qwen-review-v1` | `qwen3.6:27b` | `131072` | 复核 / 第二意见 |
| `gemma-chat-v1` | `gemma4-31b-chat:latest` | `262144` | Chatbox 通用备用 |
| `north-code-v1` | `north-mini-code-opencode:latest` | `262144` | OpenCode 代码实验备用 |

## 为什么 Review 是 128K

`qwen-review-v1` 曾临时按 256K 测试。它能跑完，但 27B dense 模型在长上下文下明显慢于 35B MoE 主力模型：

- 100K：输出约 `50.64 tok/s`
- 150K：输出约 `44.65 tok/s`
- 200K：输出约 `39.62 tok/s`

复核模型的定位是“快速第二意见”，所以最终改为 128K。主力长上下文仍交给 `qwen-main-v1`。

## 文件说明

- `ollama.env.example`：Ollama 环境变量模板。
- `modelfiles/`：最终 v1 alias Modelfile。
- `openclaw.example.json5`：OpenClaw provider / model 模板。
- `opencode.example.jsonc`：OpenCode provider / model 模板。
- `chatbox-local-models.example.json`：Chatbox 本地 Ollama 模型列表模板。
- `benchmark-summary.md`：速度与稳定性摘要。

## 本地应用

先拉取底座模型，然后创建别名：

```powershell
ollama create qwen-main-v1 -f .\public_config_backup\modelfiles\Modelfile.qwen-main-v1
ollama create qwen-review-v1 -f .\public_config_backup\modelfiles\Modelfile.qwen-review-v1
ollama create gemma-chat-v1 -f .\public_config_backup\modelfiles\Modelfile.gemma-chat-v1
ollama create north-code-v1 -f .\public_config_backup\modelfiles\Modelfile.north-code-v1
```

客户端地址：

- Ollama 原生：`http://127.0.0.1:32100`
- OpenAI-compatible：`http://127.0.0.1:32100/v1`

## 不要公开提交

- `G:\ollama\blobs`
- `G:\ollama\manifests`
- `logs`
- `backups`
- 真实 Chatbox/OpenClaw/OpenCode 配置
- `.bak`
- 任何 token、key、私钥
