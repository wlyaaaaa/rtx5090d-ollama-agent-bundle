# Public RTX 5090D Ollama Config Backup

This directory is a sanitized public backup of the final local Ollama setup used after the RTX 5080 -> RTX 5090D upgrade.

It is safe for a public repository because it contains only templates and measured summaries. It intentionally does not include local GUI config files, API keys, model blobs, manifests, logs, backups, or machine-specific account paths.

## Final Local Policy

Endpoint:

```text
http://127.0.0.1:32100
```

Recommended Ollama environment:

```text
OLLAMA_HOST=127.0.0.1:32100
OLLAMA_MODELS=D:\ollama-models
OLLAMA_FLASH_ATTENTION=1
OLLAMA_KV_CACHE_TYPE=q8_0
```

Visible model aliases:

| Alias | Base model | Context | Role |
| --- | --- | ---: | --- |
| `qwen-main-v1` | `qwen3.6:35b` | `262144` | Default local agent model |
| `qwen-review-v1` | `qwen3.6:27b` | `131072` | Review / second opinion fallback |
| `gemma-chat-v1` | `gemma4-31b-chat:latest` | `262144` | Chat fallback |
| `north-code-v1` | `north-mini-code-opencode:latest` | `262144` | OpenCode code-specialist experiment |

Why review is 128K: temporary 256K testing showed the dense 27B model was much slower than the 35B MoE main model at long contexts. Keeping review at 128K preserves usefulness without making routine review calls the slow path.

## Files

- `ollama.env.example`: public-safe environment template.
- `modelfiles/`: final alias Modelfiles.
- `openclaw.example.json5`: OpenClaw provider/model template.
- `opencode.example.jsonc`: OpenCode provider/model template.
- `chatbox-local-models.example.json`: Chatbox local Ollama model list template.
- `benchmark-summary.md`: final speed and stability summary.

## Apply Locally

Create the aliases after pulling the base models:

```powershell
ollama create qwen-main-v1 -f .\public_config_backup\modelfiles\Modelfile.qwen-main-v1
ollama create qwen-review-v1 -f .\public_config_backup\modelfiles\Modelfile.qwen-review-v1
ollama create gemma-chat-v1 -f .\public_config_backup\modelfiles\Modelfile.gemma-chat-v1
ollama create north-code-v1 -f .\public_config_backup\modelfiles\Modelfile.north-code-v1
```

Then point OpenClaw, OpenCode, and Chatbox at `http://127.0.0.1:32100` or `http://127.0.0.1:32100/v1` depending on the client.
