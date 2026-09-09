# OdoMate Modern UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the new Stitch-inspired modern utility UI to the existing OdoMate Flutter screens.

**Architecture:** Keep the current screen and domain structure. Centralize colors, typography, component shapes, app bars, cards, buttons, navigation, and input styling in `app.dart`, then make minimal owning-screen layout edits where hierarchy needs to change.

**Tech Stack:** Flutter Material 3, Dart, existing `google_fonts` dependency, existing repository/tracker/localization contracts.

**Spec:** `docs/superpowers/specs/2026-09-10-odomate-modern-ui-design.md`

## Global Constraints

- Light modern utility UI with `#F8FAFC`, `#FFFFFF`, `#E2E8F0`, and `#2563EB`.
- Preserve existing navigation, ride tracking, persistence, localization, and callbacks.
- Do not add dependencies or new abstractions.
- Maintain 48px minimum touch targets and accessible contrast.

### Task 1: Shared theme and navigation

**Files:**
- Modify: `lib/src/app.dart`

- [ ] Update light/dark `ThemeData` with the Stitch palette, Inter typography, page background, card/input/button shapes, app-bar styling, and consistent visual density.
- [ ] Restyle the existing bottom navigation and centered FAB without changing indices or callbacks.
- [ ] Run `flutter analyze`.

### Task 2: Home dashboard

**Files:**
- Modify: `lib/src/screens/home_screen.dart`

- [ ] Recompose the existing data into a Stitch-like header, odometer hero, ride-status action area, compact metrics, quick links, and service summary cards.
- [ ] Preserve notification sheet, odometer correction, tracker listener, and Home navigation callbacks.
- [ ] Run the relevant existing widget tests and `flutter analyze`.

### Task 3: Supporting screens

**Files:**
- Modify: `lib/src/screens/history_screen.dart`
- Modify: `lib/src/screens/services_screen.dart`
- Modify: `lib/src/screens/statistics_screen.dart`
- Modify: `lib/src/screens/profile_screen.dart`
- Modify: `lib/src/screens/settings_screen.dart`
- Modify: `lib/src/screens/setup_screen.dart`

- [ ] Apply the same section spacing, card borders, status treatments, app-bar hierarchy, and button/input styling.
- [ ] Preserve all existing service CRUD/detail flows, statistics period selection, profile save/photo, settings, and setup behavior.
- [ ] Run `flutter test` and `flutter analyze`.

### Task 4: Final verification

**Files:**
- No new files.

- [ ] Run `flutter test`.
- [ ] Run `flutter analyze`.
- [ ] Run `git diff --check`.
- [ ] Review the diff for unrelated behavior or generated artifacts.
