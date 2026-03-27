#!/bin/bash
# Hook: Notification — macOS notification when Claude needs attention
osascript -e 'display notification "Claude Code is ready for input" with title "Claude Code" sound name "Glass"'
exit 0
