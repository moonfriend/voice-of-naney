import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/lookup_item.dart';
import '../../domain/repositories/lookup_repository.dart';
import '../datasources/lookup_remote_data_source.dart';
import '../models/lookup_item_model.dart';

@LazySingleton(as: LookupRepository)
class LookupRepositoryImpl implements LookupRepository {
  LookupRepositoryImpl(this._remote);

  final LookupRemoteDataSource _remote;

  @override
  Future<List<LookupItem>> cultures() => _load('cultures');

  @override
  Future<List<LookupItem>> languages() => _load('languages');

  Future<List<LookupItem>> _load(String table) => guardRemoteCall(
    () async => (await _remote.fetchTable(table)).map(lookupItemFromJson).toList(),
  );
}
