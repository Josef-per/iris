#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
iris_flutter_version=3.44.8
if [[ -n "${IRIS_FLUTTER_BIN:-}" ]]; then
  iris_flutter_bin="$IRIS_FLUTTER_BIN"
elif [[ -x .flutter-sdk/bin/flutter ]]; then
  iris_flutter_bin="$PWD/.flutter-sdk/bin/flutter"
elif command -v flutter >/dev/null 2>&1; then
  iris_flutter_bin="$(command -v flutter)"
else
  git clone --depth 1 --branch "$iris_flutter_version" \
    https://github.com/flutter/flutter.git .flutter-sdk
  iris_flutter_bin="$PWD/.flutter-sdk/bin/flutter"
fi

export IRIS_FLUTTER_BIN="$iris_flutter_bin"
node scripts/build_web.mjs
