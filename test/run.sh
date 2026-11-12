#!/usr/bin/env bash
set -euo pipefail

directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for file in "$directory"/smoke/*.lua; do
    "${LUA:-lua}" "$file"
done
