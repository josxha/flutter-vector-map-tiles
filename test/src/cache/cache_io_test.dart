import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:vector_map_tiles/src/cache/cache.dart';
import 'package:vector_map_tiles/src/cache/cache_io.dart';

void main() {
  group('CacheIo', () {
    late CacheIo cache;
    late CacheProperties properties;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cache_io_test');
      properties = CacheProperties(
        fileCacheTtl: const Duration(hours: 1),
        fileCacheMaximumEntries: 100,
        cacheFolder: () async => tempDir,
      );
      cache = CacheIo(properties: properties);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('stores and retrieves data from file cache', () async {
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

    test('persists data across cache instances', () async {
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final key = 'persistent-key';

      await cache.get(key, load: (key) async => testData);

      final newCache = CacheIo(properties: properties);
      final result = await newCache.get(
        key,
        load: (key) async {
          fail('Load function should not be called for cached data');
        },
      );

      expect(result, equals(testData));
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

    test('creates file cache with correct configuration', () async {
      final testData = Uint8List.fromList([1, 2, 3]);

      await cache.get('test', load: (key) async => testData);

      expect(cache.name, equals('io'));
    });

    test('handles large data storage and retrieval', () async {
      final largeData = Uint8List.fromList(
        List.generate(10000, (i) => i % 256),
      );
      final key = 'large-data-key';

      final result = await cache.get(key, load: (key) async => largeData);

      expect(result, equals(largeData));
      expect(result.length, equals(10000));
    });

    test('handles multiple different keys', () async {
      final data1 = Uint8List.fromList([1, 2, 3]);
      final data2 = Uint8List.fromList([4, 5, 6]);
      final data3 = Uint8List.fromList([7, 8, 9]);

      final result1 = await cache.get('key1', load: (key) async => data1);
      final result2 = await cache.get('key2', load: (key) async => data2);
      final result3 = await cache.get('key3', load: (key) async => data3);

      expect(result1, equals(data1));
      expect(result2, equals(data2));
      expect(result3, equals(data3));
    });

    test('respects cache TTL configuration', () async {
      final shortTtlProperties = CacheProperties(
        fileCacheTtl: const Duration(milliseconds: 1),
        fileCacheMaximumEntries: 100,
        cacheFolder: () async => tempDir,
      );
      final shortTtlCache = CacheIo(properties: shortTtlProperties);
      final testData = Uint8List.fromList([1, 2, 3]);
      final key = 'ttl-test-key';

      await shortTtlCache.get(key, load: (key) async => testData);
      await Future.delayed(const Duration(milliseconds: 10));

      var loadCalled = false;
      await shortTtlCache.get(
        key,
        load: (key) async {
          loadCalled = true;
          return testData;
        },
      );

      expect(loadCalled, isTrue);
    });
  });

  group('createStashIoCache', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('stash_io_test');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('creates cache with custom folder', () async {
      final properties = CacheProperties(
        fileCacheTtl: const Duration(hours: 2),
        fileCacheMaximumEntries: 200,
        cacheFolder: () async => tempDir,
      );

      final cache = await createStashIoCache(properties);

      expect(cache, isNotNull);
    });
  });
}
