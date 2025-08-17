import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../layout/tile_position.dart';
import '../tile_identity.dart';

class TileDataModel {
  late final TileIdentity tile;
  TilePosition tilePosition;
  bool _displayReady = false;
  Tileset? tileset;
  RasterTileset? rasterTileset;

  TileDataModel(this.tilePosition) : tile = tilePosition.tile;

  bool get isDisplayReady => _displayReady;
  set displayReady(bool newReady) => _displayReady = newReady;

  void dispose() {
    _displayReady = false;
    rasterTileset?.dispose();
    rasterTileset = null;
    tileset = null;
  }
}
