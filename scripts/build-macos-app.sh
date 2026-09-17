#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$REPO_ROOT/dist/RoboCopy.app"
STAGING_APP="$REPO_ROOT/dist/.RoboCopy.app.staging"
BACKUP_APP="$REPO_ROOT/dist/.RoboCopy.app.backup"
STAGING_CONTENTS="$STAGING_APP/Contents"

cleanup() {
    local status=$?
    trap - EXIT
    set +e

    rm -rf "$STAGING_APP"
    if [[ -e "$BACKUP_APP" ]]; then
        if [[ -e "$APP" ]]; then
            rm -rf "$BACKUP_APP"
        elif ! mv "$BACKUP_APP" "$APP"; then
            echo "Failed to restore previous app from $BACKUP_APP" >&2
            status=1
        fi
    fi

    exit "$status"
}

trap cleanup EXIT

cd "$REPO_ROOT"
mkdir -p "$REPO_ROOT/dist"
if [[ -e "$BACKUP_APP" && ! -e "$APP" ]]; then
    mv "$BACKUP_APP" "$APP"
fi
rm -rf "$STAGING_APP"
rm -rf "$BACKUP_APP"

swift build -c release --product RoboCopy
RELEASE_BIN_PATH="$(swift build -c release --show-bin-path)"
RELEASE_BINARY="$RELEASE_BIN_PATH/RoboCopy"

if [[ ! -x "$RELEASE_BINARY" ]]; then
    echo "RoboCopy release binary is missing or not executable: $RELEASE_BINARY" >&2
    exit 1
fi

mkdir -p "$STAGING_CONTENTS/MacOS" "$STAGING_CONTENTS/Resources"
cp "$RELEASE_BINARY" "$STAGING_CONTENTS/MacOS/RoboCopy"
cp "Resources/Info.plist" "$STAGING_CONTENTS/Info.plist"

plutil -lint "$STAGING_CONTENTS/Info.plist"
codesign --force --sign - "$STAGING_APP"
codesign --verify --deep --strict --verbose=2 "$STAGING_APP"

if [[ -e "$APP" ]]; then
    mv "$APP" "$BACKUP_APP"
fi
if ! mv "$STAGING_APP" "$APP"; then
    echo "Failed to install verified app at $APP" >&2
    exit 1
fi
rm -rf "$BACKUP_APP"

echo "$APP"
