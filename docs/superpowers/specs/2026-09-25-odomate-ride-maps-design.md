# OdoMate Ride Maps Design

## Goal

Add a Google Maps Timeline-like ride route experience without putting maps in
the history list:

- Home shows a live map only while a ride is active.
- History remains a lightweight list of rides.
- Ride Detail shows the saved route on an interactive map.

## Current state

`RideTracker` receives `GeoPoint` values and uses them for distance
calculation, but only keeps the last point in memory. `Ride` stores summary
fields, not coordinates. The ride detail route section is a themed
`CustomPaint` placeholder, so existing rides have no route data to render.

## Proposed design

### Data flow

1. The tracker accepts a GPS point using the existing accuracy and distance
   filtering rules.
2. The accepted point is written to local storage for the active ride.
3. The tracker publishes the current ride plus route points through the
   existing notifier flow.
4. Home renders the current points while tracking.
5. Ride Detail loads points by ride id and renders them as a polyline with
   start and finish markers.

Only accepted points are stored. This reuses the current 5-meter location
filter and avoids persisting every raw GPS callback.

### Persistence

Add a `ride_points` table:

- `id INTEGER PRIMARY KEY`
- `ride_id INTEGER NOT NULL`
- `latitude REAL NOT NULL`
- `longitude REAL NOT NULL`
- `accuracy_m REAL NOT NULL`
- `recorded_at TEXT NOT NULL`

Add a database migration and repository methods to append, load, and delete
points. Deleting a ride must delete its points. Duplicating a ride keeps the
summary only; it does not copy the original GPS trace.

Older rides without points show a localized empty-map state instead of a
fabricated route.

### Map implementation

Use one map widget implementation shared by Home and Ride Detail. The first
implementation should use an existing lightweight Flutter map package with
OpenStreetMap tiles, avoiding a Google Maps API key and platform setup.
Map tiles require network access; route data remains local. Offline tile
caching is explicitly out of scope for this slice.

Home uses the map in a compact active-ride section with the current position,
the route polyline, and automatic camera follow. The map is absent when no
ride is active.

Ride Detail uses a larger interactive map with the full route, start/end
markers, fit-to-route camera, and normal pan/zoom gestures. The existing
placeholder painter and disabled zoom button are removed from the active
route path.

### Error and lifecycle behavior

- No active GPS fix: show the existing waiting-for-GPS state; do not add a
  fake point.
- Map tile failure: keep the route data and show the map's native empty/error
  surface; ride tracking must continue.
- Force close/relaunch: restore the active ride and its saved points before
  resuming tracking.
- Stop ride: save the final accepted point, stop live updates, and retain the
  route for Detail.
- Permission denial: preserve the existing permission error flow.

## Scope exclusions

- No map thumbnail in History.
- No route editing or point correction.
- No turn-by-turn navigation, route matching, traffic, or elevation.
- No cloud sync or account-backed timeline.
- No offline map tile cache in the first version.

## Testing and acceptance

Automated tests should cover:

- point insert/load/delete by ride;
- accepted tracker points are persisted;
- rejected inaccurate/no-distance points are not persisted;
- active ride restore includes its route points;
- duplicate ride does not copy points;
- detail shows the empty state when a ride has no points.

Manual emulator/device QA should verify:

- live marker/polyline updates during an active ride;
- force close and relaunch resumes both distance and route;
- stopping a ride leaves a complete route in Detail;
- map gestures and fit-to-route work in light and dark themes;
- tile failure does not stop tracking;
- History remains responsive without embedded maps.

## Acceptance criteria

The feature is complete when a newly recorded ride displays its live route on
Home, the same route is persisted across force close, and Ride Detail shows
the saved route interactively with start/end markers. Existing rides remain
usable and clearly indicate when route data is unavailable.
