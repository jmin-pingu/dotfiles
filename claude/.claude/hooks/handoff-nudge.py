#!/usr/bin/env python3
# UserPromptSubmit hook: once context passes 80%, tell Claude (once per
# session) to run the handoff skill. Reads the % saved by context-status.py.
import json, os, sys

THRESHOLD = 80

data = json.load(sys.stdin)
sid = data.get("session_id", "unknown")
d = os.path.expanduser("~/.cache/claude-ctx")

try:
    pct = float(open(os.path.join(d, sid)).read())
except (OSError, ValueError):
    sys.exit(0)

marker = os.path.join(d, sid + ".nudged")
if pct < THRESHOLD or os.path.exists(marker):
    sys.exit(0)
open(marker, "w").close()

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": (
            f"Context window is at {pct:.0f}% (handoff threshold {THRESHOLD}%). "
            "The user's standing preference: answer this prompt, then run the "
            "handoff skill to move the work to a fresh session."
        ),
    }
}))
