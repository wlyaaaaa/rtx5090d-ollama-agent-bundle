# 官方资料来源（审计时应重新检查最新版本）

1. NVIDIA GeForce GPU comparison/specifications: https://www.nvidia.com/en-us/geforce/graphics-cards/compare/
2. NVIDIA GeForce RTX 5090 specifications: https://www.nvidia.com/en-us/geforce/graphics-cards/50-series/rtx-5090/
3. Qwen3.6-35B-A3B official model card: https://huggingface.co/Qwen/Qwen3.6-35B-A3B
4. NVIDIA Qwen3.6-35B-A3B NVFP4 model card: https://huggingface.co/nvidia/Qwen3.6-35B-A3B-NVFP4
5. Ollama FAQ (Flash Attention / KV cache): https://docs.ollama.com/faq
6. Ollama context length: https://docs.ollama.com/context-length
7. Ollama thinking: https://docs.ollama.com/capabilities/thinking
8. Ollama tool calling: https://docs.ollama.com/capabilities/tool-calling
9. Ollama Modelfile reference: https://docs.ollama.com/modelfile
10. OpenClaw Ollama provider: https://docs.openclaw.ai/providers/ollama
11. OpenClaw local models: https://docs.openclaw.ai/gateway/local-models
12. OpenCode providers: https://opencode.ai/docs/providers/
13. OpenCode permissions: https://opencode.ai/docs/permissions/
14. OpenCode Windows/WSL: https://opencode.ai/docs/windows-wsl/

## 实机偏差记录

- 当前 OpenClaw 2026.6.10 推理路径未接受 `api=ollama`；实测可用配置为 `api=openai-completions` 与 `http://127.0.0.1:32100/v1`。
- 上述偏差应在 OpenClaw 升级后重新验证，不应盲目回切。
