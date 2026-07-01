# RTX 5080 -> RTX 5090D Pre-Swap Final Report

Date: 2026-07-01

## Completed

- Created no-SYSTEM 100K and 256K model entries for Qwen3.6 35B and 27B.
- Set the active OpenClaw/OpenCode model path to 100K.
- Kept 256K entries as post-5090D validation candidates.
- Added Ollama 11700 start/stop scripts.
- Added and ran the swap benchmark script for the RTX 5080 100K short baseline.
- Updated public documentation and sanitized the GitHub repository.
- Ran a final local backup at `results/backups/backup-20260701-080422`.
- Stopped Ollama, OpenCode, and OpenClaw before hardware swap.

## Final Verified State

- `127.0.0.1:11700` has no listener before shutdown.
- No `ollama`, `OpenCode`, or `openclaw` process should remain before shutdown.
- Public GitHub repo excludes model blobs, local backups, logs, and smoke-test workspaces.
- RTX 5080 100K baseline shows heavy offload, so long-context stress belongs after the RTX 5090D install.

## Remaining Manual Admin Item

Windows still has old `ollama.exe` inbound Allow firewall rules. The current Codex session is not elevated, so it cannot disable them.

Run this once from an Administrator PowerShell before or after the card swap:

```powershell
netsh advfirewall firewall set rule name="ollama.exe" dir=in new enable=no
```

The physical card swap can proceed after normal shutdown because Ollama is stopped and the post-swap start script binds to `127.0.0.1:11700`.
