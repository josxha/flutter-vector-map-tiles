import 'dart:ui';

import 'package:latlong2/latlong.dart';

abstract class MapState {
  LatLng get center;
  double get zoom;

  Offset get pixelOrigin;

  /// the pixel size of the bounding box of the map
  Size get size;

  /// calculates the scale to go from `fromZoom` to `toZoom`
  double getZoomScale(double fromZoom, double toZoom);

  /// calculates the pixel offset of the given [center] at the specified [zoom]
  Offset projectAtZoom(LatLng center, double zoom);
}
