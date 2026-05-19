// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TasksTable extends Tasks with TableInfo<$TasksTable, DbTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<int> points = GeneratedColumn<int>(
      'points', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, points, category, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(Insertable<DbTask> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('points')) {
      context.handle(_pointsMeta,
          points.isAcceptableOrUnknown(data['points']!, _pointsMeta));
    } else if (isInserting) {
      context.missing(_pointsMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbTask(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      points: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}points'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class DbTask extends DataClass implements Insertable<DbTask> {
  final String id;
  final int points;
  final String category;
  final int sortOrder;
  const DbTask(
      {required this.id,
      required this.points,
      required this.category,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['points'] = Variable<int>(points);
    map['category'] = Variable<String>(category);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      points: Value(points),
      category: Value(category),
      sortOrder: Value(sortOrder),
    );
  }

  factory DbTask.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbTask(
      id: serializer.fromJson<String>(json['id']),
      points: serializer.fromJson<int>(json['points']),
      category: serializer.fromJson<String>(json['category']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'points': serializer.toJson<int>(points),
      'category': serializer.toJson<String>(category),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  DbTask copyWith(
          {String? id, int? points, String? category, int? sortOrder}) =>
      DbTask(
        id: id ?? this.id,
        points: points ?? this.points,
        category: category ?? this.category,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  DbTask copyWithCompanion(TasksCompanion data) {
    return DbTask(
      id: data.id.present ? data.id.value : this.id,
      points: data.points.present ? data.points.value : this.points,
      category: data.category.present ? data.category.value : this.category,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbTask(')
          ..write('id: $id, ')
          ..write('points: $points, ')
          ..write('category: $category, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, points, category, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbTask &&
          other.id == this.id &&
          other.points == this.points &&
          other.category == this.category &&
          other.sortOrder == this.sortOrder);
}

class TasksCompanion extends UpdateCompanion<DbTask> {
  final Value<String> id;
  final Value<int> points;
  final Value<String> category;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.points = const Value.absent(),
    this.category = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required int points,
    required String category,
    required int sortOrder,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        points = Value(points),
        category = Value(category),
        sortOrder = Value(sortOrder);
  static Insertable<DbTask> custom({
    Expression<String>? id,
    Expression<int>? points,
    Expression<String>? category,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (points != null) 'points': points,
      if (category != null) 'category': category,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith(
      {Value<String>? id,
      Value<int>? points,
      Value<String>? category,
      Value<int>? sortOrder,
      Value<int>? rowid}) {
    return TasksCompanion(
      id: id ?? this.id,
      points: points ?? this.points,
      category: category ?? this.category,
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
    if (points.present) {
      map['points'] = Variable<int>(points.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
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
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('points: $points, ')
          ..write('category: $category, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserTasksTable extends UserTasks
    with TableInfo<$UserTasksTable, DbUserTask> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryRefMeta =
      const VerificationMeta('categoryRef');
  @override
  late final GeneratedColumn<String> categoryRef = GeneratedColumn<String>(
      'category_ref', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pointsMeta = const VerificationMeta('points');
  @override
  late final GeneratedColumn<int> points = GeneratedColumn<int>(
      'points', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _archivedAtMeta =
      const VerificationMeta('archivedAt');
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
      'archived_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, categoryRef, name, points, icon, sortOrder, archivedAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_tasks';
  @override
  VerificationContext validateIntegrity(Insertable<DbUserTask> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category_ref')) {
      context.handle(
          _categoryRefMeta,
          categoryRef.isAcceptableOrUnknown(
              data['category_ref']!, _categoryRefMeta));
    } else if (isInserting) {
      context.missing(_categoryRefMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('points')) {
      context.handle(_pointsMeta,
          points.isAcceptableOrUnknown(data['points']!, _pointsMeta));
    } else if (isInserting) {
      context.missing(_pointsMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('archived_at')) {
      context.handle(
          _archivedAtMeta,
          archivedAt.isAcceptableOrUnknown(
              data['archived_at']!, _archivedAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbUserTask map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbUserTask(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      categoryRef: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_ref'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      points: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}points'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      archivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}archived_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $UserTasksTable createAlias(String alias) {
    return $UserTasksTable(attachedDatabase, alias);
  }
}

class DbUserTask extends DataClass implements Insertable<DbUserTask> {
  final String id;
  final String categoryRef;
  final String name;
  final int points;
  final String icon;
  final int sortOrder;
  final DateTime? archivedAt;
  final DateTime updatedAt;
  const DbUserTask(
      {required this.id,
      required this.categoryRef,
      required this.name,
      required this.points,
      required this.icon,
      required this.sortOrder,
      this.archivedAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category_ref'] = Variable<String>(categoryRef);
    map['name'] = Variable<String>(name);
    map['points'] = Variable<int>(points);
    map['icon'] = Variable<String>(icon);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserTasksCompanion toCompanion(bool nullToAbsent) {
    return UserTasksCompanion(
      id: Value(id),
      categoryRef: Value(categoryRef),
      name: Value(name),
      points: Value(points),
      icon: Value(icon),
      sortOrder: Value(sortOrder),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DbUserTask.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbUserTask(
      id: serializer.fromJson<String>(json['id']),
      categoryRef: serializer.fromJson<String>(json['categoryRef']),
      name: serializer.fromJson<String>(json['name']),
      points: serializer.fromJson<int>(json['points']),
      icon: serializer.fromJson<String>(json['icon']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'categoryRef': serializer.toJson<String>(categoryRef),
      'name': serializer.toJson<String>(name),
      'points': serializer.toJson<int>(points),
      'icon': serializer.toJson<String>(icon),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DbUserTask copyWith(
          {String? id,
          String? categoryRef,
          String? name,
          int? points,
          String? icon,
          int? sortOrder,
          Value<DateTime?> archivedAt = const Value.absent(),
          DateTime? updatedAt}) =>
      DbUserTask(
        id: id ?? this.id,
        categoryRef: categoryRef ?? this.categoryRef,
        name: name ?? this.name,
        points: points ?? this.points,
        icon: icon ?? this.icon,
        sortOrder: sortOrder ?? this.sortOrder,
        archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DbUserTask copyWithCompanion(UserTasksCompanion data) {
    return DbUserTask(
      id: data.id.present ? data.id.value : this.id,
      categoryRef:
          data.categoryRef.present ? data.categoryRef.value : this.categoryRef,
      name: data.name.present ? data.name.value : this.name,
      points: data.points.present ? data.points.value : this.points,
      icon: data.icon.present ? data.icon.value : this.icon,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      archivedAt:
          data.archivedAt.present ? data.archivedAt.value : this.archivedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbUserTask(')
          ..write('id: $id, ')
          ..write('categoryRef: $categoryRef, ')
          ..write('name: $name, ')
          ..write('points: $points, ')
          ..write('icon: $icon, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, categoryRef, name, points, icon, sortOrder, archivedAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbUserTask &&
          other.id == this.id &&
          other.categoryRef == this.categoryRef &&
          other.name == this.name &&
          other.points == this.points &&
          other.icon == this.icon &&
          other.sortOrder == this.sortOrder &&
          other.archivedAt == this.archivedAt &&
          other.updatedAt == this.updatedAt);
}

class UserTasksCompanion extends UpdateCompanion<DbUserTask> {
  final Value<String> id;
  final Value<String> categoryRef;
  final Value<String> name;
  final Value<int> points;
  final Value<String> icon;
  final Value<int> sortOrder;
  final Value<DateTime?> archivedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserTasksCompanion({
    this.id = const Value.absent(),
    this.categoryRef = const Value.absent(),
    this.name = const Value.absent(),
    this.points = const Value.absent(),
    this.icon = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserTasksCompanion.insert({
    required String id,
    required String categoryRef,
    required String name,
    required int points,
    required String icon,
    required int sortOrder,
    this.archivedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        categoryRef = Value(categoryRef),
        name = Value(name),
        points = Value(points),
        icon = Value(icon),
        sortOrder = Value(sortOrder);
  static Insertable<DbUserTask> custom({
    Expression<String>? id,
    Expression<String>? categoryRef,
    Expression<String>? name,
    Expression<int>? points,
    Expression<String>? icon,
    Expression<int>? sortOrder,
    Expression<DateTime>? archivedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryRef != null) 'category_ref': categoryRef,
      if (name != null) 'name': name,
      if (points != null) 'points': points,
      if (icon != null) 'icon': icon,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserTasksCompanion copyWith(
      {Value<String>? id,
      Value<String>? categoryRef,
      Value<String>? name,
      Value<int>? points,
      Value<String>? icon,
      Value<int>? sortOrder,
      Value<DateTime?>? archivedAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return UserTasksCompanion(
      id: id ?? this.id,
      categoryRef: categoryRef ?? this.categoryRef,
      name: name ?? this.name,
      points: points ?? this.points,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      archivedAt: archivedAt ?? this.archivedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (categoryRef.present) {
      map['category_ref'] = Variable<String>(categoryRef.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (points.present) {
      map['points'] = Variable<int>(points.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserTasksCompanion(')
          ..write('id: $id, ')
          ..write('categoryRef: $categoryRef, ')
          ..write('name: $name, ')
          ..write('points: $points, ')
          ..write('icon: $icon, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyLogsTable extends DailyLogs
    with TableInfo<$DailyLogsTable, DbDailyLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
      'task_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES tasks (id)'));
  static const VerificationMeta _userTaskIdMeta =
      const VerificationMeta('userTaskId');
  @override
  late final GeneratedColumn<String> userTaskId = GeneratedColumn<String>(
      'user_task_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES user_tasks (id)'));
  static const VerificationMeta _completedMeta =
      const VerificationMeta('completed');
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
      'completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, date, taskId, userTaskId, completed, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_logs';
  @override
  VerificationContext validateIntegrity(Insertable<DbDailyLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(_taskIdMeta,
          taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta));
    }
    if (data.containsKey('user_task_id')) {
      context.handle(
          _userTaskIdMeta,
          userTaskId.isAcceptableOrUnknown(
              data['user_task_id']!, _userTaskIdMeta));
    }
    if (data.containsKey('completed')) {
      context.handle(_completedMeta,
          completed.isAcceptableOrUnknown(data['completed']!, _completedMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbDailyLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbDailyLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      taskId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}task_id']),
      userTaskId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_task_id']),
      completed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}completed'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DailyLogsTable createAlias(String alias) {
    return $DailyLogsTable(attachedDatabase, alias);
  }
}

class DbDailyLog extends DataClass implements Insertable<DbDailyLog> {
  final int id;
  final String date;

  /// Default catalog task code; null when [userTaskId] is set.
  final String? taskId;

  /// User-owned task id (`ut_…`); null when [taskId] is set.
  final String? userTaskId;
  final bool completed;
  final DateTime updatedAt;
  const DbDailyLog(
      {required this.id,
      required this.date,
      this.taskId,
      this.userTaskId,
      required this.completed,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    if (!nullToAbsent || userTaskId != null) {
      map['user_task_id'] = Variable<String>(userTaskId);
    }
    map['completed'] = Variable<bool>(completed);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DailyLogsCompanion toCompanion(bool nullToAbsent) {
    return DailyLogsCompanion(
      id: Value(id),
      date: Value(date),
      taskId:
          taskId == null && nullToAbsent ? const Value.absent() : Value(taskId),
      userTaskId: userTaskId == null && nullToAbsent
          ? const Value.absent()
          : Value(userTaskId),
      completed: Value(completed),
      updatedAt: Value(updatedAt),
    );
  }

  factory DbDailyLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbDailyLog(
      id: serializer.fromJson<int>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      taskId: serializer.fromJson<String?>(json['taskId']),
      userTaskId: serializer.fromJson<String?>(json['userTaskId']),
      completed: serializer.fromJson<bool>(json['completed']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'date': serializer.toJson<String>(date),
      'taskId': serializer.toJson<String?>(taskId),
      'userTaskId': serializer.toJson<String?>(userTaskId),
      'completed': serializer.toJson<bool>(completed),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DbDailyLog copyWith(
          {int? id,
          String? date,
          Value<String?> taskId = const Value.absent(),
          Value<String?> userTaskId = const Value.absent(),
          bool? completed,
          DateTime? updatedAt}) =>
      DbDailyLog(
        id: id ?? this.id,
        date: date ?? this.date,
        taskId: taskId.present ? taskId.value : this.taskId,
        userTaskId: userTaskId.present ? userTaskId.value : this.userTaskId,
        completed: completed ?? this.completed,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DbDailyLog copyWithCompanion(DailyLogsCompanion data) {
    return DbDailyLog(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      userTaskId:
          data.userTaskId.present ? data.userTaskId.value : this.userTaskId,
      completed: data.completed.present ? data.completed.value : this.completed,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbDailyLog(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('taskId: $taskId, ')
          ..write('userTaskId: $userTaskId, ')
          ..write('completed: $completed, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, taskId, userTaskId, completed, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbDailyLog &&
          other.id == this.id &&
          other.date == this.date &&
          other.taskId == this.taskId &&
          other.userTaskId == this.userTaskId &&
          other.completed == this.completed &&
          other.updatedAt == this.updatedAt);
}

class DailyLogsCompanion extends UpdateCompanion<DbDailyLog> {
  final Value<int> id;
  final Value<String> date;
  final Value<String?> taskId;
  final Value<String?> userTaskId;
  final Value<bool> completed;
  final Value<DateTime> updatedAt;
  const DailyLogsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.taskId = const Value.absent(),
    this.userTaskId = const Value.absent(),
    this.completed = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DailyLogsCompanion.insert({
    this.id = const Value.absent(),
    required String date,
    this.taskId = const Value.absent(),
    this.userTaskId = const Value.absent(),
    this.completed = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : date = Value(date);
  static Insertable<DbDailyLog> custom({
    Expression<int>? id,
    Expression<String>? date,
    Expression<String>? taskId,
    Expression<String>? userTaskId,
    Expression<bool>? completed,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (taskId != null) 'task_id': taskId,
      if (userTaskId != null) 'user_task_id': userTaskId,
      if (completed != null) 'completed': completed,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DailyLogsCompanion copyWith(
      {Value<int>? id,
      Value<String>? date,
      Value<String?>? taskId,
      Value<String?>? userTaskId,
      Value<bool>? completed,
      Value<DateTime>? updatedAt}) {
    return DailyLogsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      taskId: taskId ?? this.taskId,
      userTaskId: userTaskId ?? this.userTaskId,
      completed: completed ?? this.completed,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (userTaskId.present) {
      map['user_task_id'] = Variable<String>(userTaskId.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyLogsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('taskId: $taskId, ')
          ..write('userTaskId: $userTaskId, ')
          ..write('completed: $completed, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, DbCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _defaultNameMeta =
      const VerificationMeta('defaultName');
  @override
  late final GeneratedColumn<String> defaultName = GeneratedColumn<String>(
      'default_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _defaultIconMeta =
      const VerificationMeta('defaultIcon');
  @override
  late final GeneratedColumn<String> defaultIcon = GeneratedColumn<String>(
      'default_icon', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _defaultSortOrderMeta =
      const VerificationMeta('defaultSortOrder');
  @override
  late final GeneratedColumn<int> defaultSortOrder = GeneratedColumn<int>(
      'default_sort_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isFardMeta = const VerificationMeta('isFard');
  @override
  late final GeneratedColumn<bool> isFard = GeneratedColumn<bool>(
      'is_fard', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_fard" IN (0, 1))'));
  @override
  List<GeneratedColumn> get $columns =>
      [code, defaultName, defaultIcon, defaultSortOrder, isFard];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<DbCategory> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('default_name')) {
      context.handle(
          _defaultNameMeta,
          defaultName.isAcceptableOrUnknown(
              data['default_name']!, _defaultNameMeta));
    } else if (isInserting) {
      context.missing(_defaultNameMeta);
    }
    if (data.containsKey('default_icon')) {
      context.handle(
          _defaultIconMeta,
          defaultIcon.isAcceptableOrUnknown(
              data['default_icon']!, _defaultIconMeta));
    } else if (isInserting) {
      context.missing(_defaultIconMeta);
    }
    if (data.containsKey('default_sort_order')) {
      context.handle(
          _defaultSortOrderMeta,
          defaultSortOrder.isAcceptableOrUnknown(
              data['default_sort_order']!, _defaultSortOrderMeta));
    } else if (isInserting) {
      context.missing(_defaultSortOrderMeta);
    }
    if (data.containsKey('is_fard')) {
      context.handle(_isFardMeta,
          isFard.isAcceptableOrUnknown(data['is_fard']!, _isFardMeta));
    } else if (isInserting) {
      context.missing(_isFardMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {code};
  @override
  DbCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbCategory(
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      defaultName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}default_name'])!,
      defaultIcon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}default_icon'])!,
      defaultSortOrder: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}default_sort_order'])!,
      isFard: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_fard'])!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class DbCategory extends DataClass implements Insertable<DbCategory> {
  final String code;
  final String defaultName;
  final String defaultIcon;
  final int defaultSortOrder;
  final bool isFard;
  const DbCategory(
      {required this.code,
      required this.defaultName,
      required this.defaultIcon,
      required this.defaultSortOrder,
      required this.isFard});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['code'] = Variable<String>(code);
    map['default_name'] = Variable<String>(defaultName);
    map['default_icon'] = Variable<String>(defaultIcon);
    map['default_sort_order'] = Variable<int>(defaultSortOrder);
    map['is_fard'] = Variable<bool>(isFard);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      code: Value(code),
      defaultName: Value(defaultName),
      defaultIcon: Value(defaultIcon),
      defaultSortOrder: Value(defaultSortOrder),
      isFard: Value(isFard),
    );
  }

  factory DbCategory.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbCategory(
      code: serializer.fromJson<String>(json['code']),
      defaultName: serializer.fromJson<String>(json['defaultName']),
      defaultIcon: serializer.fromJson<String>(json['defaultIcon']),
      defaultSortOrder: serializer.fromJson<int>(json['defaultSortOrder']),
      isFard: serializer.fromJson<bool>(json['isFard']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'code': serializer.toJson<String>(code),
      'defaultName': serializer.toJson<String>(defaultName),
      'defaultIcon': serializer.toJson<String>(defaultIcon),
      'defaultSortOrder': serializer.toJson<int>(defaultSortOrder),
      'isFard': serializer.toJson<bool>(isFard),
    };
  }

  DbCategory copyWith(
          {String? code,
          String? defaultName,
          String? defaultIcon,
          int? defaultSortOrder,
          bool? isFard}) =>
      DbCategory(
        code: code ?? this.code,
        defaultName: defaultName ?? this.defaultName,
        defaultIcon: defaultIcon ?? this.defaultIcon,
        defaultSortOrder: defaultSortOrder ?? this.defaultSortOrder,
        isFard: isFard ?? this.isFard,
      );
  DbCategory copyWithCompanion(CategoriesCompanion data) {
    return DbCategory(
      code: data.code.present ? data.code.value : this.code,
      defaultName:
          data.defaultName.present ? data.defaultName.value : this.defaultName,
      defaultIcon:
          data.defaultIcon.present ? data.defaultIcon.value : this.defaultIcon,
      defaultSortOrder: data.defaultSortOrder.present
          ? data.defaultSortOrder.value
          : this.defaultSortOrder,
      isFard: data.isFard.present ? data.isFard.value : this.isFard,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbCategory(')
          ..write('code: $code, ')
          ..write('defaultName: $defaultName, ')
          ..write('defaultIcon: $defaultIcon, ')
          ..write('defaultSortOrder: $defaultSortOrder, ')
          ..write('isFard: $isFard')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(code, defaultName, defaultIcon, defaultSortOrder, isFard);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbCategory &&
          other.code == this.code &&
          other.defaultName == this.defaultName &&
          other.defaultIcon == this.defaultIcon &&
          other.defaultSortOrder == this.defaultSortOrder &&
          other.isFard == this.isFard);
}

class CategoriesCompanion extends UpdateCompanion<DbCategory> {
  final Value<String> code;
  final Value<String> defaultName;
  final Value<String> defaultIcon;
  final Value<int> defaultSortOrder;
  final Value<bool> isFard;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.code = const Value.absent(),
    this.defaultName = const Value.absent(),
    this.defaultIcon = const Value.absent(),
    this.defaultSortOrder = const Value.absent(),
    this.isFard = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String code,
    required String defaultName,
    required String defaultIcon,
    required int defaultSortOrder,
    required bool isFard,
    this.rowid = const Value.absent(),
  })  : code = Value(code),
        defaultName = Value(defaultName),
        defaultIcon = Value(defaultIcon),
        defaultSortOrder = Value(defaultSortOrder),
        isFard = Value(isFard);
  static Insertable<DbCategory> custom({
    Expression<String>? code,
    Expression<String>? defaultName,
    Expression<String>? defaultIcon,
    Expression<int>? defaultSortOrder,
    Expression<bool>? isFard,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (code != null) 'code': code,
      if (defaultName != null) 'default_name': defaultName,
      if (defaultIcon != null) 'default_icon': defaultIcon,
      if (defaultSortOrder != null) 'default_sort_order': defaultSortOrder,
      if (isFard != null) 'is_fard': isFard,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith(
      {Value<String>? code,
      Value<String>? defaultName,
      Value<String>? defaultIcon,
      Value<int>? defaultSortOrder,
      Value<bool>? isFard,
      Value<int>? rowid}) {
    return CategoriesCompanion(
      code: code ?? this.code,
      defaultName: defaultName ?? this.defaultName,
      defaultIcon: defaultIcon ?? this.defaultIcon,
      defaultSortOrder: defaultSortOrder ?? this.defaultSortOrder,
      isFard: isFard ?? this.isFard,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (defaultName.present) {
      map['default_name'] = Variable<String>(defaultName.value);
    }
    if (defaultIcon.present) {
      map['default_icon'] = Variable<String>(defaultIcon.value);
    }
    if (defaultSortOrder.present) {
      map['default_sort_order'] = Variable<int>(defaultSortOrder.value);
    }
    if (isFard.present) {
      map['is_fard'] = Variable<bool>(isFard.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('code: $code, ')
          ..write('defaultName: $defaultName, ')
          ..write('defaultIcon: $defaultIcon, ')
          ..write('defaultSortOrder: $defaultSortOrder, ')
          ..write('isFard: $isFard, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserCategoriesTable extends UserCategories
    with TableInfo<$UserCategoriesTable, DbUserCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _archivedAtMeta =
      const VerificationMeta('archivedAt');
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
      'archived_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, icon, sortOrder, archivedAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_categories';
  @override
  VerificationContext validateIntegrity(Insertable<DbUserCategory> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    } else if (isInserting) {
      context.missing(_iconMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('archived_at')) {
      context.handle(
          _archivedAtMeta,
          archivedAt.isAcceptableOrUnknown(
              data['archived_at']!, _archivedAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbUserCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbUserCategory(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      archivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}archived_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $UserCategoriesTable createAlias(String alias) {
    return $UserCategoriesTable(attachedDatabase, alias);
  }
}

class DbUserCategory extends DataClass implements Insertable<DbUserCategory> {
  final String id;
  final String name;
  final String icon;
  final int sortOrder;
  final DateTime? archivedAt;
  final DateTime updatedAt;
  const DbUserCategory(
      {required this.id,
      required this.name,
      required this.icon,
      required this.sortOrder,
      this.archivedAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['icon'] = Variable<String>(icon);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserCategoriesCompanion toCompanion(bool nullToAbsent) {
    return UserCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      icon: Value(icon),
      sortOrder: Value(sortOrder),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DbUserCategory.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbUserCategory(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String>(json['icon']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String>(icon),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DbUserCategory copyWith(
          {String? id,
          String? name,
          String? icon,
          int? sortOrder,
          Value<DateTime?> archivedAt = const Value.absent(),
          DateTime? updatedAt}) =>
      DbUserCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        icon: icon ?? this.icon,
        sortOrder: sortOrder ?? this.sortOrder,
        archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DbUserCategory copyWithCompanion(UserCategoriesCompanion data) {
    return DbUserCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      archivedAt:
          data.archivedAt.present ? data.archivedAt.value : this.archivedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbUserCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, icon, sortOrder, archivedAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbUserCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.sortOrder == this.sortOrder &&
          other.archivedAt == this.archivedAt &&
          other.updatedAt == this.updatedAt);
}

class UserCategoriesCompanion extends UpdateCompanion<DbUserCategory> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> icon;
  final Value<int> sortOrder;
  final Value<DateTime?> archivedAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserCategoriesCompanion.insert({
    required String id,
    required String name,
    required String icon,
    required int sortOrder,
    this.archivedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        icon = Value(icon),
        sortOrder = Value(sortOrder);
  static Insertable<DbUserCategory> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<int>? sortOrder,
    Expression<DateTime>? archivedAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserCategoriesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? icon,
      Value<int>? sortOrder,
      Value<DateTime?>? archivedAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return UserCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      archivedAt: archivedAt ?? this.archivedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserCategoryOverridesTable extends UserCategoryOverrides
    with TableInfo<$UserCategoryOverridesTable, DbUserCategoryOverride> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserCategoryOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _categoryCodeMeta =
      const VerificationMeta('categoryCode');
  @override
  late final GeneratedColumn<String> categoryCode = GeneratedColumn<String>(
      'category_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _hiddenMeta = const VerificationMeta('hidden');
  @override
  late final GeneratedColumn<bool> hidden = GeneratedColumn<bool>(
      'hidden', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("hidden" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _customNameMeta =
      const VerificationMeta('customName');
  @override
  late final GeneratedColumn<String> customName = GeneratedColumn<String>(
      'custom_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customIconMeta =
      const VerificationMeta('customIcon');
  @override
  late final GeneratedColumn<String> customIcon = GeneratedColumn<String>(
      'custom_icon', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [categoryCode, hidden, customName, customIcon, sortOrder, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_category_overrides';
  @override
  VerificationContext validateIntegrity(
      Insertable<DbUserCategoryOverride> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('category_code')) {
      context.handle(
          _categoryCodeMeta,
          categoryCode.isAcceptableOrUnknown(
              data['category_code']!, _categoryCodeMeta));
    } else if (isInserting) {
      context.missing(_categoryCodeMeta);
    }
    if (data.containsKey('hidden')) {
      context.handle(_hiddenMeta,
          hidden.isAcceptableOrUnknown(data['hidden']!, _hiddenMeta));
    }
    if (data.containsKey('custom_name')) {
      context.handle(
          _customNameMeta,
          customName.isAcceptableOrUnknown(
              data['custom_name']!, _customNameMeta));
    }
    if (data.containsKey('custom_icon')) {
      context.handle(
          _customIconMeta,
          customIcon.isAcceptableOrUnknown(
              data['custom_icon']!, _customIconMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {categoryCode};
  @override
  DbUserCategoryOverride map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbUserCategoryOverride(
      categoryCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_code'])!,
      hidden: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}hidden'])!,
      customName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}custom_name']),
      customIcon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}custom_icon']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $UserCategoryOverridesTable createAlias(String alias) {
    return $UserCategoryOverridesTable(attachedDatabase, alias);
  }
}

class DbUserCategoryOverride extends DataClass
    implements Insertable<DbUserCategoryOverride> {
  final String categoryCode;
  final bool hidden;
  final String? customName;
  final String? customIcon;
  final int? sortOrder;
  final DateTime updatedAt;
  const DbUserCategoryOverride(
      {required this.categoryCode,
      required this.hidden,
      this.customName,
      this.customIcon,
      this.sortOrder,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['category_code'] = Variable<String>(categoryCode);
    map['hidden'] = Variable<bool>(hidden);
    if (!nullToAbsent || customName != null) {
      map['custom_name'] = Variable<String>(customName);
    }
    if (!nullToAbsent || customIcon != null) {
      map['custom_icon'] = Variable<String>(customIcon);
    }
    if (!nullToAbsent || sortOrder != null) {
      map['sort_order'] = Variable<int>(sortOrder);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserCategoryOverridesCompanion toCompanion(bool nullToAbsent) {
    return UserCategoryOverridesCompanion(
      categoryCode: Value(categoryCode),
      hidden: Value(hidden),
      customName: customName == null && nullToAbsent
          ? const Value.absent()
          : Value(customName),
      customIcon: customIcon == null && nullToAbsent
          ? const Value.absent()
          : Value(customIcon),
      sortOrder: sortOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(sortOrder),
      updatedAt: Value(updatedAt),
    );
  }

  factory DbUserCategoryOverride.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbUserCategoryOverride(
      categoryCode: serializer.fromJson<String>(json['categoryCode']),
      hidden: serializer.fromJson<bool>(json['hidden']),
      customName: serializer.fromJson<String?>(json['customName']),
      customIcon: serializer.fromJson<String?>(json['customIcon']),
      sortOrder: serializer.fromJson<int?>(json['sortOrder']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'categoryCode': serializer.toJson<String>(categoryCode),
      'hidden': serializer.toJson<bool>(hidden),
      'customName': serializer.toJson<String?>(customName),
      'customIcon': serializer.toJson<String?>(customIcon),
      'sortOrder': serializer.toJson<int?>(sortOrder),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DbUserCategoryOverride copyWith(
          {String? categoryCode,
          bool? hidden,
          Value<String?> customName = const Value.absent(),
          Value<String?> customIcon = const Value.absent(),
          Value<int?> sortOrder = const Value.absent(),
          DateTime? updatedAt}) =>
      DbUserCategoryOverride(
        categoryCode: categoryCode ?? this.categoryCode,
        hidden: hidden ?? this.hidden,
        customName: customName.present ? customName.value : this.customName,
        customIcon: customIcon.present ? customIcon.value : this.customIcon,
        sortOrder: sortOrder.present ? sortOrder.value : this.sortOrder,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DbUserCategoryOverride copyWithCompanion(
      UserCategoryOverridesCompanion data) {
    return DbUserCategoryOverride(
      categoryCode: data.categoryCode.present
          ? data.categoryCode.value
          : this.categoryCode,
      hidden: data.hidden.present ? data.hidden.value : this.hidden,
      customName:
          data.customName.present ? data.customName.value : this.customName,
      customIcon:
          data.customIcon.present ? data.customIcon.value : this.customIcon,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbUserCategoryOverride(')
          ..write('categoryCode: $categoryCode, ')
          ..write('hidden: $hidden, ')
          ..write('customName: $customName, ')
          ..write('customIcon: $customIcon, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      categoryCode, hidden, customName, customIcon, sortOrder, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbUserCategoryOverride &&
          other.categoryCode == this.categoryCode &&
          other.hidden == this.hidden &&
          other.customName == this.customName &&
          other.customIcon == this.customIcon &&
          other.sortOrder == this.sortOrder &&
          other.updatedAt == this.updatedAt);
}

class UserCategoryOverridesCompanion
    extends UpdateCompanion<DbUserCategoryOverride> {
  final Value<String> categoryCode;
  final Value<bool> hidden;
  final Value<String?> customName;
  final Value<String?> customIcon;
  final Value<int?> sortOrder;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserCategoryOverridesCompanion({
    this.categoryCode = const Value.absent(),
    this.hidden = const Value.absent(),
    this.customName = const Value.absent(),
    this.customIcon = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserCategoryOverridesCompanion.insert({
    required String categoryCode,
    this.hidden = const Value.absent(),
    this.customName = const Value.absent(),
    this.customIcon = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : categoryCode = Value(categoryCode);
  static Insertable<DbUserCategoryOverride> custom({
    Expression<String>? categoryCode,
    Expression<bool>? hidden,
    Expression<String>? customName,
    Expression<String>? customIcon,
    Expression<int>? sortOrder,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (categoryCode != null) 'category_code': categoryCode,
      if (hidden != null) 'hidden': hidden,
      if (customName != null) 'custom_name': customName,
      if (customIcon != null) 'custom_icon': customIcon,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserCategoryOverridesCompanion copyWith(
      {Value<String>? categoryCode,
      Value<bool>? hidden,
      Value<String?>? customName,
      Value<String?>? customIcon,
      Value<int?>? sortOrder,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return UserCategoryOverridesCompanion(
      categoryCode: categoryCode ?? this.categoryCode,
      hidden: hidden ?? this.hidden,
      customName: customName ?? this.customName,
      customIcon: customIcon ?? this.customIcon,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (categoryCode.present) {
      map['category_code'] = Variable<String>(categoryCode.value);
    }
    if (hidden.present) {
      map['hidden'] = Variable<bool>(hidden.value);
    }
    if (customName.present) {
      map['custom_name'] = Variable<String>(customName.value);
    }
    if (customIcon.present) {
      map['custom_icon'] = Variable<String>(customIcon.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserCategoryOverridesCompanion(')
          ..write('categoryCode: $categoryCode, ')
          ..write('hidden: $hidden, ')
          ..write('customName: $customName, ')
          ..write('customIcon: $customIcon, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserTaskOverridesTable extends UserTaskOverrides
    with TableInfo<$UserTaskOverridesTable, DbUserTaskOverride> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserTaskOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _taskCodeMeta =
      const VerificationMeta('taskCode');
  @override
  late final GeneratedColumn<String> taskCode = GeneratedColumn<String>(
      'task_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _hiddenMeta = const VerificationMeta('hidden');
  @override
  late final GeneratedColumn<bool> hidden = GeneratedColumn<bool>(
      'hidden', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("hidden" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _customNameMeta =
      const VerificationMeta('customName');
  @override
  late final GeneratedColumn<String> customName = GeneratedColumn<String>(
      'custom_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customPointsMeta =
      const VerificationMeta('customPoints');
  @override
  late final GeneratedColumn<int> customPoints = GeneratedColumn<int>(
      'custom_points', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _customIconMeta =
      const VerificationMeta('customIcon');
  @override
  late final GeneratedColumn<String> customIcon = GeneratedColumn<String>(
      'custom_icon', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customCategoryRefMeta =
      const VerificationMeta('customCategoryRef');
  @override
  late final GeneratedColumn<String> customCategoryRef =
      GeneratedColumn<String>('custom_category_ref', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        taskCode,
        hidden,
        customName,
        customPoints,
        customIcon,
        customCategoryRef,
        sortOrder,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_task_overrides';
  @override
  VerificationContext validateIntegrity(Insertable<DbUserTaskOverride> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('task_code')) {
      context.handle(_taskCodeMeta,
          taskCode.isAcceptableOrUnknown(data['task_code']!, _taskCodeMeta));
    } else if (isInserting) {
      context.missing(_taskCodeMeta);
    }
    if (data.containsKey('hidden')) {
      context.handle(_hiddenMeta,
          hidden.isAcceptableOrUnknown(data['hidden']!, _hiddenMeta));
    }
    if (data.containsKey('custom_name')) {
      context.handle(
          _customNameMeta,
          customName.isAcceptableOrUnknown(
              data['custom_name']!, _customNameMeta));
    }
    if (data.containsKey('custom_points')) {
      context.handle(
          _customPointsMeta,
          customPoints.isAcceptableOrUnknown(
              data['custom_points']!, _customPointsMeta));
    }
    if (data.containsKey('custom_icon')) {
      context.handle(
          _customIconMeta,
          customIcon.isAcceptableOrUnknown(
              data['custom_icon']!, _customIconMeta));
    }
    if (data.containsKey('custom_category_ref')) {
      context.handle(
          _customCategoryRefMeta,
          customCategoryRef.isAcceptableOrUnknown(
              data['custom_category_ref']!, _customCategoryRefMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {taskCode};
  @override
  DbUserTaskOverride map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbUserTaskOverride(
      taskCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}task_code'])!,
      hidden: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}hidden'])!,
      customName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}custom_name']),
      customPoints: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}custom_points']),
      customIcon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}custom_icon']),
      customCategoryRef: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}custom_category_ref']),
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $UserTaskOverridesTable createAlias(String alias) {
    return $UserTaskOverridesTable(attachedDatabase, alias);
  }
}

class DbUserTaskOverride extends DataClass
    implements Insertable<DbUserTaskOverride> {
  final String taskCode;
  final bool hidden;
  final String? customName;
  final int? customPoints;
  final String? customIcon;
  final String? customCategoryRef;
  final int? sortOrder;
  final DateTime updatedAt;
  const DbUserTaskOverride(
      {required this.taskCode,
      required this.hidden,
      this.customName,
      this.customPoints,
      this.customIcon,
      this.customCategoryRef,
      this.sortOrder,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['task_code'] = Variable<String>(taskCode);
    map['hidden'] = Variable<bool>(hidden);
    if (!nullToAbsent || customName != null) {
      map['custom_name'] = Variable<String>(customName);
    }
    if (!nullToAbsent || customPoints != null) {
      map['custom_points'] = Variable<int>(customPoints);
    }
    if (!nullToAbsent || customIcon != null) {
      map['custom_icon'] = Variable<String>(customIcon);
    }
    if (!nullToAbsent || customCategoryRef != null) {
      map['custom_category_ref'] = Variable<String>(customCategoryRef);
    }
    if (!nullToAbsent || sortOrder != null) {
      map['sort_order'] = Variable<int>(sortOrder);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserTaskOverridesCompanion toCompanion(bool nullToAbsent) {
    return UserTaskOverridesCompanion(
      taskCode: Value(taskCode),
      hidden: Value(hidden),
      customName: customName == null && nullToAbsent
          ? const Value.absent()
          : Value(customName),
      customPoints: customPoints == null && nullToAbsent
          ? const Value.absent()
          : Value(customPoints),
      customIcon: customIcon == null && nullToAbsent
          ? const Value.absent()
          : Value(customIcon),
      customCategoryRef: customCategoryRef == null && nullToAbsent
          ? const Value.absent()
          : Value(customCategoryRef),
      sortOrder: sortOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(sortOrder),
      updatedAt: Value(updatedAt),
    );
  }

  factory DbUserTaskOverride.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbUserTaskOverride(
      taskCode: serializer.fromJson<String>(json['taskCode']),
      hidden: serializer.fromJson<bool>(json['hidden']),
      customName: serializer.fromJson<String?>(json['customName']),
      customPoints: serializer.fromJson<int?>(json['customPoints']),
      customIcon: serializer.fromJson<String?>(json['customIcon']),
      customCategoryRef:
          serializer.fromJson<String?>(json['customCategoryRef']),
      sortOrder: serializer.fromJson<int?>(json['sortOrder']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'taskCode': serializer.toJson<String>(taskCode),
      'hidden': serializer.toJson<bool>(hidden),
      'customName': serializer.toJson<String?>(customName),
      'customPoints': serializer.toJson<int?>(customPoints),
      'customIcon': serializer.toJson<String?>(customIcon),
      'customCategoryRef': serializer.toJson<String?>(customCategoryRef),
      'sortOrder': serializer.toJson<int?>(sortOrder),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DbUserTaskOverride copyWith(
          {String? taskCode,
          bool? hidden,
          Value<String?> customName = const Value.absent(),
          Value<int?> customPoints = const Value.absent(),
          Value<String?> customIcon = const Value.absent(),
          Value<String?> customCategoryRef = const Value.absent(),
          Value<int?> sortOrder = const Value.absent(),
          DateTime? updatedAt}) =>
      DbUserTaskOverride(
        taskCode: taskCode ?? this.taskCode,
        hidden: hidden ?? this.hidden,
        customName: customName.present ? customName.value : this.customName,
        customPoints:
            customPoints.present ? customPoints.value : this.customPoints,
        customIcon: customIcon.present ? customIcon.value : this.customIcon,
        customCategoryRef: customCategoryRef.present
            ? customCategoryRef.value
            : this.customCategoryRef,
        sortOrder: sortOrder.present ? sortOrder.value : this.sortOrder,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  DbUserTaskOverride copyWithCompanion(UserTaskOverridesCompanion data) {
    return DbUserTaskOverride(
      taskCode: data.taskCode.present ? data.taskCode.value : this.taskCode,
      hidden: data.hidden.present ? data.hidden.value : this.hidden,
      customName:
          data.customName.present ? data.customName.value : this.customName,
      customPoints: data.customPoints.present
          ? data.customPoints.value
          : this.customPoints,
      customIcon:
          data.customIcon.present ? data.customIcon.value : this.customIcon,
      customCategoryRef: data.customCategoryRef.present
          ? data.customCategoryRef.value
          : this.customCategoryRef,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbUserTaskOverride(')
          ..write('taskCode: $taskCode, ')
          ..write('hidden: $hidden, ')
          ..write('customName: $customName, ')
          ..write('customPoints: $customPoints, ')
          ..write('customIcon: $customIcon, ')
          ..write('customCategoryRef: $customCategoryRef, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(taskCode, hidden, customName, customPoints,
      customIcon, customCategoryRef, sortOrder, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbUserTaskOverride &&
          other.taskCode == this.taskCode &&
          other.hidden == this.hidden &&
          other.customName == this.customName &&
          other.customPoints == this.customPoints &&
          other.customIcon == this.customIcon &&
          other.customCategoryRef == this.customCategoryRef &&
          other.sortOrder == this.sortOrder &&
          other.updatedAt == this.updatedAt);
}

class UserTaskOverridesCompanion extends UpdateCompanion<DbUserTaskOverride> {
  final Value<String> taskCode;
  final Value<bool> hidden;
  final Value<String?> customName;
  final Value<int?> customPoints;
  final Value<String?> customIcon;
  final Value<String?> customCategoryRef;
  final Value<int?> sortOrder;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UserTaskOverridesCompanion({
    this.taskCode = const Value.absent(),
    this.hidden = const Value.absent(),
    this.customName = const Value.absent(),
    this.customPoints = const Value.absent(),
    this.customIcon = const Value.absent(),
    this.customCategoryRef = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserTaskOverridesCompanion.insert({
    required String taskCode,
    this.hidden = const Value.absent(),
    this.customName = const Value.absent(),
    this.customPoints = const Value.absent(),
    this.customIcon = const Value.absent(),
    this.customCategoryRef = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : taskCode = Value(taskCode);
  static Insertable<DbUserTaskOverride> custom({
    Expression<String>? taskCode,
    Expression<bool>? hidden,
    Expression<String>? customName,
    Expression<int>? customPoints,
    Expression<String>? customIcon,
    Expression<String>? customCategoryRef,
    Expression<int>? sortOrder,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (taskCode != null) 'task_code': taskCode,
      if (hidden != null) 'hidden': hidden,
      if (customName != null) 'custom_name': customName,
      if (customPoints != null) 'custom_points': customPoints,
      if (customIcon != null) 'custom_icon': customIcon,
      if (customCategoryRef != null) 'custom_category_ref': customCategoryRef,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserTaskOverridesCompanion copyWith(
      {Value<String>? taskCode,
      Value<bool>? hidden,
      Value<String?>? customName,
      Value<int?>? customPoints,
      Value<String?>? customIcon,
      Value<String?>? customCategoryRef,
      Value<int?>? sortOrder,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return UserTaskOverridesCompanion(
      taskCode: taskCode ?? this.taskCode,
      hidden: hidden ?? this.hidden,
      customName: customName ?? this.customName,
      customPoints: customPoints ?? this.customPoints,
      customIcon: customIcon ?? this.customIcon,
      customCategoryRef: customCategoryRef ?? this.customCategoryRef,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (taskCode.present) {
      map['task_code'] = Variable<String>(taskCode.value);
    }
    if (hidden.present) {
      map['hidden'] = Variable<bool>(hidden.value);
    }
    if (customName.present) {
      map['custom_name'] = Variable<String>(customName.value);
    }
    if (customPoints.present) {
      map['custom_points'] = Variable<int>(customPoints.value);
    }
    if (customIcon.present) {
      map['custom_icon'] = Variable<String>(customIcon.value);
    }
    if (customCategoryRef.present) {
      map['custom_category_ref'] = Variable<String>(customCategoryRef.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserTaskOverridesCompanion(')
          ..write('taskCode: $taskCode, ')
          ..write('hidden: $hidden, ')
          ..write('customName: $customName, ')
          ..write('customPoints: $customPoints, ')
          ..write('customIcon: $customIcon, ')
          ..write('customCategoryRef: $customCategoryRef, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, DbAppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<DbAppSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  DbAppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbAppSetting(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value']),
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class DbAppSetting extends DataClass implements Insertable<DbAppSetting> {
  final String key;
  final String? value;
  const DbAppSetting({required this.key, this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value:
          value == null && nullToAbsent ? const Value.absent() : Value(value),
    );
  }

  factory DbAppSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbAppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
    };
  }

  DbAppSetting copyWith(
          {String? key, Value<String?> value = const Value.absent()}) =>
      DbAppSetting(
        key: key ?? this.key,
        value: value.present ? value.value : this.value,
      );
  DbAppSetting copyWithCompanion(AppSettingsCompanion data) {
    return DbAppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbAppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbAppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<DbAppSetting> {
  final Value<String> key;
  final Value<String?> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<DbAppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith(
      {Value<String>? key, Value<String?>? value, Value<int>? rowid}) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoryNotificationSchedulesTable extends CategoryNotificationSchedules
    with
        TableInfo<$CategoryNotificationSchedulesTable,
            DbCategoryNotificationSchedule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryNotificationSchedulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _enabledMeta =
      const VerificationMeta('enabled');
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
      'enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _hourMeta = const VerificationMeta('hour');
  @override
  late final GeneratedColumn<int> hour = GeneratedColumn<int>(
      'hour', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _minuteMeta = const VerificationMeta('minute');
  @override
  late final GeneratedColumn<int> minute = GeneratedColumn<int>(
      'minute', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [category, enabled, hour, minute];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_notification_schedules';
  @override
  VerificationContext validateIntegrity(
      Insertable<DbCategoryNotificationSchedule> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(_enabledMeta,
          enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta));
    }
    if (data.containsKey('hour')) {
      context.handle(
          _hourMeta, hour.isAcceptableOrUnknown(data['hour']!, _hourMeta));
    } else if (isInserting) {
      context.missing(_hourMeta);
    }
    if (data.containsKey('minute')) {
      context.handle(_minuteMeta,
          minute.isAcceptableOrUnknown(data['minute']!, _minuteMeta));
    } else if (isInserting) {
      context.missing(_minuteMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {category};
  @override
  DbCategoryNotificationSchedule map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbCategoryNotificationSchedule(
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      enabled: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}enabled'])!,
      hour: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}hour'])!,
      minute: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}minute'])!,
    );
  }

  @override
  $CategoryNotificationSchedulesTable createAlias(String alias) {
    return $CategoryNotificationSchedulesTable(attachedDatabase, alias);
  }
}

class DbCategoryNotificationSchedule extends DataClass
    implements Insertable<DbCategoryNotificationSchedule> {
  final String category;
  final bool enabled;
  final int hour;
  final int minute;
  const DbCategoryNotificationSchedule(
      {required this.category,
      required this.enabled,
      required this.hour,
      required this.minute});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['category'] = Variable<String>(category);
    map['enabled'] = Variable<bool>(enabled);
    map['hour'] = Variable<int>(hour);
    map['minute'] = Variable<int>(minute);
    return map;
  }

  CategoryNotificationSchedulesCompanion toCompanion(bool nullToAbsent) {
    return CategoryNotificationSchedulesCompanion(
      category: Value(category),
      enabled: Value(enabled),
      hour: Value(hour),
      minute: Value(minute),
    );
  }

  factory DbCategoryNotificationSchedule.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbCategoryNotificationSchedule(
      category: serializer.fromJson<String>(json['category']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      hour: serializer.fromJson<int>(json['hour']),
      minute: serializer.fromJson<int>(json['minute']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'category': serializer.toJson<String>(category),
      'enabled': serializer.toJson<bool>(enabled),
      'hour': serializer.toJson<int>(hour),
      'minute': serializer.toJson<int>(minute),
    };
  }

  DbCategoryNotificationSchedule copyWith(
          {String? category, bool? enabled, int? hour, int? minute}) =>
      DbCategoryNotificationSchedule(
        category: category ?? this.category,
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );
  DbCategoryNotificationSchedule copyWithCompanion(
      CategoryNotificationSchedulesCompanion data) {
    return DbCategoryNotificationSchedule(
      category: data.category.present ? data.category.value : this.category,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      hour: data.hour.present ? data.hour.value : this.hour,
      minute: data.minute.present ? data.minute.value : this.minute,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbCategoryNotificationSchedule(')
          ..write('category: $category, ')
          ..write('enabled: $enabled, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(category, enabled, hour, minute);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbCategoryNotificationSchedule &&
          other.category == this.category &&
          other.enabled == this.enabled &&
          other.hour == this.hour &&
          other.minute == this.minute);
}

class CategoryNotificationSchedulesCompanion
    extends UpdateCompanion<DbCategoryNotificationSchedule> {
  final Value<String> category;
  final Value<bool> enabled;
  final Value<int> hour;
  final Value<int> minute;
  final Value<int> rowid;
  const CategoryNotificationSchedulesCompanion({
    this.category = const Value.absent(),
    this.enabled = const Value.absent(),
    this.hour = const Value.absent(),
    this.minute = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoryNotificationSchedulesCompanion.insert({
    required String category,
    this.enabled = const Value.absent(),
    required int hour,
    required int minute,
    this.rowid = const Value.absent(),
  })  : category = Value(category),
        hour = Value(hour),
        minute = Value(minute);
  static Insertable<DbCategoryNotificationSchedule> custom({
    Expression<String>? category,
    Expression<bool>? enabled,
    Expression<int>? hour,
    Expression<int>? minute,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (category != null) 'category': category,
      if (enabled != null) 'enabled': enabled,
      if (hour != null) 'hour': hour,
      if (minute != null) 'minute': minute,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoryNotificationSchedulesCompanion copyWith(
      {Value<String>? category,
      Value<bool>? enabled,
      Value<int>? hour,
      Value<int>? minute,
      Value<int>? rowid}) {
    return CategoryNotificationSchedulesCompanion(
      category: category ?? this.category,
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (hour.present) {
      map['hour'] = Variable<int>(hour.value);
    }
    if (minute.present) {
      map['minute'] = Variable<int>(minute.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryNotificationSchedulesCompanion(')
          ..write('category: $category, ')
          ..write('enabled: $enabled, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskNotificationTogglesTable extends TaskNotificationToggles
    with TableInfo<$TaskNotificationTogglesTable, DbTaskNotificationToggle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskNotificationTogglesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
      'task_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notificationsEnabledMeta =
      const VerificationMeta('notificationsEnabled');
  @override
  late final GeneratedColumn<bool> notificationsEnabled = GeneratedColumn<bool>(
      'notifications_enabled', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("notifications_enabled" IN (0, 1))'),
      defaultValue: const Constant(true));
  @override
  List<GeneratedColumn> get $columns => [taskId, notificationsEnabled];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_notification_toggles';
  @override
  VerificationContext validateIntegrity(
      Insertable<DbTaskNotificationToggle> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('task_id')) {
      context.handle(_taskIdMeta,
          taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta));
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('notifications_enabled')) {
      context.handle(
          _notificationsEnabledMeta,
          notificationsEnabled.isAcceptableOrUnknown(
              data['notifications_enabled']!, _notificationsEnabledMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {taskId};
  @override
  DbTaskNotificationToggle map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbTaskNotificationToggle(
      taskId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}task_id'])!,
      notificationsEnabled: attachedDatabase.typeMapping.read(
          DriftSqlType.bool, data['${effectivePrefix}notifications_enabled'])!,
    );
  }

  @override
  $TaskNotificationTogglesTable createAlias(String alias) {
    return $TaskNotificationTogglesTable(attachedDatabase, alias);
  }
}

class DbTaskNotificationToggle extends DataClass
    implements Insertable<DbTaskNotificationToggle> {
  final String taskId;
  final bool notificationsEnabled;
  const DbTaskNotificationToggle(
      {required this.taskId, required this.notificationsEnabled});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['task_id'] = Variable<String>(taskId);
    map['notifications_enabled'] = Variable<bool>(notificationsEnabled);
    return map;
  }

  TaskNotificationTogglesCompanion toCompanion(bool nullToAbsent) {
    return TaskNotificationTogglesCompanion(
      taskId: Value(taskId),
      notificationsEnabled: Value(notificationsEnabled),
    );
  }

  factory DbTaskNotificationToggle.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbTaskNotificationToggle(
      taskId: serializer.fromJson<String>(json['taskId']),
      notificationsEnabled:
          serializer.fromJson<bool>(json['notificationsEnabled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'taskId': serializer.toJson<String>(taskId),
      'notificationsEnabled': serializer.toJson<bool>(notificationsEnabled),
    };
  }

  DbTaskNotificationToggle copyWith(
          {String? taskId, bool? notificationsEnabled}) =>
      DbTaskNotificationToggle(
        taskId: taskId ?? this.taskId,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      );
  DbTaskNotificationToggle copyWithCompanion(
      TaskNotificationTogglesCompanion data) {
    return DbTaskNotificationToggle(
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      notificationsEnabled: data.notificationsEnabled.present
          ? data.notificationsEnabled.value
          : this.notificationsEnabled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbTaskNotificationToggle(')
          ..write('taskId: $taskId, ')
          ..write('notificationsEnabled: $notificationsEnabled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(taskId, notificationsEnabled);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbTaskNotificationToggle &&
          other.taskId == this.taskId &&
          other.notificationsEnabled == this.notificationsEnabled);
}

class TaskNotificationTogglesCompanion
    extends UpdateCompanion<DbTaskNotificationToggle> {
  final Value<String> taskId;
  final Value<bool> notificationsEnabled;
  final Value<int> rowid;
  const TaskNotificationTogglesCompanion({
    this.taskId = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskNotificationTogglesCompanion.insert({
    required String taskId,
    this.notificationsEnabled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : taskId = Value(taskId);
  static Insertable<DbTaskNotificationToggle> custom({
    Expression<String>? taskId,
    Expression<bool>? notificationsEnabled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (taskId != null) 'task_id': taskId,
      if (notificationsEnabled != null)
        'notifications_enabled': notificationsEnabled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskNotificationTogglesCompanion copyWith(
      {Value<String>? taskId,
      Value<bool>? notificationsEnabled,
      Value<int>? rowid}) {
    return TaskNotificationTogglesCompanion(
      taskId: taskId ?? this.taskId,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (notificationsEnabled.present) {
      map['notifications_enabled'] = Variable<bool>(notificationsEnabled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskNotificationTogglesCompanion(')
          ..write('taskId: $taskId, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingSyncOpsTable extends PendingSyncOps
    with TableInfo<$PendingSyncOpsTable, PendingSyncOp> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingSyncOpsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _opTypeMeta = const VerificationMeta('opType');
  @override
  late final GeneratedColumn<String> opType = GeneratedColumn<String>(
      'op_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _clientUpdatedAtMeta =
      const VerificationMeta('clientUpdatedAt');
  @override
  late final GeneratedColumn<DateTime> clientUpdatedAt =
      GeneratedColumn<DateTime>('client_updated_at', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastErrorMeta =
      const VerificationMeta('lastError');
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
      'last_error', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, opType, payloadJson, clientUpdatedAt, attempts, lastError];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_sync_ops';
  @override
  VerificationContext validateIntegrity(Insertable<PendingSyncOp> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('op_type')) {
      context.handle(_opTypeMeta,
          opType.isAcceptableOrUnknown(data['op_type']!, _opTypeMeta));
    } else if (isInserting) {
      context.missing(_opTypeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('client_updated_at')) {
      context.handle(
          _clientUpdatedAtMeta,
          clientUpdatedAt.isAcceptableOrUnknown(
              data['client_updated_at']!, _clientUpdatedAtMeta));
    } else if (isInserting) {
      context.missing(_clientUpdatedAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    if (data.containsKey('last_error')) {
      context.handle(_lastErrorMeta,
          lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingSyncOp map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingSyncOp(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      opType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}op_type'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      clientUpdatedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}client_updated_at'])!,
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
      lastError: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_error']),
    );
  }

  @override
  $PendingSyncOpsTable createAlias(String alias) {
    return $PendingSyncOpsTable(attachedDatabase, alias);
  }
}

class PendingSyncOp extends DataClass implements Insertable<PendingSyncOp> {
  final int id;
  final String opType;
  final String payloadJson;
  final DateTime clientUpdatedAt;
  final int attempts;
  final String? lastError;
  const PendingSyncOp(
      {required this.id,
      required this.opType,
      required this.payloadJson,
      required this.clientUpdatedAt,
      required this.attempts,
      this.lastError});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['op_type'] = Variable<String>(opType);
    map['payload_json'] = Variable<String>(payloadJson);
    map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  PendingSyncOpsCompanion toCompanion(bool nullToAbsent) {
    return PendingSyncOpsCompanion(
      id: Value(id),
      opType: Value(opType),
      payloadJson: Value(payloadJson),
      clientUpdatedAt: Value(clientUpdatedAt),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory PendingSyncOp.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingSyncOp(
      id: serializer.fromJson<int>(json['id']),
      opType: serializer.fromJson<String>(json['opType']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      clientUpdatedAt: serializer.fromJson<DateTime>(json['clientUpdatedAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'opType': serializer.toJson<String>(opType),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'clientUpdatedAt': serializer.toJson<DateTime>(clientUpdatedAt),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  PendingSyncOp copyWith(
          {int? id,
          String? opType,
          String? payloadJson,
          DateTime? clientUpdatedAt,
          int? attempts,
          Value<String?> lastError = const Value.absent()}) =>
      PendingSyncOp(
        id: id ?? this.id,
        opType: opType ?? this.opType,
        payloadJson: payloadJson ?? this.payloadJson,
        clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
        attempts: attempts ?? this.attempts,
        lastError: lastError.present ? lastError.value : this.lastError,
      );
  PendingSyncOp copyWithCompanion(PendingSyncOpsCompanion data) {
    return PendingSyncOp(
      id: data.id.present ? data.id.value : this.id,
      opType: data.opType.present ? data.opType.value : this.opType,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      clientUpdatedAt: data.clientUpdatedAt.present
          ? data.clientUpdatedAt.value
          : this.clientUpdatedAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingSyncOp(')
          ..write('id: $id, ')
          ..write('opType: $opType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, opType, payloadJson, clientUpdatedAt, attempts, lastError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingSyncOp &&
          other.id == this.id &&
          other.opType == this.opType &&
          other.payloadJson == this.payloadJson &&
          other.clientUpdatedAt == this.clientUpdatedAt &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError);
}

class PendingSyncOpsCompanion extends UpdateCompanion<PendingSyncOp> {
  final Value<int> id;
  final Value<String> opType;
  final Value<String> payloadJson;
  final Value<DateTime> clientUpdatedAt;
  final Value<int> attempts;
  final Value<String?> lastError;
  const PendingSyncOpsCompanion({
    this.id = const Value.absent(),
    this.opType = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.clientUpdatedAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
  });
  PendingSyncOpsCompanion.insert({
    this.id = const Value.absent(),
    required String opType,
    required String payloadJson,
    required DateTime clientUpdatedAt,
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
  })  : opType = Value(opType),
        payloadJson = Value(payloadJson),
        clientUpdatedAt = Value(clientUpdatedAt);
  static Insertable<PendingSyncOp> custom({
    Expression<int>? id,
    Expression<String>? opType,
    Expression<String>? payloadJson,
    Expression<DateTime>? clientUpdatedAt,
    Expression<int>? attempts,
    Expression<String>? lastError,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (opType != null) 'op_type': opType,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (clientUpdatedAt != null) 'client_updated_at': clientUpdatedAt,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
    });
  }

  PendingSyncOpsCompanion copyWith(
      {Value<int>? id,
      Value<String>? opType,
      Value<String>? payloadJson,
      Value<DateTime>? clientUpdatedAt,
      Value<int>? attempts,
      Value<String?>? lastError}) {
    return PendingSyncOpsCompanion(
      id: id ?? this.id,
      opType: opType ?? this.opType,
      payloadJson: payloadJson ?? this.payloadJson,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (opType.present) {
      map['op_type'] = Variable<String>(opType.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (clientUpdatedAt.present) {
      map['client_updated_at'] = Variable<DateTime>(clientUpdatedAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingSyncOpsCompanion(')
          ..write('id: $id, ')
          ..write('opType: $opType, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('clientUpdatedAt: $clientUpdatedAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $UserTasksTable userTasks = $UserTasksTable(this);
  late final $DailyLogsTable dailyLogs = $DailyLogsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $UserCategoriesTable userCategories = $UserCategoriesTable(this);
  late final $UserCategoryOverridesTable userCategoryOverrides =
      $UserCategoryOverridesTable(this);
  late final $UserTaskOverridesTable userTaskOverrides =
      $UserTaskOverridesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $CategoryNotificationSchedulesTable categoryNotificationSchedules =
      $CategoryNotificationSchedulesTable(this);
  late final $TaskNotificationTogglesTable taskNotificationToggles =
      $TaskNotificationTogglesTable(this);
  late final $PendingSyncOpsTable pendingSyncOps = $PendingSyncOpsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        tasks,
        userTasks,
        dailyLogs,
        categories,
        userCategories,
        userCategoryOverrides,
        userTaskOverrides,
        appSettings,
        categoryNotificationSchedules,
        taskNotificationToggles,
        pendingSyncOps
      ];
}

typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  required String id,
  required int points,
  required String category,
  required int sortOrder,
  Value<int> rowid,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<String> id,
  Value<int> points,
  Value<String> category,
  Value<int> sortOrder,
  Value<int> rowid,
});

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, DbTask> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DailyLogsTable, List<DbDailyLog>>
      _dailyLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.dailyLogs,
          aliasName: $_aliasNameGenerator(db.tasks.id, db.dailyLogs.taskId));

  $$DailyLogsTableProcessedTableManager get dailyLogsRefs {
    final manager = $$DailyLogsTableTableManager($_db, $_db.dailyLogs)
        .filter((f) => f.taskId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_dailyLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TasksTableFilterComposer
    extends FilterComposer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get points => $state.composableBuilder(
      column: $state.table.points,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get sortOrder => $state.composableBuilder(
      column: $state.table.sortOrder,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter dailyLogsRefs(
      ComposableFilter Function($$DailyLogsTableFilterComposer f) f) {
    final $$DailyLogsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.dailyLogs,
        getReferencedColumn: (t) => t.taskId,
        builder: (joinBuilder, parentComposers) =>
            $$DailyLogsTableFilterComposer(ComposerState(
                $state.db, $state.db.dailyLogs, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$TasksTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get points => $state.composableBuilder(
      column: $state.table.points,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get sortOrder => $state.composableBuilder(
      column: $state.table.sortOrder,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$TasksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TasksTable,
    DbTask,
    $$TasksTableFilterComposer,
    $$TasksTableOrderingComposer,
    $$TasksTableCreateCompanionBuilder,
    $$TasksTableUpdateCompanionBuilder,
    (DbTask, $$TasksTableReferences),
    DbTask,
    PrefetchHooks Function({bool dailyLogsRefs})> {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$TasksTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$TasksTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> points = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TasksCompanion(
            id: id,
            points: points,
            category: category,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int points,
            required String category,
            required int sortOrder,
            Value<int> rowid = const Value.absent(),
          }) =>
              TasksCompanion.insert(
            id: id,
            points: points,
            category: category,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$TasksTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({dailyLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (dailyLogsRefs) db.dailyLogs],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (dailyLogsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$TasksTableReferences._dailyLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TasksTableReferences(db, table, p0).dailyLogsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.taskId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TasksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TasksTable,
    DbTask,
    $$TasksTableFilterComposer,
    $$TasksTableOrderingComposer,
    $$TasksTableCreateCompanionBuilder,
    $$TasksTableUpdateCompanionBuilder,
    (DbTask, $$TasksTableReferences),
    DbTask,
    PrefetchHooks Function({bool dailyLogsRefs})>;
typedef $$UserTasksTableCreateCompanionBuilder = UserTasksCompanion Function({
  required String id,
  required String categoryRef,
  required String name,
  required int points,
  required String icon,
  required int sortOrder,
  Value<DateTime?> archivedAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$UserTasksTableUpdateCompanionBuilder = UserTasksCompanion Function({
  Value<String> id,
  Value<String> categoryRef,
  Value<String> name,
  Value<int> points,
  Value<String> icon,
  Value<int> sortOrder,
  Value<DateTime?> archivedAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$UserTasksTableReferences
    extends BaseReferences<_$AppDatabase, $UserTasksTable, DbUserTask> {
  $$UserTasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DailyLogsTable, List<DbDailyLog>>
      _dailyLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.dailyLogs,
          aliasName:
              $_aliasNameGenerator(db.userTasks.id, db.dailyLogs.userTaskId));

  $$DailyLogsTableProcessedTableManager get dailyLogsRefs {
    final manager = $$DailyLogsTableTableManager($_db, $_db.dailyLogs)
        .filter((f) => f.userTaskId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_dailyLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$UserTasksTableFilterComposer
    extends FilterComposer<_$AppDatabase, $UserTasksTable> {
  $$UserTasksTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get categoryRef => $state.composableBuilder(
      column: $state.table.categoryRef,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get points => $state.composableBuilder(
      column: $state.table.points,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get icon => $state.composableBuilder(
      column: $state.table.icon,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get sortOrder => $state.composableBuilder(
      column: $state.table.sortOrder,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get archivedAt => $state.composableBuilder(
      column: $state.table.archivedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter dailyLogsRefs(
      ComposableFilter Function($$DailyLogsTableFilterComposer f) f) {
    final $$DailyLogsTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.dailyLogs,
        getReferencedColumn: (t) => t.userTaskId,
        builder: (joinBuilder, parentComposers) =>
            $$DailyLogsTableFilterComposer(ComposerState(
                $state.db, $state.db.dailyLogs, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$UserTasksTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $UserTasksTable> {
  $$UserTasksTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get categoryRef => $state.composableBuilder(
      column: $state.table.categoryRef,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get points => $state.composableBuilder(
      column: $state.table.points,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get icon => $state.composableBuilder(
      column: $state.table.icon,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get sortOrder => $state.composableBuilder(
      column: $state.table.sortOrder,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get archivedAt => $state.composableBuilder(
      column: $state.table.archivedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$UserTasksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserTasksTable,
    DbUserTask,
    $$UserTasksTableFilterComposer,
    $$UserTasksTableOrderingComposer,
    $$UserTasksTableCreateCompanionBuilder,
    $$UserTasksTableUpdateCompanionBuilder,
    (DbUserTask, $$UserTasksTableReferences),
    DbUserTask,
    PrefetchHooks Function({bool dailyLogsRefs})> {
  $$UserTasksTableTableManager(_$AppDatabase db, $UserTasksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$UserTasksTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$UserTasksTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> categoryRef = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> points = const Value.absent(),
            Value<String> icon = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime?> archivedAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserTasksCompanion(
            id: id,
            categoryRef: categoryRef,
            name: name,
            points: points,
            icon: icon,
            sortOrder: sortOrder,
            archivedAt: archivedAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String categoryRef,
            required String name,
            required int points,
            required String icon,
            required int sortOrder,
            Value<DateTime?> archivedAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserTasksCompanion.insert(
            id: id,
            categoryRef: categoryRef,
            name: name,
            points: points,
            icon: icon,
            sortOrder: sortOrder,
            archivedAt: archivedAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$UserTasksTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({dailyLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (dailyLogsRefs) db.dailyLogs],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (dailyLogsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$UserTasksTableReferences._dailyLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$UserTasksTableReferences(db, table, p0)
                                .dailyLogsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.userTaskId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$UserTasksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserTasksTable,
    DbUserTask,
    $$UserTasksTableFilterComposer,
    $$UserTasksTableOrderingComposer,
    $$UserTasksTableCreateCompanionBuilder,
    $$UserTasksTableUpdateCompanionBuilder,
    (DbUserTask, $$UserTasksTableReferences),
    DbUserTask,
    PrefetchHooks Function({bool dailyLogsRefs})>;
typedef $$DailyLogsTableCreateCompanionBuilder = DailyLogsCompanion Function({
  Value<int> id,
  required String date,
  Value<String?> taskId,
  Value<String?> userTaskId,
  Value<bool> completed,
  Value<DateTime> updatedAt,
});
typedef $$DailyLogsTableUpdateCompanionBuilder = DailyLogsCompanion Function({
  Value<int> id,
  Value<String> date,
  Value<String?> taskId,
  Value<String?> userTaskId,
  Value<bool> completed,
  Value<DateTime> updatedAt,
});

final class $$DailyLogsTableReferences
    extends BaseReferences<_$AppDatabase, $DailyLogsTable, DbDailyLog> {
  $$DailyLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TasksTable _taskIdTable(_$AppDatabase db) => db.tasks
      .createAlias($_aliasNameGenerator(db.dailyLogs.taskId, db.tasks.id));

  $$TasksTableProcessedTableManager? get taskId {
    if ($_item.taskId == null) return null;
    final manager = $$TasksTableTableManager($_db, $_db.tasks)
        .filter((f) => f.id($_item.taskId!));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $UserTasksTable _userTaskIdTable(_$AppDatabase db) =>
      db.userTasks.createAlias(
          $_aliasNameGenerator(db.dailyLogs.userTaskId, db.userTasks.id));

  $$UserTasksTableProcessedTableManager? get userTaskId {
    if ($_item.userTaskId == null) return null;
    final manager = $$UserTasksTableTableManager($_db, $_db.userTasks)
        .filter((f) => f.id($_item.userTaskId!));
    final item = $_typedResult.readTableOrNull(_userTaskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$DailyLogsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $DailyLogsTable> {
  $$DailyLogsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get completed => $state.composableBuilder(
      column: $state.table.completed,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.taskId,
        referencedTable: $state.db.tasks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$TasksTableFilterComposer(
            ComposerState(
                $state.db, $state.db.tasks, joinBuilder, parentComposers)));
    return composer;
  }

  $$UserTasksTableFilterComposer get userTaskId {
    final $$UserTasksTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userTaskId,
        referencedTable: $state.db.userTasks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$UserTasksTableFilterComposer(ComposerState(
                $state.db, $state.db.userTasks, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$DailyLogsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $DailyLogsTable> {
  $$DailyLogsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get completed => $state.composableBuilder(
      column: $state.table.completed,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.taskId,
        referencedTable: $state.db.tasks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) => $$TasksTableOrderingComposer(
            ComposerState(
                $state.db, $state.db.tasks, joinBuilder, parentComposers)));
    return composer;
  }

  $$UserTasksTableOrderingComposer get userTaskId {
    final $$UserTasksTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.userTaskId,
        referencedTable: $state.db.userTasks,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$UserTasksTableOrderingComposer(ComposerState(
                $state.db, $state.db.userTasks, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$DailyLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DailyLogsTable,
    DbDailyLog,
    $$DailyLogsTableFilterComposer,
    $$DailyLogsTableOrderingComposer,
    $$DailyLogsTableCreateCompanionBuilder,
    $$DailyLogsTableUpdateCompanionBuilder,
    (DbDailyLog, $$DailyLogsTableReferences),
    DbDailyLog,
    PrefetchHooks Function({bool taskId, bool userTaskId})> {
  $$DailyLogsTableTableManager(_$AppDatabase db, $DailyLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$DailyLogsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$DailyLogsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> date = const Value.absent(),
            Value<String?> taskId = const Value.absent(),
            Value<String?> userTaskId = const Value.absent(),
            Value<bool> completed = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              DailyLogsCompanion(
            id: id,
            date: date,
            taskId: taskId,
            userTaskId: userTaskId,
            completed: completed,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String date,
            Value<String?> taskId = const Value.absent(),
            Value<String?> userTaskId = const Value.absent(),
            Value<bool> completed = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              DailyLogsCompanion.insert(
            id: id,
            date: date,
            taskId: taskId,
            userTaskId: userTaskId,
            completed: completed,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$DailyLogsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({taskId = false, userTaskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
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
                      dynamic>>(state) {
                if (taskId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.taskId,
                    referencedTable:
                        $$DailyLogsTableReferences._taskIdTable(db),
                    referencedColumn:
                        $$DailyLogsTableReferences._taskIdTable(db).id,
                  ) as T;
                }
                if (userTaskId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.userTaskId,
                    referencedTable:
                        $$DailyLogsTableReferences._userTaskIdTable(db),
                    referencedColumn:
                        $$DailyLogsTableReferences._userTaskIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$DailyLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DailyLogsTable,
    DbDailyLog,
    $$DailyLogsTableFilterComposer,
    $$DailyLogsTableOrderingComposer,
    $$DailyLogsTableCreateCompanionBuilder,
    $$DailyLogsTableUpdateCompanionBuilder,
    (DbDailyLog, $$DailyLogsTableReferences),
    DbDailyLog,
    PrefetchHooks Function({bool taskId, bool userTaskId})>;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String code,
  required String defaultName,
  required String defaultIcon,
  required int defaultSortOrder,
  required bool isFard,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> code,
  Value<String> defaultName,
  Value<String> defaultIcon,
  Value<int> defaultSortOrder,
  Value<bool> isFard,
  Value<int> rowid,
});

class $$CategoriesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer(super.$state);
  ColumnFilters<String> get code => $state.composableBuilder(
      column: $state.table.code,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get defaultName => $state.composableBuilder(
      column: $state.table.defaultName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get defaultIcon => $state.composableBuilder(
      column: $state.table.defaultIcon,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get defaultSortOrder => $state.composableBuilder(
      column: $state.table.defaultSortOrder,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isFard => $state.composableBuilder(
      column: $state.table.isFard,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$CategoriesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get code => $state.composableBuilder(
      column: $state.table.code,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get defaultName => $state.composableBuilder(
      column: $state.table.defaultName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get defaultIcon => $state.composableBuilder(
      column: $state.table.defaultIcon,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get defaultSortOrder => $state.composableBuilder(
      column: $state.table.defaultSortOrder,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isFard => $state.composableBuilder(
      column: $state.table.isFard,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$CategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTable,
    DbCategory,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (DbCategory, BaseReferences<_$AppDatabase, $CategoriesTable, DbCategory>),
    DbCategory,
    PrefetchHooks Function()> {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$CategoriesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$CategoriesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> code = const Value.absent(),
            Value<String> defaultName = const Value.absent(),
            Value<String> defaultIcon = const Value.absent(),
            Value<int> defaultSortOrder = const Value.absent(),
            Value<bool> isFard = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion(
            code: code,
            defaultName: defaultName,
            defaultIcon: defaultIcon,
            defaultSortOrder: defaultSortOrder,
            isFard: isFard,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String code,
            required String defaultName,
            required String defaultIcon,
            required int defaultSortOrder,
            required bool isFard,
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            code: code,
            defaultName: defaultName,
            defaultIcon: defaultIcon,
            defaultSortOrder: defaultSortOrder,
            isFard: isFard,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesTable,
    DbCategory,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (DbCategory, BaseReferences<_$AppDatabase, $CategoriesTable, DbCategory>),
    DbCategory,
    PrefetchHooks Function()>;
typedef $$UserCategoriesTableCreateCompanionBuilder = UserCategoriesCompanion
    Function({
  required String id,
  required String name,
  required String icon,
  required int sortOrder,
  Value<DateTime?> archivedAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$UserCategoriesTableUpdateCompanionBuilder = UserCategoriesCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String> icon,
  Value<int> sortOrder,
  Value<DateTime?> archivedAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$UserCategoriesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $UserCategoriesTable> {
  $$UserCategoriesTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get icon => $state.composableBuilder(
      column: $state.table.icon,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get sortOrder => $state.composableBuilder(
      column: $state.table.sortOrder,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get archivedAt => $state.composableBuilder(
      column: $state.table.archivedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$UserCategoriesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $UserCategoriesTable> {
  $$UserCategoriesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get icon => $state.composableBuilder(
      column: $state.table.icon,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get sortOrder => $state.composableBuilder(
      column: $state.table.sortOrder,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get archivedAt => $state.composableBuilder(
      column: $state.table.archivedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$UserCategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserCategoriesTable,
    DbUserCategory,
    $$UserCategoriesTableFilterComposer,
    $$UserCategoriesTableOrderingComposer,
    $$UserCategoriesTableCreateCompanionBuilder,
    $$UserCategoriesTableUpdateCompanionBuilder,
    (
      DbUserCategory,
      BaseReferences<_$AppDatabase, $UserCategoriesTable, DbUserCategory>
    ),
    DbUserCategory,
    PrefetchHooks Function()> {
  $$UserCategoriesTableTableManager(
      _$AppDatabase db, $UserCategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$UserCategoriesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$UserCategoriesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> icon = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime?> archivedAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserCategoriesCompanion(
            id: id,
            name: name,
            icon: icon,
            sortOrder: sortOrder,
            archivedAt: archivedAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String icon,
            required int sortOrder,
            Value<DateTime?> archivedAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserCategoriesCompanion.insert(
            id: id,
            name: name,
            icon: icon,
            sortOrder: sortOrder,
            archivedAt: archivedAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserCategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserCategoriesTable,
    DbUserCategory,
    $$UserCategoriesTableFilterComposer,
    $$UserCategoriesTableOrderingComposer,
    $$UserCategoriesTableCreateCompanionBuilder,
    $$UserCategoriesTableUpdateCompanionBuilder,
    (
      DbUserCategory,
      BaseReferences<_$AppDatabase, $UserCategoriesTable, DbUserCategory>
    ),
    DbUserCategory,
    PrefetchHooks Function()>;
typedef $$UserCategoryOverridesTableCreateCompanionBuilder
    = UserCategoryOverridesCompanion Function({
  required String categoryCode,
  Value<bool> hidden,
  Value<String?> customName,
  Value<String?> customIcon,
  Value<int?> sortOrder,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$UserCategoryOverridesTableUpdateCompanionBuilder
    = UserCategoryOverridesCompanion Function({
  Value<String> categoryCode,
  Value<bool> hidden,
  Value<String?> customName,
  Value<String?> customIcon,
  Value<int?> sortOrder,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$UserCategoryOverridesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $UserCategoryOverridesTable> {
  $$UserCategoryOverridesTableFilterComposer(super.$state);
  ColumnFilters<String> get categoryCode => $state.composableBuilder(
      column: $state.table.categoryCode,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get hidden => $state.composableBuilder(
      column: $state.table.hidden,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get customName => $state.composableBuilder(
      column: $state.table.customName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get customIcon => $state.composableBuilder(
      column: $state.table.customIcon,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get sortOrder => $state.composableBuilder(
      column: $state.table.sortOrder,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$UserCategoryOverridesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $UserCategoryOverridesTable> {
  $$UserCategoryOverridesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get categoryCode => $state.composableBuilder(
      column: $state.table.categoryCode,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get hidden => $state.composableBuilder(
      column: $state.table.hidden,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get customName => $state.composableBuilder(
      column: $state.table.customName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get customIcon => $state.composableBuilder(
      column: $state.table.customIcon,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get sortOrder => $state.composableBuilder(
      column: $state.table.sortOrder,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$UserCategoryOverridesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserCategoryOverridesTable,
    DbUserCategoryOverride,
    $$UserCategoryOverridesTableFilterComposer,
    $$UserCategoryOverridesTableOrderingComposer,
    $$UserCategoryOverridesTableCreateCompanionBuilder,
    $$UserCategoryOverridesTableUpdateCompanionBuilder,
    (
      DbUserCategoryOverride,
      BaseReferences<_$AppDatabase, $UserCategoryOverridesTable,
          DbUserCategoryOverride>
    ),
    DbUserCategoryOverride,
    PrefetchHooks Function()> {
  $$UserCategoryOverridesTableTableManager(
      _$AppDatabase db, $UserCategoryOverridesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$UserCategoryOverridesTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer: $$UserCategoryOverridesTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> categoryCode = const Value.absent(),
            Value<bool> hidden = const Value.absent(),
            Value<String?> customName = const Value.absent(),
            Value<String?> customIcon = const Value.absent(),
            Value<int?> sortOrder = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserCategoryOverridesCompanion(
            categoryCode: categoryCode,
            hidden: hidden,
            customName: customName,
            customIcon: customIcon,
            sortOrder: sortOrder,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String categoryCode,
            Value<bool> hidden = const Value.absent(),
            Value<String?> customName = const Value.absent(),
            Value<String?> customIcon = const Value.absent(),
            Value<int?> sortOrder = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserCategoryOverridesCompanion.insert(
            categoryCode: categoryCode,
            hidden: hidden,
            customName: customName,
            customIcon: customIcon,
            sortOrder: sortOrder,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserCategoryOverridesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $UserCategoryOverridesTable,
        DbUserCategoryOverride,
        $$UserCategoryOverridesTableFilterComposer,
        $$UserCategoryOverridesTableOrderingComposer,
        $$UserCategoryOverridesTableCreateCompanionBuilder,
        $$UserCategoryOverridesTableUpdateCompanionBuilder,
        (
          DbUserCategoryOverride,
          BaseReferences<_$AppDatabase, $UserCategoryOverridesTable,
              DbUserCategoryOverride>
        ),
        DbUserCategoryOverride,
        PrefetchHooks Function()>;
typedef $$UserTaskOverridesTableCreateCompanionBuilder
    = UserTaskOverridesCompanion Function({
  required String taskCode,
  Value<bool> hidden,
  Value<String?> customName,
  Value<int?> customPoints,
  Value<String?> customIcon,
  Value<String?> customCategoryRef,
  Value<int?> sortOrder,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$UserTaskOverridesTableUpdateCompanionBuilder
    = UserTaskOverridesCompanion Function({
  Value<String> taskCode,
  Value<bool> hidden,
  Value<String?> customName,
  Value<int?> customPoints,
  Value<String?> customIcon,
  Value<String?> customCategoryRef,
  Value<int?> sortOrder,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$UserTaskOverridesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $UserTaskOverridesTable> {
  $$UserTaskOverridesTableFilterComposer(super.$state);
  ColumnFilters<String> get taskCode => $state.composableBuilder(
      column: $state.table.taskCode,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get hidden => $state.composableBuilder(
      column: $state.table.hidden,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get customName => $state.composableBuilder(
      column: $state.table.customName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get customPoints => $state.composableBuilder(
      column: $state.table.customPoints,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get customIcon => $state.composableBuilder(
      column: $state.table.customIcon,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get customCategoryRef => $state.composableBuilder(
      column: $state.table.customCategoryRef,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get sortOrder => $state.composableBuilder(
      column: $state.table.sortOrder,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$UserTaskOverridesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $UserTaskOverridesTable> {
  $$UserTaskOverridesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get taskCode => $state.composableBuilder(
      column: $state.table.taskCode,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get hidden => $state.composableBuilder(
      column: $state.table.hidden,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get customName => $state.composableBuilder(
      column: $state.table.customName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get customPoints => $state.composableBuilder(
      column: $state.table.customPoints,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get customIcon => $state.composableBuilder(
      column: $state.table.customIcon,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get customCategoryRef => $state.composableBuilder(
      column: $state.table.customCategoryRef,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get sortOrder => $state.composableBuilder(
      column: $state.table.sortOrder,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$UserTaskOverridesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserTaskOverridesTable,
    DbUserTaskOverride,
    $$UserTaskOverridesTableFilterComposer,
    $$UserTaskOverridesTableOrderingComposer,
    $$UserTaskOverridesTableCreateCompanionBuilder,
    $$UserTaskOverridesTableUpdateCompanionBuilder,
    (
      DbUserTaskOverride,
      BaseReferences<_$AppDatabase, $UserTaskOverridesTable, DbUserTaskOverride>
    ),
    DbUserTaskOverride,
    PrefetchHooks Function()> {
  $$UserTaskOverridesTableTableManager(
      _$AppDatabase db, $UserTaskOverridesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$UserTaskOverridesTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$UserTaskOverridesTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> taskCode = const Value.absent(),
            Value<bool> hidden = const Value.absent(),
            Value<String?> customName = const Value.absent(),
            Value<int?> customPoints = const Value.absent(),
            Value<String?> customIcon = const Value.absent(),
            Value<String?> customCategoryRef = const Value.absent(),
            Value<int?> sortOrder = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserTaskOverridesCompanion(
            taskCode: taskCode,
            hidden: hidden,
            customName: customName,
            customPoints: customPoints,
            customIcon: customIcon,
            customCategoryRef: customCategoryRef,
            sortOrder: sortOrder,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String taskCode,
            Value<bool> hidden = const Value.absent(),
            Value<String?> customName = const Value.absent(),
            Value<int?> customPoints = const Value.absent(),
            Value<String?> customIcon = const Value.absent(),
            Value<String?> customCategoryRef = const Value.absent(),
            Value<int?> sortOrder = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserTaskOverridesCompanion.insert(
            taskCode: taskCode,
            hidden: hidden,
            customName: customName,
            customPoints: customPoints,
            customIcon: customIcon,
            customCategoryRef: customCategoryRef,
            sortOrder: sortOrder,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UserTaskOverridesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UserTaskOverridesTable,
    DbUserTaskOverride,
    $$UserTaskOverridesTableFilterComposer,
    $$UserTaskOverridesTableOrderingComposer,
    $$UserTaskOverridesTableCreateCompanionBuilder,
    $$UserTaskOverridesTableUpdateCompanionBuilder,
    (
      DbUserTaskOverride,
      BaseReferences<_$AppDatabase, $UserTaskOverridesTable, DbUserTaskOverride>
    ),
    DbUserTaskOverride,
    PrefetchHooks Function()>;
typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion
    Function({
  required String key,
  Value<String?> value,
  Value<int> rowid,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<String> key,
  Value<String?> value,
  Value<int> rowid,
});

class $$AppSettingsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer(super.$state);
  ColumnFilters<String> get key => $state.composableBuilder(
      column: $state.table.key,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$AppSettingsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get key => $state.composableBuilder(
      column: $state.table.key,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$AppSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    DbAppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (
      DbAppSetting,
      BaseReferences<_$AppDatabase, $AppSettingsTable, DbAppSetting>
    ),
    DbAppSetting,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$AppSettingsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$AppSettingsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String?> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            Value<String?> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    DbAppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (
      DbAppSetting,
      BaseReferences<_$AppDatabase, $AppSettingsTable, DbAppSetting>
    ),
    DbAppSetting,
    PrefetchHooks Function()>;
typedef $$CategoryNotificationSchedulesTableCreateCompanionBuilder
    = CategoryNotificationSchedulesCompanion Function({
  required String category,
  Value<bool> enabled,
  required int hour,
  required int minute,
  Value<int> rowid,
});
typedef $$CategoryNotificationSchedulesTableUpdateCompanionBuilder
    = CategoryNotificationSchedulesCompanion Function({
  Value<String> category,
  Value<bool> enabled,
  Value<int> hour,
  Value<int> minute,
  Value<int> rowid,
});

class $$CategoryNotificationSchedulesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $CategoryNotificationSchedulesTable> {
  $$CategoryNotificationSchedulesTableFilterComposer(super.$state);
  ColumnFilters<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get enabled => $state.composableBuilder(
      column: $state.table.enabled,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get hour => $state.composableBuilder(
      column: $state.table.hour,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get minute => $state.composableBuilder(
      column: $state.table.minute,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$CategoryNotificationSchedulesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase,
        $CategoryNotificationSchedulesTable> {
  $$CategoryNotificationSchedulesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get category => $state.composableBuilder(
      column: $state.table.category,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get enabled => $state.composableBuilder(
      column: $state.table.enabled,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get hour => $state.composableBuilder(
      column: $state.table.hour,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get minute => $state.composableBuilder(
      column: $state.table.minute,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$CategoryNotificationSchedulesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoryNotificationSchedulesTable,
    DbCategoryNotificationSchedule,
    $$CategoryNotificationSchedulesTableFilterComposer,
    $$CategoryNotificationSchedulesTableOrderingComposer,
    $$CategoryNotificationSchedulesTableCreateCompanionBuilder,
    $$CategoryNotificationSchedulesTableUpdateCompanionBuilder,
    (
      DbCategoryNotificationSchedule,
      BaseReferences<_$AppDatabase, $CategoryNotificationSchedulesTable,
          DbCategoryNotificationSchedule>
    ),
    DbCategoryNotificationSchedule,
    PrefetchHooks Function()> {
  $$CategoryNotificationSchedulesTableTableManager(
      _$AppDatabase db, $CategoryNotificationSchedulesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$CategoryNotificationSchedulesTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer:
              $$CategoryNotificationSchedulesTableOrderingComposer(
                  ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> category = const Value.absent(),
            Value<bool> enabled = const Value.absent(),
            Value<int> hour = const Value.absent(),
            Value<int> minute = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoryNotificationSchedulesCompanion(
            category: category,
            enabled: enabled,
            hour: hour,
            minute: minute,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String category,
            Value<bool> enabled = const Value.absent(),
            required int hour,
            required int minute,
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoryNotificationSchedulesCompanion.insert(
            category: category,
            enabled: enabled,
            hour: hour,
            minute: minute,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoryNotificationSchedulesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $CategoryNotificationSchedulesTable,
        DbCategoryNotificationSchedule,
        $$CategoryNotificationSchedulesTableFilterComposer,
        $$CategoryNotificationSchedulesTableOrderingComposer,
        $$CategoryNotificationSchedulesTableCreateCompanionBuilder,
        $$CategoryNotificationSchedulesTableUpdateCompanionBuilder,
        (
          DbCategoryNotificationSchedule,
          BaseReferences<_$AppDatabase, $CategoryNotificationSchedulesTable,
              DbCategoryNotificationSchedule>
        ),
        DbCategoryNotificationSchedule,
        PrefetchHooks Function()>;
typedef $$TaskNotificationTogglesTableCreateCompanionBuilder
    = TaskNotificationTogglesCompanion Function({
  required String taskId,
  Value<bool> notificationsEnabled,
  Value<int> rowid,
});
typedef $$TaskNotificationTogglesTableUpdateCompanionBuilder
    = TaskNotificationTogglesCompanion Function({
  Value<String> taskId,
  Value<bool> notificationsEnabled,
  Value<int> rowid,
});

class $$TaskNotificationTogglesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $TaskNotificationTogglesTable> {
  $$TaskNotificationTogglesTableFilterComposer(super.$state);
  ColumnFilters<String> get taskId => $state.composableBuilder(
      column: $state.table.taskId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get notificationsEnabled => $state.composableBuilder(
      column: $state.table.notificationsEnabled,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$TaskNotificationTogglesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $TaskNotificationTogglesTable> {
  $$TaskNotificationTogglesTableOrderingComposer(super.$state);
  ColumnOrderings<String> get taskId => $state.composableBuilder(
      column: $state.table.taskId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get notificationsEnabled => $state.composableBuilder(
      column: $state.table.notificationsEnabled,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$TaskNotificationTogglesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TaskNotificationTogglesTable,
    DbTaskNotificationToggle,
    $$TaskNotificationTogglesTableFilterComposer,
    $$TaskNotificationTogglesTableOrderingComposer,
    $$TaskNotificationTogglesTableCreateCompanionBuilder,
    $$TaskNotificationTogglesTableUpdateCompanionBuilder,
    (
      DbTaskNotificationToggle,
      BaseReferences<_$AppDatabase, $TaskNotificationTogglesTable,
          DbTaskNotificationToggle>
    ),
    DbTaskNotificationToggle,
    PrefetchHooks Function()> {
  $$TaskNotificationTogglesTableTableManager(
      _$AppDatabase db, $TaskNotificationTogglesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$TaskNotificationTogglesTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer: $$TaskNotificationTogglesTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> taskId = const Value.absent(),
            Value<bool> notificationsEnabled = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TaskNotificationTogglesCompanion(
            taskId: taskId,
            notificationsEnabled: notificationsEnabled,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String taskId,
            Value<bool> notificationsEnabled = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TaskNotificationTogglesCompanion.insert(
            taskId: taskId,
            notificationsEnabled: notificationsEnabled,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TaskNotificationTogglesTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $TaskNotificationTogglesTable,
        DbTaskNotificationToggle,
        $$TaskNotificationTogglesTableFilterComposer,
        $$TaskNotificationTogglesTableOrderingComposer,
        $$TaskNotificationTogglesTableCreateCompanionBuilder,
        $$TaskNotificationTogglesTableUpdateCompanionBuilder,
        (
          DbTaskNotificationToggle,
          BaseReferences<_$AppDatabase, $TaskNotificationTogglesTable,
              DbTaskNotificationToggle>
        ),
        DbTaskNotificationToggle,
        PrefetchHooks Function()>;
typedef $$PendingSyncOpsTableCreateCompanionBuilder = PendingSyncOpsCompanion
    Function({
  Value<int> id,
  required String opType,
  required String payloadJson,
  required DateTime clientUpdatedAt,
  Value<int> attempts,
  Value<String?> lastError,
});
typedef $$PendingSyncOpsTableUpdateCompanionBuilder = PendingSyncOpsCompanion
    Function({
  Value<int> id,
  Value<String> opType,
  Value<String> payloadJson,
  Value<DateTime> clientUpdatedAt,
  Value<int> attempts,
  Value<String?> lastError,
});

class $$PendingSyncOpsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $PendingSyncOpsTable> {
  $$PendingSyncOpsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get opType => $state.composableBuilder(
      column: $state.table.opType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get payloadJson => $state.composableBuilder(
      column: $state.table.payloadJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get clientUpdatedAt => $state.composableBuilder(
      column: $state.table.clientUpdatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get attempts => $state.composableBuilder(
      column: $state.table.attempts,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get lastError => $state.composableBuilder(
      column: $state.table.lastError,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$PendingSyncOpsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $PendingSyncOpsTable> {
  $$PendingSyncOpsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get opType => $state.composableBuilder(
      column: $state.table.opType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get payloadJson => $state.composableBuilder(
      column: $state.table.payloadJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get clientUpdatedAt => $state.composableBuilder(
      column: $state.table.clientUpdatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get attempts => $state.composableBuilder(
      column: $state.table.attempts,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get lastError => $state.composableBuilder(
      column: $state.table.lastError,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$PendingSyncOpsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PendingSyncOpsTable,
    PendingSyncOp,
    $$PendingSyncOpsTableFilterComposer,
    $$PendingSyncOpsTableOrderingComposer,
    $$PendingSyncOpsTableCreateCompanionBuilder,
    $$PendingSyncOpsTableUpdateCompanionBuilder,
    (
      PendingSyncOp,
      BaseReferences<_$AppDatabase, $PendingSyncOpsTable, PendingSyncOp>
    ),
    PendingSyncOp,
    PrefetchHooks Function()> {
  $$PendingSyncOpsTableTableManager(
      _$AppDatabase db, $PendingSyncOpsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$PendingSyncOpsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$PendingSyncOpsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> opType = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<DateTime> clientUpdatedAt = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
          }) =>
              PendingSyncOpsCompanion(
            id: id,
            opType: opType,
            payloadJson: payloadJson,
            clientUpdatedAt: clientUpdatedAt,
            attempts: attempts,
            lastError: lastError,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String opType,
            required String payloadJson,
            required DateTime clientUpdatedAt,
            Value<int> attempts = const Value.absent(),
            Value<String?> lastError = const Value.absent(),
          }) =>
              PendingSyncOpsCompanion.insert(
            id: id,
            opType: opType,
            payloadJson: payloadJson,
            clientUpdatedAt: clientUpdatedAt,
            attempts: attempts,
            lastError: lastError,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PendingSyncOpsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PendingSyncOpsTable,
    PendingSyncOp,
    $$PendingSyncOpsTableFilterComposer,
    $$PendingSyncOpsTableOrderingComposer,
    $$PendingSyncOpsTableCreateCompanionBuilder,
    $$PendingSyncOpsTableUpdateCompanionBuilder,
    (
      PendingSyncOp,
      BaseReferences<_$AppDatabase, $PendingSyncOpsTable, PendingSyncOp>
    ),
    PendingSyncOp,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$UserTasksTableTableManager get userTasks =>
      $$UserTasksTableTableManager(_db, _db.userTasks);
  $$DailyLogsTableTableManager get dailyLogs =>
      $$DailyLogsTableTableManager(_db, _db.dailyLogs);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$UserCategoriesTableTableManager get userCategories =>
      $$UserCategoriesTableTableManager(_db, _db.userCategories);
  $$UserCategoryOverridesTableTableManager get userCategoryOverrides =>
      $$UserCategoryOverridesTableTableManager(_db, _db.userCategoryOverrides);
  $$UserTaskOverridesTableTableManager get userTaskOverrides =>
      $$UserTaskOverridesTableTableManager(_db, _db.userTaskOverrides);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$CategoryNotificationSchedulesTableTableManager
      get categoryNotificationSchedules =>
          $$CategoryNotificationSchedulesTableTableManager(
              _db, _db.categoryNotificationSchedules);
  $$TaskNotificationTogglesTableTableManager get taskNotificationToggles =>
      $$TaskNotificationTogglesTableTableManager(
          _db, _db.taskNotificationToggles);
  $$PendingSyncOpsTableTableManager get pendingSyncOps =>
      $$PendingSyncOpsTableTableManager(_db, _db.pendingSyncOps);
}
