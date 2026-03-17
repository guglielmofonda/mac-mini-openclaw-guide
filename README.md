# Mac Mini + OpenClaw + Claude Code: Complete Setup Guide

A step-by-step guide to setting up a headless AI agent on a Mac Mini, based on a production setup that's been running since January 2026. Your agent will be reachable via Slack, Telegram, WhatsApp, and more, with scheduled automations, browser control, and MCP integrations.

**Last updated:** March 17, 2026 — OpenClaw 2026.3.13. New sections: Model Management, Memory Search, Dashboard v2, Agent Control Protocol, Sandbox Containers, Backup & Recovery, Work Pulse pattern. See also: [team-agents](https://github.com/solo-founders/team-agents) for multi-agent team coordination.

```
+---------------------------------------------------------------+
|                         Mac Mini                              |
|                                                               |
|   +--------------+   +--------------+   +--------------+     |
|   |   OpenClaw   |   |  Claude Code |   |   Browser    |     |
|   |   Gateway    |<->|   (Agent)    |<->|  (Headless)  |     |
|   |   :18789     |   |              |   |              |     |
|   +------+-------+   +------+-------+   +--------------+     |
|          |                  |                                 |
|     +----+----+        +----+----+                            |
|     |Channels |        |   MCP   |                            |
|     +---------+        | Servers |                            |
|     | Slack   |        +---------+                            |
|     |Telegram |        | Gmail   |                            |
|     |WhatsApp |        |Calendar |                            |
|     | Discord |        | Slack   |                            |
|     | Signal  |        +---------+                            |
|     |   ...   |                                               |
|     +---------+   +--------------+                            |
|                   |  Cron Jobs   |                            |
|                   |  Watchdogs   |                            |
|                   +--------------+                            |
+---------------------------------------------------------------+
```

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Install OpenClaw](#2-install-openclaw)
3. [Install Claude Code](#3-install-claude-code)
4. [Workspace Setup](#4-workspace-setup)
5. [Channels Overview](#5-channels-overview) — how to talk to your agent
6. [Create Your Slack App](#6-create-your-slack-app) — start here if short on time
7. [Telegram Bot Setup](#7-telegram-bot-setup)
8. [WhatsApp Setup](#8-whatsapp-setup-optional)
9. [MCP Servers](#9-mcp-servers)
10. [Gateway Configuration](#10-gateway-configuration)
11. [Cron Jobs & Automation](#11-cron-jobs--automation)
12. [Skills Installation](#12-skills-installation)
13. [Notification Hooks](#13-notification-hooks-mac-mini-edition)
14. [Browser Automation](#14-browser-automation)
15. [Model Management & Fast Mode](#15-model-management--fast-mode) ✨ new
16. [Memory Search](#16-memory-search) ✨ new
17. [Dashboard & Control UI](#17-dashboard--control-ui)
18. [Agent Control Protocol](#18-agent-control-protocol) ✨ new
19. [Sandbox Containers](#19-sandbox-containers) ✨ new
20. [Backup & Recovery](#20-backup--recovery) ✨ new
21. [Work Pulse — Autonomous Work Cycles](#21-work-pulse--autonomous-work-cycles) ✨ new
22. [Security Checklist](#22-security-checklist)
23. [Known Issues & Workarounds](#23-known-issues--workarounds)
24. [Quick Reference](#24-quick-reference)

---

## 1. Prerequisites

### Hardware
- **Mac Mini** with Apple Silicon (M1/M2/M3/M4)
- macOS 15 Sequoia or later
- Stable internet connection (the agent runs 24/7)

### Software

Install Homebrew first, then everything else:

```bash
# Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Node.js (required by OpenClaw)
brew install node

# GitHub CLI
brew install gh
gh auth login

# Python 3 (ships with macOS, but verify)
python3 --version
```

### Accounts & Keys You'll Need
- **Anthropic account** — Claude Pro/Max subscription or Console API key
- **GitHub account** — for workspace repo and `gh` CLI
- **Slack workspace** — admin access to create a Slack app
- (Optional) **Telegram account** — to create a bot via @BotFather
- (Optional) **WhatsApp** — personal number for self-chat mode

---

## 2. Install OpenClaw

```bash
# Install globally
npm install -g openclaw

# Verify
openclaw --version

# Initial setup — creates ~/.openclaw/ directory
openclaw setup

# Interactive onboarding — walks you through:
# - Anthropic API key
# - Workspace directory
# - Channel configuration
openclaw onboard

# Fine-tune agent defaults
openclaw configure
```

After setup, your `~/.openclaw/` directory will look like:

```
~/.openclaw/
├── openclaw.json          # Main configuration (everything lives here)
├── agents/                # Agent state & sessions
├── browser/               # Headless browser profiles
├── credentials/           # Channel credentials (Telegram, WhatsApp)
├── cron/                  # Scheduled jobs
├── devices/               # Paired devices
├── hooks/                 # Custom hooks
├── hook-packs/            # Hook packages
├── identity/              # Device keypair (Ed25519)
├── logs/                  # Gateway & watchdog logs
├── scripts/               # Custom scripts (watchdogs, etc.)
└── skills/                # Bundled skills
```

### Set Agent Defaults

In `openclaw.json`, configure:

```json
{
  "agents": {
    "defaults": {
      "workspace": "/Users/YOUR_USERNAME/clawd",
      "contextPruning": {
        "mode": "cache-ttl",
        "ttl": "1h"
      },
      "compaction": {
        "mode": "safeguard"
      },
      "heartbeat": {
        "every": "10m"
      },
      "maxConcurrent": 4,
      "subagents": {
        "maxConcurrent": 8
      }
    }
  }
}
```

---

## 3. Install Claude Code

```bash
# Install Claude Code (native method)
# Follow: https://docs.anthropic.com/en/docs/claude-code/getting-started

# Verify
claude --version

# First run in your workspace — accept trust prompt
cd ~/clawd
claude
```

### Configure Settings

Edit `~/.claude/settings.json`:

```json
{
  "effortLevel": "high"
}
```

See [`examples/settings.json.example`](examples/settings.json.example) for a full example with notification hooks.

---

## 4. Workspace Setup

Your workspace is the shared directory between OpenClaw and Claude Code. Think of it as your agent's brain.

```bash
# Create and initialize
mkdir -p ~/clawd
cd ~/clawd
git init

# Create the key files
touch AGENTS.md IDENTITY.md TOOLS.md USER.md MEMORY.md
```

### Key Files

| File | Purpose |
|------|---------|
| `AGENTS.md` | Multi-agent coordination rules, Slack behavior, memory management |
| `IDENTITY.md` | Agent persona — name, personality, communication style |
| `USER.md` | Your context — who you are, timezone, preferences, working style |
| `TOOLS.md` | Local tool setup notes — SSH hosts, API quirks, device names |
| `MEMORY.md` | Long-term memory — credentials, baselines, recurring context |
| `HEARTBEAT.md` | Periodic check instructions (email, calendar, mentions) |

### Permissions

Create `.claude/settings.local.json` to allowlist tools and domains your agent can use:

```json
{
  "permissions": {
    "allow": [
      "WebSearch",
      "Bash(openclaw:*)",
      "Bash(git:*)",
      "Bash(gh:*)",
      "Bash(npm:*)",
      "Bash(python3:*)",
      "Bash(curl:*)",
      "Bash(docker:*)",
      "Bash(brew:*)",
      "Bash(claude mcp:*)",
      "WebFetch(domain:docs.openclaw.ai)",
      "WebFetch(domain:github.com)",
      "WebFetch(domain:docs.anthropic.com)"
    ]
  }
}
```

See [`examples/settings.local.json.example`](examples/settings.local.json.example) for a more comprehensive permissions list.

### Skills Directory

```bash
mkdir -p ~/clawd/skills
```

Skills are loaded from this directory automatically if you set `skills.load.extraDirs` in `openclaw.json`:

```json
{
  "skills": {
    "load": {
      "extraDirs": ["/Users/YOUR_USERNAME/clawd/skills"]
    },
    "install": {
      "nodeManager": "npm"
    }
  }
}
```

---

## 5. Channels Overview

OpenClaw supports many ways to talk to your agent. Here's a comparison to help you decide which to set up.

### Recommended Channels

| Channel | Setup Time | Best For | Pros | Cons | Docs |
|---------|-----------|----------|------|------|------|
| **[Slack](#6-create-your-slack-app)** | 20 min | Team collaboration | Socket mode (no public IP), reactions, threads, mention gating, most reliable | Requires Slack admin to create app | [docs](https://docs.openclaw.ai/channels/slack) |
| **[Telegram](#7-telegram-bot-setup)** | 10 min | Personal/mobile alerts | Fastest to set up, great for cron job delivery, voice notes, inline buttons | Less common in work teams | [docs](https://docs.openclaw.ai/channels/telegram) |
| **[WhatsApp](#8-whatsapp-setup-optional)** | 30 min | Self-chat, personal use | Familiar, media support (50MB), reply threading | Connection drops, QR pairing required | [docs](https://docs.openclaw.ai/channels/whatsapp) |

### Other Supported Channels

| Channel | Best For | Setup | Key Detail | Docs |
|---------|----------|-------|------------|------|
| **Discord** | Community, gaming | Medium | Voice channels, threads, slash commands, PluralKit support | [docs](https://docs.openclaw.ai/channels/discord) |
| **Signal** | Privacy-first | Medium | End-to-end encrypted, DM + group support, 8MB media cap | [docs](https://docs.openclaw.ai/channels/signal) |
| **iMessage (BlueBubbles)** | Apple ecosystem | Hard | macOS-only, requires BlueBubbles server, edit/unsend, tapbacks | [docs](https://docs.openclaw.ai/channels/bluebubbles) |
| **Microsoft Teams** | Enterprise | Hard | Azure AD setup, RSC permissions, Adaptive Cards | [docs](https://docs.openclaw.ai/channels/msteams) |
| **Mattermost** | Self-hosted teams | Hard | Requires Mattermost instance, bot token + WebSocket | [docs](https://docs.openclaw.ai/channels/mattermost) |
| **Matrix** | Federated/self-hosted | Medium | Open protocol, decentralized, self-hosted option | [docs](https://docs.openclaw.ai/channels/matrix) |
| **Google Chat** | Google Workspace | Easy | HTTP webhook, native Google integration | [docs](https://docs.openclaw.ai/channels/google-chat) |
| **IRC** | Legacy systems | Hard | Classic protocol, persistent channels | [docs](https://docs.openclaw.ai/channels/irc) |
| **Nostr** | Decentralized | Hard | Censorship-resistant, experimental | [docs](https://docs.openclaw.ai/channels/nostr) |
| **WebChat** | Quick access | Easy | Built-in gateway UI, no app needed — run `openclaw dashboard` | — |

### How to Choose

- **Starting out?** Set up **Slack** first — it's the most reliable and your team is already there.
- **Want mobile notifications?** Add **Telegram** — 10-minute setup, great for cron job delivery (morning briefings, reminders).
- **Privacy-focused?** Use **Signal** — end-to-end encrypted, no data stored externally.
- **Apple-only team?** **iMessage via BlueBubbles** keeps everything in the Apple ecosystem but requires a dedicated macOS machine (which you already have).
- **Enterprise?** **Teams** or **Mattermost** for compliance and IT control.

You can run multiple channels simultaneously — messages from any channel reach the same agent.

---

## 6. Create Your Slack App

This is the most important integration. Once Slack is working, you can message your agent from your phone, laptop, or any device with Slack.

### Step 1: Create the App

1. Go to [api.slack.com/apps](https://api.slack.com/apps)
2. Click **Create New App** → **From scratch**
3. Name it (e.g., "Ercole" or "My Agent")
4. Select your workspace

### Step 2: Enable Socket Mode

Socket mode is critical — it uses persistent WebSocket connections instead of webhooks, which is more reliable for a Mac Mini that may not have a public IP.

1. Go to **Settings → Socket Mode**
2. Toggle **Enable Socket Mode** → ON
3. Create an **App-Level Token** with `connections:write` scope
4. Save the token — it starts with `xapp-`

### Step 3: Add Bot Token Scopes

Go to **OAuth & Permissions → Scopes → Bot Token Scopes** and add:

| Scope | Why |
|-------|-----|
| `chat:write` | Send messages |
| `channels:read` | List channels |
| `channels:history` | Read channel messages |
| `groups:read` | List private channels |
| `groups:history` | Read private channel messages |
| `im:read` | List DMs |
| `im:history` | Read DMs |
| `im:write` | Open DMs |
| `reactions:write` | Add acknowledgment reaction |
| `reactions:read` | Read reactions |
| `users:read` | Look up user info |
| `app_mentions:read` | Detect @mentions |

### Step 4: Enable Events

Go to **Event Subscriptions** → Enable Events → Subscribe to bot events:

- `message.channels`
- `message.groups`
- `message.im`
- `app_mention`

### Step 5: Install to Workspace

1. Go to **Install App** → **Install to Workspace**
2. Authorize the permissions
3. Copy the **Bot User OAuth Token** — starts with `xoxb-`

### Step 6: Get Your Slack User ID

In Slack, click your profile → **...** → **Copy member ID** (e.g., `U0XXXXXXXXX`).

### Step 7: Configure OpenClaw

Add to `openclaw.json`:

```json
{
  "channels": {
    "slack": {
      "mode": "socket",
      "webhookPath": "/slack/events",
      "botToken": "xoxb-YOUR-BOT-TOKEN",
      "appToken": "xapp-YOUR-APP-TOKEN",
      "userTokenReadOnly": true,
      "groupPolicy": "open",
      "actions": {
        "reactions": true
      },
      "dm": {
        "policy": "allowlist",
        "allowFrom": ["YOUR_SLACK_USER_ID"]
      },
      "channels": {
        "#your-agent-channel": {
          "allow": true,
          "requireMention": false
        }
      }
    }
  },
  "plugins": {
    "entries": {
      "slack": {
        "enabled": true
      }
    }
  }
}
```

### Step 8: Set Up Guard Rails

Your agent should be helpful to teammates while keeping you informed. Here's the approach that works well in practice:

**In your workspace's `AGENTS.md`, define these rules:**

1. **Respond to anyone** who tags the agent in Slack — be helpful, answer their question
2. **Notify the owner via DM** after every interaction with someone else:
   - If tagged in a channel: send the link to the message
   - If tagged in a DM: send the content of their message
3. **Never load MEMORY.md in shared contexts** — it contains personal data that shouldn't leak to others
4. **DM policy stays as allowlist** — only you can DM the agent directly

This gives teammates access to the agent's capabilities while keeping the owner in the loop on all interactions. The agent is helpful but doesn't volunteer private information.

### Step 9: Test It

```bash
# Restart gateway to pick up changes
openclaw gateway restart

# Check status
openclaw status
```

Then send a message in your configured Slack channel. You should see:
1. 👀 reaction appears (acknowledgment)
2. Agent responds
3. 👀 reaction is removed

### What Worked / What Didn't

**Worked well:**
- Socket mode is rock-solid for persistent connections
- The 👀 ack reaction is great UX — you know the agent saw your message
- `requireMention: false` in dedicated channels means no need to @mention
- Responding to everyone + DM notification to owner = best balance of helpful and informed

**Watch out for:**
- If the gateway restarts, socket mode reconnects automatically (usually within seconds)
- Keep `groupPolicy: "open"` if you want the agent to work in any channel it's invited to, or switch to `"allowlist"` for tighter control

---

## 7. Telegram Bot Setup

Good for personal/mobile notifications. The morning briefing and scheduled summaries get delivered here.

### Step 1: Create a Bot

1. Message [@BotFather](https://t.me/BotFather) on Telegram
2. Send `/newbot`
3. Follow the prompts — pick a name and username
4. Copy the **bot token** (looks like `1234567890:AABBccDDeeFFggHHiiJJkkLLmmNNoo`)

### Step 2: Get Your User ID

Message [@userinfobot](https://t.me/userinfobot) — it replies with your numeric user ID.

### Step 3: Configure OpenClaw

```json
{
  "channels": {
    "telegram": {
      "dmPolicy": "allowlist",
      "botToken": "YOUR_BOT_TOKEN",
      "allowFrom": [
        "your_telegram_username",
        "your_numeric_user_id"
      ],
      "groupPolicy": "allowlist",
      "streamMode": "partial"
    }
  },
  "plugins": {
    "entries": {
      "telegram": {
        "enabled": true
      }
    }
  }
}
```

### Step 4: Test

```bash
openclaw gateway restart
```

Send a message to your bot on Telegram.

For the full setup guide, see: [docs.openclaw.ai/channels/telegram](https://docs.openclaw.ai/channels/telegram)

---

## 8. WhatsApp Setup (Optional)

WhatsApp uses a web-based client session. It works but has known stability issues.

```json
{
  "channels": {
    "whatsapp": {
      "dmPolicy": "allowlist",
      "selfChatMode": true,
      "allowFrom": ["+1YOUR_PHONE_NUMBER"],
      "groupPolicy": "allowlist",
      "mediaMaxMb": 50,
      "ackReaction": {
        "emoji": "👀",
        "direct": true,
        "group": "always"
      },
      "debounceMs": 0
    }
  },
  "plugins": {
    "entries": {
      "whatsapp": {
        "enabled": true
      }
    }
  }
}
```

Then pair via QR code:

```bash
openclaw channels login --verbose
```

**Known issues:** Connection drops (408, 503 errors) are common. The gateway auto-reconnects, but WhatsApp is the least reliable of the three channels. Good for self-chat, not recommended as your primary channel.

For the full setup guide, see: [docs.openclaw.ai/channels/whatsapp](https://docs.openclaw.ai/channels/whatsapp)

---

## 9. MCP Servers

MCP (Model Context Protocol) servers give Claude Code access to external services as tools.

### Built-in Claude.ai Integrations

These are connected through your Claude account (no manual setup):
- **Gmail** — read/search/draft emails
- **Google Calendar** — list/create/update events, find free time
- **Slack** — search/read/send messages (separate from the OpenClaw Slack plugin)

### Optional: Add PostHog (Analytics)

```bash
claude mcp add -s user --transport http posthog \
  https://mcp.posthog.com/mcp \
  --header "Authorization: Bearer YOUR_POSTHOG_API_KEY"
```

Get your key from PostHog → Settings → Personal API Keys → select "MCP Server preset".

### List Configured MCP Servers

```bash
claude mcp list
```

### Verify Connection

Inside Claude Code, run `/mcp` to check server status.

---

## 10. Gateway Configuration

The gateway is the core process that connects everything — channels, agent, cron, browser.

### openclaw.json Gateway Section

```json
{
  "gateway": {
    "port": 18789,
    "mode": "local",
    "bind": "loopback",
    "auth": {
      "mode": "token",
      "token": "GENERATE_A_RANDOM_TOKEN"
    },
    "tailscale": {
      "mode": "off"
    }
  }
}
```

Generate a token:

```bash
openssl rand -hex 24
```

### Start the Gateway

```bash
# Foreground (for testing)
openclaw gateway

# Force restart (kills existing process first)
openclaw gateway --force

# Check health
openclaw health

# View logs
openclaw logs
```

### Gateway as a Background Service

For 24/7 operation, set up a launchd plist so the gateway starts on boot. Example plist at `~/Library/LaunchAgents/com.openclaw.gateway.plist`.

### Remote Access via Tailscale (Optional)

If you want to reach the gateway from outside your network:

```json
{
  "gateway": {
    "tailscale": {
      "mode": "on"
    }
  }
}
```

Requires Tailscale installed and configured on the Mac Mini.

---

## 11. Cron Jobs & Automation

OpenClaw has a built-in cron scheduler for recurring tasks.

### Example: Morning Briefing

```bash
openclaw cron
```

Or configure directly in `~/.openclaw/cron/jobs.json`. Here's what a daily morning briefing looks like:

```json
{
  "id": "morning-briefing",
  "label": "Morning Briefing",
  "schedule": "30 6 * * *",
  "enabled": true,
  "prompt": "Prepare my morning briefing: check calendar, triage email, weather forecast.",
  "deliver": {
    "channel": "telegram",
    "target": "YOUR_TELEGRAM_USER_ID"
  }
}
```

### Real-World Cron Job Examples

| Job | Schedule | Description |
|-----|----------|-------------|
| Morning briefing | `30 6 * * *` | Calendar check, email triage, daily quote → Telegram |
| RSS monitors | `45 11 * * *` | Watch blogs (Paul Graham, Sam Altman, etc.) for new posts |
| Slack channel sync | `0 8-20/2 * * *` | Pull latest Slack channel history to a local log file |
| Database sync | `0 23 * * *` | Git push personal JSON databases |
| Mention monitor | `*/5 * * * *` | Check for unanswered Slack @mentions |
| Work Pulse kickoff | `0 9 * * 1-5` | Start autonomous work cycle on weekdays |
| Work Pulse | `5,20,35,50 9-16 * * 1-5` | Run work cycle every 15 min during the day |
| End of Day | `0 17 * * 1-5` | Summarize the day's work, post to Slack |

### Cron Commands Reference

```bash
openclaw cron list                      # List all jobs with status
openclaw cron runs --limit 20           # Show recent run history
openclaw cron status                    # Scheduler health
openclaw cron run <job-id>              # Trigger a job immediately (debug)
openclaw cron add --name "Daily Check" --schedule "0 9 * * *" --message "Run briefing"
openclaw cron edit <job-id> --enabled true
openclaw cron disable <job-id>
openclaw cron rm <job-id>
```

### Job Types

```json
// Recurring cron job
{
  "id": "morning-briefing",
  "name": "Morning Briefing",
  "enabled": true,
  "schedule": { "kind": "cron", "expr": "30 6 * * *", "tz": "America/Los_Angeles" },
  "sessionTarget": "isolated",
  "wakeMode": "next-heartbeat",
  "payload": {
    "kind": "agentTurn",
    "message": "Run my morning briefing..."
  }
}
```

**`sessionTarget`**: `isolated` (clean session, no shared context) or `main` (uses your running session)
**`wakeMode`**: `next-heartbeat` (waits for agent heartbeat) or `now` (fires immediately)

### Known Issue: One-Shot Jobs Are Broken

OpenClaw's `at`-style one-time reminders don't fire reliably (GitHub issue #43471). Workaround: use macOS launchd for one-shot reminders.

**launchd workaround:**

```bash
# Create a reminder script
cat > ~/clawd/reminders/schedule-reminder.sh << 'EOF'
#!/bin/bash
LABEL="com.openclaw.reminder.$(date +%s)"
TIME="$1"  # HH:MM format
MESSAGE="$2"
# Creates a launchd plist that fires once at the specified time
# See the reminders/ directory for full implementation
EOF
chmod +x ~/clawd/reminders/schedule-reminder.sh
```

### Watchdog Scripts

The gateway can become unresponsive or drop Slack events silently. Two watchdog scripts handle this automatically:

| Script | What It Monitors | Trigger |
|--------|-----------------|---------|
| [`health-watchdog.sh`](examples/health-watchdog.sh) | Gateway health endpoint | Restarts if `openclaw health` times out |
| [`gap-watchdog.sh`](examples/gap-watchdog.sh) | Slack event gaps in `gateway.log` | Restarts if "event gap detected" appears |

Both have a 5-minute cooldown between restarts to avoid restart loops.

```bash
# Copy both watchdog scripts
mkdir -p ~/.openclaw/scripts
cp examples/health-watchdog.sh examples/gap-watchdog.sh ~/.openclaw/scripts/
chmod +x ~/.openclaw/scripts/*.sh

# Add both to crontab (runs every 5 minutes)
crontab -e
# Add these two lines:
# */5 * * * * ~/.openclaw/scripts/health-watchdog.sh
# */5 * * * * ~/.openclaw/scripts/gap-watchdog.sh
```

**Important:** Use the full path to the `openclaw` binary (e.g., `/opt/homebrew/bin/openclaw`) in watchdog scripts. The cron environment doesn't have the same PATH as your shell — we hit a bug where the health watchdog couldn't find `node`, causing false-positive restart loops.

---

## 12. Skills Installation

Skills extend what your agent can do. They live in the `skills/` directory with a `SKILL.md` file that describes capabilities and provides context.

### How Skills Work

```
~/clawd/skills/
└── my-skill/
    ├── SKILL.md          # Required: description, instructions, examples
    ├── scripts/          # Optional: helper scripts
    └── data/             # Optional: state files
```

The `SKILL.md` frontmatter:

```yaml
---
name: my-skill
description: "What this skill does"
version: 0.1.0
---

# My Skill

Instructions for the agent on how to use this skill...
```

### Installing Skills

```bash
# From ClawHub (if available)
clawdhub install skill-name

# Or manually — copy to skills directory
cp -r /path/to/skill ~/clawd/skills/

# Enable in openclaw.json (if needed)
openclaw config set skills.entries.my-skill.enabled true
```

### Recommended Skills to Start With

| Skill | Purpose |
|-------|---------|
| `self-improving-agent` | Logs errors and learnings automatically |
| `google-calendar` | Calendar API access |
| `airtable` | Query Airtable bases |

### Skills with Environment Variables

Some skills need API keys. Configure in `openclaw.json`:

```json
{
  "skills": {
    "entries": {
      "open-wearables": {
        "enabled": true,
        "env": {
          "OPEN_WEARABLES_API_KEY": "sk-YOUR-KEY",
          "OPEN_WEARABLES_URL": "http://localhost:8000/api/v1"
        }
      }
    }
  }
}
```

---

## 13. Notification Hooks (Mac Mini Edition)

Since Mac Mini has no camera (no LED blink trick), we use voice + system notifications.

### Quick Setup (Inline in settings.json)

Edit `~/.claude/settings.json`:

```json
{
  "effortLevel": "high",
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "say 'Need help'"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "say 'Done'"
          }
        ]
      }
    ]
  }
}
```

### Full Setup (With System Sound + Notification Banner)

For a richer experience with sound effects and macOS notification banners:

```bash
mkdir -p ~/.claude/hooks
cp examples/alert.sh examples/notify.sh examples/stop.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh
```

Then in `settings.json`:

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/alert.sh & ~/.claude/hooks/notify.sh; wait"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/stop.sh"
          }
        ]
      }
    ]
  }
}
```

**What you'll hear:**
- "Need help" + Glass chime + notification banner — when the agent needs your input
- "Done" — when the agent finishes

See also: [claude-notification-hooks-mac-mini](https://github.com/guglielmofonda/claude-notification-hooks-mac-mini)

---

## 14. Browser Automation

OpenClaw includes a built-in headless browser for tasks the agent can't do with APIs alone — OAuth re-auth, web scraping, screenshots, and interacting with pages that require JavaScript.

### How It Works

OpenClaw manages a dedicated Chromium instance with its own profile, cookies, and login sessions. The agent can control it programmatically: open tabs, click elements, fill forms, take screenshots, and extract data.

### Browser Profile Types

| Type | How It Works | Best For |
|------|-------------|----------|
| **OpenClaw-managed** (default) | Isolated Chromium instance managed by the gateway | Most use cases — OAuth, scraping, screenshots |
| **`user` profile** | Attaches to your signed-in Mac Chrome via DevTools | Pages where you're already logged in (no re-auth) |
| **`chrome-relay`** | Extension relay into live Chrome tabs | Reusing active browser sessions |
| **Remote CDP** | Connect to an external browser via WebSocket | Cloud-hosted browsers, CI/CD |

### Chrome DevTools Attach Mode (New in 2026.3.13)

Connect to your real signed-in Chrome instead of a headless instance. Useful when a site's login is hard to automate or you need your actual session state.

```bash
# 1. Launch Chrome with remote debugging enabled
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --remote-debugging-port=9222

# 2. Open chrome://inspect/#remote-debugging to verify

# 3. Use the 'user' profile in your agent session
# In openclaw.json:
{
  "browser": {
    "defaultProfile": "user"
  }
}
```

### Profile Management

```bash
openclaw browser profiles           # List all profiles
openclaw browser create-profile --name work
openclaw browser reset-profile --name openclaw  # Reset to clean state
```

### Key Capabilities

- **Deterministic tab control** — list, open, focus, close tabs by ID
- **AI snapshots** — the agent sees a simplified representation of the page with numeric references it can click/type into
- **State management** — cookies, localStorage, credentials persist across sessions
- **Device emulation** — set geolocation, timezone, viewport size
- **Console & network monitoring** — capture errors, trace network requests
- **Screenshots** — saved to `~/.openclaw/media/browser/`

### Configuration

In `openclaw.json`:

```json
{
  "browser": {
    "defaultProfile": "openclaw"
  }
}
```

### Real-World Use Cases

- **Google OAuth re-auth**: OAuth tokens for unpublished Google apps expire after ~7 days. The agent uses the browser to re-authenticate headlessly instead of requiring manual intervention.
- **Web scraping**: Pages that require JavaScript rendering or login sessions.
- **Taking screenshots**: Visual verification of deployments, dashboards, or UI changes.
- **Form submission**: Filling out web forms that don't have an API.

### Docs

Full browser tool documentation: [docs.openclaw.ai/tools/browser](https://docs.openclaw.ai/tools/browser)

---

## 15. Model Management & Fast Mode

Configure which models your agent uses, set up aliases, and enable fast mode for quicker responses.

### Model Aliases

Define short names for models in `openclaw.json`:

```json
{
  "auth": {
    "models": {
      "aliases": {
        "opus": "anthropic/claude-opus-4-5",
        "opus4.6": "anthropic/claude-opus-4-6",
        "sonnet": "anthropic/claude-sonnet-4-6"
      }
    }
  }
}
```

Use aliases when sending messages: `openclaw agent --model opus4.6 --message "..."`

### Fast Mode

Fast mode reduces latency at the cost of some throughput — good for quick back-and-forth.

```bash
openclaw models list                    # See available models
openclaw models set primary --model opus4.6
openclaw models aliases                 # List configured aliases
openclaw models scan --provider openrouter  # Discover available free models
```

### Setting the Primary Model

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "anthropic/claude-opus-4-6"
      }
    }
  }
}
```

---

## 16. Memory Search

OpenClaw indexes your workspace memory files for semantic search. Find anything your agent has written down.

```bash
openclaw memory status                  # Check indexing status
openclaw memory status --deep           # Probe embedding provider health
openclaw memory search "meeting notes"  # Semantic search
openclaw memory search --query "deployment" --max-results 20
openclaw memory index --force           # Reindex all memory files
```

Memory files indexed: everything in `~/your-workspace/memory/YYYY-MM-DD.md` and `MEMORY.md`.

---

## 17. Dashboard & Control UI

The web dashboard gives you a visual interface to monitor and control your agent.

```bash
openclaw dashboard                      # Open web UI in browser
```

### What's in the Dashboard (v2, 2026.3.13)

| View | Purpose |
|------|---------|
| **Overview** | Gateway health, active sessions, recent activity |
| **Chat** | Send messages to your agent from the browser |
| **Config** | View and edit `openclaw.json` visually |
| **Agent** | Per-agent settings, model selection |
| **Session** | Active session transcripts |

Command palette available via `Cmd+K`. Mobile-responsive with bottom tab navigation.

### Device Pairing

Each device gets its own auth token (new in 2026.3.12: short-lived bootstrap tokens for security):

```bash
openclaw pairing                        # Start pairing flow
openclaw pairing approve <channel> <code>
```

---

## 18. Agent Control Protocol

ACP lets you send messages directly to agent sessions via the gateway — useful for scripting, automation, and inter-agent communication.

```bash
openclaw acp client                     # Interactive CLI
openclaw acp --session main:main --message "Run daily check"
openclaw acp --provenance meta          # Include request metadata
```

Useful for triggering agent work from scripts or other processes without going through a messaging channel.

---

## 19. Sandbox Containers

Docker-based per-session isolation. Each agent session can run in its own container with controlled tool access.

```bash
openclaw sandbox list                   # List active sandboxes
openclaw sandbox list --browser         # Show browser sandboxes
openclaw sandbox recreate --all         # Recreate all containers
openclaw sandbox recreate --session main
openclaw sandbox explain                # Show effective sandbox policy
```

Requires Docker to be installed and running.

---

## 20. Backup & Recovery

Back up your entire OpenClaw setup: config, credentials, sessions, and workspace state.

```bash
openclaw backup create --output ~/openclaw-backup-$(date +%Y%m%d).tar.gz
openclaw backup verify ~/openclaw-backup.tar.gz
```

**What's included:** `~/.openclaw/openclaw.json`, credentials, session history, device identity, cron jobs, hook configurations.

**What's NOT included:** Your workspace files (those are in git), skills, and browser profile data.

Recommended: schedule a weekly backup cron job.

---

## 21. Work Pulse — Autonomous Work Cycles

The Work Pulse pattern lets your agent work autonomously in 15-minute cycles throughout the day — checking its own progress, spawning sub-tasks, and reporting results without constant supervision.

**How it works:**
1. **Morning Kickoff** (9am) — Sets the day's goals and spawns initial work
2. **Work Pulse** (every 15 min) — Harvests completed work, assesses progress, spawns next tasks, posts a Slack checkpoint
3. **End of Day** (5pm) — Summarizes the day, posts report

**Key insight:** The agent can't track time itself — cron handles timing, the agent handles work. A lock file prevents overlapping pulses.

**Setup:** See the `solo-founders/team-agents` repo for the full Work Pulse protocol, state machine definition, and guard scripts. It's documented there as a team pattern rather than here.

```bash
# Example cron config for Work Pulse
# Morning kickoff
# 0 9 * * 1-5  → openclaw cron job → "Morning kickoff: read goals, plan the day, spawn work"
# Every 15 min
# 5,20,35,50 9-16 * * 1-5 → "Work pulse: harvest results, spawn next tasks, post checkpoint"
# End of day
# 0 17 * * 1-5 → "End of day: summarize, create daily log, post report"
```

---

## 22. Security Checklist

OpenClaw supports multiple paired devices, each with their own auth token.

### How It Works

On first setup, OpenClaw generates an Ed25519 keypair stored in `~/.openclaw/identity/`. This is your device identity.

### Control UI (Web Dashboard)

```bash
openclaw dashboard
```

Opens a web-based control UI where you can:
- View active sessions
- Send messages to the agent
- Monitor health

### Pair a New Device

```bash
openclaw pairing
```

---

## 22. Security Checklist

| Setting | Recommended Value | Why |
|---------|-------------------|-----|
| Gateway bind | `loopback` | Only accessible from localhost |
| Gateway auth | Token-based | Prevents unauthorized access |
| Slack DM policy | `allowlist` | Only you can DM the bot |
| Telegram DM policy | `allowlist` | Only your user ID can interact |
| WhatsApp DM policy | `allowlist` | Only your phone number |
| MEMORY.md loading | Main session only | Personal data doesn't leak to group chats |
| Workspace permissions | Explicit allowlist | Only approved commands run |
| Credentials | In `~/.openclaw/credentials/` | Not in workspace repo |

### Device Pairing Security (New in 2026.3.12)

Unknown senders now get a **short-lived bootstrap token** instead of sharing gateway credentials. This means:
- New contacts trying to DM your agent get a one-time pairing code
- The code expires — no persistent credential exposure
- You approve pairing explicitly: `openclaw pairing approve <channel> <code>`

### Token Generation

```bash
# For gateway auth token
openssl rand -hex 24

# For any API integration
openssl rand -hex 32
```

### What NOT to Commit

Never commit these to your workspace repo:
- API keys and tokens
- `credentials.json` files
- `~/.openclaw/openclaw.json` (contains all tokens)
- `.env` files

---

## 23. Known Issues & Workarounds

| Issue | Impact | Workaround | Status |
|-------|--------|------------|--------|
| **Cron one-shot jobs don't fire** | Reminders broken | Use macOS launchd plist | Open (GH #43471) |
| **Google OAuth expires ~7 days** | Gmail/Calendar API fails | Browser automation re-auth or publish your Google app | Active workaround |
| **Health watchdog can't find Node** | False restart loops | Use full path `/opt/homebrew/bin/openclaw` in scripts | Easy fix |
| **WhatsApp connection drops** | 408/503 errors | Gateway auto-reconnects; monitor logs | Intermittent |
| **Slack thread sessions lack context** | Agent responds confused in threads | Fetch thread context via API before responding | Open (GH #44638) |
| **Slack `message read threadId` broken** | Can't read thread replies | Use direct Slack API call | Open (GH #44591) |

### Slack Thread Context Workaround

When someone replies in a Slack thread, OpenClaw creates a **new session** for that thread. This session starts **blank** — the agent has no context of the parent message or prior thread replies.

**Symptom:** Agent responds to thread asking "what are you referring to?" even though the context is in the thread above.

**Root cause:** Thread sessions don't bootstrap with thread history. Filed as [#44638](https://github.com/openclaw/openclaw/issues/44638).

**Workaround script** (`~/clawd/scripts/slack-thread-context.sh`):

```bash
#!/bin/bash
# Fetch Slack thread context using conversations.replies API
# Usage: slack-thread-context.sh <channel_id> <thread_ts> [limit]

CHANNEL="${1:?Usage: $0 <channel_id> <thread_ts> [limit]}"
THREAD_TS="${2:?Usage: $0 <channel_id> <thread_ts> [limit]}"
LIMIT="${3:-20}"
BOT_TOKEN="xoxb-YOUR-BOT-TOKEN"

curl -s "https://slack.com/api/conversations.replies?channel=${CHANNEL}&ts=${THREAD_TS}&limit=${LIMIT}" \
  -H "Authorization: Bearer ${BOT_TOKEN}" | \
  jq -r '.messages[] | "[\(.user)] \(.text[0:500])"'
```

**Agent behavior update** (add to `AGENTS.md`):

```markdown
### Thread Context (CRITICAL)

**ALWAYS do this when responding in Slack threads:**
1. Check if session name contains `thread:TIMESTAMP`
2. If yes, fetch thread context BEFORE responding:
   ```bash
   ~/clawd/scripts/slack-thread-context.sh <channel_id> <thread_ts>
   ```
3. Read the context, then respond appropriately

**How to extract channel/thread from session name:**
- Session: `agent:main:slack:channel:c0al7kz75tp:thread:1773368311.447129`
- Channel: `C0AL7KZ75TP` (uppercase)
- Thread ts: `1773368311.447129`
```

### Slack Channel Message Monitoring

To catch any missed @mentions (safety net):

```bash
#!/bin/bash
# ~/clawd/scripts/slack-check-unanswered.sh
# Check for unanswered @mentions in last 2 hours

BOT_TOKEN="xoxb-YOUR-BOT-TOKEN"
BOT_USER_ID="U0ACMDPT58X"  # Your bot's user ID
CHANNELS=("C0AL7KZ75TP" "C0ACMGAQ9PZ")  # Channels to monitor
OLDEST=$(( $(date +%s) - 7200 ))

for CHANNEL in "${CHANNELS[@]}"; do
  curl -s "https://slack.com/api/conversations.history?channel=${CHANNEL}&oldest=${OLDEST}&limit=50" \
    -H "Authorization: Bearer ${BOT_TOKEN}" | \
    jq -r --arg bot "$BOT_USER_ID" '
      .messages[]? | 
      select(.text | contains("<@" + $bot + ">")) |
      select(.user != $bot) |
      "Channel: '"$CHANNEL"' | ts: \(.ts) | text: \(.text[0:100])"
    '
done
```

Add to `HEARTBEAT.md` for periodic monitoring:

```markdown
### Slack Monitoring (every few hours)
Check for unanswered @mentions:
\`\`\`bash
~/clawd/scripts/slack-check-unanswered.sh
\`\`\`
If any found, respond to them.
```

### Slack Config: No Mention Required

To let your agent see all messages (not just @mentions), set `requireMention: false` for each channel:

```json
{
  "channels": {
    "slack": {
      "channels": {
        "#your-channel": {
          "allow": true,
          "requireMention": false
        }
      }
    }
  }
}
```

**Important:** When `requireMention: false`, your agent sees EVERY message. Add response rules to `AGENTS.md`:

```markdown
### When to Respond in Channels

**Respond when:**
- Directly @mentioned
- Continuing a conversation you're already in
- Your name comes up naturally
- You have genuinely useful info to add

**Stay silent (NO_REPLY) when:**
- General chatter between humans
- Topics you have nothing to add to
- Someone else already answered
```

---

## 24. Quick Reference

### File Paths

| What | Where |
|------|-------|
| OpenClaw config | `~/.openclaw/openclaw.json` |
| Cron jobs | `~/.openclaw/cron/jobs.json` |
| Gateway logs | `~/.openclaw/logs/gateway.log` |
| Error logs | `~/.openclaw/logs/gateway.err.log` |
| Watchdog log | `~/.openclaw/logs/health-watchdog.log` |
| Device identity | `~/.openclaw/identity/device.json` |
| Paired devices | `~/.openclaw/devices/paired.json` |
| Credentials | `~/.openclaw/credentials/` |
| Browser data | `~/.openclaw/browser/openclaw/` |
| Claude Code settings | `~/.claude/settings.json` |
| Workspace | `~/clawd/` |
| Skills | `~/clawd/skills/` |
| Memory | `~/clawd/MEMORY.md` |

### Common Commands

```bash
# OpenClaw — Gateway
openclaw status                    # Channel health & recent activity
openclaw health                    # Gateway health check
openclaw gateway                   # Start gateway (foreground)
openclaw gateway --force           # Kill & restart gateway
openclaw gateway restart           # Graceful restart
openclaw logs                      # View gateway logs
openclaw doctor                    # Diagnose issues
openclaw doctor --fix              # Auto-fix common configuration issues
openclaw dashboard                 # Open web control UI

# OpenClaw — Cron
openclaw cron list                 # List all jobs
openclaw cron runs --limit 20      # Run history
openclaw cron run <id>             # Trigger job now (debug)
openclaw cron status               # Scheduler health

# OpenClaw — Browser
openclaw browser profiles          # List browser profiles
openclaw browser start             # Start headless browser
openclaw browser screenshot --full-page

# OpenClaw — Models
openclaw models list               # Available models
openclaw models aliases            # Configured aliases
openclaw models set primary --model opus4.6

# OpenClaw — Memory
openclaw memory search "query"     # Semantic search
openclaw memory status --deep      # Indexing health
openclaw memory index --force      # Reindex

# OpenClaw — Sandbox & Backup
openclaw sandbox list              # Active containers
openclaw sandbox explain           # Effective policy
openclaw backup create --output ~/backup.tar.gz

# OpenClaw — ACP
openclaw acp client                # Interactive agent CLI
openclaw acp --session main:main --message "test"

# Misc
openclaw plugins list              # List installed plugins
openclaw skills list               # List available skills
openclaw config get channels       # View channel config
openclaw message send --channel slack --target "#channel" --message "test"

# Claude Code
claude                             # Start interactive session
claude mcp list                    # List MCP servers
claude mcp add ...                 # Add MCP server
/mcp                               # Check MCP status (inside Claude Code)
/hooks                             # Reload hooks (inside Claude Code)
```

### Message Acknowledgment Flow

```
User sends message in Slack
         |
         v
   Ack reaction added
         |
         v
   Agent processes message
         |
         v
   Agent sends reply
         |
         v
   Ack reaction removed
```

---

## Getting Help

- **OpenClaw docs**: [docs.openclaw.ai](https://docs.openclaw.ai)
- **Claude Code docs**: [docs.anthropic.com/en/docs/claude-code](https://docs.anthropic.com/en/docs/claude-code)
- **OpenClaw CLI help**: `openclaw --help` or `openclaw <command> --help`
- **Search docs**: `openclaw docs "your question"`
