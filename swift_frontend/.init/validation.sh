#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/swift-recipe-explorer-321166-321175/swift_frontend"
cd "$WS"
# Ensure swift on PATH
if ! command -v swift >/dev/null 2>&1; then export PATH="/opt/swift/usr/bin:$PATH"; fi
# Build step (reuse build script behavior inline for compactness)
if ! swift build -c release >/dev/null 2>&1; then echo "swift build failed" >&2; exit 30; fi
if [ "${BUILD_WASM:-0}" = "1" ]; then
  if command -v carton >/dev/null 2>&1; then mkdir -p public && carton build --release --output public || { echo "carton build failed" >&2; exit 31; }; else echo "carton not installed; skipping WASM build" >&2; fi
fi
mkdir -p public
if [ ! -f public/index.html ]; then cat > public/index.html <<'HT'
<!doctype html><meta charset="utf-8"><title>swift_frontend</title><h1>swift_frontend OK</h1>
HT
fi
LOGFILE="$WS/.serve.log"
rm -f "$LOGFILE"
# Prefer a local pinned serve binary
if [ -x "$WS/node_modules/.bin/serve" ]; then
  SERVE_BIN="$WS/node_modules/.bin/serve"
  "$SERVE_BIN" -s ./public -l 8080 > "$LOGFILE" 2>&1 &
  CHILD=$!
else
  python3 -m http.server 8080 --directory public > "$LOGFILE" 2>&1 &
  CHILD=$!
fi
# ensure we record the PID for deterministic cleanup
echo "$CHILD" > "$WS/.serve.pid"
cleanup(){
  if [ -n "${CHILD:-}" ]; then kill "$CHILD" >/dev/null 2>&1 || true; fi
  rm -f "$WS/.serve.pid"
}
trap cleanup EXIT
# wait for service to respond
ATTEMPTS=12; SLEEP=1; OK=0
for i in $(seq 1 $ATTEMPTS); do
  sleep $SLEEP
  if curl -sSf --max-time 2 http://127.0.0.1:8080/ >/dev/null 2>&1; then OK=1; break; fi
done
if [ "$OK" -ne 1 ]; then echo "Server did not respond on 8080" >&2; echo "--- Serve log ---" >&2; sed -n '1,200p' "$LOGFILE" >&2 || true; exit 32; fi
echo "Validation OK: http://127.0.0.1:8080/ responded"
# explicit cleanup
cleanup
