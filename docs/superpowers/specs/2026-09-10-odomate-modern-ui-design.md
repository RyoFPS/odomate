# OdoMate Modern UI Design

## Goal

Create a new modern visual layer for OdoMate using Google Stitch as the design source, while preserving the existing ride tracking, navigation, persistence, localization, and service-management behavior.

## Visual direction

- Light modern utility UI inspired by the new Stitch project `OdoMate Modern UI`.
- Background `#F8FAFC`, white surfaces, thin `#E2E8F0` borders.
- Primary `#2563EB`, success `#15803D`, warning `#D97706`, danger `#DC2626`.
- Inter typography, 4px spacing rhythm, 12–16px card radii, restrained shadows.
- Strong odometer and ride-status hierarchy; status colors are reserved for meaning.
- Minimum touch target: 48px. No gradients or glassmorphism.

## Scope

Refresh the shared Material 3 theme and the existing screens: Home, History, Services, Service Detail, Statistics, Profile, Settings, and Setup. Keep the current four bottom tabs and the centered Start/Stop Ride action. Statistics remains an internal Home shortcut at index 4.

## Constraints

- Do not add dependencies or new state-management abstractions.
- Preserve repository and tracker interfaces, callbacks, loading/error states, and form semantics.
- Keep Indonesian localization behavior; existing hard-coded labels may be restyled without changing their meaning.
- Use existing Flutter Material widgets and shared theme tokens.

## Verification

Run `flutter analyze` and the existing test suite. Confirm navigation callbacks, ride start/stop, odometer correction, service add/edit/delete/detail, profile save/photo, theme mode, and language callbacks remain wired.
