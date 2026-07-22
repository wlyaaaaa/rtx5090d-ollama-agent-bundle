# POST REBOOT HANDOFF

Date: 2026-07-01

## Current State Before Shutdown

- Repo: `E:\Projects\Tools\rtx5090d-ollama-agent-bundle`
- GitHub: `https://github.com/wlyaaaaa/rtx5090d-ollama-agent-bundle`
- Latest pushed commit before card swap: check `git log -1 --oneline`
- Ollama is stopped.
- `127.0.0.1:32100` has no listener.
- `ollama`, `OpenCode`, and `openclaw` processes were verified stopped.
- Final lightweight local backup: `results/backups/backup-20260701-080422`
- Active model plan: 100K first, 256K only after RTX 5090D default-frequency validation.
- No SYSTEM prompt should be added to 100K/256K model entries.

## One Manual Admin Item

Old Windows inbound firewall allow rules for `ollama.exe` still existed before shutdown and require Administrator PowerShell:

```powershell
netsh advfirewall firewall set rule name="ollama.exe" dir=in new enable=no
```

## After Installing RTX 5090D

Start with default GPU clocks. Do not apply OC first.

```powershell
cd "E:\Projects\Tools\rtx5090d-ollama-agent-bundle"
nvidia-smi
.\scripts\05_start_ollama_32100.ps1 -Apply
ollama ps
openclaw models list --provider ollama5090d
.\scripts\07_run_swap_benchmark.ps1 -Label 5090d_default
.\scripts\07_run_swap_benchmark.ps1 -Label 5090d_default -Long
```

## What To Ask Codex After Reboot

Paste this:

```text
我已经换上 RTX 5090D 并重启了。请读取 E:\Projects\Tools\rtx5090d-ollama-agent-bundle\POST_REBOOT_HANDOFF.md，按里面的步骤做 5090D 默认频率验证。先不要超频，不要加模型系统提示词。
```
