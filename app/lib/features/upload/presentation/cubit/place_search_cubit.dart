import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/place_choice.dart';
import '../../domain/repositories/upload_repositories.dart';

enum SearchStatus { idle, searching, ready, failure }

enum BoundaryStatus { none, loading, found, missing, failure }

class PlaceSearchState extends Equatable {
  const PlaceSearchState({
    this.status = SearchStatus.idle,
    this.results = const <PlaceSearchResult>[],
    this.selected,
    this.boundaryStatus = BoundaryStatus.none,
    this.boundary,
  });

  final SearchStatus status;
  final List<PlaceSearchResult> results;
  final PlaceSearchResult? selected;
  final BoundaryStatus boundaryStatus;
  final OsmPlaceChoice? boundary;

  @override
  List<Object?> get props => <Object?>[status, results, selected, boundaryStatus, boundary];
}

/// Search-as-you-type for origin places, then fetches the chosen place's boundary.
class PlaceSearchCubit extends Cubit<PlaceSearchState> {
  PlaceSearchCubit(this._repository, {Duration debounce = const Duration(milliseconds: 400)})
    : _debounce = debounce,
      super(const PlaceSearchState());

  final PlaceLookupRepository _repository;
  final Duration _debounce;
  Timer? _timer;
  int _generation = 0;

  void queryChanged(String query) {
    _timer?.cancel();
    if (query.trim().length < 2) {
      _generation += 1;
      emit(const PlaceSearchState());
      return;
    }
    _timer = Timer(_debounce, () => _search(query));
  }

  Future<void> _search(String query) async {
    final int generation = ++_generation;
    emit(PlaceSearchState(status: SearchStatus.searching, results: state.results));
    try {
      final List<PlaceSearchResult> results = await _repository.search(query);
      if (generation == _generation && !isClosed) {
        emit(PlaceSearchState(status: SearchStatus.ready, results: results));
      }
    } on Failure {
      if (generation == _generation && !isClosed) {
        emit(const PlaceSearchState(status: SearchStatus.failure));
      }
    }
  }

  Future<void> choose(PlaceSearchResult result) async {
    emit(
      PlaceSearchState(
        status: state.status,
        results: state.results,
        selected: result,
        boundaryStatus: result.hasBoundary ? BoundaryStatus.loading : BoundaryStatus.missing,
      ),
    );
    if (!result.hasBoundary) {
      return;
    }
    try {
      final OsmPlaceChoice? boundary = await _repository.boundary(result);
      if (isClosed || state.selected != result) {
        return;
      }
      emit(
        PlaceSearchState(
          status: state.status,
          results: state.results,
          selected: result,
          boundaryStatus: boundary == null ? BoundaryStatus.missing : BoundaryStatus.found,
          boundary: boundary,
        ),
      );
    } on Failure {
      if (!isClosed && state.selected == result) {
        emit(
          PlaceSearchState(
            status: state.status,
            results: state.results,
            selected: result,
            boundaryStatus: BoundaryStatus.failure,
          ),
        );
      }
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
