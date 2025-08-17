import 'dart:io';
import 'dart:typed_data';

typedef LoadFunction = Future<Uint8List> Function(String key);

class CacheProperties {
  final Duration fileCacheTtl;
  final int fileCacheMaximumEntries;
  final int memoryCacheMaximumEntries = 50;
  final bool statsEnabled = false;
  final Future<Directory> Function()? cacheFolder;

  const CacheProperties({
    required this.fileCacheTtl,
    required this.fileCacheMaximumEntries,
    required this.cacheFolder,
  });
}

abstract class Cache {
  const Cache();
  Future<Uint8List> get(String key, {required LoadFunction load});
}
