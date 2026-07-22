# RTX 5090D Post-Swap Audit Report

Date: 2026-07-03 America/Los_Angeles

Scope: post-reboot validation after installing RTX 5090D, followed by 256K GUI alias promotion and final two-hour stability closeout. GPU overclocking was user-managed and was not applied by Codex. No SYSTEM prompt was added to the 100K/256K context model entries.

## Summary

Overall result: PASS with one non-blocking WARN

Executable stage: complete through 256K production alias promotion and two-hour stability validation

Active endpoint: `127.0.0.1:32100`

Why not `11700`: Windows TCP excluded port ranges include `11677-11776`, so `127.0.0.1:11700` cannot be bound by Ollama on this host. Port `32100` is the final stable endpoint and is already present as an administered exclusion.

Base model ID: `qwen3.6:35b`, digest `647b6f633c9f`, Q4_K_M

Ollama version: `0.31.1`

GPU / VRAM: `NVIDIA GeForce RTX 5090 D`, `32607 MiB`

100K GPU residency: PASS, `qwen3.6-35b-100k` shows `100% GPU`, `CONTEXT 100000`

OpenClaw tool calls: PASS, 10/10 structured tool calls

OpenCode CLI: PASS, `1.17.12` installed

Remaining risk: Windows inbound firewall rules named `ollama.exe` are still enabled and require Administrator PowerShell to disable. Current Ollama listener is loopback-only: `127.0.0.1:32100`, so this is a hardening warning rather than a functional blocker.

## A. Hardware And Driver

- PASS: GPU is the expected 32GB-class RTX 5090D, not 24GB.
  Evidence: `nvidia-smi` shows `NVIDIA GeForce RTX 5090 D`, `4355MiB / 32607MiB` before model load.

- PASS: Driver and CUDA runtime are visible.
  Evidence: `nvidia-smi` reports `NVIDIA-SMI 610.62`, `KMD Version 610.62`, `CUDA UMD Version 13.3`.

- PASS: Default-clock validation was completed before promotion.
  Evidence: no OC script was run by Codex during default-clock validation.

- PASS: User-managed OC stability validation completed later.
  Evidence: final two-hour 256K run used user-selected `+320 core / +2800 mem`; `219/219` iterations passed with `0` failures.

- N/A: Physical PSU/cable inspection.
  Evidence cannot be collected from shell; user physically installed the card.

## B. Software, Port, And Storage

- PASS: Windows recorded.
  Evidence: Windows 10 Pro for Workstations, WindowsVersion `2009`, OsBuildNumber `26200`.

- PASS: Ollama installed and API available.
  Evidence: `ollama version is 0.31.1`; `http://127.0.0.1:32100/api/version` returns `0.31.1`.

- PASS: OpenClaw installed.
  Evidence: `OpenClaw 2026.6.10 (aa69b12)`.

- PASS: OpenCode installed.
  Evidence: `opencode --version` returns `1.17.12`.

- PASS: Stable endpoint selected and verified.
  Evidence: `Get-NetTCPConnection -LocalPort 32100 -State Listen` shows `127.0.0.1:32100` owned by `ollama.exe` PID `24976`.

- PASS: `11700` rejected for root-cause reasons, not arbitrary preference.
  Evidence: Ollama stderr showed `listen tcp 127.0.0.1:11700: bind: An attempt was made to access a socket in a way forbidden by its access permissions`; `netsh int ipv4 show excludedportrange protocol=tcp` includes `11677 11776`.

- PASS: User environment now matches final endpoint.
  Evidence: `User_OLLAMA_HOST` and process `OLLAMA_HOST` are both `127.0.0.1:32100`; `OLLAMA_MODELS=G:\ollama`, `OLLAMA_FLASH_ATTENTION=1`, `OLLAMA_KV_CACHE_TYPE=q8_0`.

- PASS: Model directory exists with sufficient space.
  Evidence: `G:\` free space was about `664,970,997,760` bytes during audit.

- WARN: Old broad inbound firewall rules still exist.
  Evidence: `netsh advfirewall firewall show rule name="ollama.exe" dir=in` shows TCP/UDP inbound Allow on Private/Public. Attempting to disable returned `The requested operation requires elevation (Run as administrator).`

## C. Model Identity

- PASS: 35B 100K model identity is correct.
  Evidence: `qwen3.6-35b-100k:latest`, parent `qwen3.6:35b`, family `qwen35moe`, parameter size `36.0B`, quantization `Q4_K_M`, capabilities include `completion`, `tools`, and `thinking`.

- PASS: 27B 100K model identity is correct.
  Evidence: `qwen3.6-27b-100k:latest`, parent `qwen3.6:27b`, family `qwen35`, parameter size `27.8B`, quantization `Q4_K_M`.

- PASS: 256K candidates exist, and visible v1 aliases were promoted with a mixed final context policy.
  Evidence: `qwen3.6-35b-256k:latest` and `qwen3.6-27b-256k:latest` are present in `/api/tags`; `qwen-main-v1`, `gemma-chat-v1`, and `north-code-v1` use `num_ctx=262144`; `qwen-review-v1` uses `num_ctx=131072`.

- PASS: No SYSTEM directive in 100K/256K model creation configs.
  Evidence: `scripts/08_create_context_models.ps1` refuses any target Modelfile containing `SYSTEM`; dry run passed.

- PASS: Behavior prompts do not alter base weights.
  Note: local Modelfiles can change runtime parameters and prompt behavior, not model weights.

## D. Ollama Capability And Runtime

- PASS: Ollama starts on final endpoint with intended acceleration settings.
  Evidence: Ollama log reports `Listening on 127.0.0.1:32100 (version 0.31.1)`, `OLLAMA_FLASH_ATTENTION:true`, `OLLAMA_KV_CACHE_TYPE:q8_0`, `OLLAMA_MODELS:G:\ollama`.

- PASS: CUDA inference device selected.
  Evidence: Ollama log reports `library=CUDA`, `compute=12.0`, `name=CUDA0`, `description="NVIDIA GeForce RTX 5090 D"`, `total="31.8 GiB"`, `available="30.3 GiB"`.

- PASS: 100K smoke tests pass.
  Evidence: `scripts/04_verify_stack.ps1` returned exact `ok` for `qwen3.6-35b-100k` and `qwen3.6-27b-100k`.

- PASS: 100K model is GPU-resident.
  Evidence: `ollama ps` after validation shows `qwen3.6-35b-100k:latest`, `SIZE 24 GB`, `PROCESSOR 100% GPU`, `CONTEXT 100000`.

## E. Integration

- PASS: OpenClaw points at the final endpoint and versioned GUI alias.
  Evidence: user config `~\.openclaw\openclaw.json` has provider `ollama5090d` with `baseUrl` `http://127.0.0.1:32100/v1`, `api` `openai-completions`, default `ollama5090d/qwen-main-v1`.

- PASS: OpenClaw model list sees the versioned local aliases.
  Evidence: `openclaw models list --provider ollama5090d` shows `qwen-main-v1` and `qwen-review-v1`, both local, context shown as about `98k`.

- PASS: OpenClaw inference works.
  Evidence: `openclaw infer model run --model ollama5090d/qwen-main-v1 --prompt "Reply with exactly: ok"` returned `ok`.

- PASS: Structured tool calls work.
  Evidence: `python scripts/tool_call_smoke.py --model qwen-main-v1` passed 10/10 runs with function `add_numbers` and arguments `a=17`, `b=25`.

- PASS: OpenCode CLI exists.
  Evidence: `opencode --version` returned `1.17.12`; `opencode models ollama5090d` lists `qwen-main-v1`, `qwen-main-think-v1`, `qwen-review-v1`, and `north-code-v1`; default config is `ollama5090d/qwen-main-v1`.

## F. Benchmarks

- PASS: 100K short benchmark completed.
  Evidence: `bench_5090d_default_100k_1k_128_20260703-053317.json`; `prompt_eval_rate` about `3994.81 tok/s`, `eval_rate` about `121.72 tok/s`, result tail `BENCH_OK`.

- PASS: 100K long-context benchmark completed.
  Evidence: `bench_5090d_default_100k_45k_64_20260703-053324.json`; `prompt_eval_count 28247`, `prompt_eval_rate` about `6340.26 tok/s`, `eval_rate` about `123.21 tok/s`, wall time about `4.75s`, result tail `BENCH_OK`.

- PASS: No observed OOM, CUDA error, driver reset, black screen, or malformed output during this validation window.

## Follow-Up Gates

1. Disable old inbound firewall Allow rules from Administrator PowerShell:

```powershell
netsh advfirewall firewall set rule name="ollama.exe" dir=in new enable=no
```

2. Current GUI production default is `qwen-main-v1` at `262144` context.
3. 256K promotion is complete for the visible v1 aliases.
4. Two-hour 256K stability validation completed successfully at user-selected `+320 core / +2800 mem`.
5. Future driver, Ollama, model, context, or OC changes should trigger a new stability run.

## Closeout Update

Date: 2026-07-03

- PASS: Current production default is 256K.
  Evidence: `ollama ps` showed `qwen-main-v1:latest`, `100% GPU`, `CONTEXT 262144`.

- PASS: OpenClaw/OpenCode/Chatbox configs use the final v1 alias policy.
  Evidence: main/gemma/north entries use `262144`; `qwen-review-v1` uses `131072`.

- PASS: Historical 128K benchmark record is retained.
  Evidence: `bench_5090d_default_128k_1k_128_20260703-063301.json` and `bench_5090d_default_128k_45k_64_20260703-063301.json`.

- WARN: Firewall rule disable still requires Administrator PowerShell.
  Evidence: direct `netsh advfirewall firewall set rule name="ollama.exe" dir=in new enable=no` returned `The requested operation requires elevation (Run as administrator).`

## Final Closeout Update

Date: 2026-07-03

- PASS: Two-hour 256K stability validation completed.
  Evidence: `results/stability/stability_256k_20260703-084539/status.json` ended with `state=completed`, `elapsed_seconds=7224.4`, `iteration=219`, `ok_count=219`, `fail_count=0`.

- PASS: Error scan was clean.
  Evidence: `runner.stderr.log` had `0` lines; no HTTP, CUDA, OOM, driver reset, Xid, panic, exception, or failed entries were found.

- PASS: GPU telemetry stayed within the selected operating envelope.
  Evidence: max observed values were `577.39W`, `78C`, `30685 MiB` VRAM used, `3262 MHz` graphics clock, and `16601 MHz` memory clock.

- PASS: Final project state can close.
  Evidence: endpoint, model aliases, GUI integrations, 256K context, 100% GPU residency, and the two-hour 256K stability target are verified. The only remaining item is the non-blocking firewall hardening warning above.
