#!/usr/bin/env bash
# Import the project and parse/compile every GDScript, printing errors with locations.
cd "$(dirname "$0")/.."
timeout 180 godot --headless --import >/dev/null 2>&1
for f in $(find . -name "*.gd" -not -path "./.godot/*"); do
  out=$(timeout 30 godot --headless --check-only -s "res://${f#./}" 2>&1 | grep -E "SCRIPT ERROR|Parse Error|at: GDScript::reload|ERROR: Failed" | grep -v "Failed to compile depended\|Failed to load script\|Identifier not found: Game\|Identifier not found: Sfx\|Identifier not found: Quality")
  [ -n "$out" ] && echo "== $f" && echo "$out" | sed 's/^\s*//' | head -20
done
echo "check done"
