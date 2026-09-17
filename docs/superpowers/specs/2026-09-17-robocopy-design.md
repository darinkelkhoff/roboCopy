# RoboCopy Design

## Summary

RoboCopy is a native macOS menu bar utility that automatically copies text selected with the mouse in explicitly allowed applications. Its initial focus is terminal-style applications, including embedded terminals in Codex and Claude, where users expect iTerm-like copy-on-select behavior.

RoboCopy observes mouse selection gestures and sends `Command-C` after the target application has finalized its selection. It uses the target application's own copy implementation instead of attempting to extract terminal text through the Accessibility hierarchy.

Version 1 targets macOS 14 and later.

## Goals

- Copy mouse-selected text automatically in user-approved applications.
- Support drag selection, double-click selection, and triple-click selection.
- Keep normal selection behavior unchanged in all applications not on the allowlist.
- Provide simple controls from the macOS menu bar.
- Require no hotkey or additional action after selecting text.
- Keep all configuration local to the Mac.

## Non-Goals

- Copying selections made only with the keyboard.
- Maintaining clipboard history.
- Restoring the previous clipboard contents when a copy fails.
- Reading selected terminal text directly through Accessibility APIs.
- Providing a modifier-key bypass in version 1.
- Synchronization, analytics, accounts, or network access.

## User Experience

RoboCopy runs as a menu-bar-only application with no Dock icon and no persistent main window. It remembers the last active application other than RoboCopy so its menu can offer a contextual item such as `Auto-copy in Codex`.

The user-provided `roboCopy.svg` is the canonical visual asset. The release build generates a full macOS `.icns` file from that source for the application bundle. The menu bar uses a separate monochrome, transparent template derivative so macOS can adapt it to light and dark menu bars. This derivative contains two identical faces with 50 percent horizontal overlap; the left face sits about two rendered pixels lower than the right in the 23-by-18-point image. Each face preserves the source artwork's outlined round head, solid upper dome, curved transparent visor, white lower face, and small curved mouth; the visor sits high enough in the dome to remain distinct from the horizontal face division at native scale. Generated raster sizes and `.icns` output are build artifacts; only the source SVG assets are committed.

Local release builds automatically use the sole installed Apple Development identity. This gives rebuilt versions a stable designated requirement so macOS can preserve privacy permissions. An environment override selects a specific identity when multiple identities exist. When no development identity is available, the build warns and falls back to ad-hoc signing.

The menu contains:

- A global enabled toggle.
- A toggle for the last active application.
- An `Allowed Apps` submenu that lists each allowed application; selecting an entry removes it.
- Accessibility permission status and an action that opens the appropriate System Settings pane when permission is missing.
- A Launch at Login toggle.
- Quit.

Applications are identified and stored by bundle identifier. A display name is retained only for presentation. If an application has no bundle identifier, RoboCopy will not add it to the allowlist and will communicate that limitation in the menu.

## Selection Behavior

RoboCopy observes global left-mouse events. A gesture qualifies for automatic copying when all of the following are true:

1. RoboCopy is enabled.
2. The application active at mouse-down is on the allowlist.
3. The same application remains active through mouse-up and the delayed copy.
4. The gesture is either:
   - A drag whose straight-line distance from mouse-down reaches at least 4 points.
   - A double-click or triple-click, represented by a click count of at least two.

Ordinary single clicks, right-clicks, and mouse gestures in applications outside the allowlist are ignored.

After a qualifying mouse-up, RoboCopy waits 40 milliseconds so the target application can finalize its selection. It then synthesizes `Command-C`. If the target application closes or loses focus before dispatch, RoboCopy cancels the copy.

Modifier state is recorded with the gesture but does not alter behavior in version 1. This leaves room for a future temporary bypass without changing the gesture-recognition boundary.

## Architecture

The application is implemented in Swift using AppKit and macOS system frameworks. It consists of the following focused components:

### Gesture Monitor

Observes global left-mouse down, drag, and up events. It records the mouse-down position, click count, modifier flags, and owning frontmost application. It emits a qualifying selection gesture only when the drag threshold or multi-click rule is met.

### Frontmost Application Tracker

Tracks application activation through `NSWorkspace` and retains the most recent non-RoboCopy application. It supplies stable application identity to both the gesture monitor and menu UI.

### Allowlist Store

Persists allowed bundle identifiers and their display names in `UserDefaults`. It exposes add, remove, membership, and listing operations without coupling callers to the storage format.

### Copy Dispatcher

Receives a qualifying gesture and schedules the delayed copy. Immediately before dispatch, it verifies that RoboCopy remains enabled, Accessibility permission is available, and the original target application is still frontmost. It then creates and posts the keyboard events for `Command-C`.

### Permission Controller

Checks Accessibility trust and requests it on first launch. It exposes permission state and a System Settings recovery action to the menu UI for users who initially decline or later revoke access.

### Menu Controller

Builds the status-item menu from current enabled, permission, frontmost-application, and allowlist state. It owns no gesture or copy behavior.

## Data Flow

1. A left-mouse gesture begins in the frontmost application.
2. The gesture monitor captures the target bundle identifier and gesture details.
3. On mouse-up, the monitor validates the gesture and allowlist membership.
4. A qualifying gesture is passed to the copy dispatcher.
5. After the short delay, the dispatcher revalidates enabled state, permission, and focus.
6. The dispatcher posts `Command-C` to the active target application.
7. The target application places its selected content on the system pasteboard using its native copy behavior.

## Permissions And Privacy

RoboCopy requires macOS Accessibility permission to synthesize keyboard input. Version 1 requests only this permission. Global mouse observation uses AppKit's event monitor. If verification on macOS 14 or later shows that Input Monitoring is also required, implementation pauses for a design amendment rather than silently adding another permission.

RoboCopy does not inspect, retain, transmit, or log selected text. The target application writes directly to the system pasteboard in response to `Command-C`.

## Error Handling

Normal runtime failures are non-disruptive:

- Missing Accessibility permission prevents copy dispatch and is shown in the menu.
- Failure to create or post an input event results in no copy.
- A target application closing or losing focus cancels the pending copy.
- An unsupported application identity cannot be added to the allowlist.
- Malformed persisted allowlist entries are ignored rather than preventing launch.

RoboCopy will not display notifications for individual failed copy attempts.

## Testing

Unit tests will cover:

- Drag distance above, below, and exactly at the threshold.
- Double-click and triple-click recognition.
- Ignoring ordinary single clicks and right-clicks.
- Allowlist membership and persistence by bundle identifier.
- Global disabled state.
- Cancellation when focus changes during the dispatch delay.
- Cancellation when Accessibility permission is unavailable.
- Corrupt or incomplete stored allowlist entries.

System integration boundaries will be represented by protocols so gesture recognition, focus validation, and copy dispatch can be tested without posting real global input.

Manual verification will cover:

- Drag, double-click, and triple-click selection in Codex, Claude, Terminal, and other locally installed terminal emulators.
- No automatic copy in applications outside the allowlist.
- Adding and removing the last active application from the menu.
- Enabling and disabling RoboCopy globally.
- Accessibility onboarding and recovery after permission is revoked.
- Launch at Login behavior.

## Future Work

Potential later additions include a modifier-key bypass, keyboard-selection support, configurable copy delay, configurable drag threshold, and richer allowlist management. These are intentionally excluded from version 1.
