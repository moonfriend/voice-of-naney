import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/media_type.dart';
import '../../../../core/widgets/recording_kind_label.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../recordings/domain/entities/recording_summary.dart';
import '../../../recordings/presentation/cubit/place_recordings_cubit.dart';
import '../../domain/entities/map_pin.dart';

/// Bottom panel listing the recordings of the selected place.
class PlaceRecordingsPanel extends StatelessWidget {
  const PlaceRecordingsPanel({
    required this.pin,
    required this.onClose,
    required this.onOpenRecording,
    required this.onRetry,
    super.key,
  });

  final MapPin pin;
  final VoidCallback onClose;
  final ValueChanged<String> onOpenRecording;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Locale locale = Localizations.localeOf(context);
    return Card(
      margin: const EdgeInsets.all(12),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.45),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ListTile(
              title: Text(pin.name.resolve(locale), style: Theme.of(context).textTheme.titleMedium),
              subtitle: Text(l10n.recordingsCount(pin.recordingCount)),
              trailing: IconButton(
                tooltip: l10n.close,
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: BlocBuilder<PlaceRecordingsCubit, PlaceRecordingsState>(
                builder:
                    (BuildContext context, PlaceRecordingsState state) => switch (state.status) {
                      PlaceRecordingsStatus.loading => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      PlaceRecordingsStatus.failure => ListTile(
                        title: Text(l10n.placeRecordingsError),
                        trailing: TextButton(onPressed: onRetry, child: Text(l10n.retry)),
                      ),
                      PlaceRecordingsStatus.ready when state.recordings.isEmpty => ListTile(
                        title: Text(l10n.noRecordingsHere),
                      ),
                      PlaceRecordingsStatus.ready => ListView(
                        shrinkWrap: true,
                        children:
                            state.recordings
                                .map(
                                  (RecordingSummary recording) => ListTile(
                                    leading: Icon(
                                      recording.mediaType == MediaType.video
                                          ? Icons.videocam_outlined
                                          : Icons.graphic_eq,
                                    ),
                                    title: Text(recording.title),
                                    subtitle: Text(
                                      <String>[
                                        recordingKindLabel(l10n, recording.kind),
                                        if (recording.performerName != null)
                                          recording.performerName!,
                                        if (recording.yearRecorded != null)
                                          '${recording.yearRecorded}',
                                      ].join(' · '),
                                    ),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => onOpenRecording(recording.id),
                                  ),
                                )
                                .toList(),
                      ),
                    },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
