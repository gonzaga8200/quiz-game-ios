#!/usr/bin/env bash
# Copies the web's question bank (data/questions/*.json of WEB_REF, default origin/main) into
# App/Resources/questions.json, the questions bundled with the app. Read-only on the web repo.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$here/.." && pwd)"
WEB_REPO="$(cd "${WEB_REPO:-$repo/../quiz-game}" && pwd)"
REF="${WEB_REF:-origin/main}"
out="$repo/App/Resources/questions.json"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
git -C "$WEB_REPO" archive "$REF" data/questions | tar -x -C "$tmp"
python3 - "$tmp/data/questions" "$out" <<'PY'
import json, os, sys
src, out = sys.argv[1], sys.argv[2]
questions = []
for name in sorted(os.listdir(src)):
    if name.endswith(".json"):
        with open(os.path.join(src, name), encoding="utf-8") as f:
            questions.extend(json.load(f))
with open(out, "w", encoding="utf-8") as f:
    json.dump(questions, f, ensure_ascii=False, separators=(",", ":"))
    f.write("\n")
print(f"{len(questions)} questions written to {out}")
PY
echo "from $(git -C "$WEB_REPO" rev-parse --short "$REF")"
