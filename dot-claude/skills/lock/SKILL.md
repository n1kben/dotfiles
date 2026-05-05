---
name: lock
description: Lock the Mac.
disable-model-invocation: true
---

!pmset displaysleepnow && osascript -e 'tell application "System Events" to keystroke "q" using {control down, command down}'
