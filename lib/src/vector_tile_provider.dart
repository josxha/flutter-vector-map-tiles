import 'dart:typed_data';

import 'tile_identity.dart';
import 'tile_offset.dart';

enum TileProviderType {
  vector,
  raster,

  /// corresponds to type `raster-dem`
  /// providers of this type should return DEM tiles in PNG format
  // ignore: constant_identifier_names
  raster_dem,
}

abstract class VectorTileProvider {
  /// provides a tile as a `pbf` or `mvt` format for [type] of [TileProviderType.vector]
  /// or `png` for [TileProviderType.raster]
  ///
  /// throws [ProviderException]
  Future<Uint8List> provide(TileIdentity tile);

  /// the maximum zoom supported by this provider
  int get maximumZoom;

  /// the minimum zoom supported by this provider
  int get minimumZoom;

  /// the offset to use with this tile provider, can be used to reduce data
  /// overhead of specific providers in a theme. This value is combined with
  /// [VectorTileLayer.tileOffset].
  TileOffset get tileOffset;

  TileProviderType get type;
}

enum Retryable { retry, none }

class ProviderException implements Exception {
  final Retryable retryable;
  final String message;
  final int? statusCode;

  ProviderException({
    required this.message,
    this.statusCode,
    required this.retryable,
  });

  @override
  String toString() => message;
}
