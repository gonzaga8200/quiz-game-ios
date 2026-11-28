#!/usr/bin/env bash
# Regenerates Contrarreloj.xcodeproj from project.yml.
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$REPO_ROOT"
# CI checks the committed project with the version in .xcodegen-version; another version writes it
# slightly differently.
wanted=$(cat .xcodegen-version)
have=$(xcodegen --version | awk '{print $2}')
if [ "$have" != "$wanted" ]; then
  echo "warning: xcodegen $have, but the project is generated with $wanted (.xcodegen-version)" >&2
fi
xcodegen generate --quiet
