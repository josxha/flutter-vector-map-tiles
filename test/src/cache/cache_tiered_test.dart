import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:vector_map_tiles/src/cache/cache.dart';
import 'package:vector_map_tiles/src/cache/cache_tiered.dart';

void main() {
  group('CacheTiered', () {
    late CacheTiered cache;
    late CacheProperties properties;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cache_tiered_test');
      properties = CacheProperties(
        fileCacheTtl: const Duration(hours: 1),
        fileCacheMaximumEntries: 100,
        cacheFolder: () async => tempDir,
      );
      cache = CacheTiered(properties: properties);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('stores and retrieves data from tiered cache', () async {
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

    test('provides fast access from memory tier', () async {
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final key = 'memory-tier-key';

      await cache.get(key, load: (key) async => testData);

      final startTime = DateTime.now();
      final result = await cache.get(key, load: (key) async => testData);
      final endTime = DateTime.now();

      expect(result, equals(testData));
      expect(endTime.difference(startTime).inMilliseconds, lessThan(50));
    });

    test('falls back to file tier when memory tier misses', () async {
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final key = 'file-tier-key';

      await cache.get(key, load: (key) async => testData);

      final newCache = CacheTiered(properties: properties);
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

    test('creates tiered cache with correct configuration', () async {
      final testData = Uint8List.fromList([1, 2, 3]);

      await cache.get('test', load: (key) async => testData);

      expect(cache.name, equals('tiered'));
    });

    test('handles large data across both tiers', () async {
      final largeData = Uint8List.fromList(
        List.generate(10000, (i) => i % 256),
      );
      final key = 'large-data-key';

      final result = await cache.get(key, load: (key) async => largeData);

      expect(result, equals(largeData));
      expect(result.length, equals(10000));
    });

    test('maintains data consistency between tiers', () async {
      final data1 = Uint8List.fromList([1, 2, 3]);
      final data2 = Uint8List.fromList([4, 5, 6]);
      final data3 = Uint8List.fromList([7, 8, 9]);

      await cache.get('key1', load: (key) async => data1);
      await cache.get('key2', load: (key) async => data2);
      await cache.get('key3', load: (key) async => data3);

      final result1 = await cache.get('key1', load: (key) async => data1);
      final result2 = await cache.get('key2', load: (key) async => data2);
      final result3 = await cache.get('key3', load: (key) async => data3);

      expect(result1, equals(data1));
      expect(result2, equals(data2));
      expect(result3, equals(data3));
    });

    test('promotes data from file tier to memory tier', () async {
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final key = 'promotion-key';

      await cache.get(key, load: (key) async => testData);

      final newCache = CacheTiered(properties: properties);
      await newCache.get(key, load: (key) async => testData);

      final startTime = DateTime.now();
      final result = await newCache.get(key, load: (key) async => testData);
      final endTime = DateTime.now();

      expect(result, equals(testData));
      expect(endTime.difference(startTime).inMilliseconds, lessThan(50));
    });

    test('handles memory tier eviction gracefully', () async {
      final smallMemoryProperties = CacheProperties(
        fileCacheTtl: const Duration(hours: 1),
        fileCacheMaximumEntries: 100,
        cacheFolder: () async => tempDir,
      );
      final smallMemoryCache = CacheTiered(properties: smallMemoryProperties);

      final keys = List.generate(100, (i) => 'key_$i');
      final dataList = List.generate(
        100,
        (i) => Uint8List.fromList([i, i + 1, i + 2]),
      );

      for (int i = 0; i < 100; i++) {
        await smallMemoryCache.get(keys[i], load: (key) async => dataList[i]);
      }

      final firstResult = await smallMemoryCache.get(
        keys[0],
        load: (key) async => dataList[0],
      );
      final lastResult = await smallMemoryCache.get(
        keys[99],
        load: (key) async => dataList[99],
      );

      expect(firstResult, equals(dataList[0]));
      expect(lastResult, equals(dataList[99]));
    });

    test('persists data across cache instances via file tier', () async {
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final key = 'persistent-key';

      await cache.get(key, load: (key) async => testData);

      final newCache = CacheTiered(properties: properties);
      final result = await newCache.get(
        key,
        load: (key) async {
          fail('Load function should not be called for cached data');
        },
      );

      expect(result, equals(testData));
    });

    test('combines memory speed with file persistence', () async {
      final testData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final key = 'combined-benefits-key';

      await cache.get(key, load: (key) async => testData);

      final memoryStartTime = DateTime.now();
      await cache.get(key, load: (key) async => testData);
      final memoryEndTime = DateTime.now();

      final newCache = CacheTiered(properties: properties);
      final persistedResult = await newCache.get(
        key,
        load: (key) async {
          fail('Load function should not be called for cached data');
        },
      );

      expect(persistedResult, equals(testData));
      expect(
        memoryEndTime.difference(memoryStartTime).inMilliseconds,
        lessThan(50),
      );
    });
  });

  group('_createTieredCache', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tiered_cache_test');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('creates tiered cache with memory and file components', () async {
      final properties = CacheProperties(
        fileCacheTtl: const Duration(hours: 1),
        fileCacheMaximumEntries: 100,
        cacheFolder: () async => tempDir,
      );

      final cache = CacheTiered(properties: properties);
      final testData = Uint8List.fromList([1, 2, 3]);

      final result = await cache.get('test', load: (key) async => testData);

      expect(result, equals(testData));
    });
  });
}
