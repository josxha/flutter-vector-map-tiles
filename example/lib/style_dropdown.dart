import 'package:flutter/material.dart';
import 'package:vector_map_tiles_example/api_key.dart';

class StyleDropdown extends StatefulWidget {
  const StyleDropdown({required this.onChanged, super.key});

  final void Function(StyleData style) onChanged;

  static StyleData get initStyle => StyleData.mapboxStreets;

  @override
  State<StyleDropdown> createState() => _StyleDropdownState();
}

class _StyleDropdownState extends State<StyleDropdown> {
  late StyleData _selectedStyle = StyleDropdown.initStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButton<StyleData>(
        value: _selectedStyle,
        items: StyleData.values
            .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
            .toList(growable: false),
        onChanged: (value) {
          if (value == null) return;
          setState(() => _selectedStyle = value);
          widget.onChanged(value);
        },
      ),
    );
  }
}

enum StyleData {
  mapboxStreets(
    name: 'Mapbox Streets (legacy)',
    uri: 'mapbox://styles/mapbox/streets-v12?access_token={key}',
    apiKey: mapboxApiKey,
  ),
  mapboxOutdoor(
    name: 'Mapbox Outdoors (legacy)',
    uri: 'mapbox://styles/mapbox/outdoors-v12?access_token={key}',
    apiKey: mapboxApiKey,
  ),
  mapboxLight(
    name: 'Mapbox Light (legacy)',
    uri: 'mapbox://styles/mapbox/light-v11?access_token={key}',
    apiKey: mapboxApiKey,
  ),
  mapboxDark(
    name: 'Mapbox Dark (legacy)',
    uri: 'mapbox://styles/mapbox/dark-v11?access_token={key}',
    apiKey: mapboxApiKey,
  ),
  mapboxSatellite(
    name: 'Mapbox Satellite (legacy)',
    uri: 'mapbox://styles/mapbox/satellite-v9?access_token={key}',
    apiKey: mapboxApiKey,
  ),
  mapboxSatelliteStreets(
    name: 'Mapbox Satellite Streets (legacy)',
    uri: 'mapbox://styles/mapbox/satellite-streets-v12?access_token={key}',
    apiKey: mapboxApiKey,
  ),
  openMapTilesLiberty(
    name: 'OpenMapTiles Liberty',
    uri: 'https://tiles.openfreemap.org/styles/liberty',
  ),
  openMapTilesBright(
    name: 'OpenMapTiles Bright',
    uri: 'https://tiles.openfreemap.org/styles/bright',
  ),
  openMapTilesPositron(
    name: 'OpenMapTiles Positron',
    uri: 'https://tiles.openfreemap.org/styles/positron',
  ),
  openMapTilesOSM(
    name: 'OpenMapTiles OSM',
    uri: 'https://api.maptiler.com/maps/streets-v2/style.json?key={key}',
    apiKey: maptilerApiKey,
  ),
  mapTilerBasic(
    name: 'MapTiler Basic',
    uri: 'https://api.maptiler.com/tiles/v3-openmaptiles/tiles.json?key={key}',
    apiKey: maptilerApiKey,
  ),
  stadiaMapsAlidade(
    name: 'StadiaMaps Alidada Smooth',
    uri:
        'https://tiles.stadiamaps.com/styles/alidade_smooth.json?api_key={key}',
    apiKey: stadiamapsApiKey,
  ),
  versaTilesColorful(
    name: 'VersaTiles Colorful',
    uri: 'https://tiles.versatiles.org/assets/styles/colorful/style.json',
  ),
  versaTilesGraybeard(
    name: 'VersaTiles Graybeard',
    uri: 'https://tiles.versatiles.org/assets/styles/graybeard/style.json',
  ),
  versaTilesEclipse(
    name: 'VersaTiles Eclipse',
    uri: 'https://tiles.versatiles.org/assets/styles/eclipse/style.json',
  ),
  versaTilesNeutrino(
    name: 'VersaTiles Neutrino',
    uri: 'https://tiles.versatiles.org/assets/styles/neutrino/style.json',
  );

  const StyleData({required this.name, required this.uri, this.apiKey});

  final String name;
  final String uri;
  final String? apiKey;
}
