import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart' show NativeDatabase;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

class DriftCounters extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get emoji => text().nullable()();
  TextColumn get colorHex => text()();
  IntColumn get currentCount => integer().withDefault(const Constant(0))();
  IntColumn get goalValue => integer().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class DriftCounterLogs extends Table {
  TextColumn get id => text()();
  TextColumn get counterId => text().references(DriftCounters, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get actionType => text()();
  IntColumn get delta => integer()();
  IntColumn get resultingCount => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [DriftCounters, DriftCounterLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;
}

QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'tickle.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
