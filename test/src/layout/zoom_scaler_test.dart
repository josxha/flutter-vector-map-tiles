import 'package:test/test.dart';
import 'package:vector_map_tiles/src/layout/zoom_scaler.dart';

void main() {
  group('ZoomScaler', () {
    double linearZoomScale(double zoom) => zoom * 2.0;
    double exponentialZoomScale(double zoom) => zoom * zoom;

    group('initialization', () {
      test('initializes with default max zoom of 26', () {
        final scaler = ZoomScaler(linearZoomScale);

        expect(scaler.tileScale(tileZoom: 0), equals(1.0));
        expect(scaler.tileScale(tileZoom: 1), equals(0.5));
        expect(scaler.tileScale(tileZoom: 25), equals(1.0 / 50.0));
      });

      test('initializes with custom max zoom', () {
        final scaler = ZoomScaler(linearZoomScale, maxZoom: 10);

        expect(scaler.tileScale(tileZoom: 0), equals(1.0));
        expect(scaler.tileScale(tileZoom: 9), equals(1.0 / 18.0));
      });

      test('precomputes CRS scales for all zoom levels', () {
        final scaler = ZoomScaler(exponentialZoomScale, maxZoom: 5);

        expect(scaler.tileScale(tileZoom: 0), equals(1.0));
        expect(scaler.tileScale(tileZoom: 1), equals(1.0));
        expect(scaler.tileScale(tileZoom: 2), equals(0.25));
        expect(scaler.tileScale(tileZoom: 3), equals(1.0 / 9.0));
        expect(scaler.tileScale(tileZoom: 4), equals(1.0 / 16.0));
      });
    });

    group('updateMapZoomScale', () {
      test('updates map zoom scale using zoom function', () {
        final scaler = ZoomScaler(linearZoomScale);

        scaler.updateMapZoomScale(5.0);
        expect(scaler.tileScale(tileZoom: 0), equals(10.0));
        expect(scaler.tileScale(tileZoom: 1), equals(5.0));
      });

      test('affects subsequent tile scale calculations', () {
        final scaler = ZoomScaler(exponentialZoomScale);

        scaler.updateMapZoomScale(3.0);
        expect(scaler.tileScale(tileZoom: 0), equals(9.0));
        expect(scaler.tileScale(tileZoom: 2), equals(2.25));

        scaler.updateMapZoomScale(2.0);
        expect(scaler.tileScale(tileZoom: 0), equals(4.0));
        expect(scaler.tileScale(tileZoom: 2), equals(1.0));
      });
    });

    group('tileScale', () {
      test('calculates scale ratio between map zoom and tile zoom', () {
        final scaler = ZoomScaler(linearZoomScale);
        scaler.updateMapZoomScale(4.0);

        expect(scaler.tileScale(tileZoom: 0), equals(8.0));
        expect(scaler.tileScale(tileZoom: 1), equals(4.0));
        expect(scaler.tileScale(tileZoom: 2), equals(2.0));
        expect(scaler.tileScale(tileZoom: 4), equals(1.0));
      });

      test('returns 1.0 when map zoom equals tile zoom scale', () {
        final scaler = ZoomScaler(linearZoomScale);
        scaler.updateMapZoomScale(1.0);

        expect(scaler.tileScale(tileZoom: 1), equals(1.0));
      });

      test(
        'returns values less than 1.0 when tile zoom scale exceeds map zoom scale',
        () {
          final scaler = ZoomScaler(linearZoomScale);
          scaler.updateMapZoomScale(1.0);

          expect(scaler.tileScale(tileZoom: 2), equals(0.5));
          expect(scaler.tileScale(tileZoom: 5), equals(0.2));
        },
      );

      test(
        'returns values greater than 1.0 when map zoom scale exceeds tile zoom scale',
        () {
          final scaler = ZoomScaler(linearZoomScale);
          scaler.updateMapZoomScale(5.0);

          expect(scaler.tileScale(tileZoom: 1), equals(5.0));
          expect(scaler.tileScale(tileZoom: 2), equals(2.5));
        },
      );

      test('works with fractional zoom scales', () {
        double fractionalZoomScale(double zoom) => zoom * 1.5;
        final scaler = ZoomScaler(fractionalZoomScale);
        scaler.updateMapZoomScale(2.5);

        expect(scaler.tileScale(tileZoom: 0), equals(3.75));
        expect(scaler.tileScale(tileZoom: 1), equals(2.5));
        expect(scaler.tileScale(tileZoom: 2), equals(1.25));
      });
    });

    group('edge cases', () {
      test('handles zero tile zoom', () {
        final scaler = ZoomScaler(linearZoomScale);
        scaler.updateMapZoomScale(3.0);

        expect(scaler.tileScale(tileZoom: 0), equals(6.0));
      });

      test('handles zoom function returning zero', () {
        double zeroZoomScale(double zoom) => 0.0;
        final scaler = ZoomScaler(zeroZoomScale);

        expect(scaler.tileScale(tileZoom: 0), equals(1.0));
        expect(scaler.tileScale(tileZoom: 1), double.infinity);
      });

      test('handles zoom function returning negative values', () {
        double negativeZoomScale(double zoom) => -zoom;
        final scaler = ZoomScaler(negativeZoomScale);
        scaler.updateMapZoomScale(2.0);

        expect(scaler.tileScale(tileZoom: 1), equals(2.0));
      });

      test('handles very small zoom scales', () {
        double smallZoomScale(double zoom) => zoom * 0.001;
        final scaler = ZoomScaler(smallZoomScale);
        scaler.updateMapZoomScale(5.0);

        expect(scaler.tileScale(tileZoom: 1), equals(5.0));
        expect(scaler.tileScale(tileZoom: 2), equals(2.5));
      });
    });
  });
}
