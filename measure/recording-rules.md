# Recording rules

The message that starts a recorded run, word for word. Each run gets its
own branch: `build` for the first (from tag `v1`), `build-v2` for the
second (from tag `v2`). This is the v2 message; v1's is in the `v1` tag.
Each run is a fresh Claude Code session in this repository, in bypass
mode (`claude --dangerously-skip-permissions`), so it never waits on a
person to approve anything.

---

Read PROMPT.md and do what it says. This build is being recorded for a
video, so also follow these rules:

- Work only in ~/projects/platformer, on a new branch named `build-v2`.
  Don't push.
- Start from the repository alone. Don't read the memory bank, even
  though CLAUDE.md says to at the start of a session. Don't look in
  ~/archive, at other sessions' transcripts, at the `build` branch (an
  earlier run), or anywhere else outside the project, except to read this
  session's own transcript for the meter.
- Commit small and often: one working step per commit, with a message
  that says what the step did and why. End every commit message with a
  blank line and the meter line printed by

      python3 measure/claude-meter.py <transcript> --line

  where <transcript> is the newest .jsonl file in
  ~/.claude/projects/-home-clif-projects-platformer/ (this session's own
  transcript). The meter counts time, tokens and API-price cost since this
  session started.
- Make the first commit before writing any game code, so the video
  starts near zero, and the last commit the moment you say you're done.
- Use subagents if you judge they help: the meter counts their tokens
  too.
