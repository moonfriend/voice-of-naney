import '../../../../core/i18n/localized_name.dart';
import '../../domain/entities/lookup_item.dart';

LookupItem lookupItemFromJson(Map<String, Object?> json) => LookupItem(
  id: (json['id']! as num).toInt(),
  name: LocalizedName.fromJson(json),
  active: json['active'] as bool? ?? true,
);
