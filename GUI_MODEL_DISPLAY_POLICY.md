# GUI Model Display Policy

Date: 2026-07-03

Endpoint: `http://127.0.0.1:32100`

## Decision

The GUI model lists should expose stable, versioned purpose names instead of raw context-test model names.

Do not show `100k`, `200k`, or `256k` as the main user-facing choice. Those are validation and promotion details. The visible GUI entries should use `v1`, `v2`, and later versions so the working default can move from 100K to a larger context after validation without training users to pick a temporary backend tag.

## Visible Entries

| GUI entry | Purpose | Current backend | Notes |
| --- | --- | --- | --- |
| `qwen-main-v1` | Default local 5090D model | `qwen3.6:35b`, `num_ctx=262144` | Default for Chatbox, OpenClaw, and OpenCode. |
| `qwen-review-v1` | Smaller review / fallback model | `qwen3.6:27b`, `num_ctx=131072` | 128K is the current optimum for this dense review model; 256K was too slow for routine review. |
| `gemma-chat-v1` | General chat fallback | `gemma4-31b-chat:latest`, `num_ctx=262144` | Chatbox-oriented backup. Not the coding default. |
| `north-code-v1` | OpenCode code specialist / experiment | `north-mini-code-opencode:latest`, `num_ctx=262144` | OpenCode-only optional entry. |

## Hidden Entries

Do not add the following raw tags to GUI favorites or provider model lists unless actively debugging:

- `qwen3.6-35b-100k:latest`
- `qwen3.6-27b-100k:latest`
- `qwen3.6-35b-256k:latest`
- `qwen3.6-27b-256k:latest`
- `qwen3.6-35b-normal:latest`
- `qwen3.6-35b-unrestricted:latest`
- `qwen3.6-35b-tuned:latest`
- `qwen3.6-35b-unfiltered:latest`
- small legacy test models
- abliterated / experimental variants

These models should remain installed for rollback, comparison, and future promotion work. Hiding them in the GUI is preferred over deleting them.

## Defaults

- Chatbox default: `ollama/qwen-main-v1:latest`, `contextWindow=262144`
- OpenClaw default: `ollama5090d/qwen-main-v1`, `contextWindow=262144`
- OpenCode default: `ollama5090d/qwen-main-v1`, `limit.context=262144`
- Review fallback in Chatbox/OpenClaw/OpenCode: `qwen-review-v1`, `context=131072`

## Current Context Decision

As of the final 2026-07-03 closeout, the visible v1 entries use a mixed context policy:

- `qwen-main-v1`: `262144`
- `qwen-review-v1`: `131072`
- `gemma-chat-v1`: `262144`
- `north-code-v1`: `262144`

The reason for promoting the main model to 256K is agent ergonomics: repeated context compression made long agent sessions feel worse than the extra VRAM cost of 256K. The review model was later retuned down to 128K after direct 27B testing showed the dense 27B model was much slower at long contexts than the 35B MoE main model.

Closeout validation on 2026-07-03 completed a two-hour 256K run for `qwen-main-v1` at the user-selected `+320 core / +2800 mem` profile: `219/219` iterations passed, `0` failed, max observed GPU was `577.39W`, `78C`, `30685 MiB` VRAM used, and `16601 MHz` memory clock. No HTTP, CUDA, OOM, or driver reset errors were found.

The 256K v1 aliases are therefore the current proven daily default for this host. Rerun the same stability class after changing driver, Ollama, model quantization, context size, or GPU overclock.

The `qwen-review-v1` 128K decision is performance-driven, not a stability failure. During the temporary 256K 27B test, output generation fell from about `72.21 tok/s` at near-empty context to `39.62 tok/s` at 200K, with a 200K wall time of about `167.73s` for 256 generated tokens. For review and second-opinion use, 128K keeps the model useful without letting it become the slow path.

## Promotion Rule

When the 5090D upgrade flow proves a larger context entry is stable, create the next visible version:

- `qwen-main-v2` for the next promoted main model.
- `qwen-review-v2` for the next promoted review model.

Then update the GUI defaults to the new versioned names and record the backend mapping in this document. Keep previous versions installed until the new version has completed the same stability class.
