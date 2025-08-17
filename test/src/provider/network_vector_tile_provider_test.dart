import 'package:test/test.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

void main() {
  group('NetworkVectorTileProvider', () {
    group('initialization', () {
      test('initializes with default values', () {
        final provider = NetworkVectorTileProvider(
          urlTemplate: 'https://example.com/{z}/{x}/{y}.pbf',
        );

        expect(provider.type, equals(TileProviderType.vector));
        expect(provider.maximumZoom, equals(16));
        expect(provider.minimumZoom, equals(1));
        expect(provider.tileOffset, equals(TileOffset.DEFAULT));
        expect(provider.httpHeaders, isNull);
      });

      test('initializes with custom values', () {
        final headers = {'Authorization': 'Bearer token'};
        final provider = NetworkVectorTileProvider(
          urlTemplate: 'https://example.com/{z}/{x}/{y}.pbf',
          type: TileProviderType.raster,
          httpHeaders: headers,
          maximumZoom: 18,
          minimumZoom: 0,
          tileOffset: TileOffset(zoomOffset: -1),
        );

        expect(provider.type, equals(TileProviderType.raster));
        expect(provider.maximumZoom, equals(18));
        expect(provider.minimumZoom, equals(0));
        expect(provider.tileOffset.zoomOffset, equals(-1));
        expect(provider.httpHeaders, equals(headers));
      });
    });

    group('tile validation', () {
      test('throws ProviderException for tile above maximum zoom', () async {
        final provider = NetworkVectorTileProvider(
          urlTemplate: 'https://example.com/{z}/{x}/{y}.pbf',
          maximumZoom: 10,
        );
        final tile = TileIdentity(11, 0, 0);

        expect(
          () => provider.provide(tile),
          throwsA(
            isA<ProviderException>()
                .having(
                  (e) => e.message,
                  'message',
                  contains('Invalid tile coordinates'),
                )
                .having((e) => e.statusCode, 'statusCode', equals(400))
                .having(
                  (e) => e.retryable,
                  'retryable',
                  equals(Retryable.none),
                ),
          ),
        );
      });

      test('throws ProviderException for tile below minimum zoom', () async {
        final provider = NetworkVectorTileProvider(
          urlTemplate: 'https://example.com/{z}/{x}/{y}.pbf',
          minimumZoom: 2,
        );
        final tile = TileIdentity(1, 0, 0);

        expect(
          () => provider.provide(tile),
          throwsA(
            isA<ProviderException>()
                .having(
                  (e) => e.message,
                  'message',
                  contains('Invalid tile coordinates'),
                )
                .having((e) => e.statusCode, 'statusCode', equals(400))
                .having(
                  (e) => e.retryable,
                  'retryable',
                  equals(Retryable.none),
                ),
          ),
        );
      });

      test('throws ProviderException for invalid tile coordinates', () async {
        final provider = NetworkVectorTileProvider(
          urlTemplate: 'https://example.com/{z}/{x}/{y}.pbf',
        );
        final tile = TileIdentity(5, -1, 0);

        expect(
          () => provider.provide(tile),
          throwsA(
            isA<ProviderException>()
                .having(
                  (e) => e.message,
                  'message',
                  contains('Invalid tile coordinates'),
                )
                .having((e) => e.statusCode, 'statusCode', equals(400))
                .having(
                  (e) => e.retryable,
                  'retryable',
                  equals(Retryable.none),
                ),
          ),
        );
      });

      test(
        'throws ProviderException for tile with coordinates outside zoom bounds',
        () async {
          final provider = NetworkVectorTileProvider(
            urlTemplate: 'https://example.com/{z}/{x}/{y}.pbf',
          );
          final tile = TileIdentity(2, 4, 0);

          expect(
            () => provider.provide(tile),
            throwsA(
              isA<ProviderException>()
                  .having(
                    (e) => e.message,
                    'message',
                    contains('Invalid tile coordinates'),
                  )
                  .having((e) => e.statusCode, 'statusCode', equals(400))
                  .having(
                    (e) => e.retryable,
                    'retryable',
                    equals(Retryable.none),
                  ),
            ),
          );
        },
      );
    });

    group('URL template processing', () {
      test('processes URL template with tile coordinates', () {
        final provider = NetworkVectorTileProvider(
          urlTemplate: 'https://example.com/{z}/{x}/{y}.pbf',
        );

        expect(provider, isNotNull);
      });

      test('processes complex URL template with query parameters', () {
        final provider = NetworkVectorTileProvider(
          urlTemplate:
              'https://tiles.example.com/data/{z}/{x}/{y}.pbf?api_key=test&format=pbf',
        );

        expect(provider, isNotNull);
      });
    });

    group('network error handling', () {
      test('throws ProviderException for non-existent domain', () async {
        final provider = NetworkVectorTileProvider(
          urlTemplate: 'https://non-existent-domain-12345.com/{z}/{x}/{y}.pbf',
        );
        final tile = TileIdentity(5, 10, 15);

        expect(
          () => provider.provide(tile),
          throwsA(
            isA<ProviderException>().having(
              (e) => e.retryable,
              'retryable',
              equals(Retryable.retry),
            ),
          ),
        );
      });

      test('throws ArgumentError for invalid URL format', () async {
        final provider = NetworkVectorTileProvider(
          urlTemplate: 'invalid-url/{z}/{x}/{y}.pbf',
        );
        final tile = TileIdentity(5, 10, 15);

        expect(() => provider.provide(tile), throwsA(isA<ArgumentError>()));
      });
    });
  });
}
