# RTX 5080 -> RTX 5090D Ollama Agent Project Final Report

Date: 2026-07-01
Closeout updated: 2026-07-03

## Completed

- Created no-SYSTEM 100K and 256K model entries for Qwen3.6 35B and 27B.
- Set the active OpenClaw/OpenCode model path to 100K.
- Kept 256K entries as post-5090D validation candidates.
- Added Ollama 32100 start/stop scripts.
- Added and ran the swap benchmark script for the RTX 5080 100K short baseline.
- Updated public documentation and sanitized the GitHub repository.
- Ran a final local backup at `results/backups/backup-20260701-080422`.
- Stopped Ollama, OpenCode, and OpenClaw before hardware swap.

## Final Verified State

- `127.0.0.1:32100` has no listener before shutdown.
- No `ollama`, `OpenCode`, or `openclaw` process should remain before shutdown.
- Public GitHub repo excludes model blobs, local backups, logs, and smoke-test workspaces.
- RTX 5080 100K baseline shows heavy offload, so long-context stress belongs after the RTX 5090D install.

## Remaining Manual Admin Item

Windows still has old `ollama.exe` inbound Allow firewall rules. The current Codex session is not elevated, so it cannot disable them.

Run this once from an Administrator PowerShell before or after the card swap:

```powershell
netsh advfirewall firewall set rule name="ollama.exe" dir=in new enable=no
```

The physical card swap can proceed after normal shutdown because Ollama is stopped and the post-swap start script binds to `127.0.0.1:32100`.

## Post-Swap Validation

Date: 2026-07-03

- RTX 5090D is installed and visible to `nvidia-smi` as `NVIDIA GeForce RTX 5090 D`, `32607 MiB`.
- Final Ollama endpoint is `127.0.0.1:32100`. The earlier `11700` endpoint is not usable on this host because Windows excludes the `11677-11776` TCP range.
- Ollama `0.31.1` is running on `127.0.0.1:32100` with `OLLAMA_FLASH_ATTENTION=1`, `OLLAMA_KV_CACHE_TYPE=q8_0`, and `OLLAMA_MODELS=G:\ollama`.
- `qwen3.6-35b-100k` and `qwen3.6-27b-100k` both passed API smoke tests.
- `qwen3.6-35b-100k` passed 10/10 structured tool-call smoke tests.
- OpenClaw `ollama5090d/qwen3.6-35b-100k` returned exact `ok` through the configured provider.
- 100K short benchmark completed at about `3994.81 tok/s` prompt eval and `121.72 tok/s` eval.
- 100K long benchmark completed at about `6340.26 tok/s` prompt eval and `123.21 tok/s` eval.
- `ollama ps` showed `qwen3.6-35b-100k`, `100% GPU`, `CONTEXT 100000`.

Initial post-swap conclusion: 5090D default-frequency 100K validation passed. This was later superseded for GUI usage by the 128K v1 context update, and then by the 256K visible alias promotion recorded below.

## GUI Model Display Decision

Date: 2026-07-03

GUI model pickers should show versioned purpose aliases instead of raw context-test tags. This keeps `100k` / `256k` out of the daily UI while the 5090D flow is still deciding whether a larger context should be promoted.

- Default visible model: `qwen-main-v1`, currently `num_ctx=262144`.
- Review fallback: `qwen-review-v1`, currently `num_ctx=131072`.
- Chat fallback: `gemma-chat-v1`, currently `num_ctx=262144`.
- OpenCode optional code entry: `north-code-v1`, currently `num_ctx=262144`.

Do not delete raw 100K/256K/base tags during this phase. Hide them from GUI favorites/provider lists and keep them installed for rollback, comparison, and promotion validation.

## GUI Alias v1 Integration Verification

Date: 2026-07-03

- Created Ollama aliases with `ollama cp`: `qwen-main-v1`, `qwen-review-v1`, `gemma-chat-v1`, and `north-code-v1`.
- OpenClaw default is now `ollama5090d/qwen-main-v1`; `openclaw infer model run --model ollama5090d/qwen-main-v1 --prompt "Reply with exactly: ok"` returned `ok`.
- OpenCode default is now `ollama5090d/qwen-main-v1`; `opencode models ollama5090d` lists `qwen-main-v1`, `qwen-main-think-v1`, `qwen-review-v1`, and `north-code-v1`; `opencode run --model ollama5090d/qwen-main-v1 --print-logs "Reply with exactly: ok"` returned `ok`.
- OpenCode optional entry `ollama5090d/north-code-v1` also returned `ok`; keep it as an experimental code fallback, not the default.
- Chatbox local Ollama config now has `apiHost=http://127.0.0.1:32100`, `useProxy=false`, default `qwen-main-v1:latest`, and favorites `qwen-main-v1:latest`, `qwen-review-v1:latest`, `gemma-chat-v1:latest`.
- Initial alias verification: `scripts/04_verify_stack.ps1 -NormalModel qwen-main-v1 -ReviewModel qwen-review-v1` returned exact `ok` for both aliases and showed `100% GPU`, `CONTEXT 100000`. This was later raised to `CONTEXT 131072` in the 128K update and then `CONTEXT 262144` in the 256K visible alias promotion.
- `tool_call_smoke.py --model qwen-main-v1` passed 10/10 structured tool-call runs.

## 256K Candidate Check

Date: 2026-07-03

- `qwen3.6-35b-256k` smoke test passed with exact `ok`.
- `ollama ps` after smoke showed `qwen3.6-35b-256k:latest`, `100% GPU`, `CONTEXT 262144`.
- GPU memory after smoke was about `31536 MiB / 32607 MiB`; this leaves only about 1 GiB of headroom.
- 256K short benchmark `bench_5090d_default_256k_1k_128_20260703-060436.json`: prompt eval about `2521.89 tok/s`, eval about `85.71 tok/s`, wall about `0.51s`.
- 256K long benchmark `bench_5090d_default_256k_45k_64_20260703-060436.json`: prompt eval about `4451.91 tok/s`, eval about `91.26 tok/s`, wall about `6.64s`.

Historical decision at that time: 256K was viable as a candidate but not yet promoted to the GUI default. This decision was superseded by the 256K visible alias promotion below.

## 128K GUI Context Update

Date: 2026-07-03

User decision: increase the four visible v1 entries to 128K immediately because agent sessions were compressing too often.

- Recreated `qwen-main-v1`, `qwen-review-v1`, `gemma-chat-v1`, and `north-code-v1` with `PARAMETER num_ctx 131072`.
- Updated OpenClaw provider entries to `contextWindow=131072` and `params.num_ctx=131072`.
- Updated OpenCode entries `qwen-main-v1`, `qwen-main-think-v1`, `qwen-review-v1`, and `north-code-v1` to `limit.context=131072`.
- Updated Chatbox local Ollama entries `qwen-main-v1:latest`, `qwen-review-v1:latest`, and `gemma-chat-v1:latest` to `contextWindow=131072`.
- 128K smoke tests returned exact `ok` for `qwen-main-v1`, `qwen-review-v1`, and `gemma-chat-v1`.
- `north-code-v1` returned `ok` through OpenCode and loaded as `100% GPU`, `CONTEXT 131072`; direct `/api/chat` is not its best test path because this model is completion/code-oriented.

Historical decision at that time: 128K became the daily default for the visible v1 GUI entries. This decision was superseded by the 256K visible alias promotion below.

## Final A/B And Completion Record

Date: 2026-07-03

Scope at the time: complete the non-long-run post-upgrade closeout items. This was later superseded by the 256K two-hour stability closeout recorded below. GPU overclocking remained user-managed and was not applied by Codex.

### Current Production Default

- Model: `qwen-main-v1`
- Context: `262144`
- Endpoint: `http://127.0.0.1:32100`
- Runtime evidence: `ollama ps` showed `qwen-main-v1:latest`, `100% GPU`, `CONTEXT 262144`.
- GUI evidence: OpenClaw, OpenCode, and Chatbox configs all point at the v1 aliases with `262144` context.

### Benchmark A/B

| Case | Model | Context | Prompt eval | Eval | Wall |
| --- | --- | ---: | ---: | ---: | ---: |
| RTX 5080 pre-swap short | `qwen3.6-35b-100k` | 100000 | `14.80 tok/s` | `5.96 tok/s` | `65.09s` |
| RTX 5090D 100K short | `qwen3.6-35b-100k` | 100000 | `6056.18 tok/s` | `133.02 tok/s` | `0.31s` |
| RTX 5090D 128K short | `qwen-main-v1` | 131072 | `2839.03 tok/s` | `105.68 tok/s` | `0.57s` |
| RTX 5090D 100K 45K prompt | `qwen3.6-35b-100k` | 100000 | `6340.26 tok/s` | `123.21 tok/s` | `4.75s` |
| RTX 5090D 128K 45K prompt | `qwen-main-v1` | 131072 | `4985.37 tok/s` | `136.40 tok/s` | `5.97s` |
| RTX 5090D 256K 45K prompt | `qwen3.6-35b-256k` | 262144 | `4451.91 tok/s` | `91.26 tok/s` | `6.64s` |

Historical 128K default versus RTX 5080 pre-swap 100K short baseline:

- Prompt eval: `+19084.86%`
- Eval: `+1673.99%`
- Wall time: `-99.12%`

Historical 128K default versus the earlier raw 256K candidate on the 45K prompt benchmark:

- Prompt eval: `+11.98%`
- Eval: `+49.46%`
- Wall time: `-10.09%`

Historical decision at that time: keep 128K as the production default. This decision was superseded by the 256K visible alias promotion below.

## 256K Visible Alias Promotion

User decision on 2026-07-03: promote all visible local v1 entries and client integrations to 256K.

- Recreated `qwen-main-v1`, `qwen-review-v1`, `gemma-chat-v1`, and `north-code-v1` with `PARAMETER num_ctx 262144`.
- Updated OpenClaw `ollama5090d` provider and model entries to `contextWindow=262144`; OpenClaw model params now use `num_ctx=262144`.
- Updated OpenCode entries `qwen-main-v1`, `qwen-main-think-v1`, `qwen-review-v1`, and `north-code-v1` to `limit.context=262144`.
- Updated Chatbox local Ollama entries `qwen-main-v1:latest`, `qwen-review-v1:latest`, `gemma-chat-v1:latest`, and `north-code-v1:latest` to `contextWindow=262144`.
- Runtime smoke: `qwen-main-v1` returned exact `ok`; `ollama ps` showed `qwen-main-v1:latest`, `100% GPU`, `CONTEXT 262144`.

Decision at the time: the visible v1 aliases were configured as the 256K daily default. Multi-hour stability validation was then completed in the project closeout below.

## Qwen Review v1 128K Retune

After the final 256K closeout, `qwen-review-v1` was tested as a temporary 256K dense-model review entry. It completed the 0K/50K/100K/150K/200K prompt cases, but was much slower than the 35B MoE main model at every context size.

Result file: `results/benchmarks/bench_5090d_oc320_mem2800_qwen27b_generation_0_50_100_150_200_20260703-160621.json`

| Prompt context | Actual prompt tokens | Prompt eval | Output generation | Wall |
| --- | ---: | ---: | ---: | ---: |
| 0K | `120` | `647.42 tok/s` | `72.21 tok/s` | `4.81s` |
| 50K | `50123` | `2679.26 tok/s` | `59.38 tok/s` | `23.27s` |
| 100K | `100125` | `1953.48 tok/s` | `50.64 tok/s` | `56.93s` |
| 150K | `150125` | `1524.39 tok/s` | `44.65 tok/s` | `105.51s` |
| 200K | `200125` | `1254.68 tok/s` | `39.62 tok/s` | `167.73s` |

Decision: keep `qwen-main-v1` as the 256K default and retune `qwen-review-v1` to `num_ctx=131072`. The review model remains useful for second opinions without becoming the slow path for routine agent work.

### Security Closeout

Attempted to disable old inbound firewall rules:

```powershell
netsh advfirewall firewall set rule name="ollama.exe" dir=in new enable=no
```

Result: Windows returned `The requested operation requires elevation (Run as administrator).` The broad inbound `ollama.exe` rules remain enabled until an Administrator PowerShell runs the command.

Added admin helper scripts:

- `G:\ollama\disable_ollama_firewall_admin.ps1`
- `scripts/09_disable_ollama_firewall_admin.ps1`

The current Ollama listener remains loopback-only at `127.0.0.1:32100`.

### Residual Notes

- No remaining functional upgrade items.
- Non-blocking WARN: old inbound `ollama.exe` firewall Allow rules are still enabled. The current Ollama listener is loopback-only at `127.0.0.1:32100`; run the Administrator PowerShell command above if strict firewall hygiene is required.
- Future optional retest: rerun the 2-hour stability check after changing NVIDIA driver, Ollama, model quantization, context size, or GPU overclock.

## Project Closeout

Date: 2026-07-03

Final status: CLOSED / PASS with one non-blocking WARN.

Current production stack:

- Endpoint: `http://127.0.0.1:32100`
- Default model: `qwen-main-v1`
- Default context: `262144`
- Client integrations: OpenClaw, OpenCode, and Chatbox point at the v1 aliases. `qwen-main-v1`, `gemma-chat-v1`, and `north-code-v1` use `262144`; `qwen-review-v1` uses `131072`.
- Runtime check: `ollama ps` showed `qwen-main-v1:latest`, `100% GPU`, `CONTEXT 262144`.
- Live API check: `http://127.0.0.1:32100/api/version` returned Ollama `0.31.1`; `127.0.0.1:32100` is listening on loopback only.

Final 256K stability validation:

- Run directory: `results/stability/stability_256k_20260703-084539`
- Profile under test: user-selected `+320 core / +2800 mem`
- Model: `qwen-main-v1`
- Context / output: `num_ctx=262144`, `num_predict=256`
- Duration: `7200` seconds target, `7224.4` seconds elapsed
- Iterations: `219`
- Result: `219` OK, `0` failed, `0` consecutive failures
- Last case: `200K`, `eval_rate=128.01 tok/s`
- Max observed GPU: `577.39W`, `78C`, `30685 MiB` VRAM used, `16601 MHz` memory clock
- Error scan: `runner.stderr.log` had `0` lines; no observed HTTP, CUDA, OOM, driver reset, Xid, panic, or exception errors.

Final generation speed check:

- Result file: `results/benchmarks/bench_5090d_oc320_mem2800_generation_0_50_100_150_200_20260703-152507.json`
- Model / context: `qwen-main-v1`, `num_ctx=262144`, `num_predict=256`
- Profile: user-selected `+320 core / +2800 mem`
- Method: 3 runs per context size; table reports medians.

| Prompt context | Actual prompt tokens | Prompt eval | Output generation | Wall |
| --- | ---: | ---: | ---: | ---: |
| 0K | `102` | `1269.41 tok/s` | `228.43 tok/s` | `1.41s` |
| 50K | `50105` | `7190.92 tok/s` | `179.11 tok/s` | `7.77s` |
| 100K | `100107` | `6178.68 tok/s` | `154.95 tok/s` | `18.25s` |
| 150K | `150107` | `5101.61 tok/s` | `128.96 tok/s` | `32.18s` |
| 200K | `200107` | `4421.24 tok/s` | `113.94 tok/s` | `48.21s` |

Note: the 50K case ended naturally at a median of about `86` generated tokens; the other listed cases reached the `256` token generation limit.

Closeout decision:

- The RTX 5090D hardware swap, Ollama 32100 endpoint, v1 model aliases, OpenClaw/OpenCode/Chatbox GUI integration, and two-hour 256K LLM stability validation are complete.
- The project can be ended at this state. The only remaining note is optional firewall cleanup for old broad inbound `ollama.exe` rules; it does not block the local loopback-only Ollama workflow.
