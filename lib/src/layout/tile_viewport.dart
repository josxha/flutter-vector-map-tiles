import 'dart:ui';

typedef TileBounds = Rect;

class TileViewport {
  /// The zoom level.
  final int zoom;

  /// The bounds in tile coordinates.
  final TileBounds bounds;

  TileViewport({required this.zoom, required this.bounds});
}
