import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/datasources/file_picker_service.dart';
import '../../domain/entities/upload_draft.dart';
import '../cubit/upload_form_cubit.dart';
import '../widgets/area_step.dart';
import '../widgets/consent_step.dart';
import '../widgets/cultures_step.dart';
import '../widgets/details_step.dart';
import '../widgets/media_step.dart';

/// Step-by-step upload form. Expects the upload cubits above it (see UploadRoute).
class UploadView extends StatelessWidget {
  const UploadView({required this.picker, required this.mapTilerKey, super.key});

  final FilePickerService picker;
  final String mapTilerKey;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return BlocConsumer<UploadFormCubit, UploadFormState>(
      listenWhen:
          (UploadFormState previous, UploadFormState current) =>
              current.submission is Submitted && previous.submission is! Submitted,
      listener:
          (BuildContext context, UploadFormState state) =>
              context.go(AppRoutes.recordingPath((state.submission as Submitted).recordingId)),
      buildWhen:
          (UploadFormState previous, UploadFormState current) =>
              previous.step != current.step || previous.isBusy != current.isBusy,
      builder: (BuildContext context, UploadFormState state) {
        final UploadFormCubit form = context.read<UploadFormCubit>();
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Stepper(
              currentStep: state.step.index,
              onStepTapped: (int index) => form.goTo(UploadStep.values[index]),
              controlsBuilder: (BuildContext context, ControlsDetails details) {
                // Collapsed steps are still built by Stepper; only the open one gets buttons.
                if (details.stepIndex != details.currentStep) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsetsDirectional.only(top: 16),
                  child: Row(
                    children: <Widget>[
                      if (state.step != UploadStep.consent)
                        FilledButton(onPressed: form.next, child: Text(l10n.next)),
                      if (state.step != UploadStep.media) ...<Widget>[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: state.isBusy ? null : form.back,
                          child: Text(l10n.back),
                        ),
                      ],
                    ],
                  ),
                );
              },
              steps: <Step>[
                _step(state, UploadStep.media, l10n.stepMedia, MediaStep(picker: picker)),
                _step(state, UploadStep.details, l10n.stepDetails, const DetailsStep()),
                _step(state, UploadStep.cultures, l10n.stepCultures, const CulturesStep()),
                _step(state, UploadStep.area, l10n.stepArea, AreaStep(mapTilerKey: mapTilerKey)),
                _step(state, UploadStep.consent, l10n.stepConsent, const ConsentStep()),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Only the current step's content is built, so maps and pickers are not kept alive.
  static Step _step(UploadFormState state, UploadStep step, String title, Widget content) => Step(
    title: Text(title),
    isActive: state.step.index >= step.index,
    state: state.step.index > step.index ? StepState.complete : StepState.indexed,
    content: state.step == step ? content : const SizedBox.shrink(),
  );
}
