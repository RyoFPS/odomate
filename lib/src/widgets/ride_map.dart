import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../domain/models.dart';
import '../i18n/app_localizations.dart';

class RideMap extends StatefulWidget {
  final List<GeoPoint> points;
  final bool followCurrentLocation;
  final double height;
  final TileProvider? tileProvider;
  final double? gpsAccuracyMeters;

  const RideMap({
    super.key,
    required this.points,
    required this.followCurrentLocation,
    required this.height,
    this.tileProvider,
    this.gpsAccuracyMeters,
  });

  @override
  State<RideMap> createState() => _RideMapState();
}

class _RideMapState extends State<RideMap> {
  final MapController _controller = MapController();
  final StreamController<void> _tileReset = StreamController<void>.broadcast();
  var _mapReady = false;
  var _isFollowing = true;
  var _hasTileError = false;

  @override
  void dispose() {
    _tileReset.close();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RideMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasNewPoint =
        oldWidget.points.length != widget.points.length ||
        (widget.points.isNotEmpty &&
            oldWidget.points.isNotEmpty &&
            oldWidget.points.last != widget.points.last);
    if (widget.followCurrentLocation && _isFollowing && hasNewPoint) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnLatest());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      final colors = Theme.of(context).colorScheme;
      return SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            Center(
              key: const ValueKey('ride-map-empty'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, color: colors.onSurfaceVariant),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context).t('route_unavailable'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).t('route_unavailable_hint'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (widget.followCurrentLocation) _gpsStatus(context),
          ],
        ),
      );
    }

    final colors = Theme.of(context).colorScheme;
    final points = widget.points.map(_latLng).toList(growable: false);
    return SizedBox(
      height: widget.height,
      child: FlutterMap(
        key: const ValueKey('ride-map'),
        mapController: _controller,
        options: MapOptions(
          initialCenter: points.first,
          initialZoom: 16,
          onMapReady: () {
            _mapReady = true;
            if (widget.followCurrentLocation) {
              _centerOnLatest();
            } else {
              _fitCamera();
            }
          },
          onPositionChanged: (_, hasGesture) {
            if (hasGesture && _isFollowing) {
              setState(() => _isFollowing = false);
            }
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.odomate',
            maxNativeZoom: 19,
            maxZoom: 19,
            tileProvider: widget.tileProvider,
            reset: _tileReset.stream,
            evictErrorTileStrategy: EvictErrorTileStrategy.notVisible,
            errorTileCallback: (_, _, _) {
              if (mounted && !_hasTileError) {
                setState(() => _hasTileError = true);
              }
            },
          ),
          if (points.length > 1)
            PolylineLayer(
              polylines: [
                Polyline(points: points, color: colors.primary, strokeWidth: 4),
              ],
            ),
          MarkerLayer(markers: _markers(context, points, colors)),
          const RichAttributionWidget(
            attributions: [
              TextSourceAttribution('© OpenStreetMap contributors'),
            ],
          ),
          if (_hasTileError)
            Positioned(
              top: 12,
              left: 12,
              right: 64,
              child: _MapOfflineBanner(
                onRetry: () {
                  setState(() => _hasTileError = false);
                  _tileReset.add(null);
                },
              ),
            ),
          if (widget.followCurrentLocation) _gpsStatus(context),
          if (widget.followCurrentLocation)
            Positioned(
              top: 12,
              right: 12,
              child: _MapControlButton(
                key: const ValueKey('ride-map-recenter'),
                tooltip: AppLocalizations.of(context).t('recenter_map'),
                icon: Icons.my_location,
                onPressed: () {
                  setState(() => _isFollowing = true);
                  _centerOnLatest();
                },
              ),
            )
          else if (points.length > 1)
            Positioned(
              top: 12,
              right: 12,
              child: _MapControlButton(
                key: const ValueKey('ride-map-fit-route'),
                tooltip: AppLocalizations.of(context).t('fit_route'),
                icon: Icons.fit_screen_outlined,
                onPressed: _fitCamera,
              ),
            ),
        ],
      ),
    );
  }

  List<Marker> _markers(
    BuildContext context,
    List<LatLng> points,
    ColorScheme colors,
  ) {
    final l10n = AppLocalizations.of(context);
    final start = Marker(
      point: points.first,
      width: 36,
      height: 36,
      child: Tooltip(
        message: l10n.t('route_start'),
        child: Icon(
          Icons.trip_origin,
          key: const ValueKey('ride-map-start'),
          color: colors.tertiary,
          size: 28,
        ),
      ),
    );
    if (points.length == 1) return [start];
    return [
      start,
      Marker(
        point: points.last,
        width: 40,
        height: 40,
        child: Tooltip(
          message: l10n.t('route_end'),
          child: Icon(
            Icons.location_on,
            key: const ValueKey('ride-map-end'),
            color: colors.primary,
            size: 32,
          ),
        ),
      ),
    ];
  }

  void _fitCamera() {
    if (!_mapReady || widget.points.isEmpty) return;
    final points = widget.points.map(_latLng).toList(growable: false);
    if (points.length == 1) {
      _controller.move(points.first, 16);
      return;
    }
    _controller.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(32),
        maxZoom: 17,
      ),
    );
  }

  void _centerOnLatest() {
    if (!_mapReady || widget.points.isEmpty) return;
    _controller.move(_latLng(widget.points.last), 16);
  }

  Positioned _gpsStatus(BuildContext context) => Positioned(
    left: 12,
    bottom: 12,
    child: _GpsStatusBadge(accuracyMeters: widget.gpsAccuracyMeters),
  );

  static LatLng _latLng(GeoPoint point) =>
      LatLng(point.latitude, point.longitude);
}

class _GpsStatusBadge extends StatelessWidget {
  final double? accuracyMeters;

  const _GpsStatusBadge({required this.accuracyMeters});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    late final String label;
    late final IconData icon;
    late final Color background;
    late final Color foreground;
    if (accuracyMeters == null) {
      label = l10n.t('waiting_for_gps');
      icon = Icons.gps_not_fixed;
      background = colors.surfaceContainerHigh;
      foreground = colors.onSurface;
    } else if (accuracyMeters! <= 20) {
      label = l10n.t('gps_accurate_short');
      icon = Icons.gps_fixed;
      background = colors.tertiaryContainer;
      foreground = colors.onTertiaryContainer;
    } else if (accuracyMeters! <= 50) {
      label = l10n.t('gps_signal_weak');
      icon = Icons.gps_not_fixed;
      background = colors.secondaryContainer;
      foreground = colors.onSecondaryContainer;
    } else {
      label = l10n.t('waiting_for_accurate_gps');
      icon = Icons.gps_off;
      background = colors.errorContainer;
      foreground = colors.onErrorContainer;
    }
    return Material(
      key: const ValueKey('ride-map-gps-status'),
      color: background,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapOfflineBanner extends StatelessWidget {
  final VoidCallback onRetry;

  const _MapOfflineBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Material(
      key: const ValueKey('ride-map-offline'),
      color: colors.errorContainer,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.only(left: 12, top: 6, right: 4, bottom: 6),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: colors.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.t('map_offline'),
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: colors.onErrorContainer),
              ),
            ),
            IconButton(
              key: const ValueKey('ride-map-retry'),
              tooltip: l10n.t('retry_map'),
              onPressed: onRetry,
              icon: Icon(Icons.refresh, color: colors.onErrorContainer),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _MapControlButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHigh,
      elevation: 2,
      shape: const CircleBorder(),
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: colors.onSurface),
        ),
      ),
    );
  }
}
