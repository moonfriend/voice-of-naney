import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/culture_choice.dart';
import '../../domain/entities/upload_draft.dart';
import '../../domain/usecases/submit_recording.dart';

sealed class SubmissionState extends Equatable {
  const SubmissionState();

  @override
  List<Object?> get props => <Object?>[];
}

class NotSubmitted extends SubmissionState {
  const NotSubmitted();
}

class Submitting extends SubmissionState {
  const Submitting([this.progress]);

  final SubmissionProgress? progress;

  @override
  List<Object?> get props => <Object?>[progress];
}

class SubmissionFailed extends SubmissionState {
  const SubmissionFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => <Object?>[failure];
}

class Submitted extends SubmissionState {
  const Submitted(this.recordingId);

  final String recordingId;

  @override
  List<Object?> get props => <Object?>[recordingId];
}

class UploadFormState extends Equatable {
  const UploadFormState({
    this.draft = const UploadDraft(),
    this.step = UploadStep.media,
    this.showIssues = false,
    this.submission = const NotSubmitted(),
    this.checkpoint = const SubmissionCheckpoint(),
  });

  final UploadDraft draft;
  final UploadStep step;

  /// Issues are only shown after the uploader tried to continue, not while typing.
  final bool showIssues;
  final SubmissionState submission;
  final SubmissionCheckpoint checkpoint;

  Set<DraftIssue> get visibleIssues => showIssues ? draft.issuesFor(step) : const <DraftIssue>{};

  bool get isBusy => submission is Submitting;

  UploadFormState copyWith({
    UploadDraft? draft,
    UploadStep? step,
    bool? showIssues,
    SubmissionState? submission,
    SubmissionCheckpoint? checkpoint,
  }) => UploadFormState(
    draft: draft ?? this.draft,
    step: step ?? this.step,
    showIssues: showIssues ?? this.showIssues,
    submission: submission ?? this.submission,
    checkpoint: checkpoint ?? this.checkpoint,
  );

  @override
  List<Object?> get props => <Object?>[draft, step, showIssues, submission, checkpoint];
}

/// Drives the step-by-step upload form and its submission.
class UploadFormCubit extends Cubit<UploadFormState> {
  UploadFormCubit(this._submit) : super(const UploadFormState());

  final SubmitRecording _submit;

  void edit(UploadDraft Function(UploadDraft draft) change) {
    if (state.isBusy) {
      return;
    }
    final UploadDraft updated = change(state.draft);
    emit(
      state.copyWith(
        draft: updated,
        checkpoint: _invalidate(state.checkpoint, state.draft, updated),
      ),
    );
  }

  void addCulture(CultureChoice choice) {
    if (state.draft.cultures.length >= CultureChoice.maxPerRecording) {
      return;
    }
    edit((UploadDraft d) => d.copyWith(cultures: <CultureChoice>[...d.cultures, choice]));
  }

  void replaceCulture(int index, CultureChoice choice) => edit(
    (UploadDraft d) => d.copyWith(cultures: List<CultureChoice>.of(d.cultures)..[index] = choice),
  );

  void removeCulture(int index) => edit(
    (UploadDraft d) => d.copyWith(cultures: List<CultureChoice>.of(d.cultures)..removeAt(index)),
  );

  void next() {
    if (state.draft.issuesFor(state.step).isNotEmpty) {
      emit(state.copyWith(showIssues: true));
      return;
    }
    final int index = state.step.index;
    if (index < UploadStep.values.length - 1) {
      emit(state.copyWith(step: UploadStep.values[index + 1], showIssues: false));
    }
  }

  void back() {
    final int index = state.step.index;
    if (index > 0 && !state.isBusy) {
      emit(state.copyWith(step: UploadStep.values[index - 1], showIssues: false));
    }
  }

  /// Lets the uploader jump back to an earlier step to fix something.
  void goTo(UploadStep step) {
    if (step.index < state.step.index && !state.isBusy) {
      emit(state.copyWith(step: step, showIssues: false));
    }
  }

  Future<void> submit() async {
    if (state.isBusy) {
      return;
    }
    if (!state.draft.isReady) {
      final UploadStep firstIncomplete = UploadStep.values.firstWhere(
        (UploadStep step) => state.draft.issuesFor(step).isNotEmpty,
      );
      emit(state.copyWith(step: firstIncomplete, showIssues: true));
      return;
    }
    emit(state.copyWith(submission: const Submitting()));
    try {
      final String recordingId = await _submit(
        state.draft,
        checkpoint: state.checkpoint,
        onCheckpoint:
            (SubmissionCheckpoint checkpoint) => emit(state.copyWith(checkpoint: checkpoint)),
        onProgress:
            (SubmissionProgress progress) => emit(state.copyWith(submission: Submitting(progress))),
      );
      emit(state.copyWith(submission: Submitted(recordingId)));
    } on Failure catch (failure) {
      emit(state.copyWith(submission: SubmissionFailed(failure)));
    } on Object catch (error) {
      // Never leave the form stuck in "submitting"; the error is still reported.
      emit(state.copyWith(submission: SubmissionFailed(UnexpectedFailure(error))));
    }
  }

  /// A different file or area must be uploaded/saved again on the next submit.
  static SubmissionCheckpoint _invalidate(
    SubmissionCheckpoint checkpoint,
    UploadDraft before,
    UploadDraft after,
  ) => SubmissionCheckpoint(
    mediaUploadId: before.media == after.media ? checkpoint.mediaUploadId : null,
    photoUploadId: before.photo == after.photo ? checkpoint.photoUploadId : null,
    placeId: before.place == after.place ? checkpoint.placeId : null,
  );
}
