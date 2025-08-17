import 'package:flutter_map/flutter_map.dart';

import '../layout/zoom_scaler.dart';

class FlutterMapZoomScaler extends ZoomScaler {
  FlutterMapZoomScaler({required Crs crs}) : super((zoom) => crs.scale(zoom));
}
