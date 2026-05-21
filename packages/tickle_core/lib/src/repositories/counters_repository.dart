import '../models/counter.dart';
import '../models/counter_log.dart';

abstract class CountersRepository {
  /// Stream active or archived counters.
  Stream<List<Counter>> watchCounters({bool includeArchived = false});

  /// Get active or archived counters once.
  Future<List<Counter>> getCounters({bool includeArchived = false});

  /// Get specific counter.
  Future<Counter?> getCounter(String id);

  /// Create or update counter.
  Future<void> saveCounter(Counter counter);

  /// Hard delete counter and all its logs.
  Future<void> deleteCounter(String id);

  /// Reorder counters according to list of IDs.
  Future<void> updateCounterOrder(List<String> orderedIds);

  /// Watch logs for a specific counter.
  Stream<List<CounterLog>> watchLogs(String counterId);

  /// Get logs for a specific counter once.
  Future<List<CounterLog>> getLogs(String counterId);

  /// Add a log record for a counter transaction.
  Future<void> addLog(CounterLog log);

  /// Clear history for a specific counter.
  Future<void> clearLogs(String counterId);

  /// Get all history logs across all counters.
  Future<List<CounterLog>> getAllLogs();
}
