# Architecture Overview

## System Diagram

```
+-------------------------------------------------------------------+
|                        Mac Mini (macOS)                            |
|                                                                   |
|  +-------------------------------------------------------------+ |
|  |                  OpenClaw Gateway (:18789)                   | |
|  |                                                              | |
|  |  +-----------+  +-----------+  +-----------+                 | |
|  |  |   Slack   |  | Telegram  |  | WhatsApp  |  <-- Channels  | |
|  |  |  (Socket) |  |   (Bot)   |  |   (Web)   |                | |
|  |  +-----+-----+  +-----+-----+  +-----+-----+               | |
|  |        +---------------+--------------+                      | |
|  |                        |                                     | |
|  |                        v                                     | |
|  |              +-----------------+                             | |
|  |              |  Agent Session  |  <-- Claude Code            | |
|  |              | (Anthropic API) |                             | |
|  |              +--------+--------+                             | |
|  |                       |                                      | |
|  |         +-------------+-------------+                        | |
|  |         v             v             v                        | |
|  |  +-----------+  +-----------+  +-----------+                 | |
|  |  |   Skills  |  |    MCP    |  |  Browser   |                | |
|  |  | (~/clawd/ |  |  Servers  |  | (Headless) |                | |
|  |  |  skills/) |  |           |  |            |                | |
|  |  +-----------+  +-----------+  +-----------+                 | |
|  |                                                              | |
|  |  +-----------+  +-----------+  +-----------+                 | |
|  |  |   Cron    |  | Watchdog  |  |  Control  |                | |
|  |  | Scheduler |  |  Scripts  |  |    UI     |                | |
|  |  +-----------+  +-----------+  +-----------+                 | |
|  +-------------------------------------------------------------+ |
|                                                                   |
|  +-------------------------------------------------------------+ |
|  |                    Workspace (~/clawd/)                      | |
|  |                                                              | |
|  |  AGENTS.md  IDENTITY.md  USER.md  TOOLS.md  MEMORY.md       | |
|  |                                                              | |
|  |  skills/           .learnings/        memory/                | |
|  |  +-- airtable/     +-- ERRORS.md      +-- YYYY-MM-DD.md     | |
|  |  +-- google-cal/   +-- LEARNINGS.md                         | |
|  |  +-- ...           +-- FEATURE_REQUESTS.md                  | |
|  +-------------------------------------------------------------+ |
+-------------------------------------------------------------------+

External Services:
  +-- Anthropic API (Claude models)
  +-- Gmail (MCP)
  +-- Google Calendar (MCP)
  +-- Slack API (MCP + Socket Mode)
  +-- Telegram Bot API
  +-- WhatsApp Web
```

## Data Flow

### Incoming Message (e.g., Slack)

```
Slack WebSocket  -->  Gateway  -->  Channel Plugin  -->  Access Check
                                                              |
                                                     +--------+--------+
                                                     | Allowlisted?    |
                                                     | YES        NO   |
                                                     v              v
                                               Add ack         Block or
                                               reaction        gate response
                                                     |
                                                     v
                                              Agent Session
                                                     |
                                              +------+------+
                                              | Process msg  |
                                              | Use tools    |
                                              | Query MCP    |
                                              +------+------+
                                                     |
                                                     v
                                              Send reply
                                              Remove ack
```

### Cron Job Execution

```
Cron Scheduler  -->  Match schedule  -->  Create agent session
                                                    |
                                                    v
                                             Execute prompt
                                                    |
                                                    v
                                          Deliver result to channel
                                          (e.g., Telegram DM)
```

## Config File Hierarchy

```
~/.openclaw/openclaw.json     <-- Everything: channels, gateway, plugins, cron
~/.claude/settings.json       <-- Claude Code: hooks, effort level
~/.claude.json                <-- Claude Code: MCP servers, project configs
~/clawd/.claude/settings.local.json  <-- Workspace: permissions allowlist
~/clawd/AGENTS.md             <-- Agent behavior rules
~/clawd/IDENTITY.md           <-- Agent persona
~/clawd/USER.md               <-- Owner context
```
