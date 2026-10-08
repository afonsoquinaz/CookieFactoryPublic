#!/usr/bin/env bash
# Render a scene to PNG with Xvfb + software Vulkan (lavapipe).
#   tools/shot.sh res://main.tscn out.png [-- --cam=... ]
#   env: RES=720x1280 FRAMES=90 METHOD=forward_plus|mobile
set -e
here="$(cd "$(dirname "$0")/.." && pwd)"
scene="$1"; out="$(realpath -m "$2")"; shift 2
[ "$1" = "--" ] && shift
timeout "${T:-240}" xvfb-run -a -s "-screen 0 1920x1920x24" godot --path "$here" --rendering-driver vulkan --rendering-method "${METHOD:-mobile}" \
  --resolution "${RES:-720x1280}" "$scene" -- --shot="$out" --frames="${FRAMES:-90}" "$@" 2>&1 \
  | grep -vE "ALSA|snd_|audio_driver|All audio drivers|audio_server|^\s*$|init_output_device|at: initialize|^Godot Engine|Vulkan 1|^\s+at:" || true
