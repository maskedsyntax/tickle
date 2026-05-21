import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tickle_core/tickle_core.dart';

// Stats Model
class CounterDistribution extends Equatable {
  final String title;
  final String? emoji;
  final String colorHex;
  final int count;

  const CounterDistribution({
    required this.title,
    required this.emoji,
    required this.colorHex,
    required this.count,
  });

  @override
  List<Object?> get props => [title, emoji, colorHex, count];
}

class AppStats extends Equatable {
  final int totalTapsToday;
  final int totalTapsYesterday;
  final int totalTapsThisWeek;
  final int totalTapsThisMonth;
  final int activeStreak;
  final int longestStreak;
  final int averageTapsPerDay;
  final DateTime? peakDay;
  final int peakDayCount;
  final Map<DateTime, int> heatmapData; // Date (YMD) -> Total count
  final List<CounterDistribution> counterDistributions;

  const AppStats({
    required this.totalTapsToday,
    required this.totalTapsYesterday,
    required this.totalTapsThisWeek,
    required this.totalTapsThisMonth,
    required this.activeStreak,
    required this.longestStreak,
    required this.averageTapsPerDay,
    required this.peakDay,
    required this.peakDayCount,
    required this.heatmapData,
    required this.counterDistributions,
  });

  factory AppStats.empty() {
    return const AppStats(
      totalTapsToday: 0,
      totalTapsYesterday: 0,
      totalTapsThisWeek: 0,
      totalTapsThisMonth: 0,
      activeStreak: 0,
      longestStreak: 0,
      averageTapsPerDay: 0,
      peakDay: null,
      peakDayCount: 0,
      heatmapData: {},
      counterDistributions: [],
    );
  }

  @override
  List<Object?> get props => [
        totalTapsToday,
        totalTapsYesterday,
        totalTapsThisWeek,
        totalTapsThisMonth,
        activeStreak,
        longestStreak,
        averageTapsPerDay,
        peakDay,
        peakDayCount,
        heatmapData,
        counterDistributions,
      ];
}

// States
abstract class StatsState extends Equatable {
  const StatsState();

  @override
  List<Object?> get props => [];
}

class StatsInitial extends StatsState {}

class StatsLoading extends StatsState {}

class StatsLoaded extends StatsState {
  final AppStats stats;

  const StatsLoaded(this.stats);

  @override
  List<Object?> get props => [stats];
}

class StatsError extends StatsState {
  final String message;

  const StatsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class StatsCubit extends Cubit<StatsState> {
  final CountersRepository _repository;
  StreamSubscription? _countersSubscription;

  StatsCubit(this._repository) : super(StatsInitial());

  void loadStats() {
    emit(StatsLoading());
    _countersSubscription?.cancel();
    // We listen to watchCounters() which changes whenever counters or count updates,
    // and recompute the statistics reactively.
    _countersSubscription = _repository.watchCounters(includeArchived: true).listen(
      (counters) async {
        try {
          final logs = await _repository.getAllLogs();
          if (isClosed) return;
          final stats = _calculateStats(counters, logs);
          emit(StatsLoaded(stats));
        } catch (e) {
          if (isClosed) return;
          emit(StatsError(e.toString()));
        }
      },
      onError: (error) {
        if (isClosed) return;
        emit(StatsError(error.toString()));
      },
    );
  }

  AppStats _calculateStats(List<Counter> counters, List<CounterLog> logs) {
    if (logs.isEmpty) {
      return AppStats.empty();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<DateTime, int> dailyTaps = {};
    int totalToday = 0;
    int totalYesterday = 0;
    int totalThisWeek = 0;
    int totalThisMonth = 0;

    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final monthStart = DateTime(today.year, today.month, 1);

    for (final log in logs) {
      if (log.actionType != CounterActionType.increment && log.actionType != CounterActionType.set) {
        continue;
      }
      if (log.delta <= 0) continue;

      final logDate = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
      dailyTaps[logDate] = (dailyTaps[logDate] ?? 0) + log.delta;

      if (logDate == today) {
        totalToday += log.delta;
      }
      if (logDate == yesterday) {
        totalYesterday += log.delta;
      }
      if (logDate.isAfter(weekStart.subtract(const Duration(seconds: 1)))) {
        totalThisWeek += log.delta;
      }
      if (logDate.isAfter(monthStart.subtract(const Duration(seconds: 1)))) {
        totalThisMonth += log.delta;
      }
    }

    // Streaks
    // Get unique sorted dates of taps
    final sortedTapDates = dailyTaps.keys.toList()..sort();
    int longest = 0;
    int current = 0;
    
    if (sortedTapDates.isNotEmpty) {
      // Calculate longest streak
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

      // Calculate active streak
      // Check if there was a tap today or yesterday
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

    // Average taps per day over active tracking period
    int averageTaps = 0;
    if (sortedTapDates.isNotEmpty) {
      final firstDate = sortedTapDates.first;
      final daysTracked = today.difference(firstDate).inDays + 1;
      final totalTaps = dailyTaps.values.fold<int>(0, (sum, val) => sum + val);
      averageTaps = (totalTaps / daysTracked).round();
    }

    // Peak day
    DateTime? peakDay;
    int maxTaps = 0;
    dailyTaps.forEach((date, count) {
      if (count > maxTaps) {
        maxTaps = count;
        peakDay = date;
      }
    });

    // Distributions across counters (sorted desc by count, only non-zero)
    final distributions = counters
        .where((c) => c.currentCount > 0)
        .map((c) => CounterDistribution(
              title: c.title,
              emoji: c.emoji,
              colorHex: c.colorHex,
              count: c.currentCount,
            ))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return AppStats(
      totalTapsToday: totalToday,
      totalTapsYesterday: totalYesterday,
      totalTapsThisWeek: totalThisWeek,
      totalTapsThisMonth: totalThisMonth,
      activeStreak: current,
      longestStreak: longest,
      averageTapsPerDay: averageTaps,
      peakDay: peakDay,
      peakDayCount: maxTaps,
      heatmapData: dailyTaps,
      counterDistributions: distributions,
    );
  }

  @override
  Future<void> close() {
    _countersSubscription?.cancel();
    return super.close();
  }
}
