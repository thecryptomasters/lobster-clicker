#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

godot --headless --editor --quit --path "$project_dir"
godot --headless --path "$project_dir" "$project_dir/tests/test_runner.tscn" -- --test
