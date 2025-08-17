import 'dart:ui';

import 'package:latlong2/latlong.dart';
import 'package:test/test.dart';
import 'package:vector_map_tiles/src/layout/tile_viewport_provider.dart';
import 'package:vector_map_tiles/src/tile_offset.dart';

import '../mocks/mock_map_state.dart';

void main() {
  group('TileViewportProvider', () {
    group('currentViewport', () {
      test('calculates viewport for basic map state', () {
        final mapState = MockMapState(
          center: LatLng(0.0, 0.0),
          zoom: 2.0,
          pixelOrigin: Offset.zero,
          size: const Size(512, 512),
        );
        final provider = TileViewportProvider(
          mapState: mapState,
          tileOffset: TileOffset.DEFAULT,
          tileSize: 256,
        );

        final viewport = provider.currentViewport();

        expect(viewport.zoom, equals(2));
        expect(viewport.bounds.left, equals(1.0));
        expect(viewport.bounds.top, equals(1.0));
        expect(viewport.bounds.right, equals(2.0));
        expect(viewport.bounds.bottom, equals(2.0));
      });

      test('applies tile offset to zoom calculation', () {
        final mapState = MockMapState(
          center: LatLng(0.0, 0.0),
          zoom: 3.0,
          pixelOrigin: Offset.zero,
          size: const Size(256, 256),
        );
        final provider = TileViewportProvider(
          mapState: mapState,
          tileOffset: const TileOffset(zoomOffset: -1),
          tileSize: 256,
        );

        final viewport = provider.currentViewport();

        expect(viewport.zoom, equals(2));
      });

      test('handles fractional zoom levels by flooring', () {
        final mapState = MockMapState(
          center: LatLng(0.0, 0.0),
          zoom: 2.7,
          pixelOrigin: Offset.zero,
          size: const Size(256, 256),
        );
        final provider = TileViewportProvider(
          mapState: mapState,
          tileOffset: TileOffset.DEFAULT,
          tileSize: 256,
        );

        final viewport = provider.currentViewport();

        expect(viewport.zoom, equals(2));
      });

      test('calculates bounds for different tile sizes', () {
        final mapState = MockMapState(
          center: LatLng(0.0, 0.0),
          zoom: 1.0,
          pixelOrigin: Offset.zero,
          size: const Size(512, 512),
        );
        final provider = TileViewportProvider(
          mapState: mapState,
          tileOffset: TileOffset.DEFAULT,
          tileSize: 128,
        );

        final viewport = provider.currentViewport();

        expect(viewport.zoom, equals(1));
        expect(viewport.bounds.width, greaterThan(0));
        expect(viewport.bounds.height, greaterThan(0));
      });

      test('handles different map sizes', () {
        final mapState = MockMapState(
          center: LatLng(0.0, 0.0),
          zoom: 1.0,
          pixelOrigin: Offset.zero,
          size: const Size(1024, 768),
        );
        final provider = TileViewportProvider(
          mapState: mapState,
          tileOffset: TileOffset.DEFAULT,
          tileSize: 256,
        );

        final viewport = provider.currentViewport();

        expect(viewport.zoom, equals(1));
        expect(viewport.bounds.width, greaterThan(0));
        expect(viewport.bounds.height, greaterThan(0));
      });

      test('produces consistent results for same inputs', () {
        final mapState = MockMapState(
          center: LatLng(45.0, -122.0),
          zoom: 10.0,
          pixelOrigin: Offset.zero,
          size: const Size(800, 600),
        );
        final provider = TileViewportProvider(
          mapState: mapState,
          tileOffset: TileOffset.DEFAULT,
          tileSize: 256,
        );

        final viewport1 = provider.currentViewport();
        final viewport2 = provider.currentViewport();

        expect(viewport1.zoom, equals(viewport2.zoom));
        expect(viewport1.bounds, equals(viewport2.bounds));
      });
    });

    group('tileZoom', () {
      test('returns map zoom plus tile offset', () {
        final mapState = MockMapState(
          center: LatLng(0.0, 0.0),
          zoom: 5.0,
          pixelOrigin: Offset.zero,
          size: const Size(256, 256),
        );
        final provider = TileViewportProvider(
          mapState: mapState,
          tileOffset: const TileOffset(zoomOffset: -2),
          tileSize: 256,
        );

        expect(provider.tileZoom(), equals(3.0));
      });

      test('enforces minimum zoom of 1.0', () {
        final mapState = MockMapState(
          center: LatLng(0.0, 0.0),
          zoom: 0.5,
          pixelOrigin: Offset.zero,
          size: const Size(256, 256),
        );
        final provider = TileViewportProvider(
          mapState: mapState,
          tileOffset: const TileOffset(zoomOffset: -1),
          tileSize: 256,
        );

        expect(provider.tileZoom(), equals(1.0));
      });

      test('handles positive tile offset', () {
        final mapState = MockMapState(
          center: LatLng(0.0, 0.0),
          zoom: 3.0,
          pixelOrigin: Offset.zero,
          size: const Size(256, 256),
        );
        final provider = TileViewportProvider(
          mapState: mapState,
          tileOffset: const TileOffset(zoomOffset: 2),
          tileSize: 256,
        );

        expect(provider.tileZoom(), equals(5.0));
      });

      test('handles zero tile offset', () {
        final mapState = MockMapState(
          center: LatLng(0.0, 0.0),
          zoom: 7.5,
          pixelOrigin: Offset.zero,
          size: const Size(256, 256),
        );
        final provider = TileViewportProvider(
          mapState: mapState,
          tileOffset: TileOffset.DEFAULT,
          tileSize: 256,
        );

        expect(provider.tileZoom(), equals(7.5));
      });
    });

    group('edge cases', () {
      test('handles very small map size', () {
        final mapState = MockMapState(
          center: LatLng(0.0, 0.0),
          zoom: 1.0,
          pixelOrigin: Offset.zero,
          size: const Size(1, 1),
        );
        final provider = TileViewportProvider(
          mapState: mapState,
          tileOffset: TileOffset.DEFAULT,
          tileSize: 256,
        );

        final viewport = provider.currentViewport();

        expect(viewport.zoom, equals(1));
        expect(viewport.bounds.width, greaterThanOrEqualTo(0));
        expect(viewport.bounds.height, greaterThanOrEqualTo(0));
      });

      test('handles very large map size', () {
        final mapState = MockMapState(
          center: LatLng(0.0, 0.0),
          zoom: 1.0,
          pixelOrigin: Offset.zero,
          size: const Size(10000, 10000),
        );
        final provider = TileViewportProvider(
          mapState: mapState,
          tileOffset: TileOffset.DEFAULT,
          tileSize: 256,
        );

        final viewport = provider.currentViewport();

        expect(viewport.zoom, equals(1));
        expect(viewport.bounds.width, greaterThan(0));
        expect(viewport.bounds.height, greaterThan(0));
      });

      test('handles extreme coordinates', () {
        final mapState = MockMapState(
          center: LatLng(85.0, 179.0),
          zoom: 1.0,
          pixelOrigin: Offset.zero,
          size: const Size(256, 256),
        );
        final provider = TileViewportProvider(
          mapState: mapState,
          tileOffset: TileOffset.DEFAULT,
          tileSize: 256,
        );

        final viewport = provider.currentViewport();

        expect(viewport.zoom, equals(1));
        expect(viewport.bounds.width, greaterThanOrEqualTo(0));
        expect(viewport.bounds.height, greaterThanOrEqualTo(0));
      });

      test('handles very high zoom levels', () {
        final mapState = MockMapState(
          center: LatLng(0.0, 0.0),
          zoom: 20.0,
          pixelOrigin: Offset.zero,
          size: const Size(256, 256),
        );
        final provider = TileViewportProvider(
          mapState: mapState,
          tileOffset: TileOffset.DEFAULT,
          tileSize: 256,
        );

        final viewport = provider.currentViewport();

        expect(viewport.zoom, equals(20));
        expect(viewport.bounds.width, greaterThanOrEqualTo(0));
        expect(viewport.bounds.height, greaterThanOrEqualTo(0));
      });
    });
  });
}
