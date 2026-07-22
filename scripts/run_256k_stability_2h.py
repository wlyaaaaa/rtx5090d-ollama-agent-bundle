#!/usr/bin/env python3
"""Run a long Ollama 256K stability workload and write resumable status logs."""

from __future__ import annotations

import argparse
import csv
import json
import subprocess
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def post_json(url: str, payload: dict[str, Any], timeout: int) -> dict[str, Any]:
    data = json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return json.loads(response.read().decode("utf-8"))


def ns_rate(count: int, duration_ns: int) -> float:
    if duration_ns <= 0:
        return 0.0
    return count / (duration_ns / 1_000_000_000)


def gpu_sample() -> dict[str, Any]:
    query = (
        "timestamp,power.draw,power.limit,temperature.gpu,utilization.gpu,"
        "clocks.current.graphics,clocks.current.memory,memory.used,memory.total"
    )
    output = subprocess.check_output(
        [
            "nvidia-smi",
            f"--query-gpu={query}",
            "--format=csv,noheader,nounits",
        ],
        text=True,
        stderr=subprocess.STDOUT,
    ).strip()
    parts = [part.strip() for part in output.split(",")]
    return {
        "timestamp": parts[0],
        "power_w": float(parts[1]),
        "power_limit_w": float(parts[2]),
        "temperature_c": int(parts[3]),
        "utilization_pct": int(parts[4]),
        "gfx_mhz": int(parts[5]),
        "mem_mhz": int(parts[6]),
        "memory_used_mib": int(parts[7]),
        "memory_total_mib": int(parts[8]),
    }


def write_status(path: Path, status: dict[str, Any]) -> None:
    tmp = path.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(status, ensure_ascii=False, indent=2), encoding="utf-8")
    tmp.replace(path)


def append_jsonl(path: Path, record: dict[str, Any]) -> None:
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(record, ensure_ascii=False) + "\n")


def make_prompt(repeat_count: int, salt: str) -> str:
    context = f"UNIQUE_STABILITY_SALT {salt}\n" + (" a" * repeat_count)
    instruction = (
        f"\nSTABILITY_ID {salt}. Ignore the repeated filler above. "
        "Generate numbered benchmark lines from 0001 upward. "
        "Each line must contain STABILITY256K and a compact phrase. "
        "Do not stop until the token limit stops you.\n"
    )
    return context + instruction


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="http://127.0.0.1:32100")
    parser.add_argument("--model", default="qwen-main-v1")
    parser.add_argument("--num-ctx", type=int, default=262144)
    parser.add_argument("--num-predict", type=int, default=256)
    parser.add_argument("--duration-seconds", type=int, default=7200)
    parser.add_argument("--run-dir", required=True)
    parser.add_argument("--timeout", type=int, default=1800)
    parser.add_argument("--max-consecutive-failures", type=int, default=3)
    args = parser.parse_args()

    run_dir = Path(args.run_dir)
    run_dir.mkdir(parents=True, exist_ok=True)
    events_path = run_dir / "events.jsonl"
    status_path = run_dir / "status.json"
    gpu_path = run_dir / "gpu_samples.csv"

    pattern = [
        ("50k", 50_000),
        ("100k", 100_000),
        ("200k", 200_000),
        ("240k", 240_000),
    ]
    started_perf = time.perf_counter()
    started_at = now_iso()
    deadline_perf = started_perf + args.duration_seconds
    ok_count = 0
    fail_count = 0
    consecutive_failures = 0
    iteration = 0
    max_gpu = {
        "power_w": 0.0,
        "temperature_c": 0,
        "utilization_pct": 0,
        "gfx_mhz": 0,
        "mem_mhz": 0,
        "memory_used_mib": 0,
    }

    with gpu_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "sample_time_utc",
                "case",
                "iteration",
                "timestamp",
                "power_w",
                "power_limit_w",
                "temperature_c",
                "utilization_pct",
                "gfx_mhz",
                "mem_mhz",
                "memory_used_mib",
                "memory_total_mib",
            ],
        )
        writer.writeheader()

    def update_gpu_max(sample: dict[str, Any]) -> None:
        for key in max_gpu:
            max_gpu[key] = max(max_gpu[key], sample[key])

    def base_status(state: str, last_record: dict[str, Any] | None = None) -> dict[str, Any]:
        elapsed = time.perf_counter() - started_perf
        remaining = max(0.0, deadline_perf - time.perf_counter())
        return {
            "state": state,
            "run_dir": str(run_dir),
            "started_at_utc": started_at,
            "updated_at_utc": now_iso(),
            "duration_seconds": args.duration_seconds,
            "elapsed_seconds": round(elapsed, 1),
            "remaining_seconds": round(remaining, 1),
            "model": args.model,
            "host": args.host,
            "num_ctx": args.num_ctx,
            "num_predict": args.num_predict,
            "iteration": iteration,
            "ok_count": ok_count,
            "fail_count": fail_count,
            "consecutive_failures": consecutive_failures,
            "max_gpu": max_gpu,
            "last_record": last_record,
        }

    last_record: dict[str, Any] | None = None
    write_status(status_path, base_status("running"))

    while time.perf_counter() < deadline_perf:
        case, repeat_count = pattern[iteration % len(pattern)]
        iteration += 1
        salt = f"{case}_iter_{iteration:05d}_{int(time.time())}"
        payload = {
            "model": args.model,
            "messages": [{"role": "user", "content": make_prompt(repeat_count, salt)}],
            "stream": False,
            "think": False,
            "keep_alive": "30m",
            "options": {
                "num_ctx": args.num_ctx,
                "num_predict": args.num_predict,
                "temperature": 0,
                "seed": 42,
            },
        }

        start_sample = gpu_sample()
        update_gpu_max(start_sample)
        with gpu_path.open("a", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(handle, fieldnames=["sample_time_utc", "case", "iteration", *start_sample.keys()])
            writer.writerow({"sample_time_utc": now_iso(), "case": case, "iteration": iteration, **start_sample})

        started = time.perf_counter()
        try:
            result = post_json(f"{args.host.rstrip('/')}/api/chat", payload, args.timeout)
            wall_seconds = time.perf_counter() - started
            end_sample = gpu_sample()
            update_gpu_max(end_sample)
            record = {
                "time_utc": now_iso(),
                "iteration": iteration,
                "case": case,
                "repeat_count": repeat_count,
                "ok": True,
                "wall_seconds": wall_seconds,
                "prompt_eval_count": int(result.get("prompt_eval_count", 0)),
                "prompt_eval_rate": ns_rate(
                    int(result.get("prompt_eval_count", 0)),
                    int(result.get("prompt_eval_duration", 0)),
                ),
                "eval_count": int(result.get("eval_count", 0)),
                "eval_rate": ns_rate(
                    int(result.get("eval_count", 0)),
                    int(result.get("eval_duration", 0)),
                ),
                "done_reason": result.get("done_reason"),
                "content_tail": result.get("message", {}).get("content", "")[-120:],
                "gpu_end": end_sample,
            }
            ok_count += 1
            consecutive_failures = 0
        except Exception as exc:  # noqa: BLE001 - stability log should keep going.
            wall_seconds = time.perf_counter() - started
            record = {
                "time_utc": now_iso(),
                "iteration": iteration,
                "case": case,
                "repeat_count": repeat_count,
                "ok": False,
                "wall_seconds": wall_seconds,
                "error_type": type(exc).__name__,
                "error": str(exc),
            }
            if isinstance(exc, urllib.error.HTTPError):
                record["http_code"] = exc.code
                try:
                    record["body_tail"] = exc.read().decode("utf-8", errors="replace")[-500:]
                except Exception:
                    pass
            fail_count += 1
            consecutive_failures += 1

        last_record = record
        append_jsonl(events_path, record)
        write_status(status_path, base_status("running", last_record))

        if consecutive_failures >= args.max_consecutive_failures:
            write_status(status_path, base_status("failed", last_record))
            return 2

        time.sleep(2)

    write_status(status_path, base_status("completed", last_record))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
