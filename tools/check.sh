#!/usr/bin/env bash
# Import the project and parse/compile every GDScript, printing real errors with
# locations. (--check-only runs without autoloads, so "Game/Sfx/Quality not
# found" is expected noise and filtered out.)
cd "$(dirname "$0")/.."
timeout 180 godot --headless --import >/dev/null 2>&1
for f in $(find . -name "*.gd" -not -path "./.godot/*"); do
  out=$(timeout 30 godot --headless --check-only -s "res://${f#./}" 2>&1 | awk '
    /SCRIPT ERROR|Parse Error/ { keep = ($0 !~ /Identifier not found: (Game|Sfx|Quality|Live|Notifier|Market|Store)|Failed to compile depended|Failed to load script/); if (keep) print; next }
    /at: GDScript::reload/ { if (keep) print; keep = 0 }')
  [ -n "$out" ] && echo "== $f" && echo "$out" | sed 's/^\s*//' | head -20
done
echo "check done"
