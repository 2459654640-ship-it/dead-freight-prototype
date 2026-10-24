#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
export XDG_CACHE_HOME="$root/.runtime/test/cache"
export XDG_DATA_HOME="$root/.runtime/test/data"
export XDG_CONFIG_HOME="$root/.runtime/test/config"
mkdir -p "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"
engine="${GODOT_BIN:-godot}"
"$engine" --headless --path "$root" --editor --import --quit
exec "$engine" --headless --path "$root" --fixed-fps 60 --script res://tests/smoke.gd
