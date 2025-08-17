import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_map_tiles_example/local_light_style.dart';
import 'package:vector_map_tiles_example/local_tile_providers.dart';
import 'package:vector_map_tiles_example/map_info.dart';
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
  final theme = ThemeReader(logger: const Logger.console()).read(lightStyle());
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(49.246292, -123.116226),
          initialZoom: 12.5,
          maxZoom: 18.0,
        ),
        children: [
          VectorTileLayer(
            tileProviders: tileProviders(),
            theme: theme,
            tileOffset: TileOffset.DEFAULT,
          ),
          MapInfo(),
        ],
      ),
    );
  }
}
