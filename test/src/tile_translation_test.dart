import 'package:test/test.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_map_tiles/src/tile_translation.dart';

void main() {
  group('TileTranslation', () {
    group('identity translation', () {
      test(
        'creates identity translation with same original and translated tiles',
        () {
          final original = TileIdentity(5, 10, 15);
          final translation = TileTranslation.identity(original);

          expect(translation.original, equals(original));
          expect(translation.translated, equals(original));
          expect(translation.fraction, equals(1));
          expect(translation.xOffset, equals(0));
          expect(translation.yOffset, equals(0));
        },
      );

      test('indicates no translation is needed', () {
        final original = TileIdentity(5, 10, 15);
        final translation = TileTranslation.identity(original);

        expect(translation.isTranslated, isFalse);
        expect(translation.zoomDifference, equals(0));
      });
    });

    group('translated tile', () {
      test('stores original and translated tile information', () {
        final original = TileIdentity(8, 100, 150);
        final translated = TileIdentity(6, 25, 37);
        final translation = TileTranslation(original, translated, 4, 0, 2);

        expect(translation.original, equals(original));
        expect(translation.translated, equals(translated));
        expect(translation.fraction, equals(4));
        expect(translation.xOffset, equals(0));
        expect(translation.yOffset, equals(2));
      });

      test('calculates zoom difference correctly', () {
        final original = TileIdentity(8, 100, 150);
        final translated = TileIdentity(6, 25, 37);
        final translation = TileTranslation(original, translated, 4, 0, 2);

        expect(translation.zoomDifference, equals(2));
      });

      test(
        'indicates translation is needed when fraction is greater than 1',
        () {
          final original = TileIdentity(8, 100, 150);
          final translated = TileIdentity(6, 25, 37);
          final translation = TileTranslation(original, translated, 4, 0, 2);

          expect(translation.isTranslated, isTrue);
        },
      );

      test('indicates no translation when fraction equals 1', () {
        final original = TileIdentity(5, 10, 15);
        final translation = TileTranslation(original, original, 1, 0, 0);

        expect(translation.isTranslated, isFalse);
      });
    });
  });

  group('SlippyMapTranslator', () {
    group('translate', () {
      test('returns identity translation for tiles at or below max zoom', () {
        final translator = SlippyMapTranslator(10);
        final tile = TileIdentity(8, 100, 150);
        final translation = translator.translate(tile);

        expect(translation.original, equals(tile));
        expect(translation.translated, equals(tile));
        expect(translation.isTranslated, isFalse);
      });

      test('returns identity translation for tiles exactly at max zoom', () {
        final translator = SlippyMapTranslator(10);
        final tile = TileIdentity(10, 100, 150);
        final translation = translator.translate(tile);

        expect(translation.original, equals(tile));
        expect(translation.translated, equals(tile));
        expect(translation.isTranslated, isFalse);
      });

      test('translates tiles above max zoom to lower zoom level', () {
        final translator = SlippyMapTranslator(8);
        final tile = TileIdentity(10, 100, 150);
        final translation = translator.translate(tile);

        expect(translation.original, equals(tile));
        expect(translation.translated, equals(TileIdentity(8, 25, 37)));
        expect(translation.fraction, equals(4));
        expect(translation.xOffset, equals(0));
        expect(translation.yOffset, equals(2));
        expect(translation.isTranslated, isTrue);
      });

      test('calculates correct offsets for tile subdivision', () {
        final translator = SlippyMapTranslator(8);
        final tile = TileIdentity(10, 101, 151);
        final translation = translator.translate(tile);

        expect(translation.translated, equals(TileIdentity(8, 25, 37)));
        expect(translation.xOffset, equals(1));
        expect(translation.yOffset, equals(3));
      });
    });

    group('lowerZoomAlternative', () {
      test('translates tile to specified number of levels lower', () {
        final translator = SlippyMapTranslator(15);
        final tile = TileIdentity(10, 100, 150);
        final translation = translator.lowerZoomAlternative(tile, levels: 2);

        expect(translation.original, equals(tile));
        expect(translation.translated, equals(TileIdentity(8, 25, 37)));
        expect(translation.fraction, equals(4));
        expect(translation.xOffset, equals(0));
        expect(translation.yOffset, equals(2));
      });

      test('returns identity translation when levels is 0', () {
        final translator = SlippyMapTranslator(15);
        final tile = TileIdentity(10, 100, 150);
        final translation = translator.lowerZoomAlternative(tile, levels: 0);

        expect(translation.original, equals(tile));
        expect(translation.translated, equals(tile));
        expect(translation.isTranslated, isFalse);
      });

      test('calculates correct subdivision for single level difference', () {
        final translator = SlippyMapTranslator(15);
        final tile = TileIdentity(5, 10, 14);
        final translation = translator.lowerZoomAlternative(tile, levels: 1);

        expect(translation.translated, equals(TileIdentity(4, 5, 7)));
        expect(translation.fraction, equals(2));
        expect(translation.xOffset, equals(0));
        expect(translation.yOffset, equals(0));
      });

      test('calculates correct subdivision for odd coordinates', () {
        final translator = SlippyMapTranslator(15);
        final tile = TileIdentity(5, 11, 15);
        final translation = translator.lowerZoomAlternative(tile, levels: 1);

        expect(translation.translated, equals(TileIdentity(4, 5, 7)));
        expect(translation.fraction, equals(2));
        expect(translation.xOffset, equals(1));
        expect(translation.yOffset, equals(1));
      });
    });

    group('specificZoomTranslation', () {
      test('translates tile to specific zoom level', () {
        final translator = SlippyMapTranslator(15);
        final tile = TileIdentity(10, 100, 150);
        final translation = translator.specificZoomTranslation(tile, zoom: 7);

        expect(translation.original, equals(tile));
        expect(translation.translated, equals(TileIdentity(7, 12, 18)));
        expect(translation.fraction, equals(8));
        expect(translation.xOffset, equals(4));
        expect(translation.yOffset, equals(6));
      });

      test(
        'returns identity translation when target zoom equals tile zoom',
        () {
          final translator = SlippyMapTranslator(15);
          final tile = TileIdentity(10, 100, 150);
          final translation = translator.specificZoomTranslation(
            tile,
            zoom: 10,
          );

          expect(translation.original, equals(tile));
          expect(translation.translated, equals(tile));
          expect(translation.isTranslated, isFalse);
        },
      );

      test('translates to zoom level 0', () {
        final translator = SlippyMapTranslator(15);
        final tile = TileIdentity(3, 5, 7);
        final translation = translator.specificZoomTranslation(tile, zoom: 0);

        expect(translation.translated, equals(TileIdentity(0, 0, 0)));
        expect(translation.fraction, equals(8));
        expect(translation.xOffset, equals(5));
        expect(translation.yOffset, equals(7));
      });
    });

    group('mathematical precision', () {
      test('calculates exact division for power of 2 coordinates', () {
        final translator = SlippyMapTranslator(10);
        final tile = TileIdentity(12, 256, 512);
        final translation = translator.translate(tile);

        expect(translation.translated, equals(TileIdentity(10, 64, 128)));
        expect(translation.xOffset, equals(0));
        expect(translation.yOffset, equals(0));
      });

      test('calculates remainders correctly for non-divisible coordinates', () {
        final translator = SlippyMapTranslator(8);
        final tile = TileIdentity(11, 1023, 2047);
        final translation = translator.translate(tile);

        expect(translation.translated, equals(TileIdentity(8, 127, 255)));
        expect(translation.xOffset, equals(7));
        expect(translation.yOffset, equals(7));
      });

      test('handles large coordinate values', () {
        final translator = SlippyMapTranslator(10);
        final tile = TileIdentity(15, 32767, 16383);
        final translation = translator.translate(tile);

        expect(translation.translated, equals(TileIdentity(10, 1023, 511)));
        expect(translation.fraction, equals(32));
        expect(translation.xOffset, equals(31));
        expect(translation.yOffset, equals(31));
      });
    });
  });
}
