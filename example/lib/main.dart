import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_map_tiles_example/map_info.dart';
import 'package:vector_map_tiles_example/style_dropdown.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart'
    hide TileLayer, Theme;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vector Map Tiles Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Vector Map Tiles Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final options = const MapOptions(
    initialCenter: LatLng(47.6, 9.2),
    // initialCenter: LatLng(49.246292, -123.116226),
    initialZoom: 12.5,
    maxZoom: 18.0,
  );
  bool _showPerfOverlay = false;
  Style? _style;
  Key _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadStyle(StyleDropdown.initStyle);
  }

  void _loadStyle(StyleData styleData) {
    StyleReader(
      uri: styleData.uri,
      apiKey: styleData.apiKey,
      logger: const Logger.console(),
    ).read().then((style) {
      _style = style;
      _key = GlobalKey();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_style != null) {
      body = FlutterMap(
        options: options,
        children: [
          SizedBox.expand(
            child: VectorTileLayer(
              key: _key,
              tileProviders: _style!.providers,
              theme: _style!.theme,
              tileOffset: TileOffset.DEFAULT,
            ),
          ),
          const MapInfo(),
          if (_showPerfOverlay) PerformanceOverlay.allEnabled(),
        ],
      );
    } else {
      body = const SizedBox.expand(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Row(
            children: [
              StyleDropdown(onChanged: _loadStyle),
              const Spacer(),
              const Icon(Icons.stacked_bar_chart),
              Checkbox(
                value: _showPerfOverlay,
                onChanged: (value) => setState(() => _showPerfOverlay = value!),
              ),
            ],
          ),
        ),
      ),
      body: body,
    );
  }
}
