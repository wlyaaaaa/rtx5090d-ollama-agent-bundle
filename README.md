# RTX 5080 to RTX 5090D Ollama Agent Bundle

Public, sanitized upgrade bundle for moving a local Ollama/OpenClaw/OpenCode agent stack from RTX 5080 to RTX 5090D 32GB.

## Current Handoff

If the machine has just rebooted after installing the RTX 5090D, start here:

- [POST_REBOOT_HANDOFF.md](POST_REBOOT_HANDOFF.md)

Recommended prompt for Codex after reboot:

```text
我已经换上 RTX 5090D 并重启了。请读取 G:\ollama\RTX5080_to_RTX5090D_Ollama_Agent_Bundle-1(1)\rtx5090d_ollama_agent_bundle\POST_REBOOT_HANDOFF.md，按里面的步骤做 5090D 默认频率验证。先不要超频，不要加模型系统提示词。
```

## What This Repo Contains

- Ollama start/stop scripts for `127.0.0.1:11700`.
- No-SYSTEM 100K and 256K model creation scripts.
- OpenClaw/OpenCode configuration notes for Ollama's OpenAI-compatible `/v1` endpoint.
- RTX 5080 pre-swap benchmark summaries.
- RTX 5090D post-swap validation plan.
- Public-safe docs and checksums.

## Main Documents

- [00_README_FIRST.md](00_README_FIRST.md): detailed operator entrypoint.
- [results/final_report.md](results/final_report.md): final pre-swap status.
- [results/reports/5080_pre_swap_status.md](results/reports/5080_pre_swap_status.md): RTX 5080 baseline and swap notes.
- [02_EXECUTION_PLAN.md](02_EXECUTION_PLAN.md): execution flow.
- [03_ACCEPTANCE_TESTS.md](03_ACCEPTANCE_TESTS.md): validation checklist.

## Important State

- Active validation context: 100K first.
- 256K entries are prepared but should only be promoted after RTX 5090D default-frequency validation.
- Do not add SYSTEM prompts to the 100K/256K local model entries.
- First boot after card swap should use default GPU clocks. Do not apply overclock first.
- Old Windows `ollama.exe` inbound firewall Allow rules may still need Administrator PowerShell cleanup:

```powershell
netsh advfirewall firewall set rule name="ollama.exe" dir=in new enable=no
```

## Not Included

The repository intentionally excludes:

- Ollama model blobs.
- Local backups.
- Runtime logs.
- Smoke-test workspaces.
- Local config backup files.
