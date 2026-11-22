import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

enum AreaMode { search, draw }

class AreaModeState {
  const AreaModeState(this.mode, {this.drawCenter});

  final AreaMode mode;

  /// Where to start drawing (e.g. the place the uploader searched for).
  final LatLng? drawCenter;
}

class AreaModeCubit extends Cubit<AreaModeState> {
  AreaModeCubit() : super(const AreaModeState(AreaMode.search));

  void search() => emit(const AreaModeState(AreaMode.search));

  void draw({LatLng? around}) => emit(AreaModeState(AreaMode.draw, drawCenter: around));
}
