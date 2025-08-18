import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import '../loader/caching_tile_loader.dart';
import '../model/map_properties.dart';
import '../model/tile_data_model.dart';
import 'abstract_map_layer_state.dart';

class MapLayer extends AbstractMapLayer {
  const MapLayer({super.key, required super.mapProperties})
    : super(tileLoaderFactory: createCachingTileLoader);

  @override
  State<StatefulWidget> createState() => MapLayerState();
}

class MapLayerState extends AbstractMapLayerState<MapLayer> {
  late final TilesRenderer tilesRenderer;
  var _ready = false;
  @override
  void initState() {
    super.initState();
    tilesRenderer = TilesRenderer();
    TilesRenderer.initialize.then(_initialized);
  }

  @override
  void dispose() {
    super.dispose();
    tilesRenderer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    updateTiles(context);
    if (!_ready) {
      return Container();
    }
    final tileModels = mapTiles.tileModels
        .where((it) => it.isDisplayReady)
        .toList(growable: false);
    final uiTiles = tileModels
        .map((it) => it.toUiModel())
        .toList(growable: false);
    tilesRenderer.update(widget.mapProperties.theme, zoom, uiTiles);

    return CustomPaint(
      key: Key(
        'mapTileLayer_${widget.mapProperties.theme.id}_${widget.mapProperties.theme.version}',
      ),
      painter: MapTilesPainter(widget.mapProperties, tilesRenderer),
      isComplex: true,
    );
  }

  FutureOr _initialized(void value) {
    if (mounted) {
      setState(() {
        _ready = true;
      });
    }
  }
}

class MapTilesPainter extends CustomPainter {
  final MapProperties properties;
  final TilesRenderer tilesRenderer;

  MapTilesPainter(this.properties, this.tilesRenderer);

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant MapTilesPainter oldDelegate) => true;
}

extension _TileDataModelUiExtension on TileDataModel {
  TileUiModel toUiModel() => TileUiModel(
    tileId: tile.toTileId(),
    position: tilePosition.position,
    tileset: tileset ?? Tileset({}),
    rasterTileset: rasterTileset ?? RasterTileset(tiles: {}),
  );
}

extension _TileIdExtension on TileIdentity {
  TileId toTileId() => TileId(z: z, x: x, y: y);
}
