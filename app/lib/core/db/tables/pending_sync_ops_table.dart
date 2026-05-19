import 'package:drift/drift.dart';

@DataClassName('PendingSyncOp')
class PendingSyncOps extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get opType => text().named('op_type')();
  TextColumn get payloadJson => text().named('payload_json')();
  DateTimeColumn get clientUpdatedAt =>
      dateTime().named('client_updated_at')();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().named('last_error').nullable()();
}
