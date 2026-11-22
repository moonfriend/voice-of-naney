import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/geo/area_polygon.dart';
import '../../domain/entities/place_choice.dart';

class AreaDrawState extends Equatable {
  const AreaDrawState({this.points = const <LatLng>[], this.nameEn = '', this.nameFa = ''});

  final List<LatLng> points;
  final String nameEn;
  final String nameFa;

  bool get hasName => nameEn.trim().isNotEmpty || nameFa.trim().isNotEmpty;

  @override
  List<Object?> get props => <Object?>[points, nameEn, nameFa];
}

/// An area the uploader draws by tapping the map, plus its name.
class AreaDrawCubit extends Cubit<AreaDrawState> {
  AreaDrawCubit() : super(const AreaDrawState());

  static const int minPoints = 3;
  static const int maxPoints = 100;

  bool get isComplete => state.points.length >= minPoints;

  void addPoint(LatLng point) {
    if (state.points.length < maxPoints) {
      emit(
        AreaDrawState(
          points: <LatLng>[...state.points, point],
          nameEn: state.nameEn,
          nameFa: state.nameFa,
        ),
      );
    }
  }

  void undo() {
    if (state.points.isNotEmpty) {
      emit(
        AreaDrawState(
          points: state.points.sublist(0, state.points.length - 1),
          nameEn: state.nameEn,
          nameFa: state.nameFa,
        ),
      );
    }
  }

  void clear() => emit(AreaDrawState(nameEn: state.nameEn, nameFa: state.nameFa));

  void setNames({String? nameEn, String? nameFa}) => emit(
    AreaDrawState(
      points: state.points,
      nameEn: nameEn ?? state.nameEn,
      nameFa: nameFa ?? state.nameFa,
    ),
  );

  AreaPolygon? toPolygon() =>
      isComplete ? AreaPolygon(outer: List<LatLng>.unmodifiable(state.points)) : null;

  /// Null until there are enough points and at least one name.
  DrawnPlaceChoice? toPlace() {
    final AreaPolygon? polygon = toPolygon();
    if (polygon == null || !state.hasName) {
      return null;
    }
    String? clean(String value) => value.trim().isEmpty ? null : value.trim();
    return DrawnPlaceChoice(
      nameEn: clean(state.nameEn),
      nameFa: clean(state.nameFa),
      polygons: <AreaPolygon>[polygon],
    );
  }
}
