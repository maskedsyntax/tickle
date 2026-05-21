import 'package:equatable/equatable.dart';

enum CounterActionType {
  increment,
  decrement,
  reset,
  set;

  String toJson() => name;
  static CounterActionType fromJson(String name) =>
      CounterActionType.values.firstWhere((e) => e.name == name,
          orElse: () => CounterActionType.increment);
}

class CounterLog extends Equatable {
  final String id;
  final String counterId;
  final DateTime timestamp;
  final CounterActionType actionType;
  final int delta;
  final int resultingCount;

  const CounterLog({
    required this.id,
    required this.counterId,
    required this.timestamp,
    required this.actionType,
    required this.delta,
    required this.resultingCount,
  });

  CounterLog copyWith({
    String? id,
    String? counterId,
    DateTime? timestamp,
    CounterActionType? actionType,
    int? delta,
    int? resultingCount,
  }) {
    return CounterLog(
      id: id ?? this.id,
      counterId: counterId ?? this.counterId,
      timestamp: timestamp ?? this.timestamp,
      actionType: actionType ?? this.actionType,
      delta: delta ?? this.delta,
      resultingCount: resultingCount ?? this.resultingCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        counterId,
        timestamp,
        actionType,
        delta,
        resultingCount,
      ];
}
