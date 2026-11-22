part of 'map_cubit.dart';

enum MapStatus { initial, loading, ready, failure }

class MapState extends Equatable {
  const MapState({
    this.status = MapStatus.initial,
    this.pins = const <MapPin>[],
    this.areas = const <PlaceArea>[],
    this.filter = const RecordingFilter(),
    this.selectedPlaceId,
    this.failure,
  });

  final MapStatus status;

  /// Kept while reloading so markers do not flicker when the map moves.
  final List<MapPin> pins;
  final List<PlaceArea> areas;
  final RecordingFilter filter;
  final int? selectedPlaceId;
  final Failure? failure;

  MapPin? get selectedPin {
    for (final MapPin pin in pins) {
      if (pin.placeId == selectedPlaceId) {
        return pin;
      }
    }
    return null;
  }

  MapState copyWith({
    MapStatus? status,
    List<MapPin>? pins,
    List<PlaceArea>? areas,
    RecordingFilter? filter,
    int? Function()? selectedPlaceId,
    Failure? Function()? failure,
  }) => MapState(
    status: status ?? this.status,
    pins: pins ?? this.pins,
    areas: areas ?? this.areas,
    filter: filter ?? this.filter,
    selectedPlaceId: selectedPlaceId != null ? selectedPlaceId() : this.selectedPlaceId,
    failure: failure != null ? failure() : this.failure,
  );

  @override
  List<Object?> get props => <Object?>[status, pins, areas, filter, selectedPlaceId, failure];
}
