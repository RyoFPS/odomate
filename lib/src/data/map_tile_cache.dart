import 'package:flutter_map/flutter_map.dart';

const _maxCacheSize = 256 * 1024 * 1024;

BuiltInMapCachingProvider _mapTileCache() =>
    BuiltInMapCachingProvider.getOrCreateInstance(maxCacheSize: _maxCacheSize);

void initializeMapTileCache() {
  _mapTileCache();
}

Future<void> clearMapTileCache() async {
  await _mapTileCache().destroy(deleteCache: true);
  _mapTileCache();
}
