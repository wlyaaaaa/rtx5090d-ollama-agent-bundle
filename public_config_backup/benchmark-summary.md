# Benchmark Summary

Hardware profile:

- GPU: RTX 5090D 32GB class
- User-managed stable OC profile: `+320 core / +2800 mem`
- Ollama endpoint: `127.0.0.1:32100`
- Main context: `262144`
- Review context after retune: `131072`

## Main Model: qwen-main-v1

Model: `qwen3.6:35b`

Test method: 3 runs per context size, median reported, `num_predict=256`.

| Prompt context | Actual prompt tokens | Prompt eval | Output generation | Wall |
| --- | ---: | ---: | ---: | ---: |
| 0K | `102` | `1269.41 tok/s` | `228.43 tok/s` | `1.41s` |
| 50K | `50105` | `7190.92 tok/s` | `179.11 tok/s` | `7.77s` |
| 100K | `100107` | `6178.68 tok/s` | `154.95 tok/s` | `18.25s` |
| 150K | `150107` | `5101.61 tok/s` | `128.96 tok/s` | `32.18s` |
| 200K | `200107` | `4421.24 tok/s` | `113.94 tok/s` | `48.21s` |

## Review Model: qwen-review-v1

Model: `qwen3.6:27b`

Temporary 256K test method: 1 run per context size, `num_predict=256`. This test motivated the final 128K review setting.

| Prompt context | Actual prompt tokens | Prompt eval | Output generation | Wall |
| --- | ---: | ---: | ---: | ---: |
| 0K | `120` | `647.42 tok/s` | `72.21 tok/s` | `4.81s` |
| 50K | `50123` | `2679.26 tok/s` | `59.38 tok/s` | `23.27s` |
| 100K | `100125` | `1953.48 tok/s` | `50.64 tok/s` | `56.93s` |
| 150K | `150125` | `1524.39 tok/s` | `44.65 tok/s` | `105.51s` |
| 200K | `200125` | `1254.68 tok/s` | `39.62 tok/s` | `167.73s` |

Decision: use `qwen-main-v1` for long-context default work. Keep `qwen-review-v1` at 128K for second opinions and review tasks.

## Stability

Final two-hour stability validation used `qwen-main-v1` at 256K:

- Duration target: `7200s`
- Elapsed: `7224.4s`
- Iterations: `219`
- Result: `219` OK, `0` failed
- Max observed GPU: `577.39W`, `78C`, `30685 MiB`, `16601 MHz` memory clock
- Error scan: no HTTP, CUDA, OOM, driver reset, Xid, panic, or exception errors were observed.
