---
name: screenshot
description: Take a screenshot of the Mac and attach it to the conversation.
disable-model-invocation: true
---

Take a full-screen screenshot and show it in the conversation:

1. Run `screencapture -x /tmp/claude-screenshot.png` via Bash (`-x` = silent, no shutter sound).
2. Read `/tmp/claude-screenshot.png` with the Read tool so the image becomes visible in context.
