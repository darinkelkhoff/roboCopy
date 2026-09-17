# Menu Bar Icon Revision Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the cramped menu icon with the approved pair of faithful RoboCopy faces at 50 percent overlap and a two-pixel vertical offset.

**Architecture:** Keep the full application icon unchanged. Replace only the monochrome template SVG, render it at 2x for a 23-by-18-point status image, and widen the `NSStatusItem` to match.

**Tech Stack:** Swift 5.10, AppKit, SVG, SwiftPM, shell packaging script

---

### Task 1: Add Native-Scale Icon Verification

**Files:**
- Create: `scripts/verify-menu-icon.swift`

- [ ] **Step 1: Write a verifier that requires a 46-by-36-pixel image with transparency and visible artwork**

The script loads the generated PNG with `NSBitmapImageRep`, rejects dimensions other than 46 by 36, and checks that the image is neither empty nor an opaque rectangle.

- [ ] **Step 2: Run the verifier against the existing build output**

Run: `swift scripts/verify-menu-icon.swift dist/RoboCopy.app/Contents/Resources/MenuBarIconTemplate.png`

Expected: FAIL because the existing image is 36 by 36 pixels.

### Task 2: Implement the Approved Two-Face Asset

**Files:**
- Modify: `Resources/MenuBarIconTemplate.svg`
- Modify: `scripts/build-macos-app.sh`
- Modify: `Sources/RoboCopy/MenuController.swift`

- [ ] **Step 1: Replace the template SVG**

Use a `28.6 22.4` view box containing two identical circular faces with 50 percent horizontal overlap. Lower the left face by 2.4 view-box units, cut the raised visors out of the solid upper domes, and draw the lower mouths as separate round-capped strokes.

- [ ] **Step 2: Render the menu image at 46 by 36 pixels**

Extend `render-svg.swift` to accept independent pixel width and height values, then update the build script to render the status image at 46 by 36 pixels.

- [ ] **Step 3: Widen the status item and preserve native image sizing**

Create the status item with a fixed 27-point length and set the loaded image size to 23 by 18 points.

- [ ] **Step 4: Rebuild and run the verifier**

Run: `scripts/build-macos-app.sh && swift scripts/verify-menu-icon.swift dist/RoboCopy.app/Contents/Resources/MenuBarIconTemplate.png`

Expected: the build and icon verification both exit successfully.

- [ ] **Step 5: Run regression tests and signing verification**

Run: `swift test && codesign --verify --deep --strict --verbose=2 dist/RoboCopy.app`

Expected: all tests pass and code signing verification exits successfully.

- [ ] **Step 6: Visually inspect the generated PNG at original and enlarged scale**

Confirm two identical, separated faces remain legible and that the raised visors do not merge with the center division.
