#!/usr/bin/env python3
# Status line: show context use, and save it per session so the
# handoff-nudge hook can read it (hooks don't get context usage).
import json, os, sys

data = json.load(sys.stdin)
sid = data.get("session_id", "unknown")
pct = (data.get("context_window") or {}).get("used_percentage") or 0
model = (data.get("model") or {}).get("display_name", "")

d = os.path.expanduser("~/.cache/claude-ctx")
os.makedirs(d, exist_ok=True)
with open(os.path.join(d, sid), "w") as f:
    f.write(str(pct))

warn = " - run /handoff" if pct >= 80 else ""
print(f"[{model}] {pct:.0f}% context{warn}")
