# 本文档的独立合理性复核

## 结论

**总体：有条件通过。**

本方案的核心选择合理：5090D 32GB 上，以 Qwen3.6-35B-A3B 4-bit 作为 OpenClaw/OpenCode 默认主力，优先吞吐与长代理循环；Ollama 开启 Flash Attention、q8_0 KV；当前实测 OpenClaw 与 OpenCode 均通过 Ollama OpenAI 兼容 `/v1` 接口接入。

## 已由官方资料支持的部分

- RTX 5090/同显存规格平台具备 32GB GDDR7、512-bit、1792 GB/s；RTX 5080 为 16GB、256-bit、960 GB/s。
- Qwen3.6-35B-A3B 为 35B 总参数、约 3B 激活，原生 262K 上下文，并支持工具调用与 thinking 控制。
- Ollama 支持 Flash Attention 与 q8_0 KV Cache；q8_0 约为 f16 KV 内存的一半，质量损失通常很小。
- Ollama 官方建议代理、搜索和编码工具至少使用 64K 上下文。
- 当前 OpenClaw 版本的实测推理路径需要 `api=openai-completions` 与 `/v1`；早期原生 `api=ollama` 配置仅作为未来版本重新验证项。
- OpenCode 可通过 Ollama 的 OpenAI 兼容 `/v1` 接口连接；Windows 下官方推荐 WSL。

## 需要实机验证的部分

- `qwen3.6:35b` 是否为当前机器上的精确模型 ID。
- Q4_K_M 的实际文件大小、视觉投影器占用和 64K/128K 时是否全 GPU 驻留。
- 5090D 上的实际 tok/s；文档中的性能门槛是工程目标，不是保证。
- +320/+2600 是否在 2 小时以上持续 LLM/代理负载下无静默错误。
- OpenClaw/OpenCode 当前版本的配置合并规则与用户现有配置是否冲突。

## 主动修正的潜在问题

1. 不直接采用 262144 上下文作为生产默认值；当前先用 100K，5090D 默认频率验收通过后再晋升。
2. 不在脚本中自动应用 GPU 超频。
3. 不把“无限制模型”与“无限系统权限”混为一谈。
4. 不固定 `num_thread=8`；全 GPU 推理时应先让 Ollama 自动选择，再用实测决定。
5. 不用单一 tok/s 决定升级成功；必须测完整 OpenClaw/OpenCode 任务。
6. 不假定 DDU 是换卡必需步骤；只有驱动异常时才使用。

## 剩余风险

- 本地模型仍可能受提示注入影响。低拒答版会提高服从性，因此更需要权限隔离。
- 100K/256K 的可行性会随 Ollama、llama.cpp、驱动和模型量化更新而变化。
- 系统提示无法真正解除基础模型权重中的对齐行为。
