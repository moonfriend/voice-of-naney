import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/lookup_item.dart';
import '../../domain/repositories/lookup_repository.dart';

enum LookupsStatus { initial, loading, ready, failure }

class LookupsState extends Equatable {
  const LookupsState({
    this.status = LookupsStatus.initial,
    this.cultures = const <LookupItem>[],
    this.languages = const <LookupItem>[],
  });

  final LookupsStatus status;
  final List<LookupItem> cultures;
  final List<LookupItem> languages;

  List<LookupItem> get activeCultures => cultures.where((LookupItem item) => item.active).toList();

  List<LookupItem> get activeLanguages =>
      languages.where((LookupItem item) => item.active).toList();

  @override
  List<Object?> get props => <Object?>[status, cultures, languages];
}

/// Curated cultures and languages, shared by the map filters and the upload form.
class LookupsCubit extends Cubit<LookupsState> {
  LookupsCubit(this._repository) : super(const LookupsState());

  final LookupRepository _repository;

  Future<void> load() async {
    emit(const LookupsState(status: LookupsStatus.loading));
    try {
      // Future.wait rethrows the first error as-is, so failures keep their type.
      final List<List<LookupItem>> lists = await Future.wait(<Future<List<LookupItem>>>[
        _repository.cultures(),
        _repository.languages(),
      ]);
      emit(LookupsState(status: LookupsStatus.ready, cultures: lists[0], languages: lists[1]));
    } on Failure {
      emit(const LookupsState(status: LookupsStatus.failure));
    }
  }
}
