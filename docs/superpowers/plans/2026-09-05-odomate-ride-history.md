# OdoMate Ride History & Trip Details Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the existing History screen with localized period filters, ride summary cards, and a ride detail page.

**Architecture:** Reuse `Ride`, `OdomateRepository.listRides()`, and the existing `StatisticsPeriod`/calculator. Keep filtering and duration formatting in small pure helpers so the UI remains testable. Do not add a database table, route map, or delete operation.

**Tech Stack:** Flutter/Dart, Material 3, existing sqflite repository, existing localization and navigation shell.

**Spec:** `docs/superpowers/specs/2026-09-05-odomate-ride-history-design.md`

## Global Constraints

- Local-only and offline-first.
- Preserve the existing five-slot navigation and circular Start Ride FAB.
- Do not change GPS tracking, odometer update, or ride persistence semantics.
- Use local device dates and one decimal place for kilometers.
- All new copy uses ID/EN/JA localization.
- Do not add charts, maps, backend, or new dependencies.
- Do not add ride deletion until odometer reversal semantics are explicitly designed.

### Task 1: Add pure history filter and display rules

**Files:**
- Create or modify: `lib/src/domain/ride_history.dart`
- Test: `test/domain/ride_history_test.dart`

- [ ] Define the smallest helper for filtering rides by `all`, today, seven days, and current month.
- [ ] Reuse the existing `StatisticsPeriod` boundaries where possible instead of duplicating date math.
- [ ] Add duration formatting rules for completed and active rides.
- [ ] Write boundary tests for local dates, active rides, and zero-distance rides.
- [ ] Run the focused test and verify the expected failure before implementation.
- [ ] Implement the helper and run the focused test until green.
- [ ] Commit the domain helper and tests.

### Task 2: Build localized ride cards and detail screen

**Files:**
- Modify: `lib/src/screens/history_screen.dart`
- Create: `lib/src/screens/ride_detail_screen.dart`
- Modify: `lib/src/i18n/app_localizations.dart`
- Test: `test/screens/history_screen_test.dart`

- [ ] Add localization keys for history filters, ride date/time, duration, active status, detail labels, empty state, loading, and error.
- [ ] Write widget tests for default all-history rendering, period switching, empty/error states, active ride, and populated ride cards.
- [ ] Run the focused widget test and verify the expected failure before implementation.
- [ ] Load rides once per screen state and render localized summary cards.
- [ ] Open `RideDetailScreen` from a card and render the selected ride without refetching unrelated data.
- [ ] Add a back button on the detail AppBar while preserving the global bottom navigation outside the detail flow.
- [ ] Run focused screen tests and verify they pass.

### Task 3: Integrate existing navigation and Home entry

**Files:**
- Modify: `lib/src/screens/home_screen.dart`
- Modify: `lib/src/app.dart`
- Modify or create: `test/screens/navigation_test.dart`

- [ ] Make the existing Home Riwayat card open the History tab using its current callback/index.
- [ ] Preserve the four labeled bottom-nav destinations around the centered Start Ride FAB.
- [ ] Verify Statistics internal navigation remains reachable from Home after the History changes.
- [ ] Add a widget test proving Home opens History and the ride action remains present.
- [ ] Run all screen tests.

### Task 4: Final verification and APK handoff

- [ ] Run `dart format lib test`.
- [ ] Run `flutter analyze` and fix only feature-related issues.
- [ ] Run `flutter test`.
- [ ] Run `git diff --check`.
- [ ] Run `flutter build apk --debug`.
- [ ] Manually verify all filters, detail/back flow, active ride, empty/error state, ID/EN/JA, light/dark theme, and unchanged Start Ride behavior on the emulator.
- [ ] Commit the completed feature with a Conventional Commit message.
