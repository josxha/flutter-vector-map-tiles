import 'package:executor_lib/executor_lib.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_map_tiles/src/model/tile_data_model.dart';

import '../executors/executors_std.dart';
import '../loader/tile_loader.dart';
import '../model/map_properties.dart';
import '../model/map_tiles.dart';
import 'flutter_map_adapter.dart';

abstract class AbstractMapLayer extends StatefulWidget {
  final MapProperties mapProperties;
  final TileLoader Function(MapProperties, Executor) tileLoaderFactory;

  const AbstractMapLayer({
    super.key,
    required this.mapProperties,
    required this.tileLoaderFactory,
  });
}

abstract class AbstractMapLayerState<T extends AbstractMapLayer>
    extends State<T> {
  late final Executor executor;
  late final TileLoader tileLoader;
  late final MapTiles mapTiles;
  FlutterMapAdapter? _mapAdapter;

  @override
  void dispose() {
    executor.dispose();
    _mapAdapter?.dispose();
    super.dispose();
  }

  double get zoom => _mapAdapter?.zoom ?? 1.0;

  void updateTiles(BuildContext context) {
    for (final tile in mapTiles.tileModels.where((model) => model.isLoaded && !model.isDisplayReady)) {
      preRender(tile).then((_) {
        tile.isDisplayReady = tile.isLoaded;
      });
    }
    _mapAdapter?.update(context);
  }

  Future<void> preRender(TileDataModel tile) => Future.sync(() {});

  @override
  void initState() {
    super.initState();
    executor = newConcurrentExecutor(
      concurrency: widget.mapProperties.concurrency,
    );
    tileLoader = widget.tileLoaderFactory(widget.mapProperties, executor);
    mapTiles = MapTiles(tileLoader: tileLoader);
    _mapAdapter ??= FlutterMapAdapter(
      mapTiles: mapTiles,
      mapUpdated: _mapUpdated,
      tileOffset: widget.mapProperties.tileOffset,
    );
    mapTiles.addListener(_mapUpdated);
  }

  void _mapUpdated() {
    if (mounted) {
      setState(() {});
    }
  }
}
