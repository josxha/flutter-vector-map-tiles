import 'dart:typed_data';
import 'dart:ui';

import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import '../cache/cache.dart';
import '../model/map_properties.dart';
import '../tile_translation.dart';

class RasterTileLoader {
  final MapProperties mapProperties;
  final Cache cache;

  RasterTileLoader({required this.mapProperties, required this.cache});
  Future<RasterTileset> load(
    TileIdentity tile,
    bool Function() cancelled,
  ) async {
    final sourceTiles = mapProperties.theme.tileSources
        .map(
          (source) => MapEntry(source, mapProperties.tileProviders.get(source)),
        )
        .where((e) => e.value.type == TileProviderType.raster)
        .map((e) => _load(e.key, e.value, tile, cancelled));
    final tilesBySource = <String, RasterTile>{};
    dynamic exception;
    for (final sourceTileFuture in sourceTiles) {
      try {
        final sourceTile = await sourceTileFuture;
        final tile = sourceTile.tile;
        if (tile != null) {
          tilesBySource[sourceTile.source] = tile;
        }
      } on ProviderException catch (error) {
        if (error.statusCode == 404 || error.statusCode == 204) {
          //ignore
        } else {
          exception = error;
        }
      } catch (e) {
        exception = e;
      }
    }
    final tileset = RasterTileset(tiles: tilesBySource);
    if (exception != null) {
      tileset.dispose();
      throw exception;
    }
    return tileset;
  }

  Future<_SourceTile> _load(
    String source,
    VectorTileProvider provider,
    TileIdentity tile,
    bool Function() cancelled,
  ) async {
    if (tile.z < provider.minimumZoom) {
      return _SourceTile(source: source, tile: null);
    }
    var translation = TileTranslation.identity(tile.normalize());
    if (tile.z > provider.maximumZoom) {
      final translator = SlippyMapTranslator(provider.maximumZoom);
      translation = translator.specificZoomTranslation(
        translation.original,
        zoom: provider.maximumZoom,
      );
    }
    final themeKey = mapProperties.theme.id;
    final cacheKey = '${themeKey}_${source}_${tile.z}_${tile.x}_${tile.y}.png';
    final Uint8List bytes;
    try {
      bytes = await cache.get(
        cacheKey,
        load: (key) => provider.provide(translation.translated),
      );
    } on ProviderException catch (error) {
      if (error.statusCode == 404 || error.statusCode == 204) {
        return _SourceTile(source: source, tile: null);
      }
      rethrow;
    }
    final image = await imageFrom(bytes: bytes);
    var scope = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    if (translation.isTranslated) {
      final fraction = translation.fraction;
      final xDimension = scope.width / fraction;
      final yDimension = scope.height / fraction;
      scope = Rect.fromLTWH(
        xDimension * translation.xOffset,
        yDimension * translation.yOffset,
        xDimension,
        yDimension,
      );
    }
    return _SourceTile(
      source: source,
      tile: RasterTile(image: image, scope: scope),
    );
  }
}

class _SourceTile {
  final String source;
  final RasterTile? tile;

  _SourceTile({required this.source, required this.tile});
}

Future<Image> imageFrom({required Uint8List bytes}) async {
  final codec = await instantiateImageCodec(bytes);
  try {
    final frame = await codec.getNextFrame();
    return frame.image;
  } finally {
    codec.dispose();
  }
}
