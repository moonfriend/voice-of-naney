import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/recording_kind.dart';
import '../../domain/entities/recording_filter.dart';

/// Edits a copy of the filter; the map only reloads when the visitor applies it.
class FilterDraftCubit extends Cubit<RecordingFilter> {
  FilterDraftCubit(super.initial);

  void toggleCulture(int id) => emit(state.copyWith(cultureIds: _toggle(state.cultureIds, id)));

  void toggleLanguage(int id) => emit(state.copyWith(languageIds: _toggle(state.languageIds, id)));

  void toggleKind(RecordingKind kind) => emit(state.copyWith(kinds: _toggle(state.kinds, kind)));

  void setTag(String tag) => emit(state.copyWith(tag: () => tag));

  void clear() => emit(const RecordingFilter());

  static Set<T> _toggle<T>(Set<T> values, T value) =>
      values.contains(value) ? (Set<T>.of(values)..remove(value)) : <T>{...values, value};
}
