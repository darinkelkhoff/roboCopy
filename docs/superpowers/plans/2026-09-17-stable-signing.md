# Stable Development Signing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Sign local RoboCopy builds with an installed Apple Development identity so macOS can recognize rebuilt versions as the same app for Accessibility permission.

**Architecture:** The build script automatically selects a sole installed Apple Development identity. An environment override resolves multiple identities or chooses another identity, while machines without a development identity fall back to ad-hoc signing with a warning.

**Tech Stack:** Bash, macOS `security`, macOS `codesign`

---

### Task 1: Verify Stable Identity Signing

**Files:**
- Create: `scripts/verify-signing.sh`
- Modify: `scripts/build-macos-app.sh`
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-09-17-robocopy-design.md`

- [ ] **Step 1: Add a failing signing verifier**

Reject ad-hoc signatures, missing team identifiers, and designated requirements based only on a CDHash.

- [ ] **Step 2: Confirm the current ad-hoc build fails verification**

Run: `bash scripts/verify-signing.sh dist/RoboCopy.app`

Expected: FAIL with `Expected identity signing, found an ad-hoc signature`.

- [ ] **Step 3: Use the installed Apple Development identity by default**

Discover Apple Development identities with `security find-identity`. Select a sole match automatically, require `ROBOCOPY_SIGNING_IDENTITY` when multiple matches exist, fall back to ad-hoc signing when no match exists, and allow `-` as an explicit ad-hoc override.

- [ ] **Step 4: Rebuild and verify the signature**

Run: `scripts/build-macos-app.sh && bash scripts/verify-signing.sh dist/RoboCopy.app`

Expected: the app is signed by Apple Development, reports a team identifier, and has a certificate-and-identifier designated requirement.

- [ ] **Step 5: Verify the designated requirement remains stable**

Capture `codesign --display --requirements -` output, rebuild, and compare the designated requirement after the second build.

Expected: both designated requirements are identical.

- [ ] **Step 6: Run regression verification**

Run: `swift test && swift scripts/verify-menu-icon.swift dist/RoboCopy.app/Contents/Resources/MenuBarIconTemplate.png && codesign --verify --deep --strict --verbose=2 dist/RoboCopy.app`

Expected: all tests and verification commands pass.
