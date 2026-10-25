#!/usr/bin/env python3
"""Claude Code session meter: wall time, tokens and API-equivalent cost.

Reads a Claude Code session transcript (~/.claude/projects/<dir>/<id>.jsonl)
and totals every model request in it, or only those between two times.
Subagents write their own transcripts next to it, in
<dir>/<id>/subagents/agent-*.jsonl: those are counted too.

  claude-meter.py <transcript.jsonl> [--since ISO] [--until ISO] [--line]

--line prints one line for a commit message instead of the table:
  Meter: 0:42:10 elapsed, 3,201,442 tokens, $1.84

Each request is counted once (its usage repeats on several lines with the
same requestId). Cost is what the tokens would cost at API list prices; on
a subscription it is a measure, not a bill.
"""
import argparse, collections, json
from pathlib import Path
from datetime import datetime, timezone

# Per million tokens, from Anthropic's price list (checked 2026-10-25).
# Cache writes: 1.25x input for the 5-minute cache, 2x for the 1-hour one.
PRICES = {
    "claude-opus-5-5": {"input": 4.00, "output": 20.00, "cache_read": 0.20},
}

def when(text):
    return datetime.fromisoformat(text.replace("Z", "+00:00")).astimezone(timezone.utc)

def main():
    args = argparse.ArgumentParser()
    args.add_argument("transcript")
    args.add_argument("--since")
    args.add_argument("--until")
    args.add_argument("--line", action="store_true")
    a = args.parse_args()
    since = when(a.since) if a.since else None
    until = when(a.until) if a.until else None
    main = Path(a.transcript)
    files = [main] + sorted(main.with_suffix("").glob("subagents/**/agent-*.jsonl"))
    requests = {}
    subagent_requests = set()
    for path in files:
        for line in open(path):
            entry = json.loads(line)
            message = entry.get("message")
            if entry.get("type") != "assistant" or not isinstance(message, dict) or not message.get("usage"):
                continue
            at = when(entry["timestamp"])
            if (since and at < since) or (until and at > until):
                continue
            key = entry.get("requestId") or entry.get("uuid")
            requests[key] = (at, message.get("model"), message["usage"])
            if path != main:
                subagent_requests.add(key)
    totals = collections.Counter()
    cost = 0.0
    unpriced = set()
    for at, model, usage in requests.values():
        writes = usage.get("cache_creation") or {}
        write_5m = writes.get("ephemeral_5m_input_tokens", 0)
        write_1h = writes.get("ephemeral_1h_input_tokens", 0)
        if not writes:
            write_5m = usage.get("cache_creation_input_tokens", 0)
        counts = {
            "input": usage.get("input_tokens", 0),
            "cache_write_5m": write_5m,
            "cache_write_1h": write_1h,
            "cache_read": usage.get("cache_read_input_tokens", 0),
            "output": usage.get("output_tokens", 0),
        }
        totals.update(counts)
        price = PRICES.get(model)
        if not price:
            unpriced.add(model)
            continue
        cost += (counts["input"] * price["input"]
                 + counts["cache_write_5m"] * price["input"] * 1.25
                 + counts["cache_write_1h"] * price["input"] * 2
                 + counts["cache_read"] * price["cache_read"]
                 + counts["output"] * price["output"]) / 1_000_000
    times = sorted(at for at, _, _ in requests.values())
    start = since or (times[0] if times else None)
    end = until or (times[-1] if times else None)
    if a.line:
        elapsed = str(end - start).split(".")[0] if start and end else "0:00:00"
        print(f"Meter: {elapsed} elapsed, {sum(totals.values()):,} tokens, ${cost:,.2f}")
        return
    print(f"requests      {len(requests)} ({len(subagent_requests)} by {len(files) - 1} subagents)")
    if start and end:
        print(f"wall time     {end - start} ({start:%Y-%m-%d %H:%M:%S} to {end:%H:%M:%S} UTC)")
    for key in ("input", "cache_write_5m", "cache_write_1h", "cache_read", "output"):
        print(f"{key:<14}{totals[key]:>12,}")
    print(f"total tokens  {sum(totals.values()):>12,}")
    print(f"cost          ${cost:,.2f} (API list prices)")
    if unpriced:
        print(f"no price for  {', '.join(sorted(map(str, unpriced)))}: not in the cost")

if __name__ == "__main__":
    main()
