import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tickle_core/tickle_core.dart';
import 'package:uuid/uuid.dart';

// Models
class CounterStats extends Equatable {
  final int activeStreak;
  final int longestStreak;
  final Map<DateTime, int> heatmapData;

  const CounterStats({
    required this.activeStreak,
    required this.longestStreak,
    required this.heatmapData,
  });

  @override
  List<Object?> get props => [activeStreak, longestStreak, heatmapData];
}

// States
abstract class CounterDetailState extends Equatable {
  const CounterDetailState();

  @override
  List<Object?> get props => [];
}

class CounterDetailInitial extends CounterDetailState {}

class CounterDetailLoading extends CounterDetailState {}

class CounterDetailLoaded extends CounterDetailState {
  final Counter counter;
  final List<CounterLog> logs;
  final CounterStats stats;

  const CounterDetailLoaded({
    required this.counter,
    required this.logs,
    required this.stats,
  });

  @override
  List<Object?> get props => [counter, logs, stats];
}

class CounterDetailError extends CounterDetailState {
  final String message;

  const CounterDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class CounterDetailCubit extends Cubit<CounterDetailState> {
  final CountersRepository _repository;
  final String _counterId;
  StreamSubscription? _logsSubscription;
  Counter? _currentCounter;
  List<CounterLog> _currentLogs = [];

  CounterDetailCubit(this._repository, this._counterId) : super(CounterDetailInitial());

  void loadDetails() async {
    emit(CounterDetailLoading());
    try {
      final counter = await _repository.getCounter(_counterId);
      if (isClosed) return;

      if (counter == null) {
        emit(const CounterDetailError('Counter not found'));
        return;
      }
      _currentCounter = counter;

      _logsSubscription?.cancel();
      _logsSubscription = _repository.watchLogs(_counterId).listen(
        (logs) {
          if (isClosed) return;
          _currentLogs = logs;
          _emitLoaded();
        },
        onError: (error) {
          if (isClosed) return;
          emit(CounterDetailError(error.toString()));
        },
      );
    } catch (e) {
      if (isClosed) return;
      emit(CounterDetailError(e.toString()));
    }
  }

  CounterStats _calculateStats(List<CounterLog> logs) {
    if (logs.isEmpty) {
      return const CounterStats(activeStreak: 0, longestStreak: 0, heatmapData: {});
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final Map<DateTime, int> dailyTaps = {};

    for (final log in logs) {
      if (log.actionType != CounterActionType.increment && log.actionType != CounterActionType.set) {
        continue;
      }
      if (log.delta <= 0) continue;

      final logDate = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
      dailyTaps[logDate] = (dailyTaps[logDate] ?? 0) + log.delta;
    }

    final sortedTapDates = dailyTaps.keys.toList()..sort();
    int longest = 0;
    int current = 0;

    if (sortedTapDates.isNotEmpty) {
      int currentRun = 1;
      for (int i = 0; i < sortedTapDates.length; i++) {
        if (i > 0) {
          final diff = sortedTapDates[i].difference(sortedTapDates[i - 1]).inDays;
          if (diff == 1) {
            currentRun++;
          } else if (diff > 1) {
            if (currentRun > longest) longest = currentRun;
            currentRun = 1;
          }
        }
      }
      if (currentRun > longest) longest = currentRun;

      final hasTapToday = dailyTaps.containsKey(today);
      final yesterday = today.subtract(const Duration(days: 1));
      final hasTapYesterday = dailyTaps.containsKey(yesterday);

      if (hasTapToday || hasTapYesterday) {
        current = 0;
        DateTime checkDate = hasTapToday ? today : yesterday;
        while (dailyTaps.containsKey(checkDate)) {
          current++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        }
      }
    }

    return CounterStats(
      activeStreak: current,
      longestStreak: longest,
      heatmapData: dailyTaps,
    );
  }

  void _emitLoaded() {
    if (isClosed) return;
    if (_currentCounter != null) {
      final stats = _calculateStats(_currentLogs);
      emit(CounterDetailLoaded(
        counter: _currentCounter!,
        logs: List.from(_currentLogs),
        stats: stats,
      ));
    }
  }

  Future<void> increment() async {
    if (_currentCounter == null) return;
    try {
      final timestamp = DateTime.now();
      final logId = const Uuid().v7();
      final newCount = _currentCounter!.currentCount + 1;
      final updatedCounter = _currentCounter!.copyWith(currentCount: newCount);

      _currentCounter = updatedCounter;
      _emitLoaded();

      await _repository.saveCounter(updatedCounter);
      await _repository.addLog(CounterLog(
        id: logId,
        counterId: _counterId,
        timestamp: timestamp,
        actionType: CounterActionType.increment,
        delta: 1,
        resultingCount: newCount,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(CounterDetailError(e.toString()));
    }
  }

  Future<void> decrement() async {
    if (_currentCounter == null) return;
    try {
      final timestamp = DateTime.now();
      final logId = const Uuid().v7();
      final newCount = _currentCounter!.currentCount - 1;
      final updatedCounter = _currentCounter!.copyWith(currentCount: newCount);

      _currentCounter = updatedCounter;
      _emitLoaded();

      await _repository.saveCounter(updatedCounter);
      await _repository.addLog(CounterLog(
        id: logId,
        counterId: _counterId,
        timestamp: timestamp,
        actionType: CounterActionType.decrement,
        delta: -1,
        resultingCount: newCount,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(CounterDetailError(e.toString()));
    }
  }

  Future<void> reset() async {
    if (_currentCounter == null) return;
    try {
      final originalCount = _currentCounter!.currentCount;
      if (originalCount == 0) return;
      final timestamp = DateTime.now();
      final logId = const Uuid().v7();
      final updatedCounter = _currentCounter!.copyWith(currentCount: 0);

      _currentCounter = updatedCounter;
      _emitLoaded();

      await _repository.saveCounter(updatedCounter);
      await _repository.addLog(CounterLog(
        id: logId,
        counterId: _counterId,
        timestamp: timestamp,
        actionType: CounterActionType.reset,
        delta: -originalCount,
        resultingCount: 0,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(CounterDetailError(e.toString()));
    }
  }

  Future<void> clearHistory() async {
    if (_currentCounter == null) return;
    try {
      final updatedCounter = _currentCounter!.copyWith(currentCount: 0);

      // Optimistic update
      _currentCounter = updatedCounter;
      _currentLogs = [];
      _emitLoaded();

      // Write to repository
      await _repository.clearLogs(_counterId);
      await _repository.saveCounter(updatedCounter);
    } catch (e) {
      if (isClosed) return;
      emit(CounterDetailError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _logsSubscription?.cancel();
    return super.close();
  }
}
