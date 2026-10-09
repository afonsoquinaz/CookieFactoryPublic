#!/usr/bin/env bash
# Exports the Web build (needs the 4.7.1 web export templates installed).
#   tools/web.sh [out_dir=build/web]
set -e
cd "$(dirname "$0")/.."
out="${1:-build/web}"
mkdir -p "$out"
timeout 600 godot --headless --path . --export-release "Web" "$out/index.html" 2>&1 | grep -E "ERROR|DONE" | tail -3
touch "$out/.nojekyll"
ls -la "$out"
