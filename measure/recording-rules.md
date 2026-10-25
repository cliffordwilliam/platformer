# Recording rules

The message that started the recorded run, word for word. The run was a
fresh Claude Code session in this repository, in bypass mode
(`claude --dangerously-skip-permissions`), so it never waited on a person
to approve anything.

---

Read PROMPT.md and do what it says. This build is being recorded for a
video, so also follow these rules:

- Work only in ~/projects/platformer, on a new branch named `build`.
  Don't push.
- Start from the repository alone. Don't read the memory bank, even
  though CLAUDE.md says to at the start of a session. Don't look in
  ~/archive, at other sessions' transcripts, or anywhere else outside the
  project, except to read this session's own transcript for the meter.
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
