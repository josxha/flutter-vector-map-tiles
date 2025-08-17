import 'package:executor_lib/executor_lib.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../cache/cache.dart';
import '../model/map_properties.dart';
import '../model/tile_data_model.dart';
import 'raster_tile_loader.dart';
import 'tile_loader.dart';
import 'vector_tile_loader.dart';

class DefaultTileLoader extends TileLoader {
  final double tileSize;
  final MapProperties mapProperties;
  final Cache cache;
  final Executor executor;
  const DefaultTileLoader({
    required this.tileSize,
    required this.mapProperties,
    required this.executor,
    required this.cache,
  });

  @override
  Future<void> load(TileDataModel model, bool Function() cancelled) async {
    RasterTileset? rasterTileset;
    try {
      final tileset = await VectorTileLoader(
        tileSize: tileSize,
        mapProperties: mapProperties,
        executor: executor,
        cache: cache,
      ).load(model.tile, cancelled);
      rasterTileset = await RasterTileLoader(
        mapProperties: mapProperties,
        cache: cache,
      ).load(model.tile, cancelled);

      model.tileset = tileset;
      model.rasterTileset = rasterTileset;
      model.displayReady = true;
    } catch (e) {
      rasterTileset?.dispose();
      rethrow;
    }
  }
}
