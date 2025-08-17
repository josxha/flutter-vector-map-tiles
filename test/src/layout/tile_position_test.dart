import 'dart:ui';

import 'package:test/test.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_map_tiles/src/layout/tile_position.dart';

void main() {
  group('TilePosition', () {
    group('equality and hashing', () {
      test('considers tile positions with same tile and position equal', () {
        final tile1 = TileIdentity(5, 10, 15);
        final tile2 = TileIdentity(5, 10, 15);
        final position1 = const Rect.fromLTWH(100, 200, 256, 256);
        final position2 = const Rect.fromLTWH(100, 200, 256, 256);

        final tilePosition1 = TilePosition(tile: tile1, position: position1);
        final tilePosition2 = TilePosition(tile: tile2, position: position2);

        expect(tilePosition1, equals(tilePosition2));
      });

      test('considers tile positions with different tiles unequal', () {
        final tile1 = TileIdentity(5, 10, 15);
        final tile2 = TileIdentity(5, 10, 16);
        final position = const Rect.fromLTWH(100, 200, 256, 256);

        final tilePosition1 = TilePosition(tile: tile1, position: position);
        final tilePosition2 = TilePosition(tile: tile2, position: position);

        expect(tilePosition1, isNot(equals(tilePosition2)));
      });

      test('considers tile positions with different positions unequal', () {
        final tile = TileIdentity(5, 10, 15);
        final position1 = const Rect.fromLTWH(100, 200, 256, 256);
        final position2 = const Rect.fromLTWH(200, 300, 256, 256);

        final tilePosition1 = TilePosition(tile: tile, position: position1);
        final tilePosition2 = TilePosition(tile: tile, position: position2);

        expect(tilePosition1, isNot(equals(tilePosition2)));
      });

      test('generates consistent hash codes for equal tile positions', () {
        final tile1 = TileIdentity(5, 10, 15);
        final tile2 = TileIdentity(5, 10, 15);
        final position1 = const Rect.fromLTWH(100, 200, 256, 256);
        final position2 = const Rect.fromLTWH(100, 200, 256, 256);

        final tilePosition1 = TilePosition(tile: tile1, position: position1);
        final tilePosition2 = TilePosition(tile: tile2, position: position2);

        expect(tilePosition1.hashCode, equals(tilePosition2.hashCode));
      });

      test('generates different hash codes for unequal tile positions', () {
        final tile1 = TileIdentity(5, 10, 15);
        final tile2 = TileIdentity(5, 10, 16);
        final position = const Rect.fromLTWH(100, 200, 256, 256);

        final tilePosition1 = TilePosition(tile: tile1, position: position);
        final tilePosition2 = TilePosition(tile: tile2, position: position);

        expect(tilePosition1.hashCode, isNot(equals(tilePosition2.hashCode)));
      });
    });
  });
}
