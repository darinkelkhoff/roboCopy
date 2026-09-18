# GitHub Binary Release Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish RoboCopy 0.1.0 as a Developer ID-signed, notarized Apple-silicon download on GitHub Releases.

**Architecture:** Extend the existing app builder to enable hardened runtime and secure timestamping for Developer ID identities. A release script builds, notarizes, staples, verifies, archives, and checksums the app before GitHub upload.

**Tech Stack:** SwiftPM, Bash, `codesign`, `notarytool`, `stapler`, `spctl`, GitHub CLI

---

### Task 1: Verify Distribution Readiness

**Files:**
- Create: `scripts/verify-distribution.sh`

- [ ] Add checks for Developer ID authority, hardened runtime, valid code signature, stapled notarization ticket, and Gatekeeper acceptance.
- [ ] Run the verifier against the current Apple Development build and confirm it fails on the signing authority.

### Task 2: Build and Notarize a Release

**Files:**
- Modify: `scripts/build-macos-app.sh`
- Create: `scripts/release-macos.sh`

- [ ] Add hardened runtime and secure timestamp options when the selected identity is a Developer ID Application identity.
- [ ] Auto-select a sole Developer ID Application identity for releases.
- [ ] Build version `0.1.0`, archive it for notarization, submit with the `notarytool` profile, and wait for acceptance.
- [ ] Staple and validate the ticket, run distribution verification, then create `RoboCopy-macos-arm64.zip` and its SHA-256 file.

### Task 3: Publish and Document

**Files:**
- Modify: `README.md`

- [ ] Add a stable latest-release download link and installation instructions.
- [ ] Run unit, signature, notarization, Gatekeeper, and checksum verification.
- [ ] Commit and push the release tooling.
- [ ] Tag `v0.1.0` and create a public GitHub Release with the archive and checksum assets.
