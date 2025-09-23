import 'dart:async';
import 'dart:isolate';

import 'package:executor_lib/executor_lib.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../../vector_map_tiles.dart';
import '../loader/caching_tile_loader.dart';
import '../loader/theme_repo.dart';
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
    tilesRenderer = TilesRenderer(widget.mapProperties.theme);
    TilesRenderer.initialize.then(_initialized);
  }

  @override
  void dispose() {
    super.dispose();
    tilesRenderer.dispose();
  }

  @override
  void didUpdateWidget(covariant MapLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mapProperties.theme != widget.mapProperties.theme) {
      tilesRenderer.dispose();
      tilesRenderer = TilesRenderer(widget.mapProperties.theme);
      super.resetState();
    }
  }

  @override
  Future<void> preRender(TileDataModel tile) {
    return super.preRender(tile).then((_) async {
      final tileset = tile.tileset ?? Tileset({});
      final tileID = tile.tile.key();
      final jobArguments = (widget.mapProperties.theme.id, zoom, tileset, tileID);

      await tilesRenderer.preRenderUi(zoom, tileset, tileID);
      await executor.submit(
        Job(
          "pre-render",
          _preRender(),
          jobArguments,
          deduplicationKey:
          "pre-render:${widget.mapProperties.theme.id}-${widget.mapProperties.theme.version}-$zoom-${tile.tile.key()}",
        )
      ).then((renderData) {
        try {
          tile.renderData ??= renderData.materialize().asUint8List();
        } catch (_) {}
      });
    });
  }

  static TransferableTypedData Function((String, double, Tileset, String) args) _preRender() {
    final preRenderer = TilesRenderer.getPreRenderer();
    return ((String, double, Tileset, String) args) {
      final theme = ThemeRepo.themeById[args.$1]!;
      return TransferableTypedData.fromList([preRenderer.call(theme, args.$2, args.$3, args.$4)]);
    };
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
    tilesRenderer.update(zoom, uiTiles);

    return CustomPaint(
      key: Key(
        'mapTileLayer_${widget.mapProperties.theme.id}_${widget.mapProperties.theme.version}',
      ),
      painter: MapTilesPainter(widget.mapProperties, tilesRenderer, rotation),
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
  final double rotation;

  MapTilesPainter(this.properties, this.tilesRenderer, this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    tilesRenderer.render(canvas, size, rotation);
  }

  @override
  bool shouldRepaint(covariant MapTilesPainter oldDelegate) => true;
}

extension _TileDataModelUiExtension on TileDataModel {
  TileUiModel toUiModel() => TileUiModel(
    tileId: tile.toTileId(),
    position: tilePosition.position,
    tileset: tileset ?? Tileset({}),
    rasterTileset: rasterTileset ?? const RasterTileset(tiles: {}),
    renderData: renderData,
  );
}

extension _TileIdExtension on TileIdentity {
  TileId toTileId() => TileId(z: z, x: x, y: y);
}
