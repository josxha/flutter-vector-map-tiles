import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:vector_map_tiles/src/cache/cache.dart';
import 'package:vector_map_tiles/src/cache/cache_memory.dart';

void main() {
  group('CacheMemory', () {
    late CacheMemory cache;
    late CacheProperties properties;

    setUp(() {
      properties = const CacheProperties(
        fileCacheTtl: Duration(hours: 1),
        fileCacheMaximumEntries: 100,
        cacheFolder: null,
      );
      cache = CacheMemory(properties: properties);
    });

    test('stores and retrieves data from memory cache', () async {
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final key = 'test-key';

      final result = await cache.get(key, load: (key) async => testData);

      expect(result, equals(testData));
    });

    test('returns cached data on subsequent requests', () async {
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final key = 'test-key';
      var loadCallCount = 0;

      Future<Uint8List> loadFunction(String key) async {
        loadCallCount++;
        return testData;
      }

      await cache.get(key, load: loadFunction);
      final result = await cache.get(key, load: loadFunction);

      expect(result, equals(testData));
      expect(loadCallCount, equals(1));
    });

    test('sanitizes keys with special characters', () async {
      final testData = Uint8List.fromList([1, 2, 3]);
      final key = 'test/key:with@special#chars';

      final result = await cache.get(key, load: (key) async => testData);

      expect(result, equals(testData));
    });

    test('loads data asynchronously when not cached', () async {
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final key = 'async-key';
      var loadCalled = false;

      Future<Uint8List> loadFunction(String key) async {
        loadCalled = true;
        await Future.delayed(const Duration(milliseconds: 10));
        return testData;
      }

      final result = await cache.get(key, load: loadFunction);

      expect(result, equals(testData));
      expect(loadCalled, isTrue);
    });

    test('prevents duplicate loading for concurrent requests', () async {
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final key = 'concurrent-key';
      var loadCallCount = 0;

      Future<Uint8List> loadFunction(String key) async {
        loadCallCount++;
        await Future.delayed(const Duration(milliseconds: 50));
        return testData;
      }

      final futures = [
        cache.get(key, load: loadFunction),
        cache.get(key, load: loadFunction),
        cache.get(key, load: loadFunction),
      ];

      final results = await Future.wait(futures);

      expect(results, everyElement(equals(testData)));
      expect(loadCallCount, equals(1));
    });

    test('creates memory cache with correct configuration', () async {
      final testData = Uint8List.fromList([1, 2, 3]);

      await cache.get('test', load: (key) async => testData);

      expect(cache.name, equals('memory'));
    });
  });
}
