---
name: vault-consistency
description: Scan the Claude vault (~/.claude/vault) for consistency, covering broken or one-way links, stale file paths, frontmatter, index.md, placement, and notes that contradict each other or CLAUDE.md. Use when the user asks to check, audit, lint, or clean up the vault, or asks whether notes are consistent or up to date. Reports first; changes nothing until the user approves.
---

# Vault consistency scan

Find places where the vault disagrees with itself, with the filesystem, or with `~/.claude/CLAUDE.md`. Report them. Fix only what the user approves.

## Rules
- Work only in `~/.claude/vault/`. Never touch `~/Desktop/vaults/notes` (read-only; a hook blocks it).
- Read-only until the user says which fixes to apply.
- Never print secret values. Notes in `notes/` are local; don't copy them anywhere.

## Step 1: Mechanical checks
Run the script from `$HOME` (the vault hook blocks interpreters run from inside the notes vault):
```
cd ~ && python3 -I ~/.claude/skills/vault-consistency/check.py
```
It checks:
| Check | Finds |
|---|---|
| names | Two notes with the same name, so `[[Name]]` is ambiguous |
| links | `[[links]]` that don't resolve to a note or alias |
| synced->local | Synced files in `notes/references/` linking to local notes, which break on other machines |
| two-way | A links to B, but B doesn't link back |
| frontmatter | Missing `tags`/`uses`/`last_used`/`sources`, tags that don't match the topic folder, bad dates |
| placement | Notes at the vault root or loose in `notes/`; non-list files in `references/` |
| index | Notes missing from `index.md`, or listed under the wrong topic |
| paths | Local paths in notes, CLAUDE.md and skills that don't exist, or `:line` past the end of the file |
| skill-candidates | Notes at `uses: 3+` with no `skill:` |

Read each finding before reporting it. Drop false positives and say why.

## Step 2: Information checks (judgment)
The script can't see meaning. For each topic folder:
1. Read its notes together, plus any notes they link to.
2. Look for claims that disagree: versions, commands, flags, paths, numbers, defaults, "X does Y" statements.
3. Compare notes against `~/.claude/CLAUDE.md` and the skills. Flag rules a note describes differently.
4. For each disagreement, check the sources (read the file, the URL, or run a read-only command) and say which side is right. If you can't tell, mark it open.
5. Flag notes whose facts the session already knows are outdated (e.g. a path that moved).

## Step 3: Report
Keep it short, most important first:
- **Contradictions:** what disagrees, where (`file:line`), which side the source supports.
- **Broken:** links, paths, placement.
- **Drift:** one-way links, frontmatter, index.
- **False positives dropped**, with one line each.

Then ask which to fix.

## Step 4: Fix (only after approval)
- Follow the Knowledge base rules in `~/.claude/CLAUDE.md`.
- For a resolved contradiction, fix the note and add under `## History`: `YYYY-MM-DD: changed X to Y. Reason: <source>`.
- Re-run Step 1 and show the new counts.
- If the vault is in `~/dotfiles`, commit only tracked files (references, lists); notes are git-ignored.
