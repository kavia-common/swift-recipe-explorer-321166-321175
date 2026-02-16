#!/usr/bin/env bash
set -euo pipefail
WS="/home/kavia/workspace/code-generation/swift-recipe-explorer-321166-321175/swift_frontend"
cd "$WS"
# ensure swift in PATH for runtime (don't expand PATH at write-time)
if ! command -v swift >/dev/null 2>&1; then export PATH="/opt/swift/usr/bin:$PATH"; fi

# CARTON install when requested
if [ "${BUILD_WASM:-0}" = "1" ]; then
  CARTON_URL="${CARTON_URL:-}"
  CARTON_SHA256="${CARTON_SHA256:-}"
  ARCH="$(uname -m)"
  case "$ARCH" in
    x86_64|amd64) DEF_NAME_PREFIX="carton-linux-amd64" ;; 
    aarch64|arm64) DEF_NAME_PREFIX="carton-linux-arm64" ;;
    *) echo "Unsupported arch $ARCH for carton" >&2; exit 21 ;;
  esac
  if [ -z "$CARTON_URL" ]; then CARTON_URL="https://github.com/swiftwasm/carton/releases/latest/download/${DEF_NAME_PREFIX}"; fi

  # skip if already installed and executable
  if command -v carton >/dev/null 2>&1; then
    echo "carton already installed"
  else
    TMPDIR="/tmp/carton-install-$$" && rm -rf "$TMPDIR" && mkdir -p "$TMPDIR"
    TMPF="$TMPDIR/asset"
    curl -fSL --retry 3 --retry-delay 2 "$CARTON_URL" -o "$TMPF" || { echo "Failed to download carton from $CARTON_URL" >&2; rm -rf "$TMPDIR"; exit 22; }
    [ -s "$TMPF" ] || { echo "Empty carton asset" >&2; rm -rf "$TMPDIR"; exit 23; }
    if [ -n "$CARTON_SHA256" ]; then echo "$CARTON_SHA256  $TMPF" > "$TMPDIR/carton.sum" && sha256sum -c "$TMPDIR/carton.sum" || { echo "carton checksum mismatch" >&2; rm -rf "$TMPDIR"; exit 24; }; fi
    # detect archive vs raw binary
    if file "$TMPF" | grep -qi 'gzip compressed data\|tar archive'; then
      tar -xzf "$TMPF" -C "$TMPDIR" || { echo "Failed to extract carton archive" >&2; rm -rf "$TMPDIR"; exit 25; }
      BIN_PATH="$(find "$TMPDIR" -type f -name 'carton*' -perm /111 | head -n1 || true)"
      [ -n "$BIN_PATH" ] || { echo "carton binary not found inside archive" >&2; rm -rf "$TMPDIR"; exit 26; }
    else
      BIN_PATH="$TMPF"
    fi
    sudo mv "$BIN_PATH" /usr/local/bin/carton
    sudo chmod 0755 /usr/local/bin/carton
    sudo chown root:root /usr/local/bin/carton
    # write profile.d without expanding $PATH at write time
    sudo bash -c 'cat >/etc/profile.d/carton.sh <<\'EOF\'
# carton helper
export PATH="/usr/local/bin:$PATH"
EOF'
    sudo chmod 0644 /etc/profile.d/carton.sh
    command -v carton >/dev/null 2>&1 || { echo "carton not available after install" >&2; rm -rf "$TMPDIR"; exit 27; }
    carton --version || true
    rm -rf "$TMPDIR"
  fi
fi

# UI tooling when requested
if [ "${BUILD_UI_TESTS:-0}" = "1" ]; then
  if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then echo "node/npm required for UI tests" >&2; exit 28; fi
  export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1
  # prefer adding to package.json devDependencies if package.json exists, else run npm i to create package.json
  if [ -f package.json ]; then
    npm i --no-audit --no-fund --save-dev puppeteer-core || { echo "npm install puppeteer-core failed" >&2; exit 29; }
  else
    npm init -y >/dev/null 2>&1
    npm i --no-audit --no-fund --save-dev puppeteer-core || { echo "npm install puppeteer-core failed" >&2; exit 29; }
  fi
  # detect system chromium
  if command -v chromium-browser >/dev/null 2>&1 || command -v chromium >/dev/null 2>&1 || command -v google-chrome >/dev/null 2>&1; then
    : # present
  else
    # Try installing chromium-browser via apt; fail fast on apt errors
    sudo apt-get update -q && sudo apt-get install -yq chromium-browser || { echo "Failed to install chromium-browser; ensure Chromium is available or provide PUPPETEER_EXECUTABLE_PATH" >&2; exit 30; }
  fi
fi
