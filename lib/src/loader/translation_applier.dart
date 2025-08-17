import 'dart:math';

import 'package:vector_tile_renderer/vector_tile_renderer.dart';

import '../tile_translation.dart';

class TranslationApplier {
  final double tileSize;

  TranslationApplier({required this.tileSize});

  TileData apply(TileData tileData, TileTranslation translation) {
    var transformedTileData = tileData;
    if (translation.isTranslated) {
      final clipSize = tileSize / translation.fraction;
      final dx = (translation.xOffset * clipSize);
      final dy = (translation.yOffset * clipSize);
      final clip = Rectangle(dx, dy, clipSize, clipSize);
      var transformed = TileClip(bounds: clip).clip(tileData);
      if (clip.left > 0.0 || clip.top > 0.0 || translation.fraction != 1.0) {
        transformedTileData = TileTranslate(
          clip.topLeft * -1,
          scale: translation.fraction.toDouble(),
        ).translate(transformed);
      }
    }
    return transformedTileData;
  }
}
