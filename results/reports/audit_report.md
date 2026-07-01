# RTX 5080 -> RTX 5090D Ollama Agent Bundle 审计报告

> Current status: superseded by later hands-on validation.
>
> This file is the initial audit snapshot from 2026-07-01 02:21. Later work corrected the Ollama listen address, OpenClaw/OpenCode configs, warning cleanup, 27B/35B model entries, 100K active context, and no-SYSTEM 100K/256K Modelfiles.
>
> Use `results/reports/5080_pre_swap_status.md` and `results/final_report.md` for current swap decisions. Keep this file only as historical evidence of the first gate check.

时间：2026-07-01 02:21 America/Los_Angeles

范围：静态审计 bundle、只读实机确认、换卡前门禁。未执行任何 Apply 脚本，未应用 GPU 超频，未复述 Modelfile 系统提示词。

## 总体结论

总体结论：FAIL（当前不得继续执行 5090D 部署阶段）

可执行阶段：0（仅备份、5080 基线采集、修正 Ollama 暴露面；换卡后重新审计）

主要阻断：

1. 当前 GPU 是 RTX 5080 16GB，不是目标 RTX 5090D 32GB。
2. Ollama 当前监听 `0.0.0.0:11434` 和 `[::]:11434`，并且 Windows 防火墙存在 Public/Private 入站 Allow、RemoteAddress=Any、LocalPort=Any。按本包硬停止条件，必须先收口。
3. 运行中的 Ollama 端口与目标环境变量不一致：环境变量是 `127.0.0.1:11700`，实际进程仍在 `11434`。

用户补充事实：

- 当前卡：RTX 5080。
- 当前 5080 超频：核心 +300、显存 +2000。此项为用户声明，本次未用工具独立验证，也未建议把该超频迁移到 5090D。
- 即将换 5090D。换卡后必须先默认频率验收，超频单独后置测试。

## A. 硬件与驱动

- FAIL：目标 GPU 未上机。
  证据：`nvidia-smi` 显示 `NVIDIA GeForce RTX 5080`，显存 `3654MiB / 16303MiB`，驱动/KMD `610.47`，CUDA UMD `13.3`。

- WARN：当前 5080 可作为基线采集对象，但不能作为 5090D 放行证据。
  证据：本包验收要求 5090D 32GB；当前只有 16GB。

- WARN：5090D 超频计划需修正。
  证据：bundle 原文写 `+320/+2600`；用户当前给出的 5080 超频是 `+300/+2000`。5090D 上机后不得直接套用 5080 或包内 OC，必须默认频率通过后再测。

## B. 软件、端口与目录

- PASS：Windows 信息已记录。
  证据：Windows 10 Pro for Workstations，WindowsVersion `2009`，OsBuildNumber `26200`。

- PASS：Ollama 已安装且 API 可用。
  证据：`ollama version is 0.30.11`；`http://127.0.0.1:11434/api/version` 返回 `0.30.11`。

- PASS：OpenClaw 已安装。
  证据：`OpenClaw 2026.6.10 (aa69b12)`。

- WARN：OpenCode 未在当前 PowerShell PATH 中找到。
  证据：`opencode --version` 返回 “not recognized”。

- FAIL：Ollama 监听地址不符合目标安全状态。
  证据：`netstat -ano` 显示 `0.0.0.0:11434 LISTENING` 和 `[::]:11434 LISTENING`，PID `21184`。

- FAIL：Windows 防火墙对 Ollama 入站过宽。
  证据：规则 `ollama.exe`，Profile `Private, Public`，Direction `Inbound`，Action `Allow`，Program `...\ollama.exe`，Protocol `TCP/UDP`，LocalPort `Any`，RemoteAddress `Any`。

- WARN：目标端口 11700 当前没有监听。
  证据：`Get-NetTCPConnection -LocalPort 11700 -State Listen` 无结果；Ollama 进程实际监听 11434。

- PASS：目标模型目录存在且空间充足。
  证据：`G:\ollama` 存在；G 盘剩余约 `705.52 GB`；Authenticated Users 具备 Modify 权限。

- PASS：Ollama 目标环境变量已存在于当前用户环境。
  证据：`OLLAMA_FLASH_ATTENTION=1`、`OLLAMA_KV_CACHE_TYPE=q8_0`、`OLLAMA_MODELS=G:\ollama`、`OLLAMA_HOST=127.0.0.1:11700`、`OLLAMA_MAX_LOADED_MODELS=1`、`OLLAMA_NUM_PARALLEL=1`。

## C. 模型身份

- PASS：基础模型 `qwen3.6:35b` 已存在。
  证据：在 `127.0.0.1:11434` 上 `ollama list` 显示 `qwen3.6:35b`，ID `647b6f633c9f`，大小约 `23 GB`。

- PASS：基础模型结构与目标大体匹配。
  证据：`ollama show qwen3.6:35b` 显示 architecture `qwen35moe`，parameters `36.0B`，context length `262144`，quantization `Q4_K_M`，capabilities 包含 `vision`、`completion`、`tools`、`thinking`。

- WARN：基础模型默认 `num_ctx` 是 32768，bundle 派生模型计划改为 65536。
  证据：`ollama show qwen3.6:35b` 参数含 `num_ctx 32768`；bundle Modelfile 含 `PARAMETER num_ctx 65536`。

- WARN：目标自定义模型尚未按本包创建。
  证据：`ollama list` 未显示 `qwen3.6-35b-normal` 或 `qwen3.6-35b-unrestricted`；当前有 `qwen3.6-35b-tuned`、`qwen3.6-35b-unfiltered` 等既有模型。

- PASS：不把系统提示词当作真正“改权重/去审查”。
  证据：本包 `configs/Modelfile.unrestricted` 注释说明低拒答不改变 base weights 或 host permissions；本次报告不包含系统提示词正文。

## D. Ollama 能力与运行状态

- WARN：Ollama 支持项只能部分确认。
  证据：基础模型 capabilities 包含 `tools` 与 `thinking`；环境变量包含 Flash Attention 与 q8_0 KV。实际 64K 运行、GPU 驻留和 tool call 未跑，因为当前不是 5090D 且服务端口需先收口。

- N/A：64K 是否 100% GPU。
  原因：当前为 RTX 5080 16GB，不能作为 5090D 64K 驻留证据。

- PASS：Dry Run 配置脚本不写系统。
  证据：运行 `scripts/02_configure_ollama_env.ps1` 无 `-Apply`，仅输出将设置的用户环境变量，并提示 dry run。

- PASS：备份脚本 Dry Run 不写系统。
  证据：运行 `scripts/01_backup_current_state.ps1` 无 `-Apply`，仅输出目标备份目录和 dry run 提示。

## E. 集成配置

- SUPERSEDED：初始审计曾认为 OpenClaw 示例配置应使用原生 Ollama URL；后续实测已修正为 OpenAI 兼容路径。
  当前证据：`configs/openclaw.normal.json5` 和 `configs/openclaw.unrestricted.json5` 的 `baseUrl` 为 `http://127.0.0.1:11700/v1`，`api` 为 `openai-completions`。

- PASS：OpenCode 示例配置使用 OpenAI 兼容 `/v1` URL。
  证据：`configs/opencode.normal.json` 和 `configs/opencode.unrestricted.json` 的 `baseURL` 为 `http://127.0.0.1:11700/v1`。

- SUPERSEDED：初始 OpenClaw `contextWindow` 与 `params.num_ctx` 为 65536；当前工作入口已改为 100K。
  当前证据：模板和实机配置均以 `qwen3.6-35b-100k` / `qwen3.6-27b-100k` 为主动入口。

- SUPERSEDED：OpenCode CLI 不是换卡前阻断项。
  当前证据：OpenCode 桌面版由用户实测可用；4 个桌面入口已配置为 100K。CLI/WSL 可在换卡后按需补测。

- SUPERSEDED：OpenClaw 目标模型和 provider 已在后续实测中修正。
  当前证据：OpenClaw 使用 `api=openai-completions` + `/v1`，默认入口为 `qwen3.6-35b-100k`；旧 telegram / parallel / deepseek warning 已清理。换卡前服务已按计划停止。

## F. Bundle 完整性与脚本安全

- PASS：SHA256 完整性校验覆盖公开跟踪文件。
  证据：`SHA256SUMS.txt` 按当前 Git 跟踪文件重新生成；本地 backups/logs/model blobs 不纳入 GitHub。

- PASS：PowerShell 脚本默认 dry run，只有 `-Apply` 才写入。
  证据：`01_backup_current_state.ps1` 和 `02_configure_ollama_env.ps1` 均检查 `$Apply`；`03_create_models.ps1` 在 dry run 只准备临时 Modelfile。

- WARN：`03_create_models.ps1` dry run 也会创建 `%TEMP%` 临时目录并写临时 Modelfile。
  影响：不是系统配置变更，但严格意义上不是完全零写入；执行前可接受，或手动清理 temp。

- PASS：脚本未自动应用 GPU 超频。
  证据：全文搜索未发现设置 GPU clock/offset 的命令；OC 阶段为 manual。

## 换卡前最终处理状态

1. 备份：已完成，最终本地备份为 `results/backups/backup-20260701-080422`。
2. Ollama：已停止，换卡前 `127.0.0.1:11700` 无监听。
3. 5080 基线：已记录 64K 历史基线与 100K 干净短基线；45K 长测留给 RTX 5090D。
4. 防火墙：仍需管理员权限禁用旧 `ollama.exe` 入站 Allow 规则；当前 Codex 会话无法提权执行。命令见 `results/final_report.md`。

## 换 5090D 后门禁

1. 默认频率启动，不加载任何 OC。
2. `nvidia-smi` 必须显示 RTX 5090D 约 32GB；若是 24GB V2 或识别异常，停止。
3. 默认频率下完成驱动、CUDA、显存、LLM 持续负载验证。
4. 重启 Ollama 后确认 `127.0.0.1:11700/api/tags` 正常，且公网/局域网不可访问。
5. 先验证当前 100K 入口，再跑 tool call、OpenClaw、OpenCode、长上下文基准。
6. 只有默认频率全部通过后，才单独测试 5090D OC；不得沿用 5080 的 `+300/+2000` 或 bundle 原假设 `+320/+2600` 作为默认值。
