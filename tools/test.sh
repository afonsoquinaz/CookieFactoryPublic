#!/usr/bin/env bash
# Runs the headless logic tests (economy, production line, workers, save).
cd "$(dirname "$0")/.." && timeout 300 godot --headless -s res://tests/run.gd 2>&1 | grep -vE "^Godot Engine|^$|ObjectDB instances|resources still in use|at: (cleanup|clear)"
exit ${PIPESTATUS[0]}
