import 'dart:math';

import 'package:test/test.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';
import 'package:vector_map_tiles/src/loader/translation_applier.dart';
import 'package:vector_map_tiles/src/tile_identity.dart';
import 'package:vector_map_tiles/src/tile_translation.dart';

void main() {
  group('TranslationApplier', () {
    late TranslationApplier applier;
    late TileData mockTileData;

    setUp(() {
      applier = TranslationApplier(tileSize: 256.0);
      mockTileData = TileData(
        layers: [
          TileDataLayer(
            name: 'test_layer',
            extent: 4096,
            features: [
              TileDataFeature(
                type: TileFeatureType.point,
                properties: {},
                geometry: null,
                points: [Point(100.0, 100.0)],
                lines: null,
                polygons: null,
              ),
            ],
          ),
        ],
      );
    });

    group('identity translation', () {
      test('returns original tile data unchanged', () {
        final original = TileIdentity(5, 10, 15);
        final translation = TileTranslation.identity(original);

        final result = applier.apply(mockTileData, translation);

        expect(result, equals(mockTileData));
      });

      test('preserves all tile layers and features', () {
        final original = TileIdentity(8, 100, 150);
        final translation = TileTranslation.identity(original);
        final complexTileData = TileData(
          layers: [
            TileDataLayer(
              name: 'layer1',
              extent: 4096,
              features: [
                TileDataFeature(
                  type: TileFeatureType.point,
                  properties: {'name': 'feature1'},
                  geometry: null,
                  points: [Point(50.0, 75.0)],
                  lines: null,
                  polygons: null,
                ),
              ],
            ),
            TileDataLayer(
              name: 'layer2',
              extent: 4096,
              features: [
                TileDataFeature(
                  type: TileFeatureType.point,
                  properties: {'type': 'marker'},
                  geometry: null,
                  points: [Point(25.0, 30.0)],
                  lines: null,
                  polygons: null,
                ),
              ],
            ),
          ],
        );

        final result = applier.apply(complexTileData, translation);

        expect(result.layers.length, equals(2));
        expect(result.layers[0].name, equals('layer1'));
        expect(result.layers[1].name, equals('layer2'));
        expect(result.layers[0].features.length, equals(1));
        expect(result.layers[1].features.length, equals(1));
      });
    });

    group('translated tile', () {
      test('applies clipping and translation for basic translation', () {
        final original = TileIdentity(10, 100, 150);
        final translated = TileIdentity(8, 25, 37);
        final translation = TileTranslation(original, translated, 4, 0, 2);

        final result = applier.apply(mockTileData, translation);

        expect(identical(result, mockTileData), isFalse);
        expect(result.layers.length, equals(mockTileData.layers.length));
      });

      test('calculates correct clip bounds for fraction 2', () {
        final original = TileIdentity(6, 10, 12);
        final translated = TileIdentity(5, 5, 6);
        final translation = TileTranslation(original, translated, 2, 0, 0);

        applier.apply(mockTileData, translation);

        final expectedClipSize = 256.0 / 2;
        final expectedDx = 0.0 * expectedClipSize;
        final expectedDy = 0.0 * expectedClipSize;

        expect(expectedClipSize, equals(128.0));
        expect(expectedDx, equals(0.0));
        expect(expectedDy, equals(0.0));
      });

      test('calculates correct clip bounds for fraction 4 with offsets', () {
        final original = TileIdentity(10, 101, 151);
        final translated = TileIdentity(8, 25, 37);
        final translation = TileTranslation(original, translated, 4, 1, 3);

        applier.apply(mockTileData, translation);

        final expectedClipSize = 256.0 / 4;
        final expectedDx = 1 * expectedClipSize;
        final expectedDy = 3 * expectedClipSize;

        expect(expectedClipSize, equals(64.0));
        expect(expectedDx, equals(64.0));
        expect(expectedDy, equals(192.0));
      });

      test('applies translation when clip has non-zero offset', () {
        final original = TileIdentity(8, 101, 151);
        final translated = TileIdentity(7, 50, 75);
        final translation = TileTranslation(original, translated, 2, 1, 1);

        final result = applier.apply(mockTileData, translation);

        expect(identical(result, mockTileData), isFalse);
      });

      test('applies translation when fraction is not 1', () {
        final original = TileIdentity(8, 100, 150);
        final translated = TileIdentity(7, 50, 75);
        final translation = TileTranslation(original, translated, 2, 0, 0);

        final result = applier.apply(mockTileData, translation);

        expect(identical(result, mockTileData), isFalse);
      });

      test('handles maximum zoom difference translation', () {
        final original = TileIdentity(15, 32767, 16383);
        final translated = TileIdentity(10, 1023, 511);
        final translation = TileTranslation(original, translated, 32, 31, 31);

        final result = applier.apply(mockTileData, translation);

        expect(identical(result, mockTileData), isFalse);
        expect(result.layers.length, equals(mockTileData.layers.length));
      });
    });

    group('edge cases', () {
      test('handles empty tile data', () {
        final emptyTileData = TileData(layers: []);
        final original = TileIdentity(8, 100, 150);
        final translated = TileIdentity(6, 25, 37);
        final translation = TileTranslation(original, translated, 4, 0, 2);

        final result = applier.apply(emptyTileData, translation);

        expect(result.layers, isEmpty);
      });

      test('handles tile data with empty layers', () {
        final tileDataWithEmptyLayer = TileData(
          layers: [
            TileDataLayer(name: 'empty_layer', extent: 4096, features: []),
          ],
        );
        final original = TileIdentity(8, 100, 150);
        final translated = TileIdentity(6, 25, 37);
        final translation = TileTranslation(original, translated, 4, 0, 2);

        final result = applier.apply(tileDataWithEmptyLayer, translation);

        expect(result.layers.length, equals(1));
        expect(result.layers[0].features, isEmpty);
      });

      test('applies translation with zero offsets', () {
        final original = TileIdentity(8, 100, 150);
        final translated = TileIdentity(6, 25, 37);
        final translation = TileTranslation(original, translated, 4, 0, 0);

        final result = applier.apply(mockTileData, translation);

        expect(identical(result, mockTileData), isFalse);
      });

      test('applies translation with maximum offsets', () {
        final original = TileIdentity(8, 103, 153);
        final translated = TileIdentity(6, 25, 38);
        final translation = TileTranslation(original, translated, 4, 3, 1);

        final result = applier.apply(mockTileData, translation);

        expect(identical(result, mockTileData), isFalse);
      });
    });

    group('different tile sizes', () {
      test('applies translation correctly with tile size 512', () {
        final largeApplier = TranslationApplier(tileSize: 512.0);
        final original = TileIdentity(8, 100, 150);
        final translated = TileIdentity(7, 50, 75);
        final translation = TileTranslation(original, translated, 2, 1, 0);

        final result = largeApplier.apply(mockTileData, translation);

        expect(identical(result, mockTileData), isFalse);
      });

      test('applies translation correctly with tile size 128', () {
        final smallApplier = TranslationApplier(tileSize: 128.0);
        final original = TileIdentity(8, 100, 150);
        final translated = TileIdentity(7, 50, 75);
        final translation = TileTranslation(original, translated, 2, 0, 1);

        final result = smallApplier.apply(mockTileData, translation);

        expect(identical(result, mockTileData), isFalse);
      });

      test('calculates clip size proportional to tile size', () {
        final customApplier = TranslationApplier(tileSize: 1024.0);
        final original = TileIdentity(8, 100, 150);
        final translated = TileIdentity(6, 25, 37);
        final translation = TileTranslation(original, translated, 4, 2, 1);

        customApplier.apply(mockTileData, translation);

        final expectedClipSize = 1024.0 / 4;
        expect(expectedClipSize, equals(256.0));
      });
    });

    group('feature preservation', () {
      test('preserves feature properties during translation', () {
        final tileDataWithProperties = TileData(
          layers: [
            TileDataLayer(
              name: 'properties_layer',
              extent: 4096,
              features: [
                TileDataFeature(
                  type: TileFeatureType.point,
                  properties: {
                    'name': 'test_feature',
                    'category': 'landmark',
                    'elevation': 1500,
                  },
                  geometry: null,
                  points: [Point(128.0, 128.0)],
                  lines: null,
                  polygons: null,
                ),
              ],
            ),
          ],
        );
        final original = TileIdentity(8, 100, 150);
        final translated = TileIdentity(7, 50, 75);
        final translation = TileTranslation(original, translated, 2, 0, 0);

        final result = applier.apply(tileDataWithProperties, translation);

        expect(
          result.layers[0].features[0].properties['name'],
          equals('test_feature'),
        );
        expect(
          result.layers[0].features[0].properties['category'],
          equals('landmark'),
        );
        expect(
          result.layers[0].features[0].properties['elevation'],
          equals(1500),
        );
      });

      test('maintains layer structure during translation', () {
        final multiLayerTileData = TileData(
          layers: [
            TileDataLayer(
              name: 'points_layer',
              extent: 4096,
              features: [
                TileDataFeature(
                  type: TileFeatureType.point,
                  properties: {'id': 1},
                  geometry: null,
                  points: [Point(50.0, 50.0)],
                  lines: null,
                  polygons: null,
                ),
                TileDataFeature(
                  type: TileFeatureType.point,
                  properties: {'id': 2},
                  geometry: null,
                  points: [Point(150.0, 150.0)],
                  lines: null,
                  polygons: null,
                ),
              ],
            ),
            TileDataLayer(name: 'metadata_layer', extent: 4096, features: []),
          ],
        );
        final original = TileIdentity(8, 100, 150);
        final translated = TileIdentity(7, 50, 75);
        final translation = TileTranslation(original, translated, 2, 1, 1);

        final result = applier.apply(multiLayerTileData, translation);

        expect(result.layers.length, equals(2));
        expect(result.layers[0].name, equals('points_layer'));
        expect(result.layers[1].name, equals('metadata_layer'));
        expect(result.layers[1].features.length, equals(0));
      });
    });
  });
}
