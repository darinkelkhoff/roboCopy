#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$REPO_ROOT/dist/RoboCopy.app"
RELEASE_DIR="$REPO_ROOT/dist/release"
ARCHIVE="$RELEASE_DIR/RoboCopy-macos-arm64.zip"
CHECKSUM="$ARCHIVE.sha256"
NOTARY_ARCHIVE="$RELEASE_DIR/.RoboCopy-notarization.zip"
NOTARY_PROFILE="${ROBOCOPY_NOTARY_PROFILE:-notarytool}"

cd "$REPO_ROOT"

AVAILABLE_IDENTITIES="$(security find-identity -v -p codesigning)"
if [[ -n "${ROBOCOPY_DEVELOPER_ID_IDENTITY:-}" ]]; then
    DEVELOPER_ID_IDENTITY="$ROBOCOPY_DEVELOPER_ID_IDENTITY"
    if ! grep -Fq "\"$DEVELOPER_ID_IDENTITY\"" <<<"$AVAILABLE_IDENTITIES"; then
        echo "Developer ID identity is not available: $DEVELOPER_ID_IDENTITY" >&2
        exit 1
    fi
else
    DEVELOPER_ID_IDENTITIES="$(
        sed -n 's/.*"\(Developer ID Application:[^"]*\)".*/\1/p' <<<"$AVAILABLE_IDENTITIES"
    )"
    IDENTITY_COUNT="$(awk 'NF { count++ } END { print count + 0 }' <<<"$DEVELOPER_ID_IDENTITIES")"
    if [[ "$IDENTITY_COUNT" -ne 1 ]]; then
        echo "Expected exactly one Developer ID Application identity, found $IDENTITY_COUNT." >&2
        printf '%s\n' "$DEVELOPER_ID_IDENTITIES" >&2
        echo "Set ROBOCOPY_DEVELOPER_ID_IDENTITY to the identity to use." >&2
        exit 1
    fi
    DEVELOPER_ID_IDENTITY="$DEVELOPER_ID_IDENTITIES"
fi

VERSION="$(plutil -extract CFBundleShortVersionString raw Resources/Info.plist)"
if [[ -z "$VERSION" ]]; then
    echo "CFBundleShortVersionString is missing" >&2
    exit 1
fi

ROBOCOPY_SIGNING_IDENTITY="$DEVELOPER_ID_IDENTITY" scripts/build-macos-app.sh

ARCHS="$(lipo -archs "$APP/Contents/MacOS/RoboCopy")"
if [[ "$ARCHS" != "arm64" ]]; then
    echo "Expected an arm64 release binary, got: $ARCHS" >&2
    exit 1
fi

SIGNING_INFO="$(codesign --display --verbose=4 "$APP" 2>&1)"
grep -q '^Authority=Developer ID Application:' <<<"$SIGNING_INFO"
grep -Eq '^CodeDirectory .*flags=.*\(runtime\)' <<<"$SIGNING_INFO"

mkdir -p "$RELEASE_DIR"
rm -f "$NOTARY_ARCHIVE" "$ARCHIVE" "$CHECKSUM"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$NOTARY_ARCHIVE"

xcrun notarytool submit "$NOTARY_ARCHIVE" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait
xcrun stapler staple "$APP"

scripts/verify-distribution.sh "$APP"

ditto -c -k --sequesterRsrc --keepParent "$APP" "$ARCHIVE"
ARCHIVE_NAME="$(basename "$ARCHIVE")"
ARCHIVE_HASH="$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')"
printf '%s  %s\n' "$ARCHIVE_HASH" "$ARCHIVE_NAME" > "$CHECKSUM"

echo "Prepared RoboCopy $VERSION release:"
echo "$ARCHIVE"
echo "$CHECKSUM"
