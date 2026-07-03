#!/usr/bin/env python3
"""Verify that Ollama returns structured tool calls for OpenClaw-style agent use."""

from __future__ import annotations

import argparse
import json
import urllib.request


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="http://127.0.0.1:32100")
    parser.add_argument("--model", default="qwen3.6-35b-normal")
    args = parser.parse_args()

    payload = {
        "model": args.model,
        "messages": [
            {
                "role": "user",
                "content": "Use the add_numbers tool to add 17 and 25. Do not calculate it yourself.",
            }
        ],
        "stream": False,
        "think": False,
        "tools": [
            {
                "type": "function",
                "function": {
                    "name": "add_numbers",
                    "description": "Add two integers",
                    "parameters": {
                        "type": "object",
                        "required": ["a", "b"],
                        "properties": {
                            "a": {"type": "integer"},
                            "b": {"type": "integer"},
                        },
                    },
                },
            }
        ],
        "options": {"num_ctx": 100000, "temperature": 0},
    }

    request = urllib.request.Request(
        f"{args.host.rstrip('/')}/api/chat",
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=300) as response:
        result = json.loads(response.read().decode("utf-8"))

    print(json.dumps(result, ensure_ascii=False, indent=2))
    calls = result.get("message", {}).get("tool_calls") or []
    if not calls:
        print("FAIL: no structured tool_calls returned")
        return 2
    first = calls[0].get("function", {})
    if first.get("name") != "add_numbers":
        print("FAIL: wrong tool name")
        return 3
    arguments = first.get("arguments", {})
    if arguments.get("a") != 17 or arguments.get("b") != 25:
        print("FAIL: wrong tool arguments")
        return 4
    print("PASS: structured tool call is correct")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
