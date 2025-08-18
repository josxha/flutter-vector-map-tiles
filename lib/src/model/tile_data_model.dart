import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../layout/tile_position.dart';
import '../tile_identity.dart';

class TileDataModel {
  late final TileIdentity tile;
  TilePosition tilePosition;
  bool isLoaded = false;
  bool isDisplayReady = false;
  Tileset? tileset;
  RasterTileset? rasterTileset;

  TileDataModel(this.tilePosition) : tile = tilePosition.tile;

  void dispose() {
    isLoaded = false;
    isDisplayReady = false;
    rasterTileset?.dispose();
    rasterTileset = null;
    tileset = null;
  }
}
