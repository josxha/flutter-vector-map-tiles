import '../model/tile_data_model.dart';
import 'tile_loader.dart';

class NoOpTileLoader extends TileLoader {
  const NoOpTileLoader();

  @override
  Future<void> load(TileDataModel model, bool Function() cancelled) async {
    model.displayReady = true;
  }
}
