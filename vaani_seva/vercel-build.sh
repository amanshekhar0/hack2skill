#!/usr/bin/env bash
set -euo pipefail

# Installs Flutter SDK (stable) and builds Flutter Web for Vercel.
# Configure backend URL in Vercel env var: API_BASE_URL

FLUTTER_DIR="${FLUTTER_DIR:-$PWD/.flutter}"

if [ ! -d "$FLUTTER_DIR" ]; then
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

flutter --version
flutter pub get

BUILD_DEFINES=()
if [ "${API_BASE_URL:-}" != "" ]; then
  BUILD_DEFINES+=( "--dart-define=API_BASE_URL=${API_BASE_URL}" )
fi

flutter build web --release --no-wasm-dry-run "${BUILD_DEFINES[@]}"
