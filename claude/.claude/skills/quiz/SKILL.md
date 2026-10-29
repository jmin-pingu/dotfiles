---
name: quiz
description: Write and run a quiz on what this session covered, or on a PR or diff, to check the user understands it. Use when the user says "quiz me", "/quiz", "test my understanding", "make a quiz for this session", or when a PR the user authored is about to be marked ready or merged (the merge gate in ~/workspace/CLAUDE.md). Fits the questions to what the user already knows, puts expected answers in the file, runs it one question at a time, and grades.
argument-hint: "[session | pr <number> | diff] [repo] (default: this session)"
---

# Quiz

The rules live in `~/workspace/CLAUDE.md` (Vault → Quizzes, and Pull requests step 9). Follow them; this file is the procedure.

## 1. Scope

From `$ARGUMENTS` (default `session`):
- **session:** what this session built, decided, or explained. Code the user wrote, design choices, concepts we closed.
- **pr <n>** / **diff:** the final diff (`gh pr diff <n>` or `git diff origin/main...`), including parts the user didn't write.

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
| Date | Q | My answer (short) | Grade |
|---|---|---|---|

## Related
- [[<lesson>]]
```

- 2-4 questions per section (3-4 total for a `low`-ceiling PR).
- Types: predict the output, explain why, spot the bug in a changed snippet, trace a request. No pure recall.
- Early in a repo, weight **Fit** toward structure: modules and dependency direction, where routes/clients/config/models live, DI wiring, request flow.

## 4. Run it

1. One question at a time. Don't show the answer first. If the user asks a question back, Socratic rules apply.
2. Grade **right / partly / wrong** against the expected answer. Say what was right in one line; for partly/wrong, ask one follow-up question before revealing.
3. Append to **Results** after each answer.
4. Each miss → propose one Anki card (rules in `~/.claude/CLAUDE.md`).
5. **Pass** = no question left "wrong". Re-ask each miss in a later turn, after the user rereads the code.

## 5. After

- Update `_understanding.md`: move items between Solid / Shaky / Not seen, with the date and the question that showed it.
- Link the quiz both ways with its lesson (and ticket/PR in frontmatter). List it in `index.md` under "Quizzes".
- For a PR: report `Quiz: <path> — <score>, passed? yes/no`. Until it's passed, don't mark the PR ready, merge it, or enable auto-merge.

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
