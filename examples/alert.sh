#!/bin/bash
# Visual + audio alert for Mac Mini (no camera LED available)
# Plays a system sound and shows a macOS notification banner

afplay /System/Library/Sounds/Glass.aiff &
osascript -e 'display notification "Claude needs your attention" with title "Claude Code" sound name "Glass"' &
wait
