#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/swift-recipe-explorer-321166-321175/swift_frontend"
cd "$WS"
LOGFILE="$WS/.serve.log"
rm -f "$LOGFILE"
# Prefer a local pinned serve binary
if [ -x "$WS/node_modules/.bin/serve" ]; then
  SERVE_BIN="$WS/node_modules/.bin/serve"
  "$SERVE_BIN" -s ./public -l 8080 > "$LOGFILE" 2>&1 &
  CHILD=$!
else
  # deterministic fallback: use python http.server (no npx/network)
  python3 -m http.server 8080 --directory public > "$LOGFILE" 2>&1 &
  CHILD=$!
fi
# record PID to file for stop script
echo "$CHILD" > "$WS/.serve.pid"
# export CHILD for immediate shell use
printf "%s" "$CHILD"
