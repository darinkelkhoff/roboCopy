#!/bin/bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: verify-signing.sh path/to/App.app" >&2
    exit 64
fi

APP="$1"
SIGNING_INFO="$(codesign --display --verbose=4 --requirements - "$APP" 2>&1)"

if grep -q '^Signature=adhoc$' <<<"$SIGNING_INFO"; then
    echo "Expected identity signing, found an ad-hoc signature" >&2
    exit 1
fi

if grep -q '^TeamIdentifier=not set$' <<<"$SIGNING_INFO"; then
    echo "Expected a signing team identifier" >&2
    exit 1
fi

if grep -Eq 'designated => cdhash ' <<<"$SIGNING_INFO"; then
    echo "Expected a stable designated requirement, found a CDHash requirement" >&2
    exit 1
fi

printf '%s\n' "$SIGNING_INFO" | grep -E '^(Authority=|TeamIdentifier=|# designated =>|designated =>)'
