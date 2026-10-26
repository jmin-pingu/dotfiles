---
name: handoff
description: Hand this session's work off to a fresh Claude session. Use when the context window nears its limit (a hook says it passed 80%), or the user says "handoff", "hand this off", "start a new session", "we're running out of context". Writes a handoff file, then opens a new tmux window running claude on it. "/handoff resume [file]" picks up a handoff in the current session instead.
argument-hint: "[resume [file]] or [optional focus for the next session]"
---

# Handoff

Two modes. If `$ARGUMENTS` starts with `resume`, go to **Resume**. Otherwise **Write**.

## Write

### 1. Write the handoff file
Path: `~/.claude/handoffs/<YYYY-MM-DD-HHMM>-<slug>.md`. Slug: 2-4 words from the session name or task.

The next session knows nothing. Write so it can act without asking. Only facts checked in this session; mark anything unverified.

```markdown
# Handoff: <task>
- From session: <session id or name>, <date>
- Working dir: <absolute path>

## Goal
What the user wants, in their words where possible.

## Done
- Each finished step, with proof: commit hash, file:line, command + result.

## State right now
- What's applied vs only committed vs only drafted.
- Anything running or waiting (builds, PRs, background jobs).

## Next step
The one thing to do first. Then the rest, in order.

## Open questions
Decisions waiting on the user.

## Decisions and why
- Choice -> reason. So the next session doesn't redo them.

## Dead ends
- What failed and why.

## Key files
- `path:line` - why it matters.

## User preferences seen this session
Only ones not already in CLAUDE.md or memory.
```

If `$ARGUMENTS` has a focus, lead with it and trim unrelated parts.

### 2. Save lasting knowledge
If the session learned something worth keeping beyond this task, run the `vault-save` skill too. The handoff file is for the task; the vault is for knowledge.

### 3. Start the new session
Topic: use the session's original name if it has one. Look in order:
1. A system reminder saying "The user named this session ...".
2. The latest `/rename` in the transcript: `grep '"type":"custom-title"' ~/.claude/projects/*/<session id>.jsonl | tail -1`. The session id is in the scratchpad path, or in `~/.cache/claude-ctx/` (newest file).
3. Else the slug.

Strip any trailing ` [continued]` or ` [handoff]` so names don't stack. Use the topic for the handoff file slug too.

If `$TMUX` is set:
```
tmux rename-window -t "$TMUX_PANE" "<topic> [handoff]"
tmux new-window -c "<working dir>" -n "<topic> [continued]" "claude -n '<topic> [continued]' '/handoff resume <handoff file>'"
```
If the sandbox blocks it, or not in tmux, give the user the `claude -n ...` command to run.

### 4. Tell the user
One or two lines: the handoff file path, and that the new session is open (or the command to run). Claude can't rename its own session, so ask the user to run `/rename <topic> [handoff]` here. This session can be closed.

## Resume

1. File: the path in `$ARGUMENTS`, else the newest file in `~/.claude/handoffs/`.
2. Read it. Check its "State right now" is still true (git log, file contents) before trusting it.
3. Tell the user in 2-3 lines: the goal, what's done, and the next step. Ask before doing anything outward-facing or hard to undo.
4. Continue from "Next step".
