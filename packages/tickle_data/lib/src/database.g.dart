// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $DriftCountersTable extends DriftCounters
    with TableInfo<$DriftCountersTable, DriftCounter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DriftCountersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  @override
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentCountMeta = const VerificationMeta(
    'currentCount',
  );
  @override
  late final GeneratedColumn<int> currentCount = GeneratedColumn<int>(
    'current_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _goalValueMeta = const VerificationMeta(
    'goalValue',
  );
  @override
  late final GeneratedColumn<int> goalValue = GeneratedColumn<int>(
    'goal_value',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
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
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drift_counters';
  @override
  VerificationContext validateIntegrity(
    Insertable<DriftCounter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    } else if (isInserting) {
      context.missing(_colorHexMeta);
    }
    if (data.containsKey('current_count')) {
      context.handle(
        _currentCountMeta,
        currentCount.isAcceptableOrUnknown(
          data['current_count']!,
          _currentCountMeta,
        ),
      );
    }
    if (data.containsKey('goal_value')) {
      context.handle(
        _goalValueMeta,
        goalValue.isAcceptableOrUnknown(data['goal_value']!, _goalValueMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DriftCounter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DriftCounter(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      ),
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      )!,
      currentCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_count'],
      )!,
      goalValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}goal_value'],
      ),
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $DriftCountersTable createAlias(String alias) {
    return $DriftCountersTable(attachedDatabase, alias);
  }
}

class DriftCounter extends DataClass implements Insertable<DriftCounter> {
  final String id;
  final String title;
  final String? emoji;
  final String colorHex;
  final int currentCount;
  final int? goalValue;
  final bool isArchived;
  final DateTime createdAt;
  final int sortOrder;
  const DriftCounter({
    required this.id,
    required this.title,
    this.emoji,
    required this.colorHex,
    required this.currentCount,
    this.goalValue,
    required this.isArchived,
    required this.createdAt,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || emoji != null) {
      map['emoji'] = Variable<String>(emoji);
    }
    map['color_hex'] = Variable<String>(colorHex);
    map['current_count'] = Variable<int>(currentCount);
    if (!nullToAbsent || goalValue != null) {
      map['goal_value'] = Variable<int>(goalValue);
    }
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  DriftCountersCompanion toCompanion(bool nullToAbsent) {
    return DriftCountersCompanion(
      id: Value(id),
      title: Value(title),
      emoji: emoji == null && nullToAbsent
          ? const Value.absent()
          : Value(emoji),
      colorHex: Value(colorHex),
      currentCount: Value(currentCount),
      goalValue: goalValue == null && nullToAbsent
          ? const Value.absent()
          : Value(goalValue),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
      sortOrder: Value(sortOrder),
    );
  }

  factory DriftCounter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DriftCounter(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      emoji: serializer.fromJson<String?>(json['emoji']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      currentCount: serializer.fromJson<int>(json['currentCount']),
      goalValue: serializer.fromJson<int?>(json['goalValue']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'emoji': serializer.toJson<String?>(emoji),
      'colorHex': serializer.toJson<String>(colorHex),
      'currentCount': serializer.toJson<int>(currentCount),
      'goalValue': serializer.toJson<int?>(goalValue),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  DriftCounter copyWith({
    String? id,
    String? title,
    Value<String?> emoji = const Value.absent(),
    String? colorHex,
    int? currentCount,
    Value<int?> goalValue = const Value.absent(),
    bool? isArchived,
    DateTime? createdAt,
    int? sortOrder,
  }) => DriftCounter(
    id: id ?? this.id,
    title: title ?? this.title,
    emoji: emoji.present ? emoji.value : this.emoji,
    colorHex: colorHex ?? this.colorHex,
    currentCount: currentCount ?? this.currentCount,
    goalValue: goalValue.present ? goalValue.value : this.goalValue,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  DriftCounter copyWithCompanion(DriftCountersCompanion data) {
    return DriftCounter(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      currentCount: data.currentCount.present
          ? data.currentCount.value
          : this.currentCount,
      goalValue: data.goalValue.present ? data.goalValue.value : this.goalValue,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DriftCounter(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('emoji: $emoji, ')
          ..write('colorHex: $colorHex, ')
          ..write('currentCount: $currentCount, ')
          ..write('goalValue: $goalValue, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    emoji,
    colorHex,
    currentCount,
    goalValue,
    isArchived,
    createdAt,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DriftCounter &&
          other.id == this.id &&
          other.title == this.title &&
          other.emoji == this.emoji &&
          other.colorHex == this.colorHex &&
          other.currentCount == this.currentCount &&
          other.goalValue == this.goalValue &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.sortOrder == this.sortOrder);
}

class DriftCountersCompanion extends UpdateCompanion<DriftCounter> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> emoji;
  final Value<String> colorHex;
  final Value<int> currentCount;
  final Value<int?> goalValue;
  final Value<bool> isArchived;
  final Value<DateTime> createdAt;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const DriftCountersCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.emoji = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.currentCount = const Value.absent(),
    this.goalValue = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DriftCountersCompanion.insert({
    required String id,
    required String title,
    this.emoji = const Value.absent(),
    required String colorHex,
    this.currentCount = const Value.absent(),
    this.goalValue = const Value.absent(),
    this.isArchived = const Value.absent(),
    required DateTime createdAt,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       colorHex = Value(colorHex),
       createdAt = Value(createdAt);
  static Insertable<DriftCounter> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? emoji,
    Expression<String>? colorHex,
    Expression<int>? currentCount,
    Expression<int>? goalValue,
    Expression<bool>? isArchived,
    Expression<DateTime>? createdAt,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (emoji != null) 'emoji': emoji,
      if (colorHex != null) 'color_hex': colorHex,
      if (currentCount != null) 'current_count': currentCount,
      if (goalValue != null) 'goal_value': goalValue,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DriftCountersCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? emoji,
    Value<String>? colorHex,
    Value<int>? currentCount,
    Value<int?>? goalValue,
    Value<bool>? isArchived,
    Value<DateTime>? createdAt,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return DriftCountersCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      colorHex: colorHex ?? this.colorHex,
      currentCount: currentCount ?? this.currentCount,
      goalValue: goalValue ?? this.goalValue,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (currentCount.present) {
      map['current_count'] = Variable<int>(currentCount.value);
    }
    if (goalValue.present) {
      map['goal_value'] = Variable<int>(goalValue.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DriftCountersCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('emoji: $emoji, ')
          ..write('colorHex: $colorHex, ')
          ..write('currentCount: $currentCount, ')
          ..write('goalValue: $goalValue, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DriftCounterLogsTable extends DriftCounterLogs
    with TableInfo<$DriftCounterLogsTable, DriftCounterLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DriftCounterLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _counterIdMeta = const VerificationMeta(
    'counterId',
  );
  @override
  late final GeneratedColumn<String> counterId = GeneratedColumn<String>(
    'counter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES drift_counters (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionTypeMeta = const VerificationMeta(
    'actionType',
  );
  @override
  late final GeneratedColumn<String> actionType = GeneratedColumn<String>(
    'action_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deltaMeta = const VerificationMeta('delta');
  @override
  late final GeneratedColumn<int> delta = GeneratedColumn<int>(
    'delta',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resultingCountMeta = const VerificationMeta(
    'resultingCount',
  );
  @override
  late final GeneratedColumn<int> resultingCount = GeneratedColumn<int>(
    'resulting_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    counterId,
    timestamp,
    actionType,
    delta,
    resultingCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drift_counter_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DriftCounterLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('counter_id')) {
      context.handle(
        _counterIdMeta,
        counterId.isAcceptableOrUnknown(data['counter_id']!, _counterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_counterIdMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('action_type')) {
      context.handle(
        _actionTypeMeta,
        actionType.isAcceptableOrUnknown(data['action_type']!, _actionTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_actionTypeMeta);
    }
    if (data.containsKey('delta')) {
      context.handle(
        _deltaMeta,
        delta.isAcceptableOrUnknown(data['delta']!, _deltaMeta),
      );
    } else if (isInserting) {
      context.missing(_deltaMeta);
    }
    if (data.containsKey('resulting_count')) {
      context.handle(
        _resultingCountMeta,
        resultingCount.isAcceptableOrUnknown(
          data['resulting_count']!,
          _resultingCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_resultingCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DriftCounterLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DriftCounterLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      counterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}counter_id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      actionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action_type'],
      )!,
      delta: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}delta'],
      )!,
      resultingCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resulting_count'],
      )!,
    );
  }

  @override
  $DriftCounterLogsTable createAlias(String alias) {
    return $DriftCounterLogsTable(attachedDatabase, alias);
  }
}

class DriftCounterLog extends DataClass implements Insertable<DriftCounterLog> {
  final String id;
  final String counterId;
  final DateTime timestamp;
  final String actionType;
  final int delta;
  final int resultingCount;
  const DriftCounterLog({
    required this.id,
    required this.counterId,
    required this.timestamp,
    required this.actionType,
    required this.delta,
    required this.resultingCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['counter_id'] = Variable<String>(counterId);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['action_type'] = Variable<String>(actionType);
    map['delta'] = Variable<int>(delta);
    map['resulting_count'] = Variable<int>(resultingCount);
    return map;
  }

  DriftCounterLogsCompanion toCompanion(bool nullToAbsent) {
    return DriftCounterLogsCompanion(
      id: Value(id),
      counterId: Value(counterId),
      timestamp: Value(timestamp),
      actionType: Value(actionType),
      delta: Value(delta),
      resultingCount: Value(resultingCount),
    );
  }

  factory DriftCounterLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DriftCounterLog(
      id: serializer.fromJson<String>(json['id']),
      counterId: serializer.fromJson<String>(json['counterId']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      actionType: serializer.fromJson<String>(json['actionType']),
      delta: serializer.fromJson<int>(json['delta']),
      resultingCount: serializer.fromJson<int>(json['resultingCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'counterId': serializer.toJson<String>(counterId),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'actionType': serializer.toJson<String>(actionType),
      'delta': serializer.toJson<int>(delta),
      'resultingCount': serializer.toJson<int>(resultingCount),
    };
  }

  DriftCounterLog copyWith({
    String? id,
    String? counterId,
    DateTime? timestamp,
    String? actionType,
    int? delta,
    int? resultingCount,
  }) => DriftCounterLog(
    id: id ?? this.id,
    counterId: counterId ?? this.counterId,
    timestamp: timestamp ?? this.timestamp,
    actionType: actionType ?? this.actionType,
    delta: delta ?? this.delta,
    resultingCount: resultingCount ?? this.resultingCount,
  );
  DriftCounterLog copyWithCompanion(DriftCounterLogsCompanion data) {
    return DriftCounterLog(
      id: data.id.present ? data.id.value : this.id,
      counterId: data.counterId.present ? data.counterId.value : this.counterId,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      actionType: data.actionType.present
          ? data.actionType.value
          : this.actionType,
      delta: data.delta.present ? data.delta.value : this.delta,
      resultingCount: data.resultingCount.present
          ? data.resultingCount.value
          : this.resultingCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DriftCounterLog(')
          ..write('id: $id, ')
          ..write('counterId: $counterId, ')
          ..write('timestamp: $timestamp, ')
          ..write('actionType: $actionType, ')
          ..write('delta: $delta, ')
          ..write('resultingCount: $resultingCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, counterId, timestamp, actionType, delta, resultingCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DriftCounterLog &&
          other.id == this.id &&
          other.counterId == this.counterId &&
          other.timestamp == this.timestamp &&
          other.actionType == this.actionType &&
          other.delta == this.delta &&
          other.resultingCount == this.resultingCount);
}

class DriftCounterLogsCompanion extends UpdateCompanion<DriftCounterLog> {
  final Value<String> id;
  final Value<String> counterId;
  final Value<DateTime> timestamp;
  final Value<String> actionType;
  final Value<int> delta;
  final Value<int> resultingCount;
  final Value<int> rowid;
  const DriftCounterLogsCompanion({
    this.id = const Value.absent(),
    this.counterId = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.actionType = const Value.absent(),
    this.delta = const Value.absent(),
    this.resultingCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DriftCounterLogsCompanion.insert({
    required String id,
    required String counterId,
    required DateTime timestamp,
    required String actionType,
    required int delta,
    required int resultingCount,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       counterId = Value(counterId),
       timestamp = Value(timestamp),
       actionType = Value(actionType),
       delta = Value(delta),
       resultingCount = Value(resultingCount);
  static Insertable<DriftCounterLog> custom({
    Expression<String>? id,
    Expression<String>? counterId,
    Expression<DateTime>? timestamp,
    Expression<String>? actionType,
    Expression<int>? delta,
    Expression<int>? resultingCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (counterId != null) 'counter_id': counterId,
      if (timestamp != null) 'timestamp': timestamp,
      if (actionType != null) 'action_type': actionType,
      if (delta != null) 'delta': delta,
      if (resultingCount != null) 'resulting_count': resultingCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DriftCounterLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? counterId,
    Value<DateTime>? timestamp,
    Value<String>? actionType,
    Value<int>? delta,
    Value<int>? resultingCount,
    Value<int>? rowid,
  }) {
    return DriftCounterLogsCompanion(
      id: id ?? this.id,
      counterId: counterId ?? this.counterId,
      timestamp: timestamp ?? this.timestamp,
      actionType: actionType ?? this.actionType,
      delta: delta ?? this.delta,
      resultingCount: resultingCount ?? this.resultingCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (counterId.present) {
      map['counter_id'] = Variable<String>(counterId.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (actionType.present) {
      map['action_type'] = Variable<String>(actionType.value);
    }
    if (delta.present) {
      map['delta'] = Variable<int>(delta.value);
    }
    if (resultingCount.present) {
      map['resulting_count'] = Variable<int>(resultingCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DriftCounterLogsCompanion(')
          ..write('id: $id, ')
          ..write('counterId: $counterId, ')
          ..write('timestamp: $timestamp, ')
          ..write('actionType: $actionType, ')
          ..write('delta: $delta, ')
          ..write('resultingCount: $resultingCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $DriftCountersTable driftCounters = $DriftCountersTable(this);
  late final $DriftCounterLogsTable driftCounterLogs = $DriftCounterLogsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    driftCounters,
    driftCounterLogs,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'drift_counters',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('drift_counter_logs', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$DriftCountersTableCreateCompanionBuilder =
    DriftCountersCompanion Function({
      required String id,
      required String title,
      Value<String?> emoji,
      required String colorHex,
      Value<int> currentCount,
      Value<int?> goalValue,
      Value<bool> isArchived,
      required DateTime createdAt,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$DriftCountersTableUpdateCompanionBuilder =
    DriftCountersCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> emoji,
      Value<String> colorHex,
      Value<int> currentCount,
      Value<int?> goalValue,
      Value<bool> isArchived,
      Value<DateTime> createdAt,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$DriftCountersTableReferences
    extends BaseReferences<_$AppDatabase, $DriftCountersTable, DriftCounter> {
  $$DriftCountersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$DriftCounterLogsTable, List<DriftCounterLog>>
  _driftCounterLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.driftCounterLogs,
    aliasName: $_aliasNameGenerator(
      db.driftCounters.id,
      db.driftCounterLogs.counterId,
    ),
  );

  $$DriftCounterLogsTableProcessedTableManager get driftCounterLogsRefs {
    final manager = $$DriftCounterLogsTableTableManager(
      $_db,
      $_db.driftCounterLogs,
    ).filter((f) => f.counterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _driftCounterLogsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DriftCountersTableFilterComposer
    extends Composer<_$AppDatabase, $DriftCountersTable> {
  $$DriftCountersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentCount => $composableBuilder(
    column: $table.currentCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get goalValue => $composableBuilder(
    column: $table.goalValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> driftCounterLogsRefs(
    Expression<bool> Function($$DriftCounterLogsTableFilterComposer f) f,
  ) {
    final $$DriftCounterLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.driftCounterLogs,
      getReferencedColumn: (t) => t.counterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DriftCounterLogsTableFilterComposer(
            $db: $db,
            $table: $db.driftCounterLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DriftCountersTableOrderingComposer
    extends Composer<_$AppDatabase, $DriftCountersTable> {
  $$DriftCountersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentCount => $composableBuilder(
    column: $table.currentCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get goalValue => $composableBuilder(
    column: $table.goalValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DriftCountersTableAnnotationComposer
    extends Composer<_$AppDatabase, $DriftCountersTable> {
  $$DriftCountersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<int> get currentCount => $composableBuilder(
    column: $table.currentCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get goalValue =>
      $composableBuilder(column: $table.goalValue, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> driftCounterLogsRefs<T extends Object>(
    Expression<T> Function($$DriftCounterLogsTableAnnotationComposer a) f,
  ) {
    final $$DriftCounterLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.driftCounterLogs,
      getReferencedColumn: (t) => t.counterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DriftCounterLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.driftCounterLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DriftCountersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DriftCountersTable,
          DriftCounter,
          $$DriftCountersTableFilterComposer,
          $$DriftCountersTableOrderingComposer,
          $$DriftCountersTableAnnotationComposer,
          $$DriftCountersTableCreateCompanionBuilder,
          $$DriftCountersTableUpdateCompanionBuilder,
          (DriftCounter, $$DriftCountersTableReferences),
          DriftCounter,
          PrefetchHooks Function({bool driftCounterLogsRefs})
        > {
  $$DriftCountersTableTableManager(_$AppDatabase db, $DriftCountersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DriftCountersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DriftCountersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DriftCountersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> emoji = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
                Value<int> currentCount = const Value.absent(),
                Value<int?> goalValue = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DriftCountersCompanion(
                id: id,
                title: title,
                emoji: emoji,
                colorHex: colorHex,
                currentCount: currentCount,
                goalValue: goalValue,
                isArchived: isArchived,
                createdAt: createdAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> emoji = const Value.absent(),
                required String colorHex,
                Value<int> currentCount = const Value.absent(),
                Value<int?> goalValue = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                required DateTime createdAt,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DriftCountersCompanion.insert(
                id: id,
                title: title,
                emoji: emoji,
                colorHex: colorHex,
                currentCount: currentCount,
                goalValue: goalValue,
                isArchived: isArchived,
                createdAt: createdAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DriftCountersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({driftCounterLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (driftCounterLogsRefs) db.driftCounterLogs,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (driftCounterLogsRefs)
                    await $_getPrefetchedData<
                      DriftCounter,
                      $DriftCountersTable,
                      DriftCounterLog
                    >(
                      currentTable: table,
                      referencedTable: $$DriftCountersTableReferences
                          ._driftCounterLogsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$DriftCountersTableReferences(
                            db,
                            table,
                            p0,
                          ).driftCounterLogsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.counterId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DriftCountersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DriftCountersTable,
      DriftCounter,
      $$DriftCountersTableFilterComposer,
      $$DriftCountersTableOrderingComposer,
      $$DriftCountersTableAnnotationComposer,
      $$DriftCountersTableCreateCompanionBuilder,
      $$DriftCountersTableUpdateCompanionBuilder,
      (DriftCounter, $$DriftCountersTableReferences),
      DriftCounter,
      PrefetchHooks Function({bool driftCounterLogsRefs})
    >;
typedef $$DriftCounterLogsTableCreateCompanionBuilder =
    DriftCounterLogsCompanion Function({
      required String id,
      required String counterId,
      required DateTime timestamp,
      required String actionType,
      required int delta,
      required int resultingCount,
      Value<int> rowid,
    });
typedef $$DriftCounterLogsTableUpdateCompanionBuilder =
    DriftCounterLogsCompanion Function({
      Value<String> id,
      Value<String> counterId,
      Value<DateTime> timestamp,
      Value<String> actionType,
      Value<int> delta,
      Value<int> resultingCount,
      Value<int> rowid,
    });

final class $$DriftCounterLogsTableReferences
    extends
        BaseReferences<_$AppDatabase, $DriftCounterLogsTable, DriftCounterLog> {
  $$DriftCounterLogsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DriftCountersTable _counterIdTable(_$AppDatabase db) =>
      db.driftCounters.createAlias(
        $_aliasNameGenerator(
          db.driftCounterLogs.counterId,
          db.driftCounters.id,
        ),
      );

  $$DriftCountersTableProcessedTableManager get counterId {
    final $_column = $_itemColumn<String>('counter_id')!;

    final manager = $$DriftCountersTableTableManager(
      $_db,
      $_db.driftCounters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_counterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DriftCounterLogsTableFilterComposer
    extends Composer<_$AppDatabase, $DriftCounterLogsTable> {
  $$DriftCounterLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get delta => $composableBuilder(
    column: $table.delta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get resultingCount => $composableBuilder(
    column: $table.resultingCount,
    builder: (column) => ColumnFilters(column),
  );

  $$DriftCountersTableFilterComposer get counterId {
    final $$DriftCountersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterId,
      referencedTable: $db.driftCounters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DriftCountersTableFilterComposer(
            $db: $db,
            $table: $db.driftCounters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DriftCounterLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $DriftCounterLogsTable> {
  $$DriftCounterLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get delta => $composableBuilder(
    column: $table.delta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get resultingCount => $composableBuilder(
    column: $table.resultingCount,
    builder: (column) => ColumnOrderings(column),
  );

  $$DriftCountersTableOrderingComposer get counterId {
    final $$DriftCountersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterId,
      referencedTable: $db.driftCounters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DriftCountersTableOrderingComposer(
            $db: $db,
            $table: $db.driftCounters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DriftCounterLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DriftCounterLogsTable> {
  $$DriftCounterLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get delta =>
      $composableBuilder(column: $table.delta, builder: (column) => column);

  GeneratedColumn<int> get resultingCount => $composableBuilder(
    column: $table.resultingCount,
    builder: (column) => column,
  );

  $$DriftCountersTableAnnotationComposer get counterId {
    final $$DriftCountersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.counterId,
      referencedTable: $db.driftCounters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DriftCountersTableAnnotationComposer(
            $db: $db,
            $table: $db.driftCounters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DriftCounterLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DriftCounterLogsTable,
          DriftCounterLog,
          $$DriftCounterLogsTableFilterComposer,
          $$DriftCounterLogsTableOrderingComposer,
          $$DriftCounterLogsTableAnnotationComposer,
          $$DriftCounterLogsTableCreateCompanionBuilder,
          $$DriftCounterLogsTableUpdateCompanionBuilder,
          (DriftCounterLog, $$DriftCounterLogsTableReferences),
          DriftCounterLog,
          PrefetchHooks Function({bool counterId})
        > {
  $$DriftCounterLogsTableTableManager(
    _$AppDatabase db,
    $DriftCounterLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DriftCounterLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DriftCounterLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DriftCounterLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> counterId = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String> actionType = const Value.absent(),
                Value<int> delta = const Value.absent(),
                Value<int> resultingCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DriftCounterLogsCompanion(
                id: id,
                counterId: counterId,
                timestamp: timestamp,
                actionType: actionType,
                delta: delta,
                resultingCount: resultingCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String counterId,
                required DateTime timestamp,
                required String actionType,
                required int delta,
                required int resultingCount,
                Value<int> rowid = const Value.absent(),
              }) => DriftCounterLogsCompanion.insert(
                id: id,
                counterId: counterId,
                timestamp: timestamp,
                actionType: actionType,
                delta: delta,
                resultingCount: resultingCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DriftCounterLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({counterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (counterId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.counterId,
                                referencedTable:
                                    $$DriftCounterLogsTableReferences
                                        ._counterIdTable(db),
                                referencedColumn:
                                    $$DriftCounterLogsTableReferences
                                        ._counterIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DriftCounterLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DriftCounterLogsTable,
      DriftCounterLog,
      $$DriftCounterLogsTableFilterComposer,
      $$DriftCounterLogsTableOrderingComposer,
      $$DriftCounterLogsTableAnnotationComposer,
      $$DriftCounterLogsTableCreateCompanionBuilder,
      $$DriftCounterLogsTableUpdateCompanionBuilder,
      (DriftCounterLog, $$DriftCounterLogsTableReferences),
      DriftCounterLog,
      PrefetchHooks Function({bool counterId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$DriftCountersTableTableManager get driftCounters =>
      $$DriftCountersTableTableManager(_db, _db.driftCounters);
  $$DriftCounterLogsTableTableManager get driftCounterLogs =>
      $$DriftCounterLogsTableTableManager(_db, _db.driftCounterLogs);
}
