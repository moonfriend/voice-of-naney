import 'package:equatable/equatable.dart';

/// One of the 1–3 cultures/ethnicities of a recording: from the list or free text.
class CultureChoice extends Equatable {
  const CultureChoice.listed(int this.cultureId) : otherText = null;

  const CultureChoice.other(String this.otherText) : cultureId = null;

  static const int maxPerRecording = 3;
  static const int maxOtherLength = 200;

  final int? cultureId;
  final String? otherText;

  bool get isValid =>
      cultureId != null ||
      (otherText != null &&
          otherText!.trim().isNotEmpty &&
          otherText!.trim().length <= maxOtherLength);

  Map<String, Object?> toJson() =>
      cultureId != null
          ? <String, Object?>{'culture_id': cultureId}
          : <String, Object?>{'other_text': otherText!.trim()};

  @override
  List<Object?> get props => <Object?>[cultureId, otherText];
}
