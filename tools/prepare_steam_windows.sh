#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
stage_dir="$project_dir/build/steam/windows"

mkdir -p "$stage_dir"

godot --headless --path "$project_dir" --export-release "Windows Desktop" "$stage_dir/LobsterClicker.exe"
cp "$project_dir/THIRD_PARTY_NOTICES.md" "$stage_dir/THIRD_PARTY_NOTICES.md"
chmod 0644 "$stage_dir/LobsterClicker.exe" "$stage_dir/THIRD_PARTY_NOTICES.md"

file "$stage_dir/LobsterClicker.exe"
(
	cd "$stage_dir"
	shasum -a 256 LobsterClicker.exe THIRD_PARTY_NOTICES.md > SHA256SUMS.txt
)
chmod 0644 "$stage_dir/SHA256SUMS.txt"
cat "$stage_dir/SHA256SUMS.txt"
