# Claude Code Feishu Notifier — Setup Guide

This file is for Claude Code to read and follow when setting up the Feishu notification hooks.

## What This Repo Does

Provides two shell scripts that integrate with Claude Code's Hook system to send Feishu (Lark) notifications:
- When Claude Code is waiting for user permission approval → orange card
- When Claude Code finishes a task and is idle → blue card

Notifications are delayed (default 60s) and auto-canceled if the user interacts before the delay expires.

## Setup Instructions

When the user asks you to set up this notification feature, follow these steps **in order**:

### Step 1: Get the Webhook URL

Ask the user for their Feishu custom bot Webhook URL if they haven't provided it. It looks like:
```
https://open.feishu.cn/open-apis/bot/v2/hook/<token>
```

If they don't have one, guide them to create a custom bot in their Feishu group:
- Group Settings → Bots → Add Bot → Custom Bot → copy the Webhook URL

### Step 2: Copy Hook Scripts

Copy the two scripts from this repo's `hooks/` directory to `~/.claude/hooks/`:

```bash
mkdir -p ~/.claude/hooks
cp hooks/feishu-notify.sh ~/.claude/hooks/
cp hooks/feishu-cancel.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/feishu-notify.sh ~/.claude/hooks/feishu-cancel.sh
```

### Step 3: Configure settings.json

Read the user's existing `~/.claude/settings.json` (create if it doesn't exist) and **merge** the following configuration into it. Do NOT overwrite existing settings — add to them.

**Add to `env`:**
```json
"FEISHU_WEBHOOK_URL": "<user's webhook URL>"
```

Optionally, if the user wants a custom delay (default is 60 seconds):
```json
"FEISHU_NOTIFY_DELAY": "30"
```

**Add to `hooks`:**

Add a `PreToolUse` entry (if `hooks.PreToolUse` doesn't exist, create it as an array):
```json
{
  "matcher": "",
  "hooks": [
    {
      "type": "command",
      "command": "~/.claude/hooks/feishu-cancel.sh",
      "async": true
    }
  ]
}
```

Add two `Notification` entries (if `hooks.Notification` doesn't exist, create it as an array):
```json
{
  "matcher": "permission_prompt",
  "hooks": [
    {
      "type": "command",
      "command": "~/.claude/hooks/feishu-notify.sh",
      "async": true
    }
  ]
},
{
  "matcher": "idle_prompt",
  "hooks": [
    {
      "type": "command",
      "command": "~/.claude/hooks/feishu-notify.sh",
      "async": true
    }
  ]
}
```

### Step 4: Verify

Run a quick test to make sure the webhook works:

```bash
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY all_proxy
curl -s -w "\nHTTP %{http_code}" "$FEISHU_WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d '{"msg_type":"text","content":{"text":"Claude Code 飞书通知测试 ✅ 配置成功！"}}'
```

If the response shows HTTP 200 and the user receives the test message in Feishu, setup is complete.

### Important Notes

- **Merge, don't overwrite**: The user likely has existing settings. Always read first, then merge.
- **Proxy**: The scripts unset proxy env vars before calling curl. If the user's network requires a proxy to reach Feishu, they'll need to adjust this.
- **async: true**: Both hooks MUST be async to avoid blocking Claude Code.
- **matcher: ""** on PreToolUse means it fires for ALL tool uses — this is intentional for the cancel mechanism.
- **Home directory**: Use `~/.claude/hooks/` as the script path. The `~` expansion works in Claude Code's hook commands.
