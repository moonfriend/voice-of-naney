import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// MapTiler raster tiles. Without a key (local development) no background is drawn.
List<Widget> baseMapLayers(String mapTilerKey) {
  if (mapTilerKey.isEmpty) {
    return const <Widget>[];
  }
  return <Widget>[
    TileLayer(
      urlTemplate: 'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key=$mapTilerKey',
      userAgentPackageName: 'org.voiceofnaney.naney',
    ),
    const RichAttributionWidget(
      attributions: <SourceAttribution>[
        TextSourceAttribution('© MapTiler'),
        TextSourceAttribution('© OpenStreetMap contributors'),
      ],
    ),
  ];
}
