#!/bin/bash
# Feishu (Lark) webhook notification for Claude Code hooks
# Sends a card message when Claude needs approval or finishes a task.
# Includes a configurable delay — if the user acts before the delay expires,
# the notification is canceled (via feishu-cancel.sh on PreToolUse).

# ── Configuration (override via environment or edit here) ──────────────────
WEBHOOK_URL="${FEISHU_WEBHOOK_URL:-}"
DELAY_SECONDS="${FEISHU_NOTIFY_DELAY:-60}"
TOKEN_FILE="/tmp/.claude_feishu_notify_token"

if [ -z "$WEBHOOK_URL" ]; then
  echo "FEISHU_WEBHOOK_URL is not set. Skipping notification." >&2
  cat > /dev/null
  exit 0
fi

# ── Read hook payload from stdin ───────────────────────────────────────────
INPUT=$(cat)

eval "$(echo "$INPUT" | python3 -c "
import sys, json, shlex
d = json.load(sys.stdin)
print(f'TYPE={shlex.quote(d.get(\"type\", d.get(\"notification_type\",\"\")))}')
print(f'CWD={shlex.quote(d.get(\"cwd\",\"\"))}')
print(f'SID={shlex.quote(d.get(\"session_id\",\"\")[:8])}')
" 2>/dev/null)"

PROJECT=$(basename "$CWD")

# ── Build message based on event type ──────────────────────────────────────
case "$TYPE" in
  permission_prompt)
    TITLE="Claude Code 需要你的审批"
    DESC="Claude Code 正在等待你的操作许可，请回到终端查看。"
    COLOR="orange"
    ;;
  idle_prompt)
    TITLE="Claude Code 任务完成"
    DESC="Claude Code 已完成当前任务，请回到终端查看结果。"
    COLOR="blue"
    ;;
  *)
    TITLE="Claude Code 通知"
    DESC="事件类型: $TYPE"
    COLOR="blue"
    ;;
esac

# ── Delayed send with cancellation support ─────────────────────────────────
TOKEN="$(date +%s%N)_$$"
echo "$TOKEN" > "$TOKEN_FILE"

(
  sleep "$DELAY_SECONDS"

  # If token changed or disappeared, user has acted — cancel
  if [ ! -f "$TOKEN_FILE" ] || [ "$(cat "$TOKEN_FILE" 2>/dev/null)" != "$TOKEN" ]; then
    exit 0
  fi

  rm -f "$TOKEN_FILE"

  # Unset proxy for direct access to Feishu API
  unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY all_proxy no_proxy NO_PROXY

  curl -s -o /dev/null "$WEBHOOK_URL" \
    -H 'Content-Type: application/json' \
    -d "$(python3 -c "
import json, sys
title, desc, color, project, cwd, sid = sys.argv[1:7]
print(json.dumps({
    'msg_type': 'interactive',
    'card': {
        'header': {
            'title': {'tag': 'plain_text', 'content': title},
            'template': color
        },
        'elements': [
            {'tag': 'markdown', 'content': desc},
            {'tag': 'hr'},
            {'tag': 'markdown', 'content': '**项目**  ' + project + '\n**目录**  ' + cwd + '\n**会话**  ' + sid}
        ]
    }
}))
" "$TITLE" "$DESC" "$COLOR" "$PROJECT" "$CWD" "$SID")"
) &

exit 0
