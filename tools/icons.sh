#!/usr/bin/env bash
# Renders every UI icon from the game's own models (dev/icons.gd), then trims,
# shadows and scales them into assets/icons/ (tools/icon_post.py).
#   tools/icons.sh             # all icons
#   tools/icons.sh gpu tk_pico # only these
set -e
cd "$(dirname "$0")/.."
timeout "${T:-900}" xvfb-run -a -s "-screen 0 1024x1024x24" godot --path . --rendering-driver vulkan --rendering-method forward_plus \
  --resolution 512x512 res://dev/icons.tscn -- "$@" 2>&1 | grep -E "icons done|SCRIPT ERROR|at: " | head -40
python3 tools/icon_post.py "$@"
