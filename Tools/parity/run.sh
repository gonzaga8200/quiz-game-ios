#!/usr/bin/env bash
# Regenerates the parity fixtures from the web's TypeScript core.
#
# Read-only on the web repository: the needed files of WEB_REF (default origin/main) are exported
# with `git archive` into a temporary directory, so the author's working tree is never touched.
#
#   Tools/parity/run.sh                     # web repo at ../quiz-game
#   WEB_REPO=/path/to/quiz-game Tools/parity/run.sh
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/../.." && pwd)"
WEB_REPO="$(cd "${WEB_REPO:-$repo/../quiz-game}" && pwd)"
REF="${WEB_REF:-origin/main}"
out="$repo/Packages/ContrarrelojCore/Tests/ContrarrelojCoreTests/Fixtures"

[ -x "$WEB_REPO/node_modules/.bin/tsx" ] || { echo "run 'npm install' in $WEB_REPO first" >&2; exit 1; }
sha=$(git -C "$WEB_REPO" rev-parse "$REF")

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

git -C "$WEB_REPO" archive "$REF" core data/questions \
  app/utils/format.ts app/utils/feedback.ts app/utils/share.ts app/utils/seo.ts app/utils/keyboard.ts \
  | tar -x -C "$tmp"

# The app utils use Nuxt aliases; point them at the exported files instead.
sed -i.bak -e "s#'~~/core'#'../../core/index.ts'#g" -e "s#'~/utils/seo'#'./seo.ts'#g" "$tmp/app/utils/share.ts"

# ESM ignores NODE_PATH: give the exported core (it imports zod) the web's node_modules.
ln -s "$WEB_REPO/node_modules" "$tmp/node_modules"
printf '{ "type": "module" }\n' > "$tmp/package.json"
cp "$here/generate.ts" "$tmp/generate.ts"

mkdir -p "$out"
(cd "$tmp" && "$WEB_REPO/node_modules/.bin/tsx" generate.ts "$out" "$sha")
