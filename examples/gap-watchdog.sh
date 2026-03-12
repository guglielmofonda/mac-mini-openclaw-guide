#!/bin/bash
# Auto-restart the OpenClaw gateway when a Slack event gap is detected.
# Add to crontab: */5 * * * * ~/.openclaw/scripts/gap-watchdog.sh
#
# IMPORTANT: Use full paths — cron does not inherit your shell's PATH.

OPENCLAW=/opt/homebrew/bin/openclaw
LOG=~/.openclaw/logs/gateway.log
STATE_FILE=/tmp/openclaw-watchdog-linecount
COOLDOWN_FILE=/tmp/openclaw-watchdog-last-restart
WATCHDOG_LOG=~/.openclaw/logs/gap-watchdog.log
COOLDOWN_SECS=300  # 5 minutes between restarts

# Get current and last-known line counts
current_lines=$(wc -l < "$LOG" 2>/dev/null | tr -d ' ') || exit 0
last_lines=$(cat "$STATE_FILE" 2>/dev/null || echo 0)

# Handle log rotation/truncation
[ "$current_lines" -lt "$last_lines" ] && last_lines=0

# Save new position
echo "$current_lines" > "$STATE_FILE"

# Nothing new to check
[ "$current_lines" -le "$last_lines" ] && exit 0

# Check only new lines for "event gap detected"
new_lines=$((current_lines - last_lines))
tail -n "$new_lines" "$LOG" | grep -q "event gap detected" || exit 0

# Respect cooldown
if [ -f "$COOLDOWN_FILE" ]; then
  last=$(cat "$COOLDOWN_FILE")
  now=$(date +%s)
  [ $((now - last)) -lt $COOLDOWN_SECS ] && exit 0
fi

# Restart
echo "$(date): Event gap detected — restarting gateway" >> "$WATCHDOG_LOG"
date +%s > "$COOLDOWN_FILE"
$OPENCLAW gateway restart >> "$WATCHDOG_LOG" 2>&1
echo "$(date): Gateway restarted" >> "$WATCHDOG_LOG"
