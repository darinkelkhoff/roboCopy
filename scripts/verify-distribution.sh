#!/bin/bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: verify-distribution.sh path/to/App.app" >&2
    exit 64
fi

APP="$1"
SIGNING_INFO="$(codesign --display --verbose=4 "$APP" 2>&1)"

if ! grep -q '^Authority=Developer ID Application:' <<<"$SIGNING_INFO"; then
    echo "Expected a Developer ID Application signature" >&2
    exit 1
fi

if ! grep -Eq '^CodeDirectory .*flags=.*\(runtime\)' <<<"$SIGNING_INFO"; then
    echo "Expected hardened runtime signing" >&2
    exit 1
fi

codesign --verify --deep --strict --verbose=2 "$APP"
xcrun stapler validate "$APP"
spctl --assess --type execute --verbose=4 "$APP"
