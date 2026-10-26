#!/usr/bin/env python3
# UserPromptSubmit hook: when the prompt says "close this conversation"
# (or session), rename the session to "<topic> [closed]".
# Topic: the latest /rename name from the transcript, else the cwd folder name.
import json, os, re, sys

CLOSE = re.compile(r"\bclose\s+(this\s+)?(conversation|session)\b", re.I)
SUFFIX = re.compile(r"(\s*\[(continued|handoff|closed)\])+\s*$")

data = json.load(sys.stdin)
if not CLOSE.search(data.get("prompt", "")):
    sys.exit(0)

topic = ""
try:
    with open(data.get("transcript_path", "")) as f:
        for line in f:
            if '"custom-title"' in line:
                topic = json.loads(line).get("customTitle", "") or topic
except (OSError, ValueError):
    pass
topic = SUFFIX.sub("", topic) or os.path.basename(data.get("cwd", "")) or "session"

title = f"{topic} [closed]"
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "sessionTitle": title,
        "additionalContext": f"Session renamed to \"{title}\" by the session-title hook.",
    }
}))
