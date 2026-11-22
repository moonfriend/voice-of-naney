import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/map_bounds.dart';
import '../../domain/entities/map_pin.dart';
import '../../domain/entities/place_area.dart';
import '../../domain/entities/recording_filter.dart';
import '../../domain/repositories/map_repository.dart';

part 'map_state.dart';

/// Loads what is visible on the public map. Viewport changes are debounced because
/// panning fires dozens of events per second.
class MapCubit extends Cubit<MapState> {
  MapCubit(this._repository, {Duration debounce = const Duration(milliseconds: 350)})
    : _debounce = debounce,
      super(const MapState());

  /// From roughly province level, outlines are worth their download size.
  static const double areaZoomThreshold = 8;

  final MapRepository _repository;
  final Duration _debounce;
  Timer? _timer;
  MapBounds? _bounds;
  double _zoom = 0;
  int _generation = 0;

  void viewportChanged(MapBounds bounds, double zoom) {
    _bounds = bounds;
    _zoom = zoom;
    _timer?.cancel();
    _timer = Timer(_debounce, _load);
  }

  Future<void> filterChanged(RecordingFilter filter) {
    emit(state.copyWith(filter: filter, selectedPlaceId: () => null));
    return _load();
  }

  void selectPlace(int? placeId) => emit(state.copyWith(selectedPlaceId: () => placeId));

  Future<void> retry() => _load();

  Future<void> _load() async {
    final MapBounds? bounds = _bounds;
    if (bounds == null) {
      return;
    }
    final int generation = ++_generation;
    final RecordingFilter filter = state.filter;
    emit(state.copyWith(status: MapStatus.loading, failure: () => null));
    try {
      final List<MapPin> pins = await _repository.pinsIn(bounds, filter);
      final List<PlaceArea> areas =
          _zoom >= areaZoomThreshold ? await _repository.areasIn(bounds) : const <PlaceArea>[];
      if (generation != _generation || isClosed) {
        return;
      }
      final Set<int> visiblePlaces = pins.map((MapPin pin) => pin.placeId).toSet();
      emit(
        state.copyWith(
          status: MapStatus.ready,
          pins: pins,
          areas: areas.where((PlaceArea area) => visiblePlaces.contains(area.placeId)).toList(),
        ),
      );
    } on Failure catch (failure) {
      if (generation != _generation || isClosed) {
        return;
      }
      emit(state.copyWith(status: MapStatus.failure, failure: () => failure));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
