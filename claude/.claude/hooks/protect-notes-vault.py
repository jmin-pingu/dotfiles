#!/usr/bin/env python3
"""PreToolUse hook: block every write to the read-only notes vault.

Blocks only when a write actually targets the vault. Commands that merely
mention the vault path (grep, ls, a note that quotes the path) are allowed.
"""
import json, os, re, shlex, sys

HOME = os.path.expanduser("~")
VAULT = os.path.realpath(os.path.join(HOME, "Desktop/vaults/notes"))

# Every path argument is written (created, changed, or removed).
WRITES_ALL_ARGS = {"rm", "rmdir", "touch", "mkdir", "tee", "truncate", "chmod",
                   "chown", "chflags", "unlink", "mv", "xattr"}
# Only the last path argument is written (the destination).
WRITES_LAST_ARG = {"cp", "rsync", "install", "ln", "ditto", "scp"}
# In-place editors: file arguments are written when -i is present.
IN_PLACE = {"sed", "perl", "gsed"}
# Interpreters can write anywhere; we can't tell where. Block if they name the vault.
INTERPRETERS = {"python", "python3", "node", "ruby", "perl", "osascript", "bash",
                "sh", "zsh", "swift", "deno", "bun"}

# Git subcommands that only read. Any other git command run in the vault is blocked.
# Left out on purpose: branch, stash, tag, remote, config, reflog (can write
# depending on args) and fetch/pull (write to .git/ or the working tree).
GIT_READ_ONLY = {"status", "log", "diff", "show", "blame", "grep", "shortlog",
                 "describe", "ls-files", "ls-tree", "rev-parse", "rev-list",
                 "cat-file", "show-ref", "whatchanged", "help", "version"}

SEPARATORS = {"&&", "||", ";", "|", "&", "(", ")", "\n"}
REDIRECT = re.compile(r"^(\d*|&)(>>?|>\|)(.*)$")


def resolve(path, cwd):
    path = path.replace("$HOME", HOME).replace("${HOME}", HOME)
    path = os.path.expanduser(path)
    if not os.path.isabs(path):
        path = os.path.join(cwd, path)
    return os.path.realpath(path)


def in_vault(path, cwd):
    if not path:
        return False
    real = resolve(path, cwd)
    return real == VAULT or real.startswith(VAULT + os.sep)


def block(reason):
    print(f"Blocked: {reason}. ~/Desktop/vaults/notes is read-only.", file=sys.stderr)
    sys.exit(2)


def split_segments(cmd):
    """Split a shell command into simple commands (lists of words)."""
    lex = shlex.shlex(cmd, posix=True, punctuation_chars=";&|()")
    lex.whitespace_split = True
    lex.commenters = ""
    segs, cur = [], []
    for tok in lex:
        if tok in SEPARATORS or (tok and set(tok) <= set(";&|()")):
            if cur:
                segs.append(cur)
            cur = []
        else:
            cur.append(tok)
    if cur:
        segs.append(cur)
    return segs


def check_bash(cmd, cwd):
    try:
        segments = split_segments(cmd)
    except ValueError:
        # Can't parse (e.g. unbalanced quotes): fall back to the cautious rule.
        if "vaults/notes" in cmd or VAULT in cmd or in_vault(cwd, cwd):
            block("shell command could not be parsed safely")
        return

    for words in segments:
        # Redirects: `> file`, `>> file`, `2>file`. `2>&1` and /dev/null are fine.
        args, i = [], 0
        while i < len(words):
            m = REDIRECT.match(words[i])
            if m:
                target = m.group(3) or (words[i + 1] if i + 1 < len(words) else "")
                i += 1 if m.group(3) else 2
                if target.startswith("&") or target == "/dev/null":
                    continue
                if in_vault(target, cwd):
                    block(f"redirect writes to {target}")
                continue
            args.append(words[i])
            i += 1
        if not args:
            continue

        # Skip leading env assignments and wrappers like `sudo`, `env`, `xargs`.
        while args and (re.match(r"^\w+=", args[0]) or args[0] in {"sudo", "env", "command", "nohup", "time", "xargs"}):
            args = args[1:]
        if not args:
            continue
        prog = os.path.basename(args[0])
        paths = [a for a in args[1:] if not a.startswith("-")]

        if prog == "cd":
            cwd = resolve(paths[0], cwd) if paths else HOME
        elif prog in WRITES_ALL_ARGS:
            for p in paths:
                if in_vault(p, cwd):
                    block(f"{prog} writes to {p}")
        elif prog in WRITES_LAST_ARG:
            if paths and in_vault(paths[-1], cwd):
                block(f"{prog} writes to {paths[-1]}")
        elif prog in IN_PLACE and any(a.startswith("-i") or a == "-pi" for a in args[1:]):
            for p in paths:
                if in_vault(p, cwd):
                    block(f"{prog} -i edits {p}")
        elif prog == "find" and any(a in ("-delete", "-exec", "-execdir", "-ok") for a in args):
            if any(in_vault(p, cwd) for p in paths) or in_vault(cwd, cwd):
                block("find -delete/-exec in the vault")
        elif prog == "git":
            sub, gdir, rest = None, cwd, args[1:]
            while rest:
                if rest[0] == "-C" and len(rest) > 1:
                    gdir, rest = resolve(rest[1], gdir), rest[2:]
                elif rest[0].startswith("-"):
                    rest = rest[1:]
                else:
                    sub = rest[0]
                    break
            if in_vault(gdir, gdir) and sub not in GIT_READ_ONLY:
                block(f"git {sub} in the vault")
        elif prog in INTERPRETERS or re.match(r"^python3?(\.\d+)?$", prog):
            joined = " ".join(args)
            if "vaults/notes" in joined or VAULT in joined or in_vault(cwd, cwd):
                block(f"{prog} may write to the vault")


data = json.load(sys.stdin)
tool = data.get("tool_name", "")
inp = data.get("tool_input", {}) or {}
cwd = data.get("cwd") or os.getcwd()

if tool in ("Edit", "Write", "MultiEdit", "NotebookEdit"):
    target = inp.get("file_path") or inp.get("notebook_path")
    if in_vault(target, cwd):
        block(f"{tool} on {target}")
elif tool == "Bash":
    check_bash(inp.get("command", ""), cwd)

sys.exit(0)
