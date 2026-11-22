import '../entities/lookup_item.dart';

abstract interface class LookupRepository {
  Future<List<LookupItem>> cultures();

  Future<List<LookupItem>> languages();
}
