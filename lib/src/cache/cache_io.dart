import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:stash/stash_api.dart';
import 'package:stash_file/stash_file.dart';

import 'abstract_stash_cache.dart';
import 'cache.dart';

class CacheIo extends AbstractStashCache {
  CacheIo({required CacheProperties properties})
    : super(name: 'io', cacheFactory: () => createStashIoCache(properties));
}

Future<BinaryCache> createStashIoCache(CacheProperties properties) async {
  final pather = properties.cacheFolder ?? cacheStorageResolver;
  final cacheFolder = await pather();
  final store = await newFileLocalCacheStore(path: cacheFolder.path);
  return store.cache(
    name: 'default',
    evictionPolicy: LruEvictionPolicy(),
    expiryPolicy: CreatedExpiryPolicy(properties.fileCacheTtl),
    maxEntries: properties.fileCacheMaximumEntries,
    statsEnabled: properties.statsEnabled,
  );
}

Future<Directory> cacheStorageResolver() async {
  final tempFolder = await getTemporaryDirectory();
  return Directory('${tempFolder.path}/.vector_map');
}
