import 'package:flutter/widgets.dart';

import '../tile_identity.dart';

class TilePosition {
  final TileIdentity tile;
  final Rect position;

  TilePosition({required this.tile, required this.position});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TilePosition && tile == other.tile && position == other.position;

  @override
  int get hashCode => Object.hash(tile, position);
}
