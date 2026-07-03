#!/usr/bin/env python3
"""Benchmark Ollama prompt evaluation and generation rates.

Uses only Python standard library. The generated prompt is approximate; the Ollama
response's prompt_eval_count is the source of truth.
"""

from __future__ import annotations

import argparse
import json
import statistics
import time
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any


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


def make_prompt(target_tokens: int) -> str:
    block = (
        "Repository audit record. Read carefully and retain exact constraints. "
        "function validate_config(value): return value if value is not None else 'missing'\n"
        "Do not summarize this repeated context. At the end answer only with the requested marker.\n"
    )
    # Roughly 3.3 characters/token for this mixed English/code text.
    target_chars = max(256, int(target_tokens * 3.3))
    repetitions = (target_chars // len(block)) + 1
    return (block * repetitions)[:target_chars] + "\nReply with exactly: BENCH_OK"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="http://127.0.0.1:32100")
    parser.add_argument("--model", default="qwen3.6-35b-100k")
    parser.add_argument("--num-ctx", type=int, default=100000)
    parser.add_argument("--prompt-tokens", type=int, default=1000)
    parser.add_argument("--output-tokens", type=int, default=512)
    parser.add_argument("--repeats", type=int, default=3)
    parser.add_argument("--think", action="store_true")
    parser.add_argument("--prompt-file", type=Path)
    parser.add_argument("--timeout", type=int, default=1800)
    parser.add_argument("--output-json", type=Path)
    args = parser.parse_args()

    if args.num_ctx <= args.prompt_tokens + args.output_tokens:
        raise SystemExit("num_ctx must exceed prompt_tokens + output_tokens")

    prompt = (
        args.prompt_file.read_text(encoding="utf-8")
        if args.prompt_file
        else make_prompt(args.prompt_tokens)
    )

    records: list[dict[str, Any]] = []
    for index in range(1, args.repeats + 1):
        payload = {
            "model": args.model,
            "messages": [{"role": "user", "content": prompt}],
            "stream": False,
            "think": args.think,
            "keep_alive": "30m",
            "options": {
                "num_ctx": args.num_ctx,
                "num_predict": args.output_tokens,
                "temperature": 0,
                "seed": 42,
            },
        }
        started = time.perf_counter()
        try:
            result = post_json(f"{args.host.rstrip('/')}/api/chat", payload, args.timeout)
        except (urllib.error.URLError, TimeoutError) as exc:
            raise SystemExit(f"Request failed: {exc}") from exc
        wall_seconds = time.perf_counter() - started

        record = {
            "run": index,
            "model": args.model,
            "num_ctx": args.num_ctx,
            "think": args.think,
            "prompt_eval_count": int(result.get("prompt_eval_count", 0)),
            "prompt_eval_duration_ns": int(result.get("prompt_eval_duration", 0)),
            "prompt_eval_rate": ns_rate(
                int(result.get("prompt_eval_count", 0)),
                int(result.get("prompt_eval_duration", 0)),
            ),
            "eval_count": int(result.get("eval_count", 0)),
            "eval_duration_ns": int(result.get("eval_duration", 0)),
            "eval_rate": ns_rate(
                int(result.get("eval_count", 0)),
                int(result.get("eval_duration", 0)),
            ),
            "load_duration_ns": int(result.get("load_duration", 0)),
            "total_duration_ns": int(result.get("total_duration", 0)),
            "wall_seconds": wall_seconds,
            "done_reason": result.get("done_reason"),
            "content_tail": result.get("message", {}).get("content", "")[-200:],
        }
        records.append(record)
        print(json.dumps(record, ensure_ascii=False, indent=2))

    summary = {
        "runs": len(records),
        "median_prompt_tokens": statistics.median(r["prompt_eval_count"] for r in records),
        "median_prompt_eval_rate": statistics.median(r["prompt_eval_rate"] for r in records),
        "median_eval_rate": statistics.median(r["eval_rate"] for r in records),
        "median_wall_seconds": statistics.median(r["wall_seconds"] for r in records),
        "records": records,
    }
    print("\nSUMMARY")
    print(json.dumps(summary, ensure_ascii=False, indent=2))

    if args.output_json:
        args.output_json.parent.mkdir(parents=True, exist_ok=True)
        args.output_json.write_text(
            json.dumps(summary, ensure_ascii=False, indent=2), encoding="utf-8"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
