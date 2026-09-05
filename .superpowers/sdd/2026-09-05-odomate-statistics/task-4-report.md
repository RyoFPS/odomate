# Task 4 Report: Home and navigation integration

## Result

- Added a localized Home statistics card using the existing `RideStatistics` calculator for the default last-seven-days distance and ride count.
- Added `StatisticsScreen` to the app's internal page list at index 4.
- Kept the bottom navigation at exactly four labeled destinations around the existing centered Start Ride FAB: Home, Riwayat, Service, Profile.
- The Home card invokes the existing `onNavigate` callback with internal index 4; no second navigator key or duplicate FAB was added.
- Added a widget test proving the card opens `StatisticsScreen` and the Start Ride FAB remains present.

## Verification

- `flutter test test/screens/navigation_test.dart --concurrency=1` — passed (2 tests).
- `flutter analyze` — passed, no issues.
- `git diff --check` — passed.

## TDD evidence

The new navigation test was written first and initially failed because the card callback opened the wrong page. The implementation then redirected the callback to the internal Statistics page while preserving the four-slot bottom navigation; the focused test passed afterward.
