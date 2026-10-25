# How the run was measured

Two recorded runs built the game from this repository, each on its own
branch: `build` from the spec at tag `v1`, and `build-v2` from tag `v2`,
the spec revised from the first run's own feedback. This folder says how
the runs were set up and measured, so the numbers in their commits can be
checked and repeated. Both runs used the same prompt, rules and meter;
only the specs changed.

## The setup

- **The prompt:** `PROMPT.md`, at the root of `main`. It is the whole
  brief: build what `specs/` describes, with the assets in this
  repository, and say when it's done. Anyone can run it: clone `main`,
  open Claude Code in it and say "Read PROMPT.md and do what it says."
- **The recorded run** got the same prompt plus the rules in
  `recording-rules.md`: work on the run's own branch, make small commits, end
  each commit message with a meter reading, start from the repository
  alone.
- **A fresh start:** a new Claude Code session that had never seen these
  specs. Claude's memory from earlier sessions was off limits, and the
  practice build made while writing the specs was moved out of the
  repository and out of reach before the first run. The second run was
  told not to look at the first run's branch either.
- **No waiting on a person:** bypass mode, so no step waited for approval
  and the clock only measures Claude's work.
- **Subagents allowed:** Claude decided whether to use them. Their tokens
  are counted (below).
- **Done is Claude's call:** the run ended when Claude said the game was
  complete and working. Then a person played it. There was no separate
  pass mark.

## The meter

`claude-meter.py` reads the session's transcript, which Claude Code
saves at `~/.claude/projects/<project folder>/<session id>.jsonl`, and
the transcripts of any subagents, saved next to it in
`<session id>/subagents/`. Every model request there records its tokens
and a timestamp.

```
python3 measure/claude-meter.py <transcript.jsonl>          # a table
python3 measure/claude-meter.py <transcript.jsonl> --line   # one line, for a commit
python3 measure/claude-meter.py <transcript.jsonl> --since 2026-10-25T18:00:00+07:00 --until ...
```

It reports:

- **Time:** wall-clock time from the session's first model request to
  its last.
- **Tokens:** every token of every request, by kind: input, cache writes
  (5-minute and 1-hour), cache reads and output. Each request is counted
  once (its usage repeats on several lines of the transcript).
- **Cost:** what those tokens cost at Anthropic's API list prices for the
  model used, Claude Opus 5.5: $4 per million input tokens, $20 per
  million output, $0.20 per million cache reads, and cache writes at 1.25×
  input (5-minute cache) or 2× (1-hour), as of October 2026.

## Reading the numbers

- **Cost is the API price, not a bill.** The run was made on a Claude
  subscription, which is priced differently. The API price is the
  comparable number: it is what anyone running the same tokens through
  the API would pay.
- **Most tokens are cache reads.** Every request re-sends the whole
  conversation so far, and most of it is read from the cache at a small
  fraction of the input price. That is why the token count is large and
  the cost small.
- **The meters in each commit are totals so far**, since the session
  started, so the video can show them climbing commit by commit.
