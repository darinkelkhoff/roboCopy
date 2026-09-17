# RoboCopy

RoboCopy adds iTerm-style mouse copy-on-select behavior to explicitly allowed macOS applications.

## Requirements

- macOS 14 or later
- Xcode Command Line Tools

## Build

```bash
scripts/build-macos-app.sh
```

The app is written to `dist/RoboCopy.app`. Move it to `/Applications` before enabling Launch at Login so macOS has a stable bundle location.

## Use

1. Launch RoboCopy and grant Accessibility access when prompted.
2. Focus the application you want to configure.
3. Open RoboCopy's menu bar menu and enable `Auto-copy in <App Name>`.
4. Drag-select, double-click, or triple-click text in that application.

Single clicks and selections in applications outside the allowlist are ignored.

All RoboCopy configuration stays local. RoboCopy does not read or log selected text; the target application handles the Command-C action.

## Development

```bash
swift test
swift build
```
