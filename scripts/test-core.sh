#!/usr/bin/env bash
# Unit and parity tests of the ContrarrelojCore package, on the Mac (fast, no simulator).
set -euo pipefail
source "$(dirname "$0")/env.sh"
swift test --package-path "$REPO_ROOT/Packages/ContrarrelojCore" "$@"
