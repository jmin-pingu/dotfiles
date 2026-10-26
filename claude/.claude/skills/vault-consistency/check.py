#!/usr/bin/env python3
"""Mechanical consistency checks for the Claude vault. Read-only.

Usage: python3 -I check.py [VAULT] [--claude-md PATH] [--skills DIR]
Prints findings grouped by check, with file:line. Exit code 1 if any found.
"""
import argparse
import datetime
import os
import pathlib
import re
import sys

HOME = pathlib.Path.home()
WIKILINK = re.compile(r"\[\[([^\]|#]+)")
CODE_SPAN = re.compile(r"`[^`]*`")
FRONTMATTER = re.compile(r"\A---\n(.*?)\n---\n", re.S)
# Local paths in backticks or in frontmatter sources: ~/..., $HOME/..., /abs/...
INLINE_PATH = re.compile(r"`((?:~|\$HOME)/[^`\s]+|/(?:Users|etc|nix|run|opt|usr)/[^`\s]+)`")
SOURCE_PATH = re.compile(r"^\s*-\s+((?:~|\$HOME)/\S+|/(?:Users|etc|nix|run|opt|usr)/\S+)")
TODAY = datetime.date.today()

findings = {}


def add(check, where, msg):
    findings.setdefault(check, []).append(f"{where}: {msg}")


def expand(p):
    p = p.rstrip(".,;)")
    p = p.replace("$HOME", str(HOME))
    return pathlib.Path(os.path.expanduser(p))


def check_path(raw, where):
    """Flag a local path that doesn't exist, or a :line past the end of the file."""
    if any(c in raw for c in "*<>{}"):  # globs and placeholders
        return
    # path, path:N, path:N-M, path:N,M,...
    m = re.match(r"(.+?):(\d+(?:[-,]\d+)*)$", raw)
    path, line = (m.group(1), max(map(int, re.split(r"[-,]", m.group(2))))) if m else (raw, None)
    p = expand(path)
    if not p.exists():
        add("paths", where, f"missing path {raw}")
    elif line and p.is_file():
        n = sum(1 for _ in p.open(errors="ignore"))
        if line > n:
            add("paths", where, f"{raw}: file has only {n} lines")


def parse_frontmatter(text):
    m = FRONTMATTER.match(text)
    if not m:
        return None, 0
    fm, key = {}, None
    for line in m.group(1).splitlines():
        km = re.match(r"^([a-z_]+):\s*(.*)$", line)
        if km:
            key = km.group(1)
            fm[key] = km.group(2).strip()
        elif key == "sources" and line.strip().startswith("-"):
            fm.setdefault("_sources", []).append(line)
    return fm, m.group(0).count("\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("vault", nargs="?", default=str(HOME / ".claude/vault"))
    ap.add_argument("--claude-md", default=str(HOME / ".claude/CLAUDE.md"))
    ap.add_argument("--skills", default=str(HOME / ".claude/skills"))
    args = ap.parse_args()
    V = pathlib.Path(args.vault).resolve()

    files = sorted(p for p in V.rglob("*.md") if not p.is_symlink())
    rel = lambda p: str(p.relative_to(V))
    texts = {p: p.read_text(errors="ignore") for p in files}

    # Names and aliases
    by_name = {}
    for p in files:
        by_name.setdefault(p.stem, []).append(p)
    aliases = {}
    for p, t in texts.items():
        fm, _ = parse_frontmatter(t)
        if fm and fm.get("aliases", "").startswith("["):
            for a in fm["aliases"].strip("[]").split(","):
                if a.strip():
                    aliases.setdefault(a.strip(), p)
    for name, ps in by_name.items():
        if len(ps) > 1:
            add("names", name, "duplicate note name: " + ", ".join(rel(p) for p in ps))

    def resolve(target):
        if target in by_name:
            return by_name[target][0]
        return aliases.get(target)

    def is_synced(p):
        r = rel(p)
        return r.startswith("notes/references/") and not r.startswith("notes/references/trusted/notes/")

    def topic_of(p):
        parts = p.relative_to(V).parts
        if parts[0] in ("notes", "dead-ends") and len(parts) > 2:
            return parts[1]
        return None

    # Links: resolve, synced -> local, two-way
    links = {}
    for p, t in texts.items():
        if p.name == "_template.md":
            continue
        for i, line in enumerate(t.splitlines(), 1):
            for target in WIKILINK.findall(CODE_SPAN.sub("", line)):
                target = target.strip()
                q = resolve(target)
                if q is None:
                    add("links", f"{rel(p)}:{i}", f"[[{target}]] doesn't resolve")
                    continue
                links.setdefault(p, set()).add(q)
                if is_synced(p) and not is_synced(q):
                    add("synced->local", f"{rel(p)}:{i}", f"[[{target}]] points to a local note that won't sync")
    for a, targets in links.items():
        if a.name == "index.md":
            continue
        for b in targets:
            if b.name == "index.md" or b == a:
                continue
            if is_synced(b) and not is_synced(a):
                continue  # synced files must not link back to local notes
            if a not in links.get(b, set()):
                add("two-way", rel(b), f"missing back-link to [[{a.stem}]] (it links here)")

    # Frontmatter
    notes = [p for p in files if rel(p).startswith(("notes/", "dead-ends/"))
             and not rel(p).startswith("notes/references/trusted/notes/")]
    for p in notes:
        fm, _ = parse_frontmatter(texts[p])
        if fm is None:
            add("frontmatter", rel(p), "no frontmatter")
            continue
        for key in ("tags", "uses", "last_used", "sources"):
            if key not in fm:
                add("frontmatter", rel(p), f"missing {key}")
        topic = topic_of(p)
        if topic and "tags" in fm and fm["tags"] != f"[{topic}]":
            add("frontmatter", rel(p), f"tags {fm['tags']} don't match folder [{topic}]")
        if "uses" in fm and not re.fullmatch(r"[1-9]\d*", fm["uses"]):
            add("frontmatter", rel(p), f"uses '{fm['uses']}' isn't a positive number")
        if "last_used" in fm:
            try:
                d = datetime.date.fromisoformat(fm["last_used"])
                if d > TODAY:
                    add("frontmatter", rel(p), f"last_used {d} is in the future")
            except ValueError:
                add("frontmatter", rel(p), f"last_used '{fm['last_used']}' isn't YYYY-MM-DD")
        if "sources" in fm and not fm.get("_sources") and fm["sources"] in ("", "[]"):
            add("frontmatter", rel(p), "sources is empty")
        if fm.get("uses", "").isdigit() and int(fm["uses"]) >= 3 and not fm.get("skill"):
            add("skill-candidates", rel(p), f"uses: {fm['uses']} and no skill: (propose one)")

    # Placement
    for p in files:
        r = rel(p)
        parts = p.relative_to(V).parts
        if len(parts) == 1 and p.name not in ("index.md", "_template.md"):
            add("placement", r, "only index.md and _template.md belong at the vault root")
        if parts[0] in ("notes", "dead-ends") and len(parts) == 2:
            add("placement", r, f"note sits directly in {parts[0]}/, not in a topic folder")
    for p in (V / "notes/references").rglob("*") if (V / "notes/references").exists() else []:
        r = rel(p)
        if p.is_dir() or p.name == ".gitkeep" or r.startswith("notes/references/trusted/notes/"):
            continue
        if not (p.name in ("Role models.md", "Trusted references.md") or
                (p.parent.name == "trusted" and p.name.startswith("Trusted - "))):
            add("placement", r, "references/ should hold only the trusted lists and Role models.md")

    # Index
    index = V / "index.md"
    if index.exists():
        itext = texts.get(index, index.read_text())
        listed, heading = {}, None
        for i, line in enumerate(itext.splitlines(), 1):
            h = re.match(r"^###\s+(.+?)\s*$", line)
            if h:
                heading = h.group(1)
            for target in WIKILINK.findall(line):
                listed.setdefault(target.strip(), (i, heading))
        for p in notes:
            if p.stem not in listed and not any(a for a, q in aliases.items() if q == p and a in listed):
                add("index", rel(p), "not listed in index.md")
            elif p.stem in listed:
                i, h = listed[p.stem]
                topic = topic_of(p)
                if topic and h and h != topic and not rel(p).startswith("notes/references/"):
                    add("index", f"index.md:{i}", f"[[{p.stem}]] is under '### {h}' but lives in {topic}/")

    # Local paths in notes, CLAUDE.md and skills
    others = [pathlib.Path(args.claude_md)] + sorted(pathlib.Path(args.skills).glob("*/SKILL.md"))
    for p in files + [o for o in others if o.exists() and "synced" not in o.parts]:
        where_base = rel(p) if V in p.resolve().parents else str(p).replace(str(HOME), "~")
        in_sources = False
        for i, line in enumerate(p.read_text(errors="ignore").splitlines(), 1):
            if line.startswith("sources:"):
                in_sources = True
                continue
            if in_sources and not line.startswith((" ", "-")):
                in_sources = False
            raws = INLINE_PATH.findall(line)
            if in_sources:
                m = SOURCE_PATH.match(line)
                if m:
                    raws.append(m.group(1))
            for raw in raws:
                check_path(raw, f"{where_base}:{i}")

    # Report
    total = sum(len(v) for v in findings.values())
    print(f"Scanned {len(files)} files in {V}")
    for check in ("names", "links", "synced->local", "two-way", "frontmatter",
                  "placement", "index", "paths", "skill-candidates"):
        items = findings.get(check, [])
        print(f"\n## {check}: {len(items)}")
        for item in items:
            print(f"- {item}")
    print(f"\nTotal findings: {total}")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
