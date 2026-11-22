import 'package:equatable/equatable.dart';

import '../../../../core/i18n/localized_name.dart';

/// An entry of an admin-curated list (cultures/ethnicities or languages).
class LookupItem extends Equatable {
  const LookupItem({required this.id, required this.name, required this.active});

  final int id;
  final LocalizedName name;

  /// Inactive items stay readable for old recordings but are not offered to uploaders.
  final bool active;

  @override
  List<Object?> get props => <Object?>[id, name, active];
}
