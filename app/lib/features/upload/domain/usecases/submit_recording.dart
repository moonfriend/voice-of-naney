import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../entities/upload_draft.dart';
import '../entities/upload_source.dart';
import '../repositories/upload_repositories.dart';

/// What has already succeeded, so a retry after a failure does not re-upload files.
class SubmissionCheckpoint extends Equatable {
  const SubmissionCheckpoint({this.mediaUploadId, this.photoUploadId, this.placeId});

  final String? mediaUploadId;
  final String? photoUploadId;
  final int? placeId;

  @override
  List<Object?> get props => <Object?>[mediaUploadId, photoUploadId, placeId];
}

enum SubmissionStage { uploadingMedia, uploadingPhoto, savingPlace, savingRecording }

class SubmissionProgress extends Equatable {
  const SubmissionProgress(this.stage, {this.sentBytes = 0, this.totalBytes = 0});

  final SubmissionStage stage;
  final int sentBytes;
  final int totalBytes;

  double? get fraction => totalBytes == 0 ? null : (sentBytes / totalBytes).clamp(0, 1).toDouble();

  @override
  List<Object?> get props => <Object?>[stage, sentBytes, totalBytes];
}

/// Uploads files, saves the origin area, then creates the recording — in that order,
/// because the database only accepts verified uploads and existing places.
@injectable
class SubmitRecording {
  SubmitRecording(this._files, this._places, this._recordings);

  final FileUploadRepository _files;
  final PlaceLookupRepository _places;
  final RecordingSubmissionRepository _recordings;

  /// Returns the new recording id. On failure, [onCheckpoint] has recorded the
  /// completed steps; pass that checkpoint back to resume.
  Future<String> call(
    UploadDraft draft, {
    SubmissionCheckpoint checkpoint = const SubmissionCheckpoint(),
    required void Function(SubmissionCheckpoint) onCheckpoint,
    required void Function(SubmissionProgress) onProgress,
  }) async {
    if (!draft.isReady) {
      throw StateError('Draft is not complete: ${draft.issues}');
    }
    SubmissionCheckpoint current = checkpoint;

    String? mediaUploadId = current.mediaUploadId;
    if (mediaUploadId == null) {
      final UploadSource media = draft.media!;
      onProgress(SubmissionProgress(SubmissionStage.uploadingMedia, totalBytes: media.size));
      mediaUploadId = await _files.upload(
        media,
        UploadPurpose.media,
        onProgress:
            (int sent) => onProgress(
              SubmissionProgress(
                SubmissionStage.uploadingMedia,
                sentBytes: sent,
                totalBytes: media.size,
              ),
            ),
      );
      current = SubmissionCheckpoint(mediaUploadId: mediaUploadId, placeId: current.placeId);
      onCheckpoint(current);
    }

    String? photoUploadId = current.photoUploadId;
    final UploadSource? photo = draft.photo;
    if (photo != null && photoUploadId == null) {
      onProgress(SubmissionProgress(SubmissionStage.uploadingPhoto, totalBytes: photo.size));
      photoUploadId = await _files.upload(
        photo,
        UploadPurpose.photo,
        onProgress:
            (int sent) => onProgress(
              SubmissionProgress(
                SubmissionStage.uploadingPhoto,
                sentBytes: sent,
                totalBytes: photo.size,
              ),
            ),
      );
      current = SubmissionCheckpoint(
        mediaUploadId: mediaUploadId,
        photoUploadId: photoUploadId,
        placeId: current.placeId,
      );
      onCheckpoint(current);
    }

    int? placeId = current.placeId;
    if (placeId == null) {
      onProgress(const SubmissionProgress(SubmissionStage.savingPlace));
      placeId = await _places.save(draft.place!);
      current = SubmissionCheckpoint(
        mediaUploadId: mediaUploadId,
        photoUploadId: photoUploadId,
        placeId: placeId,
      );
      onCheckpoint(current);
    }

    onProgress(const SubmissionProgress(SubmissionStage.savingRecording));
    return _recordings.create(
      draft.toNewRecording(
        placeId: placeId,
        mediaUploadId: mediaUploadId,
        photoUploadId: photoUploadId,
      ),
    );
  }
}
