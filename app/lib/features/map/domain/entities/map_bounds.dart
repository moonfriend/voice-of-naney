import 'package:equatable/equatable.dart';

class MapBounds extends Equatable {
  const MapBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  final double south;
  final double west;
  final double north;
  final double east;

  @override
  List<Object?> get props => <Object?>[south, west, north, east];
}
