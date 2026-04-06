#!/bin/bash
# Cancel any pending Feishu notification.
# Hooked to PreToolUse — when the user approves/triggers any tool,
# we know they're active, so we cancel the pending "come back" notification.
cat > /dev/null
rm -f /tmp/.claude_feishu_notify_token
exit 0
