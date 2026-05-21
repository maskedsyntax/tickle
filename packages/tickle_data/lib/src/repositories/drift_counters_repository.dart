import 'package:drift/drift.dart';
import 'package:tickle_core/tickle_core.dart';
import '../database.dart';

class DriftCountersRepository implements CountersRepository {
  final AppDatabase _db;

  DriftCountersRepository(this._db);

  Counter _mapToDomainCounter(DriftCounter d) {
    return Counter(
      id: d.id,
      title: d.title,
      emoji: d.emoji,
      colorHex: d.colorHex,
      currentCount: d.currentCount,
      goalValue: d.goalValue,
      isArchived: d.isArchived,
      createdAt: d.createdAt,
      sortOrder: d.sortOrder,
    );
  }

  DriftCountersCompanion _mapToDriftCounterCompanion(Counter c) {
    return DriftCountersCompanion(
      id: Value(c.id),
      title: Value(c.title),
      emoji: Value(c.emoji),
      colorHex: Value(c.colorHex),
      currentCount: Value(c.currentCount),
      goalValue: Value(c.goalValue),
      isArchived: Value(c.isArchived),
      createdAt: Value(c.createdAt),
      sortOrder: Value(c.sortOrder),
    );
  }

  CounterLog _mapToDomainLog(DriftCounterLog d) {
    return CounterLog(
      id: d.id,
      counterId: d.counterId,
      timestamp: d.timestamp,
      actionType: CounterActionType.fromJson(d.actionType),
      delta: d.delta,
      resultingCount: d.resultingCount,
    );
  }

  DriftCounterLogsCompanion _mapToDriftLogCompanion(CounterLog l) {
    return DriftCounterLogsCompanion(
      id: Value(l.id),
      counterId: Value(l.counterId),
      timestamp: Value(l.timestamp),
      actionType: Value(l.actionType.toJson()),
      delta: Value(l.delta),
      resultingCount: Value(l.resultingCount),
    );
  }

  @override
  Stream<List<Counter>> watchCounters({bool includeArchived = false}) {
    final query = _db.select(_db.driftCounters);
    if (!includeArchived) {
      query.where((t) => t.isArchived.equals(false));
    }
    // Order by sortOrder ascending, then by createdAt descending
    query.orderBy([
      (t) => OrderingTerm(expression: t.sortOrder, mode: OrderingMode.asc),
      (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
    ]);

    return query.watch().map((rows) => rows.map(_mapToDomainCounter).toList());
  }

  @override
  Future<List<Counter>> getCounters({bool includeArchived = false}) async {
    final query = _db.select(_db.driftCounters);
    if (!includeArchived) {
      query.where((t) => t.isArchived.equals(false));
    }
    query.orderBy([
      (t) => OrderingTerm(expression: t.sortOrder, mode: OrderingMode.asc),
      (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
    ]);

    final rows = await query.get();
    return rows.map(_mapToDomainCounter).toList();
  }

  @override
  Future<Counter?> getCounter(String id) async {
    final query = _db.select(_db.driftCounters)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapToDomainCounter(row) : null;
  }

  @override
  Future<void> saveCounter(Counter counter) async {
    await _db.into(_db.driftCounters).insertOnConflictUpdate(_mapToDriftCounterCompanion(counter));
  }

  @override
  Future<void> deleteCounter(String id) async {
    // Delete logs and counter inside transaction. Note: ForeignKey constraint with cascade delete handles this automatically,
    // but running it in transaction is safe.
    await _db.transaction(() async {
      await (_db.delete(_db.driftCounters)..where((t) => t.id.equals(id))).go();
    });
  }

  @override
  Future<void> updateCounterOrder(List<String> orderedIds) async {
    await _db.transaction(() async {
      for (int i = 0; i < orderedIds.length; i++) {
        await (_db.update(_db.driftCounters)
              ..where((t) => t.id.equals(orderedIds[i])))
            .write(DriftCountersCompanion(sortOrder: Value(i)));
      }
    });
  }

  @override
  Stream<List<CounterLog>> watchLogs(String counterId) {
    final query = _db.select(_db.driftCounterLogs)
      ..where((t) => t.counterId.equals(counterId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
        // UUID v7 ids embed creation time, so this is a chronological tiebreaker
        // when multiple logs land in the same second.
        (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
      ]);

    return query.watch().map((rows) => rows.map(_mapToDomainLog).toList());
  }

  @override
  Future<List<CounterLog>> getLogs(String counterId) async {
    final query = _db.select(_db.driftCounterLogs)
      ..where((t) => t.counterId.equals(counterId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
      ]);

    final rows = await query.get();
    return rows.map(_mapToDomainLog).toList();
  }

  @override
  Future<void> addLog(CounterLog log) async {
    await _db.into(_db.driftCounterLogs).insert(_mapToDriftLogCompanion(log));
  }

  @override
  Future<void> clearLogs(String counterId) async {
    await (_db.delete(_db.driftCounterLogs)..where((t) => t.counterId.equals(counterId))).go();
  }

  @override
  Future<List<CounterLog>> getAllLogs() async {
    final query = _db.select(_db.driftCounterLogs)
      ..orderBy([
        (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
        (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
      ]);
    final rows = await query.get();
    return rows.map(_mapToDomainLog).toList();
  }
}
