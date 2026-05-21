import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tickle_core/tickle_core.dart';
import 'package:uuid/uuid.dart';

// States
abstract class CountersState extends Equatable {
  const CountersState();

  @override
  List<Object?> get props => [];
}

class CountersInitial extends CountersState {}

class CountersLoading extends CountersState {}

class CountersLoaded extends CountersState {
  final List<Counter> activeCounters;
  final List<Counter> archivedCounters;

  const CountersLoaded({
    required this.activeCounters,
    required this.archivedCounters,
  });

  @override
  List<Object?> get props => [activeCounters, archivedCounters];
}

class CountersError extends CountersState {
  final String message;

  const CountersError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class CountersCubit extends Cubit<CountersState> {
  final CountersRepository _repository;
  StreamSubscription? _activeSubscription;
  StreamSubscription? _archivedSubscription;

  List<Counter> _activeCounters = [];
  List<Counter> _archivedCounters = [];

  CountersCubit(this._repository) : super(CountersInitial());

  void loadCounters() {
    emit(CountersLoading());
    _activeSubscription?.cancel();
    _archivedSubscription?.cancel();

    _activeSubscription = _repository.watchCounters(includeArchived: false).listen(
      (counters) {
        if (isClosed) return;
        _activeCounters = counters;
        _emitLoaded();
      },
      onError: (error) {
        if (isClosed) return;
        emit(CountersError(error.toString()));
      },
    );

    _archivedSubscription = _repository.watchCounters(includeArchived: true).listen(
      (counters) {
        if (isClosed) return;
        // filter manually to get archived counters only
        _archivedCounters = counters.where((c) => c.isArchived).toList();
        _emitLoaded();
      },
      onError: (error) {
        if (isClosed) return;
        emit(CountersError(error.toString()));
      },
    );
  }

  void _emitLoaded() {
    if (isClosed) return;
    emit(CountersLoaded(
      activeCounters: List.from(_activeCounters),
      archivedCounters: List.from(_archivedCounters),
    ));
  }

  Future<void> createCounter({
    required String title,
    String? emoji,
    required String colorHex,
    int? goalValue,
  }) async {
    try {
      final newCounter = Counter(
        id: const Uuid().v4(),
        title: title,
        emoji: emoji,
        colorHex: colorHex,
        currentCount: 0,
        goalValue: goalValue,
        isArchived: false,
        createdAt: DateTime.now(),
        sortOrder: _activeCounters.length,
      );
      await _repository.saveCounter(newCounter);

      // Log creation action
      final log = CounterLog(
        id: const Uuid().v4(),
        counterId: newCounter.id,
        timestamp: DateTime.now(),
        actionType: CounterActionType.set,
        delta: 0,
        resultingCount: 0,
      );
      await _repository.addLog(log);
    } catch (e) {
      if (isClosed) return;
      emit(CountersError(e.toString()));
    }
  }

  Future<void> renameCounter(String id, String newTitle) async {
    try {
      final counter = await _repository.getCounter(id);
      if (counter != null) {
        await _repository.saveCounter(counter.copyWith(title: newTitle));
      }
    } catch (e) {
      if (isClosed) return;
      emit(CountersError(e.toString()));
    }
  }

  Future<void> updateGoal(String id, int? newGoal) async {
    try {
      final counter = await _repository.getCounter(id);
      if (counter != null) {
        await _repository.saveCounter(counter.copyWith(goalValue: newGoal));
      }
    } catch (e) {
      if (isClosed) return;
      emit(CountersError(e.toString()));
    }
  }

  Future<void> archiveCounter(String id) async {
    try {
      final counter = await _repository.getCounter(id);
      if (counter != null) {
        // Move to archive and set sortOrder to 0
        await _repository.saveCounter(counter.copyWith(isArchived: true, sortOrder: 0));
        
        // Re-index remaining active counters sortOrder
        final remaining = _activeCounters.where((c) => c.id != id).toList();
        final orderedIds = remaining.map((c) => c.id).toList();
        await _repository.updateCounterOrder(orderedIds);
      }
    } catch (e) {
      if (isClosed) return;
      emit(CountersError(e.toString()));
    }
  }

  Future<void> restoreCounter(String id) async {
    try {
      final counter = await _repository.getCounter(id);
      if (counter != null) {
        await _repository.saveCounter(counter.copyWith(
          isArchived: false,
          sortOrder: _activeCounters.length,
        ));
      }
    } catch (e) {
      if (isClosed) return;
      emit(CountersError(e.toString()));
    }
  }

  Future<void> deleteCounter(String id) async {
    try {
      await _repository.deleteCounter(id);
      // Reorder remaining active counters
      final remaining = _activeCounters.where((c) => c.id != id).toList();
      final orderedIds = remaining.map((c) => c.id).toList();
      await _repository.updateCounterOrder(orderedIds);
    } catch (e) {
      if (isClosed) return;
      emit(CountersError(e.toString()));
    }
  }

  Future<void> duplicateCounter(String id) async {
    try {
      final counter = await _repository.getCounter(id);
      if (counter != null) {
        final duplicated = Counter(
          id: const Uuid().v4(),
          title: '${counter.title} (Copy)',
          emoji: counter.emoji,
          colorHex: counter.colorHex,
          currentCount: 0,
          goalValue: counter.goalValue,
          isArchived: false,
          createdAt: DateTime.now(),
          sortOrder: _activeCounters.length,
        );
        await _repository.saveCounter(duplicated);

        final log = CounterLog(
          id: const Uuid().v4(),
          counterId: duplicated.id,
          timestamp: DateTime.now(),
          actionType: CounterActionType.set,
          delta: 0,
          resultingCount: 0,
        );
        await _repository.addLog(log);
      }
    } catch (e) {
      if (isClosed) return;
      emit(CountersError(e.toString()));
    }
  }

  Future<void> reorderCounters(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _activeCounters.length || newIndex < 0 || newIndex >= _activeCounters.length) {
      return;
    }
    try {
      final list = List<Counter>.from(_activeCounters);
      final item = list.removeAt(oldIndex);
      list.insert(newIndex, item);

      final orderedIds = list.map((c) => c.id).toList();
      // optimistic update
      _activeCounters = list;
      _emitLoaded();

      await _repository.updateCounterOrder(orderedIds);
    } catch (e) {
      if (isClosed) return;
      emit(CountersError(e.toString()));
    }
  }

  Future<void> incrementCounter(String id) async {
    await _updateCounterValue(id, (val) => val + 1, CounterActionType.increment);
  }

  Future<void> decrementCounter(String id) async {
    await _updateCounterValue(id, (val) => val - 1, CounterActionType.decrement);
  }

  Future<void> resetCounter(String id) async {
    await _updateCounterValue(id, (_) => 0, CounterActionType.reset);
  }

  Future<void> _updateCounterValue(
    String id,
    int Function(int) updateFn,
    CounterActionType actionType,
  ) async {
    try {
      final all = [..._activeCounters, ..._archivedCounters];
      final index = all.indexWhere((c) => c.id == id);
      if (index == -1) return;

      final counter = all[index];
      final oldCount = counter.currentCount;
      final newCount = updateFn(oldCount);
      final updatedCounter = counter.copyWith(currentCount: newCount);

      // Optimistic update if it's in active counters
      final activeIndex = _activeCounters.indexWhere((c) => c.id == id);
      if (activeIndex != -1) {
        _activeCounters[activeIndex] = updatedCounter;
        _emitLoaded();
      }

      await _repository.saveCounter(updatedCounter);
      await _repository.addLog(CounterLog(
        id: const Uuid().v4(),
        counterId: id,
        timestamp: DateTime.now(),
        actionType: actionType,
        delta: newCount - oldCount,
        resultingCount: newCount,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(CountersError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _activeSubscription?.cancel();
    _archivedSubscription?.cancel();
    return super.close();
  }
}
