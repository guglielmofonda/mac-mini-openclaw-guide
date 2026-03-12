#!/bin/bash
# Restart the OpenClaw gateway if it is running but not responding to health checks.
# Add to crontab: */5 * * * * ~/.openclaw/scripts/health-watchdog.sh
#
# IMPORTANT: Use full paths — cron does not inherit your shell's PATH.

OPENCLAW=/opt/homebrew/bin/openclaw
COOLDOWN_FILE=/tmp/openclaw-health-watchdog-last-restart
WATCHDOG_LOG=~/.openclaw/logs/health-watchdog.log
COOLDOWN_SECS=300  # 5 minutes between restarts
TIMEOUT_SECS=10    # how long to wait for a health response

# Try to get a healthy response
if $OPENCLAW health --timeout "${TIMEOUT_SECS}000" > /dev/null 2>&1; then
  exit 0  # all good
fi

# Gateway is unresponsive — respect cooldown
if [ -f "$COOLDOWN_FILE" ]; then
  last=$(cat "$COOLDOWN_FILE")
  now=$(date +%s)
  [ $((now - last)) -lt $COOLDOWN_SECS ] && exit 0
fi

# Restart
echo "$(date): Gateway unresponsive — restarting" >> "$WATCHDOG_LOG"
date +%s > "$COOLDOWN_FILE"
$OPENCLAW gateway restart >> "$WATCHDOG_LOG" 2>&1
echo "$(date): Gateway restarted" >> "$WATCHDOG_LOG"
