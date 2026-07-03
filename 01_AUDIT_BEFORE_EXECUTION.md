# 审计优先：执行代理必须先完成

## 角色

你是独立审计代理。你的任务不是照抄本包，而是先判断本包在当前机器、当前软件版本和当前模型版本上是否合理。

## 输出格式

在执行任何更改前，生成 `results/reports/audit_report.md`，每项标记：

- PASS：已验证并可执行
- WARN：可执行但存在假设或风险
- FAIL：不得继续
- N/A：不适用

每项必须附上证据：命令输出、配置文件路径、版本号或官方文档日期。

## 必审项目

### A. 硬件与驱动

1. `nvidia-smi` 显示 RTX 5090D，显存约 32GB，而不是 24GB V2。
2. 驱动能正常识别 CUDA；无 Code 43、掉卡或明显 PCIe 降速异常。
3. 电源、供电线与显卡厂商要求匹配；接头无明显弯折、松动或过热迹象。
4. 首轮部署与基准必须在显卡默认频率完成。
5. +320/+2600 只在默认频率验收通过后单独测试；不得由本包脚本自动施加。

### B. 软件与端口

1. 记录 Windows、NVIDIA 驱动、Ollama、OpenClaw、OpenCode 的版本。
2. 确认 `127.0.0.1:32100` 未被其他程序占用；若已占用，统一修改所有配置。
3. 确认模型目录 `G:\ollama` 存在、空间充足、权限正常。
4. 确认防火墙没有把 Ollama 暴露到不可信网络。默认仅监听回环地址。

### C. 模型身份

1. 执行 `ollama list`，确定真实基础模型 ID。
2. 对基础模型执行 `ollama show --modelfile <MODEL_ID>`。
3. 确认模型确实是 Qwen3.6-35B-A3B 的 4-bit / Q4_K_M 量化，而不是同名错误模型。
4. 若 `qwen3.6:35b` 不存在，允许使用已验证的精确模型 ID；禁止盲目改名后继续。
5. 系统提示只能改变行为倾向，不能把对齐模型真正“去审查”或改变权重。审计报告必须明确这一点。

### D. Ollama 能力

1. 当前 Ollama 版本支持 Flash Attention、`OLLAMA_KV_CACHE_TYPE=q8_0`、tool calling 与 `think` 字段。
2. 100K 工作上下文运行时，`ollama ps` 显示模型尽可能为 `100% GPU`；RTX 5080 16GB 下已记录 `41%/59% CPU/GPU` offload，不能作为 5090D 失败依据。
3. 如果出现 CPU offload，先记录比例、速度和原因，再决定是否接受。
4. 256K 入口已准备好，但仅在 RTX 5090D 默认频率下 100K 验收通过后晋升。

### E. 集成正确性

1. OpenClaw 当前实测可用路径为 `api=openai-completions` + `http://127.0.0.1:32100/v1`。若将来 OpenClaw 原生 `api=ollama` 路径恢复可用，必须重新实测后再切换。
2. OpenCode 使用 `/v1` OpenAI 兼容 URL。
3. OpenClaw 的 `contextWindow` 与 `params.num_ctx` 保持一致。
4. OpenClaw 工具调用返回结构化 tool call，而不是把 JSON 当普通文本。
5. OpenCode 能读取仓库、编辑测试文件并运行测试；权限配置与选择的版本一致。

## 硬停止条件

任一项发生即 FAIL，并停止执行：

- GPU 不是 32GB RTX 5090D。
- 显卡在默认频率下出现黑屏、驱动复位、CUDA 错误或显存错误。
- 未备份原 Ollama 环境、模型清单和 OpenClaw/OpenCode 配置。
- 基础模型身份无法确认。
- OpenClaw 工具调用连续 3 次失败或输出原始工具 JSON。
- 100K 上下文在 RTX 5090D 默认频率下持续 OOM，且降低 batch/关闭视觉后仍无法解决。
- 发现配置会把 Ollama 暴露到公网或不可信局域网。

## 审计结论模板

```text
总体结论：PASS / WARN / FAIL
可执行阶段：0 / 1 / 2 / 3 / 4 / 5
基础模型真实 ID：
Ollama 版本：
GPU / 显存：
100K 是否 100% GPU：
OpenClaw 工具调用：
OpenCode 编辑与测试：
主要风险：
建议修改：
```
