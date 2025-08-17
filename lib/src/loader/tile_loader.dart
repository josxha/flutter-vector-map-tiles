import '../model/tile_data_model.dart';

abstract class TileLoader {
  const TileLoader();
  Future<void> load(TileDataModel model, bool Function() cancelled);
}
