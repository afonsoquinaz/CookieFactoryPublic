#!/usr/bin/env bash
# Plays the real game headless with the autopilot and prints progress/milestones.
# Uses fixed 15 fps steps (simulated time, runs as fast as the CPU allows).
#   tools/bot.sh [minutes=30] [extra args...]
cd "$(dirname "$0")/.." && m="${1:-30}"; shift
timeout 20000 godot --headless --fixed-fps 15 --path . res://main.tscn -- --fresh --bot --minutes="$m" --speed=1 "$@" 2>&1 \
  | grep --line-buffered -E "^\[|BOT|SCRIPT ERROR|^\s+at: .*\.gd|^   "
