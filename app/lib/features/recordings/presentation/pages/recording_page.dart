import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/geo/area_polygon.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/map_tiles.dart';
import '../../../../core/widgets/recording_kind_label.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/recording_detail.dart';
import '../cubit/recording_detail_cubit.dart';
import '../widgets/media_players.dart';

/// Shows one recording (`/r/<id>`). Expects a [RecordingDetailCubit] above it.
class RecordingView extends StatelessWidget {
  const RecordingView({
    required this.mapTilerKey,
    this.playerBuilder = defaultMediaPlayerBuilder,
    super.key,
  });

  final String mapTilerKey;
  final MediaPlayerBuilder playerBuilder;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return BlocBuilder<RecordingDetailCubit, RecordingDetailState>(
      builder:
          (BuildContext context, RecordingDetailState state) => switch (state) {
            RecordingDetailLoading() => const Center(child: CircularProgressIndicator()),
            RecordingDetailNotFound() => _Message(text: l10n.recordingNotFound),
            RecordingDetailFailed() => _Message(text: l10n.recordingLoadError),
            RecordingDetailLoaded() => _Details(
              state: state,
              mapTilerKey: mapTilerKey,
              playerBuilder: playerBuilder,
            ),
          },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(text, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextButton.icon(
            icon: const Icon(Icons.map_outlined),
            label: Text(AppLocalizations.of(context).backToMap),
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
    ),
  );
}

class _Details extends StatelessWidget {
  const _Details({required this.state, required this.mapTilerKey, required this.playerBuilder});

  final RecordingDetailLoaded state;
  final String mapTilerKey;
  final MediaPlayerBuilder playerBuilder;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Locale locale = Localizations.localeOf(context);
    final TextTheme text = Theme.of(context).textTheme;
    final RecordingDetail detail = state.detail;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(detail.title, style: text.headlineSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Chip(label: Text(recordingKindLabel(l10n, detail.kind))),
                if (detail.performerName != null) Text(l10n.performedBy(detail.performerName!)),
                if (detail.yearRecorded != null) Text(l10n.recordedIn(detail.yearRecorded!)),
              ],
            ),
            const SizedBox(height: 16),
            if (detail.revisions.length > 1) ...<Widget>[
              _RevisionPicker(state: state),
              const SizedBox(height: 8),
            ],
            playerBuilder(context, state.selectedRevision),
            if (state.selectedRevision.note != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: 4),
                child: Text(state.selectedRevision.note!, style: text.bodySmall),
              ),
            if (detail.photoUrl != null) ...<Widget>[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  detail.photoUrl.toString(),
                  semanticLabel: l10n.photoOf(detail.title),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
            if (detail.description != null) ...<Widget>[
              const SizedBox(height: 16),
              Text(detail.description!, style: text.bodyLarge),
            ],
            const SizedBox(height: 16),
            _InfoTile(
              icon: Icons.place_outlined,
              label: l10n.origin,
              value: detail.place.name.resolve(locale),
            ),
            if (detail.place.area.isNotEmpty)
              _AreaMap(polygons: detail.place.area, mapTilerKey: mapTilerKey),
            _InfoTile(
              icon: Icons.diversity_3_outlined,
              label: l10n.cultures,
              value: detail.cultures
                  .map((CultureEntry entry) => entry.name?.resolve(locale) ?? entry.otherText!)
                  .join(locale.languageCode == 'fa' ? '، ' : ', '),
            ),
            if (detail.language != null || detail.languageOther != null)
              _InfoTile(
                icon: Icons.translate,
                label: l10n.language,
                value: detail.language?.resolve(locale) ?? detail.languageOther!,
              ),
            if (detail.originNote != null)
              _InfoTile(icon: Icons.history_edu, label: l10n.originNote, value: detail.originNote!),
            if (detail.tags.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: detail.tags.map((String tag) => Chip(label: Text('#$tag'))).toList(),
              ),
            ],
            if (detail.transcript != null)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(l10n.transcript),
                children: <Widget>[
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SelectableText(detail.transcript!),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _RevisionPicker extends StatelessWidget {
  const _RevisionPicker({required this.state});

  final RecordingDetailLoaded state;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return DropdownMenu<int>(
      label: Text(l10n.versionLabel),
      initialSelection: state.selectedRevisionNo,
      onSelected: (int? revisionNo) {
        if (revisionNo != null) {
          context.read<RecordingDetailCubit>().selectRevision(revisionNo);
        }
      },
      dropdownMenuEntries:
          state.detail.revisions
              .map(
                (MediaRevision revision) => DropdownMenuEntry<int>(
                  value: revision.revisionNo,
                  label:
                      revision.isOriginal
                          ? l10n.versionOriginal
                          : l10n.versionRevision(revision.revisionNo),
                ),
              )
              .toList(),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(label, style: Theme.of(context).textTheme.labelLarge),
    subtitle: Text(value),
  );
}

class _AreaMap extends StatelessWidget {
  const _AreaMap({required this.polygons, required this.mapTilerKey});

  final List<AreaPolygon> polygons;
  final String mapTilerKey;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<LatLng> allPoints = <LatLng>[
      for (final AreaPolygon polygon in polygons) ...polygon.outer,
    ];
    return SizedBox(
      height: 200,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FlutterMap(
          options: MapOptions(
            initialCameraFit: CameraFit.coordinates(
              coordinates: allPoints,
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
