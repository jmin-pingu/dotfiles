---
name: quiz
description: Write and run a quiz on what this session covered, a PR or diff, or a vault lesson or learning todo we worked through, to check the user understands it. Use when the user says "quiz me", "/quiz", "test my understanding", "make a quiz for this session", or when a PR the user authored is about to be marked ready or merged (the merge gate in ~/workspace/CLAUDE.md). Fits the questions to what the user already knows, puts expected answers in the file, runs it one question at a time, and grades.
argument-hint: "[session | pr <number> | diff | lesson <name> | todo <name> | review] [repo] (default: this session)"
---

**`review` mode** (spaced repetition): skip to **Review** at the bottom.

# Quiz

The rules live in `~/workspace/CLAUDE.md` (Vault → Quizzes, and Pull requests step 9). Follow them; this file is the procedure.

## 1. Scope

From `$ARGUMENTS` (default `session`):
- **session:** what this session built, decided, or explained. Code the user wrote, design choices, concepts we closed.
- **pr <n>** / **diff:** the final diff (`gh pr diff <n>` or `git diff origin/main...`), including parts the user didn't write.
- **lesson <name>** / **todo <name>:** a vault lesson or learning todo we worked through. Quiz its questions and its "Do it" tasks; file it at `quiz/<topic>/<note name>.md`; add `quiz: [[<quiz name>]]` to the note's frontmatter and link both ways. A todo is done only when its quiz passes. Also trigger this automatically when we finish (a chunk of) a lesson or todo.

**Repo:** the arg, else the current worktree's repo. A session with no repo (e.g. a learning lab, tooling) uses a topic name instead.

## 2. Read first

1. `vault/quiz/<repo>/_understanding.md` (create it from the template below if missing). Aim at the edge: shaky and not-seen items first; skip what's solid unless the change touches it in a new way.
2. Any earlier quiz for the same ticket, so you re-ask misses instead of repeating passes.
3. The code itself. Every expected answer must be checked against a `file:line` or a source opened this session. Never answer from memory.

## 3. Write the file

Path (workspace sessions): `~/workspace/vault/quiz/<repo>/<TICKET-ID> <short name>.md`. No ticket → `<YYYY-MM-DD> <short name>.md`. Outside `~/workspace`: `~/.claude/vault/quiz/<topic>/...`.

```markdown
---
tags: [quiz]
repo: <repo>
ticket: <full ticket URL or none>
pr: <full PR URL or none>
created: <date>
verified: <repo>@<short sha of origin/main> <date>
sources: [<file paths / URLs>]
---

# Quiz: <short name>

Level: <one line: what this quiz targets, from _understanding.md>

## 1. My change
### Q1. <question>
> [!note]- Answer
> <expected answer in plain words> — `<abs path>:<line>`

## 2. Style
## 3. Design
## 4. Fit

## Results
| Date | Q | My answer (short) | Grade | Assist | Interval | Next due |
|---|---|---|---|---|---|---|

## Related
- [[<lesson>]]
```

- 2-4 questions per section (3-4 total for a `low`-ceiling PR).
- **Learn by producing: at least half the questions are hands-on tasks**, and every section has one. Prefer tasks that make the user write the language or library from scratch (e.g. "derive a null-dropping encoder for a new case class without looking at the repo"), not just edit lines already there. The user does the work; the check says pass or fail. Examples:
  - **Change and predict:** "Swap the `Encoder` for a `Codec` in `UserUpdate`. Predict the JSON, then run the scratch check." 
  - **Break it:** "Delete line X. Which compile error or test failure do you expect? Run the compile and compare."
  - **Write it:** "Write a 5-line `scala-cli` script that encodes `UserUpdate(None, Some(Seq("t")))`" or "Write the test `rejects a tampered body`" (name and what it checks only, never the body).
  - **Trace it live:** "Run the route locally and `curl` it with a bad signature. What status comes back, and which line decided it?"
  - **Find it:** "Without searching for the name, find where `UserRoutes` gets wired in. What did you search for?"
- Each task's answer callout holds the **check command and the pass condition**, not a solution to copy. Scratch work goes in `$TMPDIR` or the learning lab, never committed to the repo; restore any deliberate break before moving on.
- The rest: predict the output, explain why, spot the bug, trace a request on paper. No pure recall.
- Early in a repo, weight **Fit** toward structure: modules and dependency direction, where routes/clients/config/models live, DI wiring, request flow.

## 4. Run it

1. One question at a time. Don't show the answer first. Help only as far as the user's **assistance level** allows (`~/workspace/CLAUDE.md` → Assistance levels); log the level used in the Results row. If the user asks a question back, Socratic rules apply. For a task, the user runs it; you read the result (diff, compile output) and grade from that, not from their description. Never do the task for them.
2. Grade **right / partly / wrong** against the expected answer. Say what was right in one line; for partly/wrong, ask one follow-up question before revealing.
3. Append to **Results** after each answer.
4. Each miss → propose one Anki card (rules in `~/.claude/CLAUDE.md`).
5. **Pass** = no question left "wrong". Re-ask each miss in a later turn, after the user rereads the code.

## 5. After

- Update `_understanding.md`: move items between Solid / Shaky / Not seen, with the date and the question that showed it.
- Link the quiz both ways with its lesson (and ticket/PR in frontmatter). List it in `index.md` under "Quizzes".
- For a PR: report `Quiz: <path> — <score>, passed? yes/no`. Until it's passed, don't mark the PR ready, merge it, or enable auto-merge.

## Review (spaced repetition)

1. **Find due questions:** scan `~/workspace/vault/quiz/**/*.md` (and `~/.claude/vault/quiz/`) Results tables; a question is due when its latest `Next due` ≤ today. Pick at most 5, oldest due first, mixing repos.
2. **Drift check first:** for each picked quiz, `git -C ~/workspace/code/repos-main/<repo> fetch -q && git -C ... log --oneline <verified sha>..origin/main -- <sources>`. If anything changed, reread the code; update the question and answer (or drop it), bump `verified`, and log it in `~/workspace/vault/todos/Context maintenance.md`. Never quiz on stale answers.
3. **Ask** as in "Run it". Hands-on tasks are redone in scratch (the code may have moved on: that's part of the test).
4. **Schedule:** wrong → 1 day; partly → 3 days; right → double the last interval (first right 7 days, cap 90). Append a Results row with the new `Interval` and `Next due`.
5. **Report:** questions asked, grades, next due date overall, and any drift found.

## `_understanding.md` template

```markdown
---
tags: [quiz]
last_updated: <date>
---

# <repo>: what I understand

## Solid (shown in my own words or code)
## Shaky (asked about, partly right)
## Not seen yet
```
