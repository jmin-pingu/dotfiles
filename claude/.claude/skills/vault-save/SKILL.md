---
name: vault-save
description: Save what this session learned to the knowledge base at ~/.claude/vault, in the background. Use when the user says an exploration is "good enough", "save this", "add this to the vault", "remember this", or otherwise signals the current line of work is done and worth keeping. Checks existing notes for conflicts, then updates or creates notes.
argument-hint: "[optional focus, e.g. 'just the Databricks part']"
---

# Save to vault (non-blocking)

The user wants this exploration saved. Do not do the work in the main conversation.

## In the main conversation

1. Spawn ONE background agent with the Agent tool:
   - `subagent_type: "fork"`. A fork inherits this conversation, so it knows what was learned.
   - If `fork` is not available, use `general-purpose` and paste a short brief of the findings and their sources into the prompt.
   - `description`: "Save findings to vault"
   - `prompt`: "Run the vault-save procedure in ~/.claude/skills/vault-save/SKILL.md (section 'Background procedure'). Focus: $ARGUMENTS"
2. Tell the user in one line that it's saving in the background. Then carry on with whatever they want next.
3. When the agent finishes, relay its short report.

## Background procedure

You are the background agent. Work alone. You cannot ask the user questions.

### Rules
- Write only inside `~/.claude/vault/`. Never touch `~/Desktop/vaults/notes` (read-only; a hook blocks it) or `~/.claude/skills/synced/`.
- Follow the Knowledge base rules in `~/.claude/CLAUDE.md`.
- Use `~/.claude/vault/_template.md` for new notes.

### Step 1: List the findings
From the conversation, list each thing worth keeping: facts, how something works, fixes, commands, gotchas.
- Keep only what was actually checked in this session. Each finding needs a source (`file:line`, URL, or command + output).
- Drop guesses, dead ends, and anything only about this one task.
- If a focus was given, keep only findings about it.

### Step 2: Check for conflicts
For each finding, search the vault for related notes:
- Read `~/.claude/vault/index.md`.
- Grep `~/.claude/vault/notes/` (recursively) for key terms, names, file paths, and synonyms.
- Read every note that looks related.

Sort each finding into one of these:
| Type | Meaning | Action |
|---|---|---|
| New | No related note | Create a note |
| Same | A note already says this | Bump `uses`, `last_used`; add any new source |
| Extends | A note covers it partly | Add the new part to that note |
| Conflict | A note says something different | Resolve (Step 3) |

### Step 3: Resolve conflicts
1. Re-check both claims against their sources (read the file, the URL, or run a read-only command).
2. If one is clearly right: fix the note to match. Add a line under `## History`: `YYYY-MM-DD: changed X to Y. Reason: <source>`.
3. If both can be true (different versions, settings, or contexts): keep both and say when each applies.
4. If you can't tell: don't overwrite. Add an `## Open conflict` section with both claims and their sources, and flag it in your report.

### Step 4: Write
- One idea per note, with a plain name.
- File it in a topic directory: `notes/<topic>/<Note>.md`. Never write flat in the vault root or directly in `notes/`. Reuse an existing topic folder before making a new one (`ls ~/.claude/vault/notes`).
- Fill frontmatter: `uses`, `last_used` (today), `sources`.
- Link related notes Obsidian-style (`[[Note Name]]`, both directions, `tags: [<topic>]`). Follow the link rules in `~/.claude/CLAUDE.md`.
- Add new notes to `index.md` under "Notes", with a one-line summary.

### Step 5: Check for skills
If any note now has `uses >= 3` and no `skill:` value, don't create the skill. Suggest it in your report (name + what it would do). The user approves skills.

### Step 6: Report
Keep it short:
- Created: `notes/<topic>/X.md`, ...
- Updated: `notes/<topic>/Y.md` (what changed), ...
- Conflicts: resolved (how) / open (needs the user)
- Skill candidates, if any
