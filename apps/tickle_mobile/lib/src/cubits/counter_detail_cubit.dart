import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tickle_core/tickle_core.dart';
import 'package:uuid/uuid.dart';

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

  const CounterDetailLoaded({
    required this.counter,
    required this.logs,
  });

  @override
  List<Object?> get props => [counter, logs];
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

  void _emitLoaded() {
    if (isClosed) return;
    if (_currentCounter != null) {
      emit(CounterDetailLoaded(
        counter: _currentCounter!,
        logs: List.from(_currentLogs),
      ));
    }
  }

  Future<void> increment() async {
    if (_currentCounter == null) return;
    try {
      final newCount = _currentCounter!.currentCount + 1;
      final updatedCounter = _currentCounter!.copyWith(currentCount: newCount);
      
      // Optimistic update
      _currentCounter = updatedCounter;
      _emitLoaded();

      // Write to repository
      await _repository.saveCounter(updatedCounter);
      await _repository.addLog(CounterLog(
        id: const Uuid().v4(),
        counterId: _counterId,
        timestamp: DateTime.now(),
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
      final newCount = _currentCounter!.currentCount - 1;
      final updatedCounter = _currentCounter!.copyWith(currentCount: newCount);

      // Optimistic update
      _currentCounter = updatedCounter;
      _emitLoaded();

      // Write to repository
      await _repository.saveCounter(updatedCounter);
      await _repository.addLog(CounterLog(
        id: const Uuid().v4(),
        counterId: _counterId,
        timestamp: DateTime.now(),
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
      final updatedCounter = _currentCounter!.copyWith(currentCount: 0);

      // Optimistic update
      _currentCounter = updatedCounter;
      _emitLoaded();

      // Write to repository
      await _repository.saveCounter(updatedCounter);
      await _repository.addLog(CounterLog(
        id: const Uuid().v4(),
        counterId: _counterId,
        timestamp: DateTime.now(),
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
