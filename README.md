# RoboCopy

RoboCopy adds iTerm-style mouse copy-on-select behavior to explicitly allowed macOS applications.

## Requirements

- macOS 14 or later
- Xcode 15.3 or later, or equivalent Xcode Command Line Tools

## Build

```bash
scripts/build-macos-app.sh
```

The app is written to `dist/RoboCopy.app`. Move it to `/Applications` before enabling Launch at Login so macOS has a stable bundle location.

The build uses an ad-hoc signature for local use. It is not signed with a Developer ID or notarized for distribution.

## Use

1. Launch RoboCopy and grant Accessibility access when prompted.
2. Focus the application you want to configure.
3. Open RoboCopy's menu bar menu and enable `Auto-copy in <App Name>`.
4. Drag-select, double-click, or triple-click text in that application.

Single clicks and selections in applications outside the allowlist are ignored.

RoboCopy observes global left-mouse gestures and the active application's identity. It stores only the allowlist and app settings locally. Selected text is never read or logged; the target application handles the Command-C action. RoboCopy has no network behavior.

## Development

```bash
swift test
swift build
```
