#!/usr/bin/env bash
# Regenerate package-lock.json for the pinned @pen.dev/cli version.
#
# Two upstream quirks force this to be a script rather than a plain
# `npm install --package-lock-only`:
#
# 1. `@earendil-works/pi-coding-agent` ships an npm-shrinkwrap.json. A
#    lock-only resolve records that package but not the subtree its shrinkwrap
#    pins (@aws-sdk/*, among others), so `npm ci` would then reach for tarballs
#    that were never prefetched. A full install materialises the real tree and
#    writes all of it to the lock.
# 2. npm still omits `integrity` for the shrinkwrapped entries, and nixpkgs'
#    prefetch-npm-deps panics on those ("non-git dependencies should have
#    associated integrity"), so backfill the hashes from the registry.
#
# Usage: edit the @pen.dev/cli version in package.json, run this script, then
# update `version` and `npmDepsHash` in default.nix.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

cp "$here/package.json" "$work/package.json"
cd "$work"
npm install --ignore-scripts --no-audit --no-fund

python3 - <<'PYEOF'
import json
import urllib.parse
import urllib.request

with open("package-lock.json") as handle:
    lock = json.load(handle)

patched = 0
for path, entry in lock["packages"].items():
    if not path or "resolved" not in entry or "integrity" in entry:
        continue
    name = path.rsplit("node_modules/", 1)[1]
    url = f"https://registry.npmjs.org/{urllib.parse.quote(name, safe='')}/{entry['version']}"
    with urllib.request.urlopen(url) as response:
        entry["integrity"] = json.load(response)["dist"]["integrity"]
    patched += 1
    print(f"backfilled integrity for {name}@{entry['version']}")

with open("package-lock.json", "w") as handle:
    json.dump(lock, handle, indent=2)
    handle.write("\n")

print(f"patched {patched} entries")
PYEOF

cp package-lock.json "$here/package-lock.json"
echo "wrote $here/package-lock.json"
