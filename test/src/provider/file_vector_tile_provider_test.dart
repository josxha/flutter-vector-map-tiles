import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

void main() {
  group('FileVectorTileProvider', () {
    late Directory tempDir;
    late String tempPath;

    setUp(() async {
      tempDir = Directory("build/tmp/file_provider_test");
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
      await tempDir.create(recursive: true);
      tempPath = tempDir.path;
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('initialization', () {
      test('initializes with required parameters', () {
        final provider = FileVectorTileProvider(
          root: '/path/to/tiles',
          extension: 'pbf',
          type: TileProviderType.vector,
          maximumZoom: 16,
          minimumZoom: 1,
        );

        expect(provider.root, equals('/path/to/tiles'));
        expect(provider.extension, equals('pbf'));
        expect(provider.type, equals(TileProviderType.vector));
        expect(provider.maximumZoom, equals(16));
        expect(provider.minimumZoom, equals(1));
        expect(provider.tileOffset, equals(TileOffset.DEFAULT));
      });

      test('initializes with custom tile offset', () {
        final customOffset = TileOffset(zoomOffset: -1);
        final provider = FileVectorTileProvider(
          root: '/path/to/tiles',
          extension: 'pbf',
          type: TileProviderType.vector,
          maximumZoom: 16,
          minimumZoom: 1,
          tileOffset: customOffset,
        );

        expect(provider.tileOffset, equals(customOffset));
        expect(provider.tileOffset.zoomOffset, equals(-1));
      });

      test('initializes with different tile provider types', () {
        final vectorProvider = FileVectorTileProvider(
          root: '/path/to/tiles',
          extension: 'pbf',
          type: TileProviderType.vector,
          maximumZoom: 16,
          minimumZoom: 1,
        );

        final rasterProvider = FileVectorTileProvider(
          root: '/path/to/tiles',
          extension: 'png',
          type: TileProviderType.raster,
          maximumZoom: 16,
          minimumZoom: 1,
        );

        expect(vectorProvider.type, equals(TileProviderType.vector));
        expect(rasterProvider.type, equals(TileProviderType.raster));
      });
    });

    group('file path construction', () {
      test('constructs correct file path for tile', () async {
        await _createTileFile(tempPath, 5, 10, 15, 'pbf', [1, 2, 3, 4]);

        final provider = FileVectorTileProvider(
          root: tempPath,
          extension: 'pbf',
          type: TileProviderType.vector,
          maximumZoom: 16,
          minimumZoom: 1,
        );
        final tile = TileIdentity(5, 10, 15);

        final result = await provider.provide(tile);
        expect(result, equals(Uint8List.fromList([1, 2, 3, 4])));
      });

      test('handles different file extensions', () async {
        await _createTileFile(tempPath, 3, 2, 1, 'png', [255, 0, 0, 255]);

        final provider = FileVectorTileProvider(
          root: tempPath,
          extension: 'png',
          type: TileProviderType.raster,
          maximumZoom: 16,
          minimumZoom: 1,
        );
        final tile = TileIdentity(3, 2, 1);

        final result = await provider.provide(tile);
        expect(result, equals(Uint8List.fromList([255, 0, 0, 255])));
      });

      test('handles relative root paths', () async {
        final relativeDir = Directory('$tempPath/relative');
        await relativeDir.create(recursive: true);
        await _createTileFile(relativeDir.path, 2, 1, 0, 'mvt', [10, 20, 30]);

        final provider = FileVectorTileProvider(
          root: '$tempPath/relative',
          extension: 'mvt',
          type: TileProviderType.vector,
          maximumZoom: 16,
          minimumZoom: 1,
        );
        final tile = TileIdentity(2, 1, 0);

        final result = await provider.provide(tile);
        expect(result, equals(Uint8List.fromList([10, 20, 30])));
      });
    });

    group('tile provision', () {
      test('provides tile data for valid coordinates', () async {
        final tileData = List.generate(256, (i) => i % 256);
        await _createTileFile(tempPath, 8, 128, 64, 'pbf', tileData);

        final provider = FileVectorTileProvider(
          root: tempPath,
          extension: 'pbf',
          type: TileProviderType.vector,
          maximumZoom: 16,
          minimumZoom: 1,
        );
        final tile = TileIdentity(8, 128, 64);

        final result = await provider.provide(tile);
        expect(result, equals(Uint8List.fromList(tileData)));
      });

      test('provides empty tile data', () async {
        await _createTileFile(tempPath, 1, 0, 0, 'pbf', []);

        final provider = FileVectorTileProvider(
          root: tempPath,
          extension: 'pbf',
          type: TileProviderType.vector,
          maximumZoom: 16,
          minimumZoom: 1,
        );
        final tile = TileIdentity(1, 0, 0);

        final result = await provider.provide(tile);
        expect(result, equals(Uint8List.fromList([])));
      });

      test('provides large tile data', () async {
        final largeTileData = List.generate(10000, (i) => (i * 7) % 256);
        await _createTileFile(tempPath, 12, 2048, 1024, 'pbf', largeTileData);

        final provider = FileVectorTileProvider(
          root: tempPath,
          extension: 'pbf',
          type: TileProviderType.vector,
          maximumZoom: 16,
          minimumZoom: 1,
        );
        final tile = TileIdentity(12, 2048, 1024);

        final result = await provider.provide(tile);
        expect(result, equals(Uint8List.fromList(largeTileData)));
        expect(result.length, equals(10000));
      });
    });

    group('error handling', () {
      test('throws ProviderException when file does not exist', () async {
        final provider = FileVectorTileProvider(
          root: tempPath,
          extension: 'pbf',
          type: TileProviderType.vector,
          maximumZoom: 16,
          minimumZoom: 1,
        );
        final tile = TileIdentity(5, 10, 15);

        expect(
          () => provider.provide(tile),
          throwsA(
            isA<ProviderException>()
                .having((e) => e.statusCode, 'statusCode', equals(404))
                .having((e) => e.retryable, 'retryable', equals(Retryable.none))
                .having(
                  (e) => e.message,
                  'message',
                  contains('PathNotFoundException'),
                ),
          ),
        );
      });

      test('throws ProviderException when directory does not exist', () async {
        final provider = FileVectorTileProvider(
          root: '/non/existent/path',
          extension: 'pbf',
          type: TileProviderType.vector,
          maximumZoom: 16,
          minimumZoom: 1,
        );
        final tile = TileIdentity(1, 0, 0);

        expect(
          () => provider.provide(tile),
          throwsA(
            isA<ProviderException>()
                .having((e) => e.statusCode, 'statusCode', equals(404))
                .having(
                  (e) => e.retryable,
                  'retryable',
                  equals(Retryable.none),
                ),
          ),
        );
      });

      test('throws ProviderException when file is not readable', () async {
        if (!Platform.isWindows) {
          await _createTileFile(tempPath, 3, 4, 5, 'pbf', [1, 2, 3]);
          final file = File('$tempPath/3/4/5.pbf');
          await Process.run('chmod', ['000', file.path]);

          final provider = FileVectorTileProvider(
            root: tempPath,
            extension: 'pbf',
            type: TileProviderType.vector,
            maximumZoom: 16,
            minimumZoom: 1,
          );
          final tile = TileIdentity(3, 4, 5);

          expect(
            () => provider.provide(tile),
            throwsA(
              isA<ProviderException>()
                  .having((e) => e.statusCode, 'statusCode', equals(404))
                  .having(
                    (e) => e.retryable,
                    'retryable',
                    equals(Retryable.none),
                  ),
            ),
          );

          await Process.run('chmod', ['644', file.path]);
        }
      });

      test(
        'throws ProviderException with original exception message',
        () async {
          final provider = FileVectorTileProvider(
            root: tempPath,
            extension: 'pbf',
            type: TileProviderType.vector,
            maximumZoom: 16,
            minimumZoom: 1,
          );
          final tile = TileIdentity(1, 0, 0);

          try {
            await provider.provide(tile);
            fail('Expected ProviderException to be thrown');
          } catch (e) {
            expect(e, isA<ProviderException>());
            final providerException = e as ProviderException;
            expect(
              providerException.message,
              contains('PathNotFoundException'),
            );
            expect(providerException.message, contains('$tempPath/1/0/0.pbf'));
          }
        },
      );
    });

    group('edge cases', () {
      test('handles zero coordinates', () async {
        await _createTileFile(tempPath, 0, 0, 0, 'pbf', [42]);

        final provider = FileVectorTileProvider(
          root: tempPath,
          extension: 'pbf',
          type: TileProviderType.vector,
          maximumZoom: 16,
          minimumZoom: 0,
        );
        final tile = TileIdentity(0, 0, 0);

        final result = await provider.provide(tile);
        expect(result, equals(Uint8List.fromList([42])));
      });

      test('handles maximum zoom coordinates', () async {
        final maxCoord = (1 << 16) - 1; // 2^16 - 1
        await _createTileFile(tempPath, 16, maxCoord, maxCoord, 'pbf', [255]);

        final provider = FileVectorTileProvider(
          root: tempPath,
          extension: 'pbf',
          type: TileProviderType.vector,
          maximumZoom: 16,
          minimumZoom: 1,
        );
        final tile = TileIdentity(16, maxCoord, maxCoord);

        final result = await provider.provide(tile);
        expect(result, equals(Uint8List.fromList([255])));
      });

      test('handles root path with trailing slash', () async {
        await _createTileFile(tempPath, 2, 1, 3, 'pbf', [100, 200]);

        final provider = FileVectorTileProvider(
          root: '$tempPath/',
          extension: 'pbf',
          type: TileProviderType.vector,
          maximumZoom: 16,
          minimumZoom: 1,
        );
        final tile = TileIdentity(2, 1, 3);

        final result = await provider.provide(tile);
        expect(result, equals(Uint8List.fromList([100, 200])));
      });

      test('handles extension without dot', () async {
        await _createTileFile(tempPath, 1, 1, 0, 'mvt', [50]);

        final provider = FileVectorTileProvider(
          root: tempPath,
          extension: 'mvt',
          type: TileProviderType.vector,
          maximumZoom: 16,
          minimumZoom: 1,
        );
        final tile = TileIdentity(1, 1, 0);

        final result = await provider.provide(tile);
        expect(result, equals(Uint8List.fromList([50])));
      });
    });
  });
}

Future<void> _createTileFile(
  String rootPath,
  int z,
  int x,
  int y,
  String extension,
  List<int> data,
) async {
  final dir = Directory('$rootPath/$z/$x');
  await dir.create(recursive: true);
  final file = File('$rootPath/$z/$x/$y.$extension');
  await file.writeAsBytes(data);
}
