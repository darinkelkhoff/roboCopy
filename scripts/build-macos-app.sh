#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$REPO_ROOT/dist/RoboCopy.app"
STAGING_APP="$REPO_ROOT/dist/.RoboCopy.app.staging"
BACKUP_APP="$REPO_ROOT/dist/.RoboCopy.app.backup"
STAGING_CONTENTS="$STAGING_APP/Contents"
ICON_WORK="$REPO_ROOT/.build/robocopy-icons"
ICONSET="$ICON_WORK/RoboCopy.iconset"
MASTER="$ICON_WORK/AppIcon-1024.png"
AVAILABLE_IDENTITIES="$(security find-identity -v -p codesigning)"

if [[ -n "${ROBOCOPY_SIGNING_IDENTITY:-}" ]]; then
    SIGNING_IDENTITY="$ROBOCOPY_SIGNING_IDENTITY"
    if [[ "$SIGNING_IDENTITY" != "-" ]] && \
        ! grep -Fq "\"$SIGNING_IDENTITY\"" <<<"$AVAILABLE_IDENTITIES"; then
        echo "Code-signing identity is not available: $SIGNING_IDENTITY" >&2
        exit 1
    fi
else
    DEVELOPMENT_IDENTITIES="$(
        sed -n 's/.*"\(Apple Development:[^"]*\)".*/\1/p' <<<"$AVAILABLE_IDENTITIES"
    )"
    IDENTITY_COUNT="$(awk 'NF { count++ } END { print count + 0 }' <<<"$DEVELOPMENT_IDENTITIES")"

    if [[ "$IDENTITY_COUNT" -eq 1 ]]; then
        SIGNING_IDENTITY="$DEVELOPMENT_IDENTITIES"
    elif [[ "$IDENTITY_COUNT" -eq 0 ]]; then
        SIGNING_IDENTITY="-"
        echo "Warning: no Apple Development identity found; using ad-hoc signing." >&2
    else
        echo "Multiple Apple Development identities found:" >&2
        printf '%s\n' "$DEVELOPMENT_IDENTITIES" >&2
        echo "Set ROBOCOPY_SIGNING_IDENTITY to the identity to use." >&2
        exit 1
    fi
fi

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

rm -rf "$ICON_WORK"
mkdir -p "$ICONSET"
swift scripts/render-svg.swift Resources/roboCopy.svg "$MASTER" 1024

render_icon() {
    local pixels="$1"
    local filename="$2"
    sips -z "$pixels" "$pixels" "$MASTER" --out "$ICONSET/$filename" >/dev/null
}

render_icon 16 icon_16x16.png
render_icon 32 icon_16x16@2x.png
render_icon 32 icon_32x32.png
render_icon 64 icon_32x32@2x.png
render_icon 128 icon_128x128.png
render_icon 256 icon_128x128@2x.png
render_icon 256 icon_256x256.png
render_icon 512 icon_256x256@2x.png
render_icon 512 icon_512x512.png
cp "$MASTER" "$ICONSET/icon_512x512@2x.png"

iconutil -c icns "$ICONSET" -o "$STAGING_CONTENTS/Resources/RoboCopy.icns"
swift scripts/render-svg.swift \
    Resources/MenuBarIconTemplate.svg \
    "$STAGING_CONTENTS/Resources/MenuBarIconTemplate.png" \
    46 \
    36

plutil -lint "$STAGING_CONTENTS/Info.plist"
echo "Signing RoboCopy with: $SIGNING_IDENTITY"
codesign --force --sign "$SIGNING_IDENTITY" "$STAGING_APP"
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
