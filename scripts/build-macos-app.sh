#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$REPO_ROOT/dist/RoboCopy.app"
CONTENTS="$APP/Contents"

cd "$REPO_ROOT"
swift build -c release
RELEASE_BIN_PATH="$(swift build -c release --show-bin-path)"

rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
cp "$RELEASE_BIN_PATH/RoboCopy" "$CONTENTS/MacOS/RoboCopy"
cp "Resources/Info.plist" "$CONTENTS/Info.plist"

codesign --force --deep --sign - "$APP"
echo "$APP"
