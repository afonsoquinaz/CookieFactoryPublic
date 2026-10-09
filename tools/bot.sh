#!/usr/bin/env bash
# Plays the real game headless with the autopilot and prints progress/milestones.
#   tools/bot.sh [minutes=30] [speed=10]
cd "$(dirname "$0")/.." && timeout 3000 godot --headless --path . res://main.tscn -- --fresh --bot --minutes="${1:-30}" --speed="${2:-10}" 2>&1 \
  | grep -E "^\[|BOT|SCRIPT ERROR|^\s+at: .*\.gd|^   "
