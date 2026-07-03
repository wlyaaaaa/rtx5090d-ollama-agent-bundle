# RTX 5080 to RTX 5090D Ollama Agent Bundle

Public, sanitized upgrade bundle for moving a local Ollama/OpenClaw/OpenCode agent stack from RTX 5080 to RTX 5090D 32GB.

## Current Status

Project status as of 2026-07-03: CLOSED / PASS with one non-blocking WARN.

- RTX 5090D 32GB is installed and validated.
- Final Ollama endpoint: `127.0.0.1:32100`.
- Current production default: `qwen-main-v1`, `num_ctx=262144`.
- OpenClaw, OpenCode, and Chatbox use the v1 aliases: main/gemma/north at 256K, review at 128K.
- Final two-hour 256K stability run passed: `219/219` OK, `0` failed.
- Non-blocking WARN: old inbound `ollama.exe` firewall Allow rules are still enabled; Ollama currently listens on loopback only.

## What This Repo Contains

- Ollama start/stop scripts for `127.0.0.1:32100`.
- No-SYSTEM 100K and 256K model creation scripts.
- OpenClaw/OpenCode configuration notes for Ollama's OpenAI-compatible `/v1` endpoint.
- RTX 5080 pre-swap benchmark summaries.
- RTX 5090D post-swap validation and final closeout records.
- Public-safe docs and checksums.

## Main Documents

- [00_README_FIRST.md](00_README_FIRST.md): detailed operator entrypoint.
- [results/final_report.md](results/final_report.md): final project status and closeout evidence.
- [public_config_backup/README.md](public_config_backup/README.md): sanitized public backup of the final Ollama/OpenClaw/OpenCode/Chatbox templates.
- [results/reports/5080_pre_swap_status.md](results/reports/5080_pre_swap_status.md): RTX 5080 baseline and swap notes.
- [02_EXECUTION_PLAN.md](02_EXECUTION_PLAN.md): execution flow.
- [03_ACCEPTANCE_TESTS.md](03_ACCEPTANCE_TESTS.md): validation checklist.

## Important State

- Active production context: 256K binary context (`262144`) via the v1 aliases.
- Review fallback context: 128K binary context (`131072`) via `qwen-review-v1`.
- Keep raw 100K/256K/base tags installed for rollback and comparison, but hide them from daily GUI lists.
- Do not add SYSTEM prompts to the 100K/256K local model entries.
- Final validated user-managed OC profile for the two-hour 256K LLM workload: `+320 core / +2800 mem`.
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
