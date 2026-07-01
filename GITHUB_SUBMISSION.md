# GitHub Submission Notes

This repository contains the RTX 5080 to RTX 5090D Ollama/OpenClaw/OpenCode upgrade bundle, scripts, sanitized benchmark summaries, and pre-swap documentation.

## Included

- Upgrade and acceptance documentation.
- PowerShell and Python helper scripts.
- Sanitized Modelfiles for 64K, 100K, and 256K local model entries.
- Small benchmark JSON/text summaries needed for 5080 vs 5090D comparison.

## Excluded

- Ollama model blobs and manifests.
- Full local backups under `results/backups/` or legacy `results/backup-*`.
- Runtime service logs under `results/logs/` or legacy `results/ollama-service`.
- Disposable OpenCode smoke-test repositories.
- Local `.bak*` configuration snapshots.

Those excluded files can contain API keys, chat/session traces, or large generated artifacts and must stay local.
