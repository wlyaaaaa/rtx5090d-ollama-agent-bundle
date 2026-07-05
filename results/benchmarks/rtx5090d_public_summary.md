# RTX 5090D Public Benchmark Summary

Generated: 2026-07-05

This file is a public-safe summary derived from local raw benchmark and stability evidence. It intentionally excludes Windows paths, process lists, launcher logs, private URLs, generated text tails, random run IDs, credentials, and private environment details.

## Source Counts

- Benchmark JSON files summarized: 25
- SMI CSV files summarized: 9
- Stability status files summarized: 3

## Top Prompt Evaluation Runs

| Label | Runs | OK | Median prompt tokens | Median prompt eval tok/s | Median eval tok/s | Median wall seconds |
|---|---:|---:|---:|---:|---:|---:|
| `bench_5090d_manual_current_oc360_mem3000_repeat5_20260703-070420_45k_64` | 5 |  | 28247 | 252295.46 | 136.36 | 0.38 |
| `bench_5090d_oc250_mem2000_128k_45k_64_20260703-065353` | 1 |  | 28247 | 219373.73 | 117.48 | 0.48 |
| `bench_5090d_oc300_mem2500_128k_cold_45k_64_20260703-065719` | 1 |  | 28247 | 6556.57 | 113.51 | 9.21 |
| `bench_5090d_oc360_mem3000_128k_cold_45k_64_20260703-065941` | 1 |  | 28247 | 6553.61 | 103.89 | 9.49 |
| `manual_current_oc360_mem3000_unique5` | 5 |  | 41954 | 6398.84 | 172.2 | 6.96 |

## Top Generation Runs

| Label | Runs | OK | Median prompt tokens | Median prompt eval tok/s | Median eval tok/s | Median wall seconds |
|---|---:|---:|---:|---:|---:|---:|
| `manual_current_oc360_mem3000_unique5` | 5 |  | 41954 | 6398.84 | 172.2 | 6.96 |
| `manual_oc320_mem2500_unique5` | 5 |  | 41954 | 6333.67 | 169.78 | 7.27 |
| `oc340_mem3000` | 7 | 7 | 46838 | 6249.63 | 164.5 | 7.96 |
| `oc340_mem2500` | 7 | 7 | 46838 | 6236.43 | 163.89 | 7.97 |
| `manual_oc365_mem2500_retest_unique7` | 7 | 7 | 42178 | 5968.31 | 163.73 | 7.5 |

## Long-Context Generation Cases

| Label | Case | OK / Runs | Median actual prompt tokens | Median prompt eval tok/s | Median eval tok/s | Median wall seconds |
|---|---|---:|---:|---:|---:|---:|
| `bench_5090d_oc320_mem2800_generation_0_50_100_150_200_20260703-152507` | `0K` | 3/3 | 102 | 1269.41 | 228.43 | 1.41 |
| `bench_5090d_oc320_mem2800_generation_0_50_100_150_200_20260703-152507` | `50K` | 3/3 | 50105 | 7190.92 | 179.11 | 7.77 |
| `bench_5090d_oc320_mem2800_generation_0_50_100_150_200_20260703-152507` | `100K` | 3/3 | 100107 | 6178.68 | 154.95 | 18.25 |
| `bench_5090d_oc320_mem2800_generation_0_50_100_150_200_20260703-152507` | `150K` | 3/3 | 150107 | 5101.61 | 128.96 | 32.18 |
| `bench_5090d_oc320_mem2800_generation_0_50_100_150_200_20260703-152507` | `200K` | 3/3 | 200107 | 4421.24 | 113.94 | 48.21 |
| `bench_5090d_oc320_mem2800_qwen27b_generation_0_50_100_150_200_20260703-160621` | `0K` | 1/1 | 120 | 647.42 | 72.21 | 4.81 |
| `bench_5090d_oc320_mem2800_qwen27b_generation_0_50_100_150_200_20260703-160621` | `50K` | 1/1 | 50123 | 2679.26 | 59.38 | 23.27 |
| `bench_5090d_oc320_mem2800_qwen27b_generation_0_50_100_150_200_20260703-160621` | `100K` | 1/1 | 100125 | 1953.48 | 50.64 | 56.93 |
| `bench_5090d_oc320_mem2800_qwen27b_generation_0_50_100_150_200_20260703-160621` | `150K` | 1/1 | 150125 | 1524.39 | 44.65 | 105.51 |
| `bench_5090d_oc320_mem2800_qwen27b_generation_0_50_100_150_200_20260703-160621` | `200K` | 1/1 | 200125 | 1254.68 | 39.62 | 167.73 |
| `oc340_mem3000_generation_0_50k_100k` | `near_0` | 3/3 | 57 | 2026.88 | 232.29 | 2.43 |
| `oc340_mem3000_generation_0_50k_100k` | `50k` | 3/3 | 81250 | 5663.65 | 164.15 | 17.97 |
| `oc340_mem3000_generation_0_50k_100k` | `100k` | 3/3 | 65538 | 5876.59 | 175.37 | 14.57 |
| `oc340_mem3000_generation_calibrated_0_50k_100k` | `near_0` | 3/3 | 72 | 1046.71 | 235.07 | 2.44 |
| `oc340_mem3000_generation_calibrated_0_50k_100k` | `50k` | 3/3 | 50074 | 420426.02 | 188.14 | 3.03 |
| `oc340_mem3000_generation_calibrated_0_50k_100k` | `100k` | 3/3 | 100075 | 639951.66 | 155.06 | 3.69 |

## Stability Summary

| Run | State | Iterations | OK | Fail | Max power W | Max temp C | Max util % | Max memory MiB |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| `smoke_test` | completed | 1 | 1 | 0 | 436.14 | 65 | 91 | 31590 |
| `stability_256k_20260703-082357` | running | 11 | 11 | 0 | 575.25 | 76 | 91 | 31713 |
| `stability_256k_20260703-084539` | completed | 219 | 219 | 0 | 577.39 | 78 | 95 | 30685 |

## Raw Evidence Policy

Raw benchmark/stability files remain local evidence unless explicitly cleaned. The public repository ignores raw 5090D benchmark files, GPU process snapshots, launcher/status files, and stability logs by default.
