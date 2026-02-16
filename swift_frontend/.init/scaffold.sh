#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/swift-recipe-explorer-321166-321175/swift_frontend"
mkdir -p "$WS" && cd "$WS"
# ensure swift available in this shell if installed in /opt
if ! command -v swift >/dev/null 2>&1; then
  if [ -x "/opt/swift/usr/bin/swift" ]; then export PATH="/opt/swift/usr/bin:$PATH"; fi
fi
# determine package name (prefer override)
PKG_NAME_OVERRIDE="${SWIFT_PKG_NAME:-}"
if [ -n "$PKG_NAME_OVERRIDE" ]; then
  PKG_NAME="$PKG_NAME_OVERRIDE"
else
  if [ -f Package.swift ]; then
    PKG_NAME="$(swift package dump-package 2>/dev/null | (command -v jq >/dev/null 2>&1 && jq -r .name || python3 -c 'import sys,json;print(json.load(sys.stdin).get("name",""))'))"
  fi
fi
if [ -z "${PKG_NAME:-}" ]; then PKG_NAME="swift_frontend"; fi
# initialize package non-interactively if missing
if [ ! -f Package.swift ]; then
  # swift package init may fail when swift missing; fail fast with clear message
  if ! command -v swift >/dev/null 2>&1; then echo "swift not found on PATH; please ensure swift toolchain is installed or available at /opt/swift/usr/bin" >&2; exit 10; fi
  swift package init --name "$PKG_NAME" --type executable
fi
# Ensure Sources/<PackageName>/main.swift exists
MAIN_DIR="$WS/Sources/$PKG_NAME"
mkdir -p "$MAIN_DIR"
MAIN_FILE="$MAIN_DIR/main.swift"
if [ ! -f "$MAIN_FILE" ]; then
  cat > "$MAIN_FILE" <<'SW'
import Foundation
print("Hello Swift Frontend")
SW
fi
# Create package.json only if missing. Pin 'serve' devDependency.
PKG_JSON="$WS/package.json"
if [ ! -f "$PKG_JSON" ]; then
  cat > "$PKG_JSON" <<'NP'
{
  "name": "swift-frontend-static",
  "version": "0.0.1",
  "scripts": {
    "build": "echo \"no-op: swift builds handled via Makefile\"",
    "serve": "./node_modules/.bin/serve -s ./public -l 8080"
  },
  "devDependencies": {
    "serve": "14.0.1"
  }
}
NP
  # attempt to write deterministic package-lock only; tolerate offline/no-network
  npm i --package-lock-only --no-audit --no-fund >/dev/null 2>&1 || true
fi
# Install npm deps only when node_modules missing; this avoids network if node_modules already present
if [ ! -d node_modules ]; then
  npm i --no-audit --no-fund || { echo "npm install failed" >&2; exit 20; }
fi
# Write Makefile protecting $! expansion so it is evaluated at runtime
cat > Makefile <<'MK'
.PHONY: build test package serve stop-serve
build:
	 swift build -c release

test:
	 swift test

package:
	 mkdir -p public
	 if [ -d Resources ]; then cp -r Resources/* public/ || true; fi

serve:
	 ./node_modules/.bin/serve -s ./public -l 8080 > .serve.log 2>&1 &
	 echo \$! > .serve.pid

stop-serve:
	 [ -f .serve.pid ] && kill "$(cat .serve.pid)" >/dev/null 2>&1 || true
	 rm -f .serve.pid || true
MK

# Final validation: basic checks
if [ -f Package.swift ]; then
  : # OK
else
  echo "Warning: Package.swift not present after init" >&2
fi
if [ -f package.json ]; then
  : # OK
else
  echo "Warning: package.json not present" >&2
fi

echo "scaffold step completed: PKG_NAME=$PKG_NAME"
