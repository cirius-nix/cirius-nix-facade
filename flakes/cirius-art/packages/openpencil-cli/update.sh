#!/usr/bin/env bash
# Regenerate package-lock.json for the pinned @open-pencil/cli version.
#
# Usage: edit the @open-pencil/cli version in package.json, run this script,
# then update `version` and `npmDepsHash` in default.nix.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

cp "$here/package.json" "$work/package.json"
cd "$work"
npm install --package-lock-only --ignore-scripts --no-audit --no-fund

cp package-lock.json "$here/package-lock.json"
echo "wrote $here/package-lock.json"
