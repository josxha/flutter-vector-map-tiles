import 'package:executor_lib/executor_lib.dart';
import 'package:flutter/material.dart';
import 'package:vector_map_tiles/src/loader/caching_tile_loader.dart';

import '../cache/cache_tiered.dart';
import '../loader/default_tile_loader.dart';
import '../loader/tile_loader.dart';
import '../model/map_properties.dart';
import '../model/tile_data_model.dart';
import 'abstract_map_layer_state.dart';
import 'tile_widget.dart';

class MapTilesLayer extends AbstractMapLayer {
  const MapTilesLayer({super.key, required super.mapProperties})
    : super(tileLoaderFactory: createCachingTileLoader);

  @override
  State<StatefulWidget> createState() => MapTilesLayerState();
}

class MapTilesLayerState extends AbstractMapLayerState<MapTilesLayer> {
  @override
  Widget build(BuildContext context) {
    updateTiles(context);
    return Stack(
      children: mapTiles.tileModels
          .where((m) => m.isDisplayReady)
          .map(_toTile)
          .toList(),
    );
  }

  Widget _toTile(TileDataModel model) {
    final tilePosition = model.tilePosition;
    return Positioned(
      left: tilePosition.position.topLeft.dx,
      top: tilePosition.position.topLeft.dy,
      width: tilePosition.position.size.width,
      height: tilePosition.position.size.height,
      child: TileWidget(mapProperties: widget.mapProperties, model: model),
    );
  }
}
