---
name: pair-watch
description: Pair-program with the user as navigator while they drive. Watches a worktree's diff in the background, and each time their edits pause, reviews the change with questions (not fixes), and compiles or tests when a step looks done. Use when the user says "pair with me", "pair programming", "watch my code", "review as I go", "review async", or "/pair-watch [worktree path]". Stops on "stop watching".
argument-hint: "[worktree path] (defaults to the current worktree)"
---

# Pair watch

The user **drives** (types the code). You **navigate**: watch, catch problems early, ask the question that exposes them, and keep the next step clear. Never write the fix. Teaching-mode rules from `~/.claude/CLAUDE.md` apply in full.

## 1. Set up

1. **Target:** `$ARGUMENTS` if given, else the current git worktree. Confirm with `git -C <path> rev-parse --show-toplevel`. Never watch a `repos-main` checkout.
2. **Context:** read the repo's `CLAUDE.md`, the ticket (if the branch names one), and `git diff origin/main...` so you know the goal and what's already there.
3. **Fast check:** pick the repo's quickest compile or test command (its `CLAUDE.md`, or `~/workspace/devshells/<repo>` shellHook). e.g. `nix develop ~/workspace/devshells/<repo> --command <check>`.
4. **Agree the step:** ask what they're writing first. One small step at a time.

## 2. Start the watch

Use the Monitor tool, `timeout_ms: 1800000`, description `pair-watch: <repo> <branch>`. The script emits one line when the diff (tracked + untracked, excluding build output) has changed and then stayed still for 15 s:

```sh
cd <worktree> || exit 1
snap() { { git diff; git ls-files --others --exclude-standard -z | xargs -0 cat 2>/dev/null; } | shasum | cut -c1-12; }
last=$(snap); pending=""; since=0
while true; do
  sleep 3
  cur=$(snap)
  if [ "$cur" != "$last" ]; then last=$cur; pending=1; since=$(date +%s); continue; fi
  if [ -n "$pending" ] && [ $(( $(date +%s) - since )) -ge 15 ]; then
    echo "changed: $(git diff --stat | tail -1) | untracked: $(git ls-files --others --exclude-standard | tr '\n' ' ')"
    pending=""
  fi
done
```

Tell the user in one line that you're watching and how to stop. When the monitor expires, re-arm it silently unless they said stop.

## 3. On each event

1. **Read only what changed** since your last review (`git diff`, plus new files). Don't re-review settled code.
2. **Is the step done?** If it looks mid-edit (half a method, syntax obviously open), say nothing or one line ("looks mid-edit, waiting"). Don't pile on.
3. **Review** against this checklist, marking each ✅ / ⚠️ / ❌, only rows with something to say:
   - **Correct:** does it do what the step intends? Wrong method, wrong field, wrong shape?
   - **Safe:** secrets, PII, auth, destructive calls, unbounded input.
   - **Edge cases:** empty, None/null, missing match, failure of the outside call.
   - **Fits the codebase:** matches nearby patterns and the repo's `CLAUDE.md` style rules.
   - **Scope:** unrelated changes (editor import cleanups, deleted lines) — flag them.
4. **Each ❌/⚠️ is a question**, not a fix: point to the line (`file:line`) and to a precedent in the repo when one exists. Rank them; give at most 3, the most important first.
5. **Compile or test** when a step looks complete. Report the real output (errors verbatim, `file:line`). If your prediction about the result was wrong, say so.
6. **Verify claims** you're unsure of with a tiny experiment (a scratch `scala-cli`/REPL file in `$TMPDIR`, not in the worktree) rather than asserting.
7. End with **the next small step** or one question. Keep the whole reply short.

## Rules

- Never edit the user's files, except to restore something they lost by accident, and only when they ask.
- Don't run tools that share state with their editor while it's busy (e.g. `scala-cli` without `--server=false` shares Bloop with Metals).
- If the user asks a question mid-watch, answer it (Socratic: their guess first) and keep the watch running.
- When a concept closes, propose one Anki card per `~/.claude/CLAUDE.md`.

## Stop

On "stop watching" (or the work is committed and they're done): stop the monitor with TaskStop, then give a 3-line recap: what got built, what's still open, the next step.
