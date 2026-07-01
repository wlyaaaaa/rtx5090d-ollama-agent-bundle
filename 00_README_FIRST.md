# RTX 5080 → RTX 5090D 32GB：Ollama / OpenClaw / OpenCode 升级执行包

版本：2026-07-01

## 决策摘要

- 目标显卡：**RTX 5090D 32GB（非 5090D V2 24GB）**。
- 默认主模型：**Qwen3.6-35B-A3B，Q4_K_M / 4-bit**。
- 默认用途：OpenClaw 与 OpenCode 的高吞吐本地代理。
- 默认推理策略：OpenClaw 日常循环关闭 thinking；OpenCode 精确编码可按任务开启 thinking。
- 27B 稠密模型不作为默认主力；仅作为可选疑难任务复核模型。
- 当前换卡前工作上下文：**100K**。RTX 5080 16GB 下已确认 100K 会发生明显 CPU/GPU offload；45K 长测留给 RTX 5090D 默认频率后执行。
- 256K 模型入口已准备好，但仅作为 RTX 5090D 32GB 验证通过后的晋升目标，不作为换卡前 5080 生产默认值。
- Ollama：启用 Flash Attention，KV Cache 使用 q8_0。
- OpenClaw 当前实机版本使用 Ollama OpenAI 兼容接口：`http://127.0.0.1:11700/v1`，`api=openai-completions`。早期 `api=ollama` 路径在当前版本推理时报 `No API provider registered for api: ollama`。
- OpenCode 通过 OpenAI 兼容接口连接 Ollama，地址应为 `http://127.0.0.1:11700/v1`。

## 模型入口

1. `qwen3.6-35b-normal`：正常版，可靠、直接、避免虚构工具结果。
2. `qwen3.6-35b-unrestricted`：低拒答研究版，减少说教和泛化拒绝。
3. `qwen3.6-35b-100k` / `qwen3.6-27b-100k`：当前 OpenCode/OpenClaw 工作入口，无 SYSTEM 段。
4. `qwen3.6-35b-256k` / `qwen3.6-27b-256k`：5090D 后验证用最大上下文入口，无 SYSTEM 段。

“无限制”仅指回答风格和研究范围更宽，不等于自动获得无限文件、Shell、网络或凭据权限。OpenClaw/OpenCode 的权限层仍独立生效。

## 执行顺序

1. **先阅读并执行 `01_AUDIT_BEFORE_EXECUTION.md`。**
2. 所有审计项通过后，再执行 `02_EXECUTION_PLAN.md`。
3. 使用 `scripts/` 中的脚本，但默认先运行 Dry Run。
4. 按 `03_ACCEPTANCE_TESTS.md` 验收。
5. 任何硬停止条件触发时，执行回滚，不得继续堆叠改动。

## 换卡前最新状态

- Ollama 监听：`127.0.0.1:11700`。
- OpenCode 四个桌面入口已配置为 100K：35B normal/think、27B review/think。
- OpenClaw provider 已清理旧 telegram/parallel/deepseek warning。
- 5080 100K 短基线已记录；45K 长基线不在 5080 上继续跑。
- 最终本地备份：`results/backups/backup-20260701-080422`，不提交 GitHub。
- 当前 Codex 会话无管理员权限，无法禁用旧 `ollama.exe` 入站防火墙 Allow 规则；若按严格网络门禁执行，请用管理员 PowerShell 运行：
  `netsh advfirewall firewall set rule name="ollama.exe" dir=in new enable=no`
- 详细记录见 `results/reports/5080_pre_swap_status.md` 和 `results/final_report.md`。

## 重要假设

以下数据来自设备所有者实测或声明，不是本包独立测得：

- 当前平台：Ryzen 9 9950X3D、64GB DDR5，时序 C28-32-32-48。
- 当前 RTX 5080 上，Qwen3.6-35B-A3B：短上下文约 100 tok/s，40K 上下文约 60 tok/s。
- 目标 RTX 5090D 的 +320 核心 / +2600 显存超频被声明为稳定。

执行代理必须重新验证，不得把这些数字当作已审计事实。
