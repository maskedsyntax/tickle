import 'package:equatable/equatable.dart';

class Counter extends Equatable {
  final String id;
  final String title;
  final String? emoji;
  final String colorHex;
  final int currentCount;
  final int? goalValue;
  final bool isArchived;
  final DateTime createdAt;
  final int sortOrder;

  const Counter({
    required this.id,
    required this.title,
    this.emoji,
    required this.colorHex,
    this.currentCount = 0,
    this.goalValue,
    this.isArchived = false,
    required this.createdAt,
    this.sortOrder = 0,
  });

  Counter copyWith({
    String? id,
    String? title,
    String? emoji,
    String? colorHex,
    int? currentCount,
    int? goalValue,
    bool? isArchived,
    DateTime? createdAt,
    int? sortOrder,
  }) {
    return Counter(
      id: id ?? this.id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      colorHex: colorHex ?? this.colorHex,
      currentCount: currentCount ?? this.currentCount,
      goalValue: goalValue ?? this.goalValue,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        emoji,
        colorHex,
        currentCount,
        goalValue,
        isArchived,
        createdAt,
        sortOrder,
      ];
}
