import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/geo/area_polygon.dart';
import '../../../../core/widgets/map_tiles.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/place_choice.dart';
import '../../domain/entities/upload_draft.dart';
import '../cubit/area_draw_cubit.dart';
import '../cubit/area_mode_cubit.dart';
import '../cubit/place_search_cubit.dart';
import '../cubit/upload_form_cubit.dart';
import 'issue_list.dart';

/// Choose the origin as an area: an OpenStreetMap boundary, or one drawn by hand.
class AreaStep extends StatelessWidget {
  const AreaStep({required this.mapTilerKey, super.key});

  final String mapTilerKey;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return BlocBuilder<UploadFormCubit, UploadFormState>(
      builder: (BuildContext context, UploadFormState state) {
        final PlaceChoice? place = state.draft.place;
        if (place != null) {
          return _ChosenArea(place: place, mapTilerKey: mapTilerKey);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(l10n.areaIntro),
            const SizedBox(height: 12),
            BlocBuilder<AreaModeCubit, AreaModeState>(
              builder:
                  (BuildContext context, AreaModeState mode) => switch (mode.mode) {
                    AreaMode.search => _SearchArea(mapTilerKey: mapTilerKey),
                    AreaMode.draw => _DrawArea(mapTilerKey: mapTilerKey, center: mode.drawCenter),
                  },
            ),
            IssueList(issues: state.visibleIssues),
          ],
        );
      },
    );
  }
}

class _ChosenArea extends StatelessWidget {
  const _ChosenArea({required this.place, required this.mapTilerKey});

  final PlaceChoice place;
  final String mapTilerKey;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String name =
        Localizations.localeOf(context).languageCode == 'fa' && (place.nameFa ?? '').isNotEmpty
            ? place.nameFa!
            : place.displayName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.place),
          title: Text(l10n.chosenArea(name)),
          trailing: TextButton(
            onPressed: () {
              context.read<AreaModeCubit>().search();
              context.read<UploadFormCubit>().edit(
                (UploadDraft d) => d.copyWith(place: () => null),
              );
            },
            child: Text(l10n.changeArea),
          ),
        ),
        AreaPreview(polygons: place.polygons, mapTilerKey: mapTilerKey),
      ],
    );
  }
}

class _SearchArea extends StatelessWidget {
  const _SearchArea({required this.mapTilerKey});

  final String mapTilerKey;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PlaceSearchCubit search = context.read<PlaceSearchCubit>();
    return BlocBuilder<PlaceSearchCubit, PlaceSearchState>(
      builder: (BuildContext context, PlaceSearchState state) {
        final PlaceSearchResult? selected = state.selected;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              onChanged: search.queryChanged,
              decoration: InputDecoration(
                labelText: l10n.searchPlace,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon:
                    state.status == SearchStatus.searching
                        ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : null,
              ),
            ),
            if (state.status == SearchStatus.failure) _Hint(text: l10n.searchFailed),
            if (state.status == SearchStatus.ready && state.results.isEmpty)
              _Hint(text: l10n.noPlacesFound),
            ...state.results.map(
              (PlaceSearchResult result) => ListTile(
                selected: result == selected,
                leading: const Icon(Icons.place_outlined),
                title: Text(result.name),
                subtitle: result.context.isEmpty ? null : Text(result.context),
                onTap: () => search.choose(result),
              ),
            ),
            if (selected != null) ...<Widget>[
              const SizedBox(height: 8),
              switch (state.boundaryStatus) {
                BoundaryStatus.loading => _Hint(text: l10n.loadingBoundary),
                BoundaryStatus.missing => _Hint(text: l10n.noBoundary),
                BoundaryStatus.failure => _Hint(text: l10n.boundaryFailed),
                BoundaryStatus.found || BoundaryStatus.none => const SizedBox.shrink(),
              },
              if (state.boundary != null) ...<Widget>[
                AreaPreview(polygons: state.boundary!.polygons, mapTilerKey: mapTilerKey),
                const SizedBox(height: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: Text(l10n.useThisArea),
                  onPressed:
                      () => context.read<UploadFormCubit>().edit(
                        (UploadDraft d) => d.copyWith(place: () => state.boundary),
                      ),
                ),
              ],
            ],
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                icon: const Icon(Icons.draw_outlined),
                label: Text(l10n.drawArea),
                onPressed: () => context.read<AreaModeCubit>().draw(around: selected?.position),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DrawArea extends StatelessWidget {
  const _DrawArea({required this.mapTilerKey, this.center});

  final String mapTilerKey;
  final LatLng? center;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AreaDrawCubit draw = context.read<AreaDrawCubit>();
    final ColorScheme colors = Theme.of(context).colorScheme;
    return BlocBuilder<AreaDrawCubit, AreaDrawState>(
      builder: (BuildContext context, AreaDrawState state) {
        final DrawnPlaceChoice? place = draw.toPlace();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(l10n.drawHint(state.points.length)),
            const SizedBox(height: 8),
            SizedBox(
              height: 320,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: center ?? const LatLng(33.5, 52.5),
                    initialZoom: center == null ? 4.5 : 11,
                    onTap: (TapPosition _, LatLng point) => draw.addPoint(point),
                  ),
                  children: <Widget>[
                    ...baseMapLayers(mapTilerKey),
                    if (state.points.length >= 3)
                      PolygonLayer(
                        polygons: <Polygon>[
                          Polygon(
                            points: state.points,
                            color: colors.primary.withValues(alpha: 0.2),
                            borderColor: colors.primary,
                            borderStrokeWidth: 2,
                          ),
                        ],
                      )
                    else
                      PolylineLayer(
                        polylines: <Polyline>[
                          Polyline(points: state.points, color: colors.primary, strokeWidth: 2),
                        ],
                      ),
                    MarkerLayer(
                      markers:
                          state.points
                              .map(
                                (LatLng point) => Marker(
                                  point: point,
                                  width: 12,
                                  height: 12,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: colors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: <Widget>[
                TextButton(
                  onPressed: state.points.isEmpty ? null : draw.undo,
                  child: Text(l10n.undoPoint),
                ),
                TextButton(
                  onPressed: state.points.isEmpty ? null : draw.clear,
                  child: Text(l10n.clearPoints),
                ),
                const Spacer(),
                TextButton(
                  onPressed: context.read<AreaModeCubit>().search,
                  child: Text(l10n.searchPlace),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: state.nameEn,
              onChanged: (String v) => draw.setNames(nameEn: v),
              decoration: InputDecoration(
                labelText: l10n.areaNameEn,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: state.nameFa,
              textDirection: TextDirection.rtl,
              onChanged: (String v) => draw.setNames(nameFa: v),
              decoration: InputDecoration(
                labelText: l10n.areaNameFa,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.check),
              label: Text(l10n.saveDrawnArea),
              onPressed:
                  place == null
                      ? null
                      : () => context.read<UploadFormCubit>().edit(
                        (UploadDraft d) => d.copyWith(place: () => place),
                      ),
            ),
          ],
        );
      },
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(text));
}

/// A small, non-interactive map showing an area.
class AreaPreview extends StatelessWidget {
  const AreaPreview({required this.polygons, required this.mapTilerKey, super.key});

  final List<AreaPolygon> polygons;
  final String mapTilerKey;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<LatLng> points = <LatLng>[for (final AreaPolygon p in polygons) ...p.outer];
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 220,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.coordinates(
              coordinates: points,
              padding: const EdgeInsets.all(24),
            ),
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
          ),
          children: <Widget>[
            ...baseMapLayers(mapTilerKey),
            PolygonLayer(
              polygons: <Polygon>[
                for (final AreaPolygon polygon in polygons)
                  Polygon(
                    points: polygon.outer,
                    holePointsList: polygon.holes,
                    color: colors.primary.withValues(alpha: 0.2),
                    borderColor: colors.primary,
                    borderStrokeWidth: 2,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
