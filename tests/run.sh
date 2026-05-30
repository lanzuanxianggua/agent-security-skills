#!/usr/bin/env bash
# Run convert.sh tests
# Usage: ./tests/run.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if bats is installed
if ! command -v bats &>/dev/null; then
  echo "bats is not installed. Install it with one of:"
  echo ""
  echo "  macOS:   brew install bats-core"
  echo "  Linux:   sudo apt install bats  OR  npm install -g bats"
  echo "  Windows: npm install -g bats    (via Git Bash)"
  echo ""
  echo "Then run:  bats tests/convert.bats"
  exit 1
fi

echo "Running convert.sh tests..."
echo ""

cd "$REPO_ROOT"
bats tests/convert.bats
