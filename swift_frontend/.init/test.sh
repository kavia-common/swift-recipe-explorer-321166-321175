#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/swift-recipe-explorer-321166-321175/swift_frontend"
cd "$WS"
if ! command -v swift >/dev/null 2>&1; then export PATH="/opt/swift/usr/bin:$PATH"; fi
# run swift tests if present
if [ -f Package.swift ]; then
  swift test || { echo "swift test failed" >&2; exit 40; }
else
  echo "No Package.swift found; skipping swift test"
fi
