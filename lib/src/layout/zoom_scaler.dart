typedef CrsZoomFunction = double Function(double zoom);

class ZoomScaler {
  final CrsZoomFunction zoomScale;
  final _crsScaleByZoom = <double>[];
  var _mapZoomCrsScale = 1.0;

  ZoomScaler(this.zoomScale, {int maxZoom = 26}) {
    _crsScaleByZoom.add(1.0);
    for (int zoom = 1; zoom < maxZoom; ++zoom) {
      _crsScaleByZoom.add(zoomScale(zoom.toDouble()));
    }
  }

  void updateMapZoomScale(double mapZoom) {
    _mapZoomCrsScale = zoomScale(mapZoom);
  }

  double tileScale({required int tileZoom}) {
    final tileScale = _crsScaleByZoom[tileZoom];
    return _mapZoomCrsScale / tileScale;
  }
}
