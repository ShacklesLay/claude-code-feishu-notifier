# Claude Code Feishu Notifier

当 Claude Code 需要你审批操作或者完成任务时，自动通过飞书机器人发送通知卡片，让你不必一直盯着终端。

<p align="center">
  <img src="assets/notification-example.png" alt="飞书通知示例" width="360">
</p>

## 功能

- **审批提醒** — Claude Code 等待你授权操作时，发送橙色卡片提醒
- **完成通知** — Claude Code 任务完成等待输入时，发送蓝色卡片通知
- **智能防打扰** — 通知延迟 60 秒发送（可配置），如果你在此期间回到终端操作，通知会自动取消
- **零侵入** — 纯 Hook 实现，不修改 Claude Code 本身

## 工作原理

```
Claude Code 事件 (Notification hook)
  ↓
feishu-notify.sh 收到事件 → 写入 token → 等待 60s
  ↓                                ↑
  ↓                     feishu-cancel.sh (PreToolUse hook)
  ↓                     用户操作时清除 token，取消通知
  ↓
60s 后检查 token 是否还在 → 还在 → 发送飞书卡片
                         → 没了 → 静默退出
```

## 快速开始

### 前置条件

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 已安装
- 飞书自定义机器人 Webhook URL（[创建方法](https://open.feishu.cn/document/client-docs/bot-v3/add-custom-bot)）
- `curl` 和 `python3`（通常已预装）

### 方法一：让 Claude Code 帮你安装

这是推荐的方式。克隆本仓库后，在仓库目录下启动 Claude Code：

```bash
git clone https://github.com/shackleslay/claude-code-feishu-notifier.git
cd claude-code-feishu-notifier
claude
```

然后对 Claude 说：

> 帮我把飞书通知功能配置到我的 Claude Code 上，我的 Webhook URL 是 https://open.feishu.cn/open-apis/bot/v2/hook/xxxxx

Claude Code 会读取本仓库的 `CLAUDE.md`，自动完成所有配置步骤。

### 方法二：手动安装

**1. 复制 Hook 脚本**

```bash
cp hooks/feishu-notify.sh ~/.claude/hooks/
cp hooks/feishu-cancel.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/feishu-notify.sh ~/.claude/hooks/feishu-cancel.sh
```

**2. 设置 Webhook URL**

在 `~/.claude/settings.json` 的 `env` 字段中添加：

```json
{
  "env": {
    "FEISHU_WEBHOOK_URL": "https://open.feishu.cn/open-apis/bot/v2/hook/your-token-here"
  }
}
```

**3. 注册 Hooks**

在 `~/.claude/settings.json` 中添加 hooks 配置：

```json
{
  "hooks": {
    "PreToolUse": [
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
    ],
    "Notification": [
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
    ]
  }
}
```

**4. 验证**

启动 Claude Code，让它执行一个需要审批的操作（比如写文件），等待 60 秒看是否收到飞书通知。

## 配置项

| 环境变量 | 说明 | 默认值 |
|---------|------|--------|
| `FEISHU_WEBHOOK_URL` | 飞书自定义机器人 Webhook 地址 | （必填） |
| `FEISHU_NOTIFY_DELAY` | 通知延迟秒数，防止频繁打扰 | `60` |

环境变量可以在 `~/.claude/settings.json` 的 `env` 中配置，也可以直接 export 到 shell 环境。

## 通知效果

| 场景 | 卡片颜色 | 标题 |
|------|---------|------|
| 等待审批 | 🟠 橙色 | Claude Code 需要你的审批 |
| 任务完成 | 🔵 蓝色 | Claude Code 任务完成 |

卡片内容包含：项目名称、工作目录、会话 ID，方便你快速定位是哪个终端。

## 适配其他平台

Hook 脚本的核心逻辑（延迟发送 + token 取消机制）是通用的。如果你使用 Slack、Discord、企业微信等，只需修改 `feishu-notify.sh` 中的 `curl` 请求部分，适配对应平台的 Webhook 格式即可。

## License

MIT
