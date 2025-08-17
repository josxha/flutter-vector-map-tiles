import 'package:test/test.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

void main() {
  group('TileIdentity', () {
    group('construction and properties', () {
      test('stores zoom level and coordinates', () {
        final tile = TileIdentity(5, 10, 15);
        expect(tile.z, equals(5));
        expect(tile.x, equals(10));
        expect(tile.y, equals(15));
      });
    });

    group('equality and hashing', () {
      test('considers tiles with same coordinates equal', () {
        final tile1 = TileIdentity(5, 10, 15);
        final tile2 = TileIdentity(5, 10, 15);
        final tile3 = TileIdentity(5, 10, 16);
        final tile4 = TileIdentity(6, 10, 15);

        expect(tile1, equals(tile2));
        expect(tile1, isNot(equals(tile3)));
        expect(tile1, isNot(equals(tile4)));
      });

      test('generates consistent hash codes for equal tiles', () {
        final tile1 = TileIdentity(5, 10, 15);
        final tile2 = TileIdentity(5, 10, 15);
        final tile3 = TileIdentity(5, 10, 16);

        expect(tile1.hashCode, equals(tile2.hashCode));
        expect(tile1.hashCode, isNot(equals(tile3.hashCode)));
      });
    });

    group('string representation', () {
      test('provides string representation as key format', () {
        final tile = TileIdentity(5, 10, 15);
        expect(tile.toString(), equals('z=5,x=10,y=15'));
      });

      test('generates key in coordinate format', () {
        final tile = TileIdentity(5, 10, 15);
        expect(tile.key(), equals('z=5,x=10,y=15'));
      });
    });

    group('validation', () {
      test('accepts tiles within zoom level bounds', () {
        final tile1 = TileIdentity(0, 0, 0);
        final tile2 = TileIdentity(1, 0, 1);
        final tile3 = TileIdentity(2, 3, 3);

        expect(tile1.isValid(), isTrue);
        expect(tile2.isValid(), isTrue);
        expect(tile3.isValid(), isTrue);
      });

      test(
        'rejects tiles with negative coordinates or outside zoom bounds',
        () {
          final tile1 = TileIdentity(-1, 0, 0);
          final tile2 = TileIdentity(0, -1, 0);
          final tile3 = TileIdentity(0, 0, -1);
          final tile4 = TileIdentity(2, 4, 0);
          final tile5 = TileIdentity(2, 0, 4);

          expect(tile1.isValid(), isFalse);
          expect(tile2.isValid(), isFalse);
          expect(tile3.isValid(), isFalse);
          expect(tile4.isValid(), isFalse);
          expect(tile5.isValid(), isFalse);
        },
      );
    });

    group('normalization', () {
      test('preserves tiles already within coordinate bounds', () {
        final tile = TileIdentity(2, 2, 1);
        final normalized = tile.normalize();
        expect(normalized, equals(tile));
      });

      test('wraps x coordinates to valid range', () {
        final tile1 = TileIdentity(2, 4, 1);
        final normalized1 = tile1.normalize();
        expect(normalized1, equals(TileIdentity(2, 0, 1)));

        final tile2 = TileIdentity(2, 5, 1);
        final normalized2 = tile2.normalize();
        expect(normalized2, equals(TileIdentity(2, 1, 1)));

        final tile3 = TileIdentity(2, -1, 1);
        final normalized3 = tile3.normalize();
        expect(normalized3, equals(TileIdentity(2, 3, 1)));
      });
    });

    group('containment', () {
      test('contains itself', () {
        final tile = TileIdentity(2, 1, 1);
        expect(tile.contains(tile), isTrue);
      });

      test('contains tiles at higher zoom levels within its bounds', () {
        final parent = TileIdentity(1, 0, 0);
        final child1 = TileIdentity(2, 0, 0);
        final child2 = TileIdentity(2, 0, 1);
        final child3 = TileIdentity(2, 1, 0);
        final child4 = TileIdentity(2, 1, 1);

        expect(parent.contains(child1), isTrue);
        expect(parent.contains(child2), isTrue);
        expect(parent.contains(child3), isTrue);
        expect(parent.contains(child4), isTrue);
      });

      test('excludes tiles at lower zoom levels', () {
        final child = TileIdentity(2, 0, 0);
        final parent = TileIdentity(1, 0, 0);
        expect(child.contains(parent), isFalse);
      });

      test('excludes tiles outside its spatial bounds', () {
        final tile1 = TileIdentity(2, 0, 0);
        final tile2 = TileIdentity(2, 1, 1);
        expect(tile1.contains(tile2), isFalse);
      });
    });

    group('overlap detection', () {
      test('overlaps with itself', () {
        final tile = TileIdentity(2, 1, 1);
        expect(tile.overlaps(tile), isTrue);
      });

      test('overlaps with tiles in parent-child relationship', () {
        final parent = TileIdentity(1, 0, 0);
        final child = TileIdentity(2, 0, 0);
        expect(parent.overlaps(child), isTrue);
        expect(child.overlaps(parent), isTrue);
      });

      test('excludes tiles with no spatial overlap', () {
        final tile1 = TileIdentity(2, 0, 0);
        final tile2 = TileIdentity(2, 1, 1);
        expect(tile1.overlaps(tile2), isFalse);
      });
    });
  });
}
