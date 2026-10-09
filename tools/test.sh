#!/usr/bin/env bash
# Headless logic tests (economy, holders, save, a real assembly line).
cd "$(dirname "$0")/.." && timeout 300 godot --headless --path . res://tests/run.tscn -- --fresh 2>&1 \
  | grep -vE "^Godot Engine|^$|ObjectDB instances|resources still in use|at: (cleanup|clear|_free_rids)|RID allocations|RID of type"
exit ${PIPESTATUS[0]}
