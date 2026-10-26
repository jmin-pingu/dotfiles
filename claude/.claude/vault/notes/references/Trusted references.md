---
tags: [references]
aliases: [Credible references, Trusted sources, Reading list]
uses: 2
last_used: 2026-10-08
sources:
  - ~/.claude/CLAUDE.md (References section)
skill:
---

# Trusted references

Sources held to a higher bar. Claude checks this list before citing anything.
Rules for using it are in `~/.claude/CLAUDE.md` (References section).

## The bar

A source is trusted when it is:
1. **Primary or authoritative:** the people who built it, the original paper, the spec, or a standard textbook.
2. **Checkable:** shows its evidence (code, data, proofs, citations).
3. **Kept current:** versioned or dated, and fixed when wrong.
4. **Proven in use:** has held up when checked against real behavior in our sessions.

## Trusted

Only the user promotes a source here. Use the same topic headings as Candidates.

_None yet._

## By topic

From the user's bookmarks (blogs, reading lists, articles). These count as Trusted.

- [[Trusted - systems]] (69)
- [[Trusted - languages-compilers]] (41)
- [[Trusted - databases-distributed]] (16)
- [[Trusted - security]] (33)
- [[Trusted - ml]] (7)
- [[Trusted - math]] (9)
- [[Trusted - stats]] (24)
- [[Trusted - graphics-viz]] (7)
- [[Trusted - software-design]] (6)
- [[Trusted - tools-web]] (23)
- [[Trusted - learning]] (12)

## Candidates

Claude adds sources here after they hold up in a session. The user reviews them.
Grouped by topic. Put a new source under its topic heading; add a heading if none fits.

### Developer tools

| Source | Kind | Why it's a candidate | Link |
|---|---|---|---|
| Claude Code docs | Primary (official docs) | Used to set up hooks, permissions and skills. Matched real behavior. Gap: didn't mention that `Write(path)` rules are ignored. | https://code.claude.com/docs |
| coder/claudecode.nvim README | Third-party (plugin's own docs, beta) | Used to set up Claude + Neovim. Provider `none`, lock files, and `/ide` connection matched real behavior. Pin to a commit. | https://github.com/coder/claudecode.nvim |

### Hardware

| Source | Kind | Why it's a candidate | Link |
|---|---|---|---|
| NVIDIA Developer Blog | Vendor (primary for NVIDIA hardware) | Source for 2:4 structured sparsity. Accurate for NVIDIA, but promotes NVIDIA products. | https://developer.nvidia.com/blog |

### Machine learning

| Source | Kind | Why it's a candidate | Link |
|---|---|---|---|
| PyTorch source (pytorch/pytorch) | Primary (source code) | User asked for references to real repos. Pin links to a commit SHA so line numbers don't drift. Modules in `torch/nn/modules/`, backward formulas in `tools/autograd/derivatives.yaml`. | https://github.com/pytorch/pytorch |
| hendrycks/GELUs | Primary (paper authors' code) | Official code for the GELU paper (arXiv:1606.08415). | https://github.com/hendrycks/GELUs |

## Rejected

Sources that failed the bar, and why. Don't cite these.

| Source | Why rejected |
|---|---|
| _none yet_ | |

## Trusted notes

`trusted/notes/` holds links to my own notes that I trust, the way the lists above hold trusted outside sources.
- Add a note by symlinking it from its topic folder, or with a short file of `[[links]]`. Don't move the note itself.
- The folder syncs through git, but what's in it doesn't. Each machine's vault fills it with its own notes.

## Related

- [[Role models]]
