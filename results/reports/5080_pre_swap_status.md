# RTX 5080 换卡前状态与基线

时间：2026-07-01 02:35 America/Los_Angeles

## 结论

- Ollama 服务：PASS，`127.0.0.1:11700` 可用。
- 本包两个派生模型：PASS，已创建。
- OpenClaw 配置：PASS，已改为 256K 上下文入口，模型列表显示 `Ctx 256k`。
- OpenCode 配置：PASS，CLI 已安装并能列出 4 个桌面模型入口，均已改为 256K context。
- 5080 64K 运行：PASS/WARN，可运行但发生 CPU offload，`40%/60% CPU/GPU`，显存贴近上限。
- 完整备份脚本：PASS，已运行 `scripts/01_backup_current_state.ps1 -Apply`。

## 服务与模型

- Ollama API：`http://127.0.0.1:11700/api/version` 返回 `0.31.1`。
- 监听地址：`127.0.0.1:11700`，进程名 `ollama`。
- 基础模型：`qwen3.6:35b`，Q4_K_M，tools/thinking 可用。
- 派生模型：
  - `qwen3.6-35b-normal:latest`，ID `5ba74aaf2e97`，约 23GB，`num_ctx=65536`，`num_predict=8192`。
  - `qwen3.6-35b-unrestricted:latest`，ID `bcfbb249d868`，约 23GB，`num_ctx=65536`，`num_predict=-1`。
  - `qwen3.6-35b-256k:latest`，ID `46c6d39f92e7`，约 23GB，`num_ctx=262144`，`num_predict=8192`，无 SYSTEM 段。
  - `qwen3.6-27b-256k:latest`，ID `2b3a35c95f39`，约 17GB，`num_ctx=262144`，`num_predict=8192`，无 SYSTEM 段。
- 可选复核模型：
  - `qwen3.6:27b`，ID `a50eda8ed977`，约 17GB，27.8B dense，Q4_K_M，原生 context length `262144`，tools/thinking 可用。
  - 该模型仅下载基础模型并加入客户端列表，未创建带系统提示词的派生模型。

## 配置落地

- OpenClaw 配置文件：`C:\Users\10979\.openclaw\openclaw.json`
- OpenClaw 备份：`C:\Users\10979\.openclaw\openclaw.json.bak.ollama5090d-20260701-023046`
- OpenClaw 实测可用配置：
  - provider：`ollama5090d`
  - api：`openai-completions`
  - baseUrl：`http://127.0.0.1:11700/v1`
  - default：`ollama5090d/qwen3.6-35b-256k`
  - optional review model：`ollama5090d/qwen3.6-27b-256k`
  - contextWindow / num_ctx：`262144`

说明：bundle 模板原建议 OpenClaw 使用 `api: "ollama"` 与不带 `/v1` 的原生地址；但当前 OpenClaw 2026.6.10 推理路径报错 `No API provider registered for api: ollama`。实机验证后改为 Ollama OpenAI 兼容接口，`openclaw infer model run` 已通过。

- OpenCode 配置文件：`C:\Users\10979\.config\opencode\opencode.jsonc`
- OpenCode 备份：`C:\Users\10979\.config\opencode\opencode.jsonc.bak.ollama5090d-20260701-023046`
- OpenCode 4 模型入口：
  - `ollama5090d/qwen3.6-35b-normal`：35B normal，实际模型 `qwen3.6-35b-256k`，`reasoning=false`，256K context。
  - `ollama5090d/qwen3.6-35b-normal-think`：35B think，实际模型 `qwen3.6-35b-256k`，`reasoning=true`，256K context。
  - `ollama5090d/qwen3.6-27b-review`：27B review，实际模型 `qwen3.6-27b-256k`，`reasoning=false`，256K context。
  - `ollama5090d/qwen3.6-27b-review-think`：27B think，实际模型 `qwen3.6-27b-256k`，`reasoning=true`，256K context。
- OpenCode 默认仍保持入口名 `ollama5090d/qwen3.6-35b-normal`，但实际请求底层 `qwen3.6-35b-256k`。

### OpenCode 卡思考排查

- 现象：OpenCode Desktop Plan 会话显示“思考中”，Ollama 短请求排队，GPU 一度 98%-99%。
- 暂停 OpenCode 后：`ollama ps` 为空，GPU 显存从约 15GB 回落到约 2.3GB，说明 Ollama 服务未挂死。
- 根因：此前 256K 客户端入口曾临时指向基础模型 `qwen3.6:35b`；该基础模型实际默认 `num_ctx=32768`，导致“UI 标 256K、Ollama 实际 32K”不一致，并且 Plan 会话在 5080 上长时间运行。
- 修复：新增无 SYSTEM 段的 `qwen3.6-35b-256k` / `qwen3.6-27b-256k`，并把 OpenCode/OpenClaw 指向这两个真 256K 派生模型。

### 100K 换卡前短基线

- 当前主动工作入口已降为 100K：`qwen3.6-35b-100k` / `qwen3.6-27b-100k`，无 SYSTEM 段。
- 新增换卡对比脚本：`scripts/07_run_swap_benchmark.ps1`。
- 5080 干净短测：`qwen3.6-35b-100k`，`num_ctx=100000`，1K prompt / 128 output，未跑 45K。
- 结果文件：`results/benchmarks/bench_5080_preswap_clean_100k_1k_128_20260701-073514.json`。
- 结果摘要：实际 prompt tokens `647`，prompt eval `14.80 tok/s`，eval `5.96 tok/s`，wall `65.09s`，`ollama ps` 显示 `41%/59% CPU/GPU`。
- 结论：5080 16GB 下 100K 已明显 offload；45K 长测不建议换卡前继续跑，留给 5090D 默认频率复测。
- OpenCode CLI：`opencode models ollama5090d` 已确认能列出上述 4 个入口。
- Ollama 11700 启停脚本：
  - 启动：`scripts/05_start_ollama_11700.ps1`
  - 停止：`scripts/06_stop_ollama_11700.ps1`
  - 两者默认 dry-run，真正执行需加 `-Apply`。

## 完整备份

- 备份目录：`G:\ollama\RTX5080_to_RTX5090D_Ollama_Agent_Bundle-1(1)\rtx5090d_ollama_agent_bundle\results\backup-20260701-030105`
- 已保存：
  - `nvidia-smi.txt`
  - `ollama-version.txt`
  - `ollama-list.txt`
  - `ollama-ps.txt`
  - `ollama-environment.txt`
  - `C__Users_10979_.openclaw`
  - `C__Users_10979_.config_opencode`

## 仍未完成/不建议换卡前强行做

- 2 小时持续代理负载：未跑满。建议换 5090D 后默认频率下执行，因为该测试的目标是验证新卡稳定性。
- OpenCode 实仓编辑测试：未完成。CLI 已可用，但用户已实测桌面版正常；换卡前不建议再跑长时间 CLI 代理写仓压测。
- OpenClaw 旧 warning：已修复。`openclaw models list --provider ollama5090d` 已无 telegram / parallel / deepseek 配置 warning。
- 5090D 验证：未执行，只能换卡后做。

## 5080 基线

当前 GPU：`NVIDIA GeForce RTX 5080`，显存约 `16303 MiB`。

用户声明当前 5080 OC：核心 `+300`，显存 `+2000`。本次未自动应用或修改超频。

### GPU 驻留

`ollama ps`：

- model：`qwen3.6-35b-normal:latest`
- size：`24 GB`
- processor：`40%/60% CPU/GPU`
- context：`65536`

`nvidia-smi` 末状态：

- 显存：约 `15771 / 16303 MiB`
- 温度：约 `44 C`
- 功耗：约 `62.51 / 380 W`
- 核心频率：约 `2797 MHz`
- 显存频率：约 `16801 MHz`

### 功能烟雾

- `scripts/tool_call_smoke.py --model qwen3.6-35b-normal`：PASS。
- 结果：返回结构化 `tool_calls`，工具名 `add_numbers`，参数 `a=17,b=25`。
- 冷加载：约 `22.6s`；总耗时约 `31.9s`。
- `openclaw infer model run --model ollama5090d/qwen3.6:27b --prompt "Reply with exactly: ok"`：PASS，返回 `ok`。
- Ollama API 直接调用 `qwen3.6:27b`：PASS，返回 `ok`。

### 生成测试

64K 配置下，约 260 token 输出：

- prompt_eval_count：`713`
- prompt_eval_rate：`94.91 tok/s`
- eval_count：`260`
- eval_rate：`53.21 tok/s`
- total：`12.56s`

### 上下文测试

结果文件：

- `results/benchmarks/bench_5080_64k_1k_128_20260701.json`
- `results/benchmarks/bench_5080_64k_25k_64_20260701.json`
- `results/benchmarks/bench_5080_64k_40k_64_20260701.json`

摘要：

- 1K 档：实际 prompt tokens `1325`，prompt eval `106.12 tok/s`，总耗时 `12.75s`。
- 25K 档：实际 prompt tokens `16379`，prompt eval `324.82 tok/s`，总耗时 `50.72s`。
- 40K 档：实际 prompt tokens `25785`，prompt eval `948.93 tok/s`，总耗时 `27.46s`。

注意：25K/40K 顺序执行，后者明显受 warm cache/前缀复用影响，不能作为冷启动吞吐；可作为“长上下文不崩溃、无 OOM/TDR”的换卡前基线。

## 换 5090D 后对比点

1. 同模型、同 64K 配置下，`ollama ps` 应优先目标 `100% GPU`。
2. 生成速度应明显高于当前 5080 的约 `53 tok/s`。
3. 显存不应贴边；如仍 offload，先查模型身份、KV cache、视觉 projector、并行数和后台占用。
4. OpenClaw 当前实机可用配置应沿用 `openai-completions + /v1`，除非换卡后 OpenClaw 版本确认原生 `api: ollama` 已可用于推理路径。
