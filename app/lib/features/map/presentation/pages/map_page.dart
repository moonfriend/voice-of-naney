import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/geo/area_polygon.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/map_tiles.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../lookups/presentation/cubit/lookups_cubit.dart';
import '../../../recordings/presentation/cubit/place_recordings_cubit.dart';
import '../../domain/entities/map_bounds.dart';
import '../../domain/entities/map_pin.dart';
import '../../domain/entities/place_area.dart';
import '../../domain/entities/recording_filter.dart';
import '../cubit/map_cubit.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/place_marker.dart';
import '../widgets/place_recordings_panel.dart';

/// The public map. Expects [MapCubit], [LookupsCubit] and [PlaceRecordingsCubit] above it.
class MapView extends StatefulWidget {
  const MapView({required this.mapTilerKey, super.key});

  final String mapTilerKey;

  /// Roughly centred on Iran and its neighbours, where the first recordings come from.
  static const LatLng initialCenter = LatLng(33.5, 52.5);
  static const double initialZoom = 4.5;

  @override
  State<MapView> createState() => _MapViewState();
}

/// Holds only the [MapController] (a UI resource); all data state lives in [MapCubit].
class _MapViewState extends State<MapView> {
  final MapController _controller = MapController();

  String get mapTilerKey => widget.mapTilerKey;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MapCubit, MapState>(
      listenWhen:
          (MapState previous, MapState current) =>
              previous.selectedPlaceId != current.selectedPlaceId ||
              previous.filter != current.filter,
      listener: (BuildContext context, MapState state) {
        final int? placeId = state.selectedPlaceId;
        if (placeId != null) {
          context.read<PlaceRecordingsCubit>().load(placeId, state.filter);
        }
      },
      builder: (BuildContext context, MapState state) {
        final MapCubit cubit = context.read<MapCubit>();
        final MapPin? selected = state.selectedPin;
        return Stack(
          children: <Widget>[
            FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: MapView.initialCenter,
                initialZoom: MapView.initialZoom,
                minZoom: 2,
                maxZoom: 16,
                onMapReady:
                    () => cubit.viewportChanged(
                      _boundsOf(_controller.camera),
                      _controller.camera.zoom,
                    ),
                onPositionChanged:
                    (MapCamera camera, bool hasGesture) =>
                        cubit.viewportChanged(_boundsOf(camera), camera.zoom),
                onTap: (_, __) => cubit.selectPlace(null),
              ),
              children: <Widget>[
                ...baseMapLayers(mapTilerKey),
                PolygonLayer(polygons: _polygons(context, state.areas, state.selectedPlaceId)),
                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    markers: state.pins.map((MapPin pin) => _marker(context, pin, state)).toList(),
                    maxClusterRadius: 60,
                    size: const Size(48, 48),
                    padding: const EdgeInsets.all(48),
                    disableClusteringAtZoom: 13,
                    builder:
                        (BuildContext context, List<Marker> markers) =>
                            CountBadge(count: _countFor(markers, state.pins)),
                  ),
                ),
              ],
            ),
            if (state.status == MapStatus.loading)
              const Align(alignment: Alignment.topCenter, child: LinearProgressIndicator()),
            PositionedDirectional(top: 12, end: 12, child: _FilterButton(filter: state.filter)),
            if (mapTilerKey.isEmpty) const _TilesMissingNote(),
            if (state.status == MapStatus.failure)
              Align(alignment: Alignment.topCenter, child: _ErrorBanner(onRetry: cubit.retry)),
            if (selected != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: PlaceRecordingsPanel(
                    pin: selected,
                    onClose: () => cubit.selectPlace(null),
                    onOpenRecording: (String id) => context.push(AppRoutes.recordingPath(id)),
                    onRetry:
                        () => context.read<PlaceRecordingsCubit>().load(
                          selected.placeId,
                          state.filter,
                        ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static MapBounds _boundsOf(MapCamera camera) {
    final LatLngBounds bounds = camera.visibleBounds;
    return MapBounds(
      south: bounds.south,
      west: bounds.west,
      north: bounds.north,
      east: bounds.east,
    );
  }

  Marker _marker(BuildContext context, MapPin pin, MapState state) => Marker(
    key: ValueKey<int>(pin.placeId),
    point: pin.position,
    width: 44,
    height: 44,
    child: GestureDetector(
      onTap: () => context.read<MapCubit>().selectPlace(pin.placeId),
      child: CountBadge(
        count: pin.recordingCount,
        selected: pin.placeId == state.selectedPlaceId,
        label: pin.name.resolve(Localizations.localeOf(context)),
      ),
    ),
  );

  static int _countFor(List<Marker> markers, List<MapPin> pins) {
    final Map<int, int> counts = <int, int>{
      for (final MapPin pin in pins) pin.placeId: pin.recordingCount,
    };
    return markers.fold<int>(0, (int sum, Marker marker) {
      final Key? key = marker.key;
      return sum + (key is ValueKey<int> ? counts[key.value] ?? 0 : 0);
    });
  }

  static List<Polygon> _polygons(BuildContext context, List<PlaceArea> areas, int? selectedId) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return <Polygon>[
      for (final PlaceArea area in areas)
        for (final AreaPolygon polygon in area.polygons)
          Polygon(
            points: polygon.outer,
            holePointsList: polygon.holes,
            color: (area.placeId == selectedId ? colors.tertiary : colors.primary).withValues(
              alpha: area.placeId == selectedId ? 0.25 : 0.12,
            ),
            borderColor: area.placeId == selectedId ? colors.tertiary : colors.primary,
            borderStrokeWidth: area.placeId == selectedId ? 2.5 : 1.2,
          ),
    ];
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.filter});

  final RecordingFilter filter;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final int count = filter.activeCount;
    return FilledButton.tonalIcon(
      icon: const Icon(Icons.tune),
      label: Text(count == 0 ? l10n.filters : l10n.filtersWithCount(count)),
      onPressed: () async {
        final LookupsState lookups = context.read<LookupsCubit>().state;
        final MapCubit cubit = context.read<MapCubit>();
        final RecordingFilter? applied = await showFilterSheet(
          context,
          initial: filter,
          cultures: lookups.cultures,
          languages: lookups.languages,
        );
        if (applied != null && applied != filter) {
          await cubit.filterChanged(applied);
        }
      },
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 16, end: 8, top: 4, bottom: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(child: Text(l10n.mapLoadError)),
            TextButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}

class _TilesMissingNote extends StatelessWidget {
  const _TilesMissingNote();

  @override
  Widget build(BuildContext context) => PositionedDirectional(
    bottom: 8,
    start: 8,
    child: Text(
      AppLocalizations.of(context).mapTilesMissing,
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );
}
