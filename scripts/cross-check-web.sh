#!/usr/bin/env bash
# Starts the web (origin/main of ../quiz-game, or WEB_REPO/WEB_REF) pointed at the local Firebase
# emulators, to check that the web shows what the iOS app wrote there:
#   1. scripts/emulators.sh                       (leave running)
#   2. run an integration test that writes a board, e.g. EmulatorTests/Ranking/positionCountsBetterPlayers()
#   3. scripts/cross-check-web.sh                 then open http://localhost:3100/ranking
# The web is exported with git archive into a temporary folder: its repository is not modified.
set -euo pipefail
source "$(dirname "$0")/env.sh"
WEB="${WEB_REPO:-$REPO_ROOT/../quiz-game}"
REF="${WEB_REF:-origin/main}"
[ -d "$WEB/node_modules" ] || { echo "run npm install in $WEB first" >&2; exit 1; }
dir="${TMPDIR:-/tmp}/contrarreloj-web-$(git -C "$WEB" rev-parse --short "$REF")"
rm -rf "$dir"
mkdir -p "$dir"
git -C "$WEB" archive "$REF" | tar -x -C "$dir"
ln -s "$WEB/node_modules" "$dir/node_modules"
cd "$dir"
echo "web $REF ($(git -C "$WEB" rev-parse --short "$REF")) on the emulators: http://localhost:${PORT:-3100}/ranking" >&2
exec npm run dev:emulators -- --port "${PORT:-3100}"
