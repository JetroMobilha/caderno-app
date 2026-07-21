// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _avatarMeta = const VerificationMeta('avatar');
  @override
  late final GeneratedColumn<String> avatar = GeneratedColumn<String>(
    'avatar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _planTypeMeta = const VerificationMeta(
    'planType',
  );
  @override
  late final GeneratedColumn<String> planType = GeneratedColumn<String>(
    'plan_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('free'),
  );
  static const VerificationMeta _syncedWithCloudMeta = const VerificationMeta(
    'syncedWithCloud',
  );
  @override
  late final GeneratedColumn<int> syncedWithCloud = GeneratedColumn<int>(
    'synced_with_cloud',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    name,
    email,
    avatar,
    planType,
    syncedWithCloud,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('avatar')) {
      context.handle(
        _avatarMeta,
        avatar.isAcceptableOrUnknown(data['avatar']!, _avatarMeta),
      );
    }
    if (data.containsKey('plan_type')) {
      context.handle(
        _planTypeMeta,
        planType.isAcceptableOrUnknown(data['plan_type']!, _planTypeMeta),
      );
    }
    if (data.containsKey('synced_with_cloud')) {
      context.handle(
        _syncedWithCloudMeta,
        syncedWithCloud.isAcceptableOrUnknown(
          data['synced_with_cloud']!,
          _syncedWithCloudMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      avatar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar'],
      ),
      planType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_type'],
      )!,
      syncedWithCloud: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_with_cloud'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final int id;
  final int? serverId;
  final String name;
  final String email;
  final String? avatar;
  final String planType;
  final int syncedWithCloud;
  final int updatedAt;
  const User({
    required this.id,
    this.serverId,
    required this.name,
    required this.email,
    this.avatar,
    required this.planType,
    required this.syncedWithCloud,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['name'] = Variable<String>(name);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || avatar != null) {
      map['avatar'] = Variable<String>(avatar);
    }
    map['plan_type'] = Variable<String>(planType);
    map['synced_with_cloud'] = Variable<int>(syncedWithCloud);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      name: Value(name),
      email: Value(email),
      avatar: avatar == null && nullToAbsent
          ? const Value.absent()
          : Value(avatar),
      planType: Value(planType),
      syncedWithCloud: Value(syncedWithCloud),
      updatedAt: Value(updatedAt),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String>(json['email']),
      avatar: serializer.fromJson<String?>(json['avatar']),
      planType: serializer.fromJson<String>(json['planType']),
      syncedWithCloud: serializer.fromJson<int>(json['syncedWithCloud']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String>(email),
      'avatar': serializer.toJson<String?>(avatar),
      'planType': serializer.toJson<String>(planType),
      'syncedWithCloud': serializer.toJson<int>(syncedWithCloud),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  User copyWith({
    int? id,
    Value<int?> serverId = const Value.absent(),
    String? name,
    String? email,
    Value<String?> avatar = const Value.absent(),
    String? planType,
    int? syncedWithCloud,
    int? updatedAt,
  }) => User(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    name: name ?? this.name,
    email: email ?? this.email,
    avatar: avatar.present ? avatar.value : this.avatar,
    planType: planType ?? this.planType,
    syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      avatar: data.avatar.present ? data.avatar.value : this.avatar,
      planType: data.planType.present ? data.planType.value : this.planType,
      syncedWithCloud: data.syncedWithCloud.present
          ? data.syncedWithCloud.value
          : this.syncedWithCloud,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('avatar: $avatar, ')
          ..write('planType: $planType, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    name,
    email,
    avatar,
    planType,
    syncedWithCloud,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.name == this.name &&
          other.email == this.email &&
          other.avatar == this.avatar &&
          other.planType == this.planType &&
          other.syncedWithCloud == this.syncedWithCloud &&
          other.updatedAt == this.updatedAt);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<String> name;
  final Value<String> email;
  final Value<String?> avatar;
  final Value<String> planType;
  final Value<int> syncedWithCloud;
  final Value<int> updatedAt;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.avatar = const Value.absent(),
    this.planType = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required String name,
    required String email,
    this.avatar = const Value.absent(),
    this.planType = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name),
       email = Value(email);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? avatar,
    Expression<String>? planType,
    Expression<int>? syncedWithCloud,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (avatar != null) 'avatar': avatar,
      if (planType != null) 'plan_type': planType,
      if (syncedWithCloud != null) 'synced_with_cloud': syncedWithCloud,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  UsersCompanion copyWith({
    Value<int>? id,
    Value<int?>? serverId,
    Value<String>? name,
    Value<String>? email,
    Value<String?>? avatar,
    Value<String>? planType,
    Value<int>? syncedWithCloud,
    Value<int>? updatedAt,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      planType: planType ?? this.planType,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (avatar.present) {
      map['avatar'] = Variable<String>(avatar.value);
    }
    if (planType.present) {
      map['plan_type'] = Variable<String>(planType.value);
    }
    if (syncedWithCloud.present) {
      map['synced_with_cloud'] = Variable<int>(syncedWithCloud.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('avatar: $avatar, ')
          ..write('planType: $planType, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SubjectsTable extends Subjects with TableInfo<$SubjectsTable, Subject> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<int> isDeleted = GeneratedColumn<int>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncedWithCloudMeta = const VerificationMeta(
    'syncedWithCloud',
  );
  @override
  late final GeneratedColumn<int> syncedWithCloud = GeneratedColumn<int>(
    'synced_with_cloud',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    userId,
    name,
    color,
    icon,
    isDeleted,
    syncedWithCloud,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subjects';
  @override
  VerificationContext validateIntegrity(
    Insertable<Subject> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('synced_with_cloud')) {
      context.handle(
        _syncedWithCloudMeta,
        syncedWithCloud.isAcceptableOrUnknown(
          data['synced_with_cloud']!,
          _syncedWithCloudMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Subject map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Subject(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_deleted'],
      )!,
      syncedWithCloud: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_with_cloud'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SubjectsTable createAlias(String alias) {
    return $SubjectsTable(attachedDatabase, alias);
  }
}

class Subject extends DataClass implements Insertable<Subject> {
  final int id;
  final int? serverId;
  final int userId;
  final String name;
  final String color;
  final String? icon;
  final int isDeleted;
  final int syncedWithCloud;
  final int updatedAt;
  const Subject({
    required this.id,
    this.serverId,
    required this.userId,
    required this.name,
    required this.color,
    this.icon,
    required this.isDeleted,
    required this.syncedWithCloud,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['user_id'] = Variable<int>(userId);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<String>(color);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['is_deleted'] = Variable<int>(isDeleted);
    map['synced_with_cloud'] = Variable<int>(syncedWithCloud);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  SubjectsCompanion toCompanion(bool nullToAbsent) {
    return SubjectsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      userId: Value(userId),
      name: Value(name),
      color: Value(color),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      isDeleted: Value(isDeleted),
      syncedWithCloud: Value(syncedWithCloud),
      updatedAt: Value(updatedAt),
    );
  }

  factory Subject.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Subject(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      userId: serializer.fromJson<int>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String>(json['color']),
      icon: serializer.fromJson<String?>(json['icon']),
      isDeleted: serializer.fromJson<int>(json['isDeleted']),
      syncedWithCloud: serializer.fromJson<int>(json['syncedWithCloud']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'userId': serializer.toJson<int>(userId),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String>(color),
      'icon': serializer.toJson<String?>(icon),
      'isDeleted': serializer.toJson<int>(isDeleted),
      'syncedWithCloud': serializer.toJson<int>(syncedWithCloud),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Subject copyWith({
    int? id,
    Value<int?> serverId = const Value.absent(),
    int? userId,
    String? name,
    String? color,
    Value<String?> icon = const Value.absent(),
    int? isDeleted,
    int? syncedWithCloud,
    int? updatedAt,
  }) => Subject(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    color: color ?? this.color,
    icon: icon.present ? icon.value : this.icon,
    isDeleted: isDeleted ?? this.isDeleted,
    syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Subject copyWithCompanion(SubjectsCompanion data) {
    return Subject(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      icon: data.icon.present ? data.icon.value : this.icon,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      syncedWithCloud: data.syncedWithCloud.present
          ? data.syncedWithCloud.value
          : this.syncedWithCloud,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subject(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    userId,
    name,
    color,
    icon,
    isDeleted,
    syncedWithCloud,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subject &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.color == this.color &&
          other.icon == this.icon &&
          other.isDeleted == this.isDeleted &&
          other.syncedWithCloud == this.syncedWithCloud &&
          other.updatedAt == this.updatedAt);
}

class SubjectsCompanion extends UpdateCompanion<Subject> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<int> userId;
  final Value<String> name;
  final Value<String> color;
  final Value<String?> icon;
  final Value<int> isDeleted;
  final Value<int> syncedWithCloud;
  final Value<int> updatedAt;
  const SubjectsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SubjectsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required int userId,
    required String name,
    required String color,
    this.icon = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : userId = Value(userId),
       name = Value(name),
       color = Value(color);
  static Insertable<Subject> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<int>? userId,
    Expression<String>? name,
    Expression<String>? color,
    Expression<String>? icon,
    Expression<int>? isDeleted,
    Expression<int>? syncedWithCloud,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (syncedWithCloud != null) 'synced_with_cloud': syncedWithCloud,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SubjectsCompanion copyWith({
    Value<int>? id,
    Value<int?>? serverId,
    Value<int>? userId,
    Value<String>? name,
    Value<String>? color,
    Value<String?>? icon,
    Value<int>? isDeleted,
    Value<int>? syncedWithCloud,
    Value<int>? updatedAt,
  }) {
    return SubjectsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isDeleted: isDeleted ?? this.isDeleted,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<int>(isDeleted.value);
    }
    if (syncedWithCloud.present) {
      map['synced_with_cloud'] = Variable<int>(syncedWithCloud.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubjectsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $NotebooksTable extends Notebooks
    with TableInfo<$NotebooksTable, Notebook> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotebooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _subjectIdMeta = const VerificationMeta(
    'subjectId',
  );
  @override
  late final GeneratedColumn<int> subjectId = GeneratedColumn<int>(
    'subject_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverTypeMeta = const VerificationMeta(
    'coverType',
  );
  @override
  late final GeneratedColumn<String> coverType = GeneratedColumn<String>(
    'cover_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverImageMeta = const VerificationMeta(
    'coverImage',
  );
  @override
  late final GeneratedColumn<String> coverImage = GeneratedColumn<String>(
    'cover_image',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lineTypeMeta = const VerificationMeta(
    'lineType',
  );
  @override
  late final GeneratedColumn<String> lineType = GeneratedColumn<String>(
    'line_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paperSizeMeta = const VerificationMeta(
    'paperSize',
  );
  @override
  late final GeneratedColumn<String> paperSize = GeneratedColumn<String>(
    'paper_size',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPublishedMeta = const VerificationMeta(
    'isPublished',
  );
  @override
  late final GeneratedColumn<int> isPublished = GeneratedColumn<int>(
    'is_published',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.00),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _authorNameMeta = const VerificationMeta(
    'authorName',
  );
  @override
  late final GeneratedColumn<String> authorName = GeneratedColumn<String>(
    'author_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<int> isDeleted = GeneratedColumn<int>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncedWithCloudMeta = const VerificationMeta(
    'syncedWithCloud',
  );
  @override
  late final GeneratedColumn<int> syncedWithCloud = GeneratedColumn<int>(
    'synced_with_cloud',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    subjectId,
    title,
    coverType,
    color,
    coverImage,
    lineType,
    paperSize,
    isPublished,
    price,
    description,
    authorName,
    isDeleted,
    syncedWithCloud,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notebooks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Notebook> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('subject_id')) {
      context.handle(
        _subjectIdMeta,
        subjectId.isAcceptableOrUnknown(data['subject_id']!, _subjectIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('cover_type')) {
      context.handle(
        _coverTypeMeta,
        coverType.isAcceptableOrUnknown(data['cover_type']!, _coverTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_coverTypeMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('cover_image')) {
      context.handle(
        _coverImageMeta,
        coverImage.isAcceptableOrUnknown(data['cover_image']!, _coverImageMeta),
      );
    }
    if (data.containsKey('line_type')) {
      context.handle(
        _lineTypeMeta,
        lineType.isAcceptableOrUnknown(data['line_type']!, _lineTypeMeta),
      );
    }
    if (data.containsKey('paper_size')) {
      context.handle(
        _paperSizeMeta,
        paperSize.isAcceptableOrUnknown(data['paper_size']!, _paperSizeMeta),
      );
    }
    if (data.containsKey('is_published')) {
      context.handle(
        _isPublishedMeta,
        isPublished.isAcceptableOrUnknown(
          data['is_published']!,
          _isPublishedMeta,
        ),
      );
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('author_name')) {
      context.handle(
        _authorNameMeta,
        authorName.isAcceptableOrUnknown(data['author_name']!, _authorNameMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('synced_with_cloud')) {
      context.handle(
        _syncedWithCloudMeta,
        syncedWithCloud.isAcceptableOrUnknown(
          data['synced_with_cloud']!,
          _syncedWithCloudMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Notebook map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Notebook(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      subjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subject_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      coverType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_type'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      coverImage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_image'],
      ),
      lineType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}line_type'],
      ),
      paperSize: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paper_size'],
      ),
      isPublished: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_published'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      authorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_name'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_deleted'],
      )!,
      syncedWithCloud: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_with_cloud'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $NotebooksTable createAlias(String alias) {
    return $NotebooksTable(attachedDatabase, alias);
  }
}

class Notebook extends DataClass implements Insertable<Notebook> {
  final int id;
  final int? serverId;
  final int? subjectId;
  final String title;
  final String coverType;
  final String? color;
  final String? coverImage;
  final String? lineType;
  final String? paperSize;
  final int isPublished;
  final double price;
  final String? description;
  final String? authorName;
  final int isDeleted;
  final int syncedWithCloud;
  final int updatedAt;
  const Notebook({
    required this.id,
    this.serverId,
    this.subjectId,
    required this.title,
    required this.coverType,
    this.color,
    this.coverImage,
    this.lineType,
    this.paperSize,
    required this.isPublished,
    required this.price,
    this.description,
    this.authorName,
    required this.isDeleted,
    required this.syncedWithCloud,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    if (!nullToAbsent || subjectId != null) {
      map['subject_id'] = Variable<int>(subjectId);
    }
    map['title'] = Variable<String>(title);
    map['cover_type'] = Variable<String>(coverType);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || coverImage != null) {
      map['cover_image'] = Variable<String>(coverImage);
    }
    if (!nullToAbsent || lineType != null) {
      map['line_type'] = Variable<String>(lineType);
    }
    if (!nullToAbsent || paperSize != null) {
      map['paper_size'] = Variable<String>(paperSize);
    }
    map['is_published'] = Variable<int>(isPublished);
    map['price'] = Variable<double>(price);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || authorName != null) {
      map['author_name'] = Variable<String>(authorName);
    }
    map['is_deleted'] = Variable<int>(isDeleted);
    map['synced_with_cloud'] = Variable<int>(syncedWithCloud);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  NotebooksCompanion toCompanion(bool nullToAbsent) {
    return NotebooksCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      subjectId: subjectId == null && nullToAbsent
          ? const Value.absent()
          : Value(subjectId),
      title: Value(title),
      coverType: Value(coverType),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      coverImage: coverImage == null && nullToAbsent
          ? const Value.absent()
          : Value(coverImage),
      lineType: lineType == null && nullToAbsent
          ? const Value.absent()
          : Value(lineType),
      paperSize: paperSize == null && nullToAbsent
          ? const Value.absent()
          : Value(paperSize),
      isPublished: Value(isPublished),
      price: Value(price),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      authorName: authorName == null && nullToAbsent
          ? const Value.absent()
          : Value(authorName),
      isDeleted: Value(isDeleted),
      syncedWithCloud: Value(syncedWithCloud),
      updatedAt: Value(updatedAt),
    );
  }

  factory Notebook.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Notebook(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      subjectId: serializer.fromJson<int?>(json['subjectId']),
      title: serializer.fromJson<String>(json['title']),
      coverType: serializer.fromJson<String>(json['coverType']),
      color: serializer.fromJson<String?>(json['color']),
      coverImage: serializer.fromJson<String?>(json['coverImage']),
      lineType: serializer.fromJson<String?>(json['lineType']),
      paperSize: serializer.fromJson<String?>(json['paperSize']),
      isPublished: serializer.fromJson<int>(json['isPublished']),
      price: serializer.fromJson<double>(json['price']),
      description: serializer.fromJson<String?>(json['description']),
      authorName: serializer.fromJson<String?>(json['authorName']),
      isDeleted: serializer.fromJson<int>(json['isDeleted']),
      syncedWithCloud: serializer.fromJson<int>(json['syncedWithCloud']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'subjectId': serializer.toJson<int?>(subjectId),
      'title': serializer.toJson<String>(title),
      'coverType': serializer.toJson<String>(coverType),
      'color': serializer.toJson<String?>(color),
      'coverImage': serializer.toJson<String?>(coverImage),
      'lineType': serializer.toJson<String?>(lineType),
      'paperSize': serializer.toJson<String?>(paperSize),
      'isPublished': serializer.toJson<int>(isPublished),
      'price': serializer.toJson<double>(price),
      'description': serializer.toJson<String?>(description),
      'authorName': serializer.toJson<String?>(authorName),
      'isDeleted': serializer.toJson<int>(isDeleted),
      'syncedWithCloud': serializer.toJson<int>(syncedWithCloud),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Notebook copyWith({
    int? id,
    Value<int?> serverId = const Value.absent(),
    Value<int?> subjectId = const Value.absent(),
    String? title,
    String? coverType,
    Value<String?> color = const Value.absent(),
    Value<String?> coverImage = const Value.absent(),
    Value<String?> lineType = const Value.absent(),
    Value<String?> paperSize = const Value.absent(),
    int? isPublished,
    double? price,
    Value<String?> description = const Value.absent(),
    Value<String?> authorName = const Value.absent(),
    int? isDeleted,
    int? syncedWithCloud,
    int? updatedAt,
  }) => Notebook(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    subjectId: subjectId.present ? subjectId.value : this.subjectId,
    title: title ?? this.title,
    coverType: coverType ?? this.coverType,
    color: color.present ? color.value : this.color,
    coverImage: coverImage.present ? coverImage.value : this.coverImage,
    lineType: lineType.present ? lineType.value : this.lineType,
    paperSize: paperSize.present ? paperSize.value : this.paperSize,
    isPublished: isPublished ?? this.isPublished,
    price: price ?? this.price,
    description: description.present ? description.value : this.description,
    authorName: authorName.present ? authorName.value : this.authorName,
    isDeleted: isDeleted ?? this.isDeleted,
    syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Notebook copyWithCompanion(NotebooksCompanion data) {
    return Notebook(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      title: data.title.present ? data.title.value : this.title,
      coverType: data.coverType.present ? data.coverType.value : this.coverType,
      color: data.color.present ? data.color.value : this.color,
      coverImage: data.coverImage.present
          ? data.coverImage.value
          : this.coverImage,
      lineType: data.lineType.present ? data.lineType.value : this.lineType,
      paperSize: data.paperSize.present ? data.paperSize.value : this.paperSize,
      isPublished: data.isPublished.present
          ? data.isPublished.value
          : this.isPublished,
      price: data.price.present ? data.price.value : this.price,
      description: data.description.present
          ? data.description.value
          : this.description,
      authorName: data.authorName.present
          ? data.authorName.value
          : this.authorName,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      syncedWithCloud: data.syncedWithCloud.present
          ? data.syncedWithCloud.value
          : this.syncedWithCloud,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Notebook(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('subjectId: $subjectId, ')
          ..write('title: $title, ')
          ..write('coverType: $coverType, ')
          ..write('color: $color, ')
          ..write('coverImage: $coverImage, ')
          ..write('lineType: $lineType, ')
          ..write('paperSize: $paperSize, ')
          ..write('isPublished: $isPublished, ')
          ..write('price: $price, ')
          ..write('description: $description, ')
          ..write('authorName: $authorName, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    subjectId,
    title,
    coverType,
    color,
    coverImage,
    lineType,
    paperSize,
    isPublished,
    price,
    description,
    authorName,
    isDeleted,
    syncedWithCloud,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Notebook &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.subjectId == this.subjectId &&
          other.title == this.title &&
          other.coverType == this.coverType &&
          other.color == this.color &&
          other.coverImage == this.coverImage &&
          other.lineType == this.lineType &&
          other.paperSize == this.paperSize &&
          other.isPublished == this.isPublished &&
          other.price == this.price &&
          other.description == this.description &&
          other.authorName == this.authorName &&
          other.isDeleted == this.isDeleted &&
          other.syncedWithCloud == this.syncedWithCloud &&
          other.updatedAt == this.updatedAt);
}

class NotebooksCompanion extends UpdateCompanion<Notebook> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<int?> subjectId;
  final Value<String> title;
  final Value<String> coverType;
  final Value<String?> color;
  final Value<String?> coverImage;
  final Value<String?> lineType;
  final Value<String?> paperSize;
  final Value<int> isPublished;
  final Value<double> price;
  final Value<String?> description;
  final Value<String?> authorName;
  final Value<int> isDeleted;
  final Value<int> syncedWithCloud;
  final Value<int> updatedAt;
  const NotebooksCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.title = const Value.absent(),
    this.coverType = const Value.absent(),
    this.color = const Value.absent(),
    this.coverImage = const Value.absent(),
    this.lineType = const Value.absent(),
    this.paperSize = const Value.absent(),
    this.isPublished = const Value.absent(),
    this.price = const Value.absent(),
    this.description = const Value.absent(),
    this.authorName = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  NotebooksCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.subjectId = const Value.absent(),
    required String title,
    required String coverType,
    this.color = const Value.absent(),
    this.coverImage = const Value.absent(),
    this.lineType = const Value.absent(),
    this.paperSize = const Value.absent(),
    this.isPublished = const Value.absent(),
    this.price = const Value.absent(),
    this.description = const Value.absent(),
    this.authorName = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : title = Value(title),
       coverType = Value(coverType);
  static Insertable<Notebook> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<int>? subjectId,
    Expression<String>? title,
    Expression<String>? coverType,
    Expression<String>? color,
    Expression<String>? coverImage,
    Expression<String>? lineType,
    Expression<String>? paperSize,
    Expression<int>? isPublished,
    Expression<double>? price,
    Expression<String>? description,
    Expression<String>? authorName,
    Expression<int>? isDeleted,
    Expression<int>? syncedWithCloud,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (subjectId != null) 'subject_id': subjectId,
      if (title != null) 'title': title,
      if (coverType != null) 'cover_type': coverType,
      if (color != null) 'color': color,
      if (coverImage != null) 'cover_image': coverImage,
      if (lineType != null) 'line_type': lineType,
      if (paperSize != null) 'paper_size': paperSize,
      if (isPublished != null) 'is_published': isPublished,
      if (price != null) 'price': price,
      if (description != null) 'description': description,
      if (authorName != null) 'author_name': authorName,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (syncedWithCloud != null) 'synced_with_cloud': syncedWithCloud,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  NotebooksCompanion copyWith({
    Value<int>? id,
    Value<int?>? serverId,
    Value<int?>? subjectId,
    Value<String>? title,
    Value<String>? coverType,
    Value<String?>? color,
    Value<String?>? coverImage,
    Value<String?>? lineType,
    Value<String?>? paperSize,
    Value<int>? isPublished,
    Value<double>? price,
    Value<String?>? description,
    Value<String?>? authorName,
    Value<int>? isDeleted,
    Value<int>? syncedWithCloud,
    Value<int>? updatedAt,
  }) {
    return NotebooksCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      coverType: coverType ?? this.coverType,
      color: color ?? this.color,
      coverImage: coverImage ?? this.coverImage,
      lineType: lineType ?? this.lineType,
      paperSize: paperSize ?? this.paperSize,
      isPublished: isPublished ?? this.isPublished,
      price: price ?? this.price,
      description: description ?? this.description,
      authorName: authorName ?? this.authorName,
      isDeleted: isDeleted ?? this.isDeleted,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (subjectId.present) {
      map['subject_id'] = Variable<int>(subjectId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (coverType.present) {
      map['cover_type'] = Variable<String>(coverType.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (coverImage.present) {
      map['cover_image'] = Variable<String>(coverImage.value);
    }
    if (lineType.present) {
      map['line_type'] = Variable<String>(lineType.value);
    }
    if (paperSize.present) {
      map['paper_size'] = Variable<String>(paperSize.value);
    }
    if (isPublished.present) {
      map['is_published'] = Variable<int>(isPublished.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (authorName.present) {
      map['author_name'] = Variable<String>(authorName.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<int>(isDeleted.value);
    }
    if (syncedWithCloud.present) {
      map['synced_with_cloud'] = Variable<int>(syncedWithCloud.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotebooksCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('subjectId: $subjectId, ')
          ..write('title: $title, ')
          ..write('coverType: $coverType, ')
          ..write('color: $color, ')
          ..write('coverImage: $coverImage, ')
          ..write('lineType: $lineType, ')
          ..write('paperSize: $paperSize, ')
          ..write('isPublished: $isPublished, ')
          ..write('price: $price, ')
          ..write('description: $description, ')
          ..write('authorName: $authorName, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PagesTable extends Pages with TableInfo<$PagesTable, Page> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _notebookIdMeta = const VerificationMeta(
    'notebookId',
  );
  @override
  late final GeneratedColumn<int> notebookId = GeneratedColumn<int>(
    'notebook_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageNumberMeta = const VerificationMeta(
    'pageNumber',
  );
  @override
  late final GeneratedColumn<int> pageNumber = GeneratedColumn<int>(
    'page_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isLandscapeMeta = const VerificationMeta(
    'isLandscape',
  );
  @override
  late final GeneratedColumn<int> isLandscape = GeneratedColumn<int>(
    'is_landscape',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _headerDataMeta = const VerificationMeta(
    'headerData',
  );
  @override
  late final GeneratedColumn<String> headerData = GeneratedColumn<String>(
    'header_data',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _footerDataMeta = const VerificationMeta(
    'footerData',
  );
  @override
  late final GeneratedColumn<String> footerData = GeneratedColumn<String>(
    'footer_data',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<int> isDeleted = GeneratedColumn<int>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncedWithCloudMeta = const VerificationMeta(
    'syncedWithCloud',
  );
  @override
  late final GeneratedColumn<int> syncedWithCloud = GeneratedColumn<int>(
    'synced_with_cloud',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    notebookId,
    pageNumber,
    isLandscape,
    headerData,
    footerData,
    isDeleted,
    syncedWithCloud,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Page> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('notebook_id')) {
      context.handle(
        _notebookIdMeta,
        notebookId.isAcceptableOrUnknown(data['notebook_id']!, _notebookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_notebookIdMeta);
    }
    if (data.containsKey('page_number')) {
      context.handle(
        _pageNumberMeta,
        pageNumber.isAcceptableOrUnknown(data['page_number']!, _pageNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_pageNumberMeta);
    }
    if (data.containsKey('is_landscape')) {
      context.handle(
        _isLandscapeMeta,
        isLandscape.isAcceptableOrUnknown(
          data['is_landscape']!,
          _isLandscapeMeta,
        ),
      );
    }
    if (data.containsKey('header_data')) {
      context.handle(
        _headerDataMeta,
        headerData.isAcceptableOrUnknown(data['header_data']!, _headerDataMeta),
      );
    }
    if (data.containsKey('footer_data')) {
      context.handle(
        _footerDataMeta,
        footerData.isAcceptableOrUnknown(data['footer_data']!, _footerDataMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('synced_with_cloud')) {
      context.handle(
        _syncedWithCloudMeta,
        syncedWithCloud.isAcceptableOrUnknown(
          data['synced_with_cloud']!,
          _syncedWithCloudMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Page map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Page(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      notebookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notebook_id'],
      )!,
      pageNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_number'],
      )!,
      isLandscape: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_landscape'],
      )!,
      headerData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}header_data'],
      ),
      footerData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}footer_data'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_deleted'],
      )!,
      syncedWithCloud: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_with_cloud'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PagesTable createAlias(String alias) {
    return $PagesTable(attachedDatabase, alias);
  }
}

class Page extends DataClass implements Insertable<Page> {
  final int id;
  final int? serverId;
  final int notebookId;
  final int pageNumber;
  final int isLandscape;
  final String? headerData;
  final String? footerData;
  final int isDeleted;
  final int syncedWithCloud;
  final int updatedAt;
  const Page({
    required this.id,
    this.serverId,
    required this.notebookId,
    required this.pageNumber,
    required this.isLandscape,
    this.headerData,
    this.footerData,
    required this.isDeleted,
    required this.syncedWithCloud,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['notebook_id'] = Variable<int>(notebookId);
    map['page_number'] = Variable<int>(pageNumber);
    map['is_landscape'] = Variable<int>(isLandscape);
    if (!nullToAbsent || headerData != null) {
      map['header_data'] = Variable<String>(headerData);
    }
    if (!nullToAbsent || footerData != null) {
      map['footer_data'] = Variable<String>(footerData);
    }
    map['is_deleted'] = Variable<int>(isDeleted);
    map['synced_with_cloud'] = Variable<int>(syncedWithCloud);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  PagesCompanion toCompanion(bool nullToAbsent) {
    return PagesCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      notebookId: Value(notebookId),
      pageNumber: Value(pageNumber),
      isLandscape: Value(isLandscape),
      headerData: headerData == null && nullToAbsent
          ? const Value.absent()
          : Value(headerData),
      footerData: footerData == null && nullToAbsent
          ? const Value.absent()
          : Value(footerData),
      isDeleted: Value(isDeleted),
      syncedWithCloud: Value(syncedWithCloud),
      updatedAt: Value(updatedAt),
    );
  }

  factory Page.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Page(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      notebookId: serializer.fromJson<int>(json['notebookId']),
      pageNumber: serializer.fromJson<int>(json['pageNumber']),
      isLandscape: serializer.fromJson<int>(json['isLandscape']),
      headerData: serializer.fromJson<String?>(json['headerData']),
      footerData: serializer.fromJson<String?>(json['footerData']),
      isDeleted: serializer.fromJson<int>(json['isDeleted']),
      syncedWithCloud: serializer.fromJson<int>(json['syncedWithCloud']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'notebookId': serializer.toJson<int>(notebookId),
      'pageNumber': serializer.toJson<int>(pageNumber),
      'isLandscape': serializer.toJson<int>(isLandscape),
      'headerData': serializer.toJson<String?>(headerData),
      'footerData': serializer.toJson<String?>(footerData),
      'isDeleted': serializer.toJson<int>(isDeleted),
      'syncedWithCloud': serializer.toJson<int>(syncedWithCloud),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Page copyWith({
    int? id,
    Value<int?> serverId = const Value.absent(),
    int? notebookId,
    int? pageNumber,
    int? isLandscape,
    Value<String?> headerData = const Value.absent(),
    Value<String?> footerData = const Value.absent(),
    int? isDeleted,
    int? syncedWithCloud,
    int? updatedAt,
  }) => Page(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    notebookId: notebookId ?? this.notebookId,
    pageNumber: pageNumber ?? this.pageNumber,
    isLandscape: isLandscape ?? this.isLandscape,
    headerData: headerData.present ? headerData.value : this.headerData,
    footerData: footerData.present ? footerData.value : this.footerData,
    isDeleted: isDeleted ?? this.isDeleted,
    syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Page copyWithCompanion(PagesCompanion data) {
    return Page(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      notebookId: data.notebookId.present
          ? data.notebookId.value
          : this.notebookId,
      pageNumber: data.pageNumber.present
          ? data.pageNumber.value
          : this.pageNumber,
      isLandscape: data.isLandscape.present
          ? data.isLandscape.value
          : this.isLandscape,
      headerData: data.headerData.present
          ? data.headerData.value
          : this.headerData,
      footerData: data.footerData.present
          ? data.footerData.value
          : this.footerData,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      syncedWithCloud: data.syncedWithCloud.present
          ? data.syncedWithCloud.value
          : this.syncedWithCloud,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Page(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('notebookId: $notebookId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('isLandscape: $isLandscape, ')
          ..write('headerData: $headerData, ')
          ..write('footerData: $footerData, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    notebookId,
    pageNumber,
    isLandscape,
    headerData,
    footerData,
    isDeleted,
    syncedWithCloud,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Page &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.notebookId == this.notebookId &&
          other.pageNumber == this.pageNumber &&
          other.isLandscape == this.isLandscape &&
          other.headerData == this.headerData &&
          other.footerData == this.footerData &&
          other.isDeleted == this.isDeleted &&
          other.syncedWithCloud == this.syncedWithCloud &&
          other.updatedAt == this.updatedAt);
}

class PagesCompanion extends UpdateCompanion<Page> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<int> notebookId;
  final Value<int> pageNumber;
  final Value<int> isLandscape;
  final Value<String?> headerData;
  final Value<String?> footerData;
  final Value<int> isDeleted;
  final Value<int> syncedWithCloud;
  final Value<int> updatedAt;
  const PagesCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.notebookId = const Value.absent(),
    this.pageNumber = const Value.absent(),
    this.isLandscape = const Value.absent(),
    this.headerData = const Value.absent(),
    this.footerData = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PagesCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required int notebookId,
    required int pageNumber,
    this.isLandscape = const Value.absent(),
    this.headerData = const Value.absent(),
    this.footerData = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : notebookId = Value(notebookId),
       pageNumber = Value(pageNumber);
  static Insertable<Page> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<int>? notebookId,
    Expression<int>? pageNumber,
    Expression<int>? isLandscape,
    Expression<String>? headerData,
    Expression<String>? footerData,
    Expression<int>? isDeleted,
    Expression<int>? syncedWithCloud,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (notebookId != null) 'notebook_id': notebookId,
      if (pageNumber != null) 'page_number': pageNumber,
      if (isLandscape != null) 'is_landscape': isLandscape,
      if (headerData != null) 'header_data': headerData,
      if (footerData != null) 'footer_data': footerData,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (syncedWithCloud != null) 'synced_with_cloud': syncedWithCloud,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PagesCompanion copyWith({
    Value<int>? id,
    Value<int?>? serverId,
    Value<int>? notebookId,
    Value<int>? pageNumber,
    Value<int>? isLandscape,
    Value<String?>? headerData,
    Value<String?>? footerData,
    Value<int>? isDeleted,
    Value<int>? syncedWithCloud,
    Value<int>? updatedAt,
  }) {
    return PagesCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      notebookId: notebookId ?? this.notebookId,
      pageNumber: pageNumber ?? this.pageNumber,
      isLandscape: isLandscape ?? this.isLandscape,
      headerData: headerData ?? this.headerData,
      footerData: footerData ?? this.footerData,
      isDeleted: isDeleted ?? this.isDeleted,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (notebookId.present) {
      map['notebook_id'] = Variable<int>(notebookId.value);
    }
    if (pageNumber.present) {
      map['page_number'] = Variable<int>(pageNumber.value);
    }
    if (isLandscape.present) {
      map['is_landscape'] = Variable<int>(isLandscape.value);
    }
    if (headerData.present) {
      map['header_data'] = Variable<String>(headerData.value);
    }
    if (footerData.present) {
      map['footer_data'] = Variable<String>(footerData.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<int>(isDeleted.value);
    }
    if (syncedWithCloud.present) {
      map['synced_with_cloud'] = Variable<int>(syncedWithCloud.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PagesCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('notebookId: $notebookId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('isLandscape: $isLandscape, ')
          ..write('headerData: $headerData, ')
          ..write('footerData: $footerData, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CanvasStrokesTable extends CanvasStrokes
    with TableInfo<$CanvasStrokesTable, CanvasStroke> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CanvasStrokesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientStrokeIdMeta = const VerificationMeta(
    'clientStrokeId',
  );
  @override
  late final GeneratedColumn<String> clientStrokeId = GeneratedColumn<String>(
    'client_stroke_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<int> pageId = GeneratedColumn<int>(
    'page_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _strokeDataMeta = const VerificationMeta(
    'strokeData',
  );
  @override
  late final GeneratedColumn<String> strokeData = GeneratedColumn<String>(
    'stroke_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<int> isDeleted = GeneratedColumn<int>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncedWithCloudMeta = const VerificationMeta(
    'syncedWithCloud',
  );
  @override
  late final GeneratedColumn<int> syncedWithCloud = GeneratedColumn<int>(
    'synced_with_cloud',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientStrokeId,
    serverId,
    pageId,
    strokeData,
    isDeleted,
    syncedWithCloud,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'canvas_strokes';
  @override
  VerificationContext validateIntegrity(
    Insertable<CanvasStroke> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_stroke_id')) {
      context.handle(
        _clientStrokeIdMeta,
        clientStrokeId.isAcceptableOrUnknown(
          data['client_stroke_id']!,
          _clientStrokeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientStrokeIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('page_id')) {
      context.handle(
        _pageIdMeta,
        pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('stroke_data')) {
      context.handle(
        _strokeDataMeta,
        strokeData.isAcceptableOrUnknown(data['stroke_data']!, _strokeDataMeta),
      );
    } else if (isInserting) {
      context.missing(_strokeDataMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('synced_with_cloud')) {
      context.handle(
        _syncedWithCloudMeta,
        syncedWithCloud.isAcceptableOrUnknown(
          data['synced_with_cloud']!,
          _syncedWithCloudMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientStrokeId};
  @override
  CanvasStroke map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CanvasStroke(
      clientStrokeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_stroke_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      pageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_id'],
      )!,
      strokeData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stroke_data'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_deleted'],
      )!,
      syncedWithCloud: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_with_cloud'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CanvasStrokesTable createAlias(String alias) {
    return $CanvasStrokesTable(attachedDatabase, alias);
  }
}

class CanvasStroke extends DataClass implements Insertable<CanvasStroke> {
  final String clientStrokeId;
  final int? serverId;
  final int pageId;
  final String strokeData;
  final int isDeleted;
  final int syncedWithCloud;
  final int updatedAt;
  const CanvasStroke({
    required this.clientStrokeId,
    this.serverId,
    required this.pageId,
    required this.strokeData,
    required this.isDeleted,
    required this.syncedWithCloud,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_stroke_id'] = Variable<String>(clientStrokeId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['page_id'] = Variable<int>(pageId);
    map['stroke_data'] = Variable<String>(strokeData);
    map['is_deleted'] = Variable<int>(isDeleted);
    map['synced_with_cloud'] = Variable<int>(syncedWithCloud);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  CanvasStrokesCompanion toCompanion(bool nullToAbsent) {
    return CanvasStrokesCompanion(
      clientStrokeId: Value(clientStrokeId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      pageId: Value(pageId),
      strokeData: Value(strokeData),
      isDeleted: Value(isDeleted),
      syncedWithCloud: Value(syncedWithCloud),
      updatedAt: Value(updatedAt),
    );
  }

  factory CanvasStroke.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CanvasStroke(
      clientStrokeId: serializer.fromJson<String>(json['clientStrokeId']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      pageId: serializer.fromJson<int>(json['pageId']),
      strokeData: serializer.fromJson<String>(json['strokeData']),
      isDeleted: serializer.fromJson<int>(json['isDeleted']),
      syncedWithCloud: serializer.fromJson<int>(json['syncedWithCloud']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientStrokeId': serializer.toJson<String>(clientStrokeId),
      'serverId': serializer.toJson<int?>(serverId),
      'pageId': serializer.toJson<int>(pageId),
      'strokeData': serializer.toJson<String>(strokeData),
      'isDeleted': serializer.toJson<int>(isDeleted),
      'syncedWithCloud': serializer.toJson<int>(syncedWithCloud),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  CanvasStroke copyWith({
    String? clientStrokeId,
    Value<int?> serverId = const Value.absent(),
    int? pageId,
    String? strokeData,
    int? isDeleted,
    int? syncedWithCloud,
    int? updatedAt,
  }) => CanvasStroke(
    clientStrokeId: clientStrokeId ?? this.clientStrokeId,
    serverId: serverId.present ? serverId.value : this.serverId,
    pageId: pageId ?? this.pageId,
    strokeData: strokeData ?? this.strokeData,
    isDeleted: isDeleted ?? this.isDeleted,
    syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CanvasStroke copyWithCompanion(CanvasStrokesCompanion data) {
    return CanvasStroke(
      clientStrokeId: data.clientStrokeId.present
          ? data.clientStrokeId.value
          : this.clientStrokeId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      strokeData: data.strokeData.present
          ? data.strokeData.value
          : this.strokeData,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      syncedWithCloud: data.syncedWithCloud.present
          ? data.syncedWithCloud.value
          : this.syncedWithCloud,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CanvasStroke(')
          ..write('clientStrokeId: $clientStrokeId, ')
          ..write('serverId: $serverId, ')
          ..write('pageId: $pageId, ')
          ..write('strokeData: $strokeData, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientStrokeId,
    serverId,
    pageId,
    strokeData,
    isDeleted,
    syncedWithCloud,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CanvasStroke &&
          other.clientStrokeId == this.clientStrokeId &&
          other.serverId == this.serverId &&
          other.pageId == this.pageId &&
          other.strokeData == this.strokeData &&
          other.isDeleted == this.isDeleted &&
          other.syncedWithCloud == this.syncedWithCloud &&
          other.updatedAt == this.updatedAt);
}

class CanvasStrokesCompanion extends UpdateCompanion<CanvasStroke> {
  final Value<String> clientStrokeId;
  final Value<int?> serverId;
  final Value<int> pageId;
  final Value<String> strokeData;
  final Value<int> isDeleted;
  final Value<int> syncedWithCloud;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const CanvasStrokesCompanion({
    this.clientStrokeId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.pageId = const Value.absent(),
    this.strokeData = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CanvasStrokesCompanion.insert({
    required String clientStrokeId,
    this.serverId = const Value.absent(),
    required int pageId,
    required String strokeData,
    this.isDeleted = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientStrokeId = Value(clientStrokeId),
       pageId = Value(pageId),
       strokeData = Value(strokeData);
  static Insertable<CanvasStroke> custom({
    Expression<String>? clientStrokeId,
    Expression<int>? serverId,
    Expression<int>? pageId,
    Expression<String>? strokeData,
    Expression<int>? isDeleted,
    Expression<int>? syncedWithCloud,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientStrokeId != null) 'client_stroke_id': clientStrokeId,
      if (serverId != null) 'server_id': serverId,
      if (pageId != null) 'page_id': pageId,
      if (strokeData != null) 'stroke_data': strokeData,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (syncedWithCloud != null) 'synced_with_cloud': syncedWithCloud,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CanvasStrokesCompanion copyWith({
    Value<String>? clientStrokeId,
    Value<int?>? serverId,
    Value<int>? pageId,
    Value<String>? strokeData,
    Value<int>? isDeleted,
    Value<int>? syncedWithCloud,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return CanvasStrokesCompanion(
      clientStrokeId: clientStrokeId ?? this.clientStrokeId,
      serverId: serverId ?? this.serverId,
      pageId: pageId ?? this.pageId,
      strokeData: strokeData ?? this.strokeData,
      isDeleted: isDeleted ?? this.isDeleted,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientStrokeId.present) {
      map['client_stroke_id'] = Variable<String>(clientStrokeId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<int>(pageId.value);
    }
    if (strokeData.present) {
      map['stroke_data'] = Variable<String>(strokeData.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<int>(isDeleted.value);
    }
    if (syncedWithCloud.present) {
      map['synced_with_cloud'] = Variable<int>(syncedWithCloud.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CanvasStrokesCompanion(')
          ..write('clientStrokeId: $clientStrokeId, ')
          ..write('serverId: $serverId, ')
          ..write('pageId: $pageId, ')
          ..write('strokeData: $strokeData, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CanvasTextBlocksTable extends CanvasTextBlocks
    with TableInfo<$CanvasTextBlocksTable, CanvasTextBlock> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CanvasTextBlocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientTextIdMeta = const VerificationMeta(
    'clientTextId',
  );
  @override
  late final GeneratedColumn<String> clientTextId = GeneratedColumn<String>(
    'client_text_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<int> pageId = GeneratedColumn<int>(
    'page_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _textDataMeta = const VerificationMeta(
    'textData',
  );
  @override
  late final GeneratedColumn<String> textData = GeneratedColumn<String>(
    'text_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<int> isDeleted = GeneratedColumn<int>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncedWithCloudMeta = const VerificationMeta(
    'syncedWithCloud',
  );
  @override
  late final GeneratedColumn<int> syncedWithCloud = GeneratedColumn<int>(
    'synced_with_cloud',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientTextId,
    serverId,
    pageId,
    textData,
    isDeleted,
    syncedWithCloud,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'canvas_text_blocks';
  @override
  VerificationContext validateIntegrity(
    Insertable<CanvasTextBlock> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_text_id')) {
      context.handle(
        _clientTextIdMeta,
        clientTextId.isAcceptableOrUnknown(
          data['client_text_id']!,
          _clientTextIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientTextIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('page_id')) {
      context.handle(
        _pageIdMeta,
        pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('text_data')) {
      context.handle(
        _textDataMeta,
        textData.isAcceptableOrUnknown(data['text_data']!, _textDataMeta),
      );
    } else if (isInserting) {
      context.missing(_textDataMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('synced_with_cloud')) {
      context.handle(
        _syncedWithCloudMeta,
        syncedWithCloud.isAcceptableOrUnknown(
          data['synced_with_cloud']!,
          _syncedWithCloudMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientTextId};
  @override
  CanvasTextBlock map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CanvasTextBlock(
      clientTextId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_text_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      pageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_id'],
      )!,
      textData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_data'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_deleted'],
      )!,
      syncedWithCloud: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_with_cloud'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CanvasTextBlocksTable createAlias(String alias) {
    return $CanvasTextBlocksTable(attachedDatabase, alias);
  }
}

class CanvasTextBlock extends DataClass implements Insertable<CanvasTextBlock> {
  final String clientTextId;
  final int? serverId;
  final int pageId;
  final String textData;
  final int isDeleted;
  final int syncedWithCloud;
  final int updatedAt;
  const CanvasTextBlock({
    required this.clientTextId,
    this.serverId,
    required this.pageId,
    required this.textData,
    required this.isDeleted,
    required this.syncedWithCloud,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_text_id'] = Variable<String>(clientTextId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['page_id'] = Variable<int>(pageId);
    map['text_data'] = Variable<String>(textData);
    map['is_deleted'] = Variable<int>(isDeleted);
    map['synced_with_cloud'] = Variable<int>(syncedWithCloud);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  CanvasTextBlocksCompanion toCompanion(bool nullToAbsent) {
    return CanvasTextBlocksCompanion(
      clientTextId: Value(clientTextId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      pageId: Value(pageId),
      textData: Value(textData),
      isDeleted: Value(isDeleted),
      syncedWithCloud: Value(syncedWithCloud),
      updatedAt: Value(updatedAt),
    );
  }

  factory CanvasTextBlock.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CanvasTextBlock(
      clientTextId: serializer.fromJson<String>(json['clientTextId']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      pageId: serializer.fromJson<int>(json['pageId']),
      textData: serializer.fromJson<String>(json['textData']),
      isDeleted: serializer.fromJson<int>(json['isDeleted']),
      syncedWithCloud: serializer.fromJson<int>(json['syncedWithCloud']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientTextId': serializer.toJson<String>(clientTextId),
      'serverId': serializer.toJson<int?>(serverId),
      'pageId': serializer.toJson<int>(pageId),
      'textData': serializer.toJson<String>(textData),
      'isDeleted': serializer.toJson<int>(isDeleted),
      'syncedWithCloud': serializer.toJson<int>(syncedWithCloud),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  CanvasTextBlock copyWith({
    String? clientTextId,
    Value<int?> serverId = const Value.absent(),
    int? pageId,
    String? textData,
    int? isDeleted,
    int? syncedWithCloud,
    int? updatedAt,
  }) => CanvasTextBlock(
    clientTextId: clientTextId ?? this.clientTextId,
    serverId: serverId.present ? serverId.value : this.serverId,
    pageId: pageId ?? this.pageId,
    textData: textData ?? this.textData,
    isDeleted: isDeleted ?? this.isDeleted,
    syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CanvasTextBlock copyWithCompanion(CanvasTextBlocksCompanion data) {
    return CanvasTextBlock(
      clientTextId: data.clientTextId.present
          ? data.clientTextId.value
          : this.clientTextId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      textData: data.textData.present ? data.textData.value : this.textData,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      syncedWithCloud: data.syncedWithCloud.present
          ? data.syncedWithCloud.value
          : this.syncedWithCloud,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CanvasTextBlock(')
          ..write('clientTextId: $clientTextId, ')
          ..write('serverId: $serverId, ')
          ..write('pageId: $pageId, ')
          ..write('textData: $textData, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientTextId,
    serverId,
    pageId,
    textData,
    isDeleted,
    syncedWithCloud,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CanvasTextBlock &&
          other.clientTextId == this.clientTextId &&
          other.serverId == this.serverId &&
          other.pageId == this.pageId &&
          other.textData == this.textData &&
          other.isDeleted == this.isDeleted &&
          other.syncedWithCloud == this.syncedWithCloud &&
          other.updatedAt == this.updatedAt);
}

class CanvasTextBlocksCompanion extends UpdateCompanion<CanvasTextBlock> {
  final Value<String> clientTextId;
  final Value<int?> serverId;
  final Value<int> pageId;
  final Value<String> textData;
  final Value<int> isDeleted;
  final Value<int> syncedWithCloud;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const CanvasTextBlocksCompanion({
    this.clientTextId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.pageId = const Value.absent(),
    this.textData = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CanvasTextBlocksCompanion.insert({
    required String clientTextId,
    this.serverId = const Value.absent(),
    required int pageId,
    required String textData,
    this.isDeleted = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientTextId = Value(clientTextId),
       pageId = Value(pageId),
       textData = Value(textData);
  static Insertable<CanvasTextBlock> custom({
    Expression<String>? clientTextId,
    Expression<int>? serverId,
    Expression<int>? pageId,
    Expression<String>? textData,
    Expression<int>? isDeleted,
    Expression<int>? syncedWithCloud,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientTextId != null) 'client_text_id': clientTextId,
      if (serverId != null) 'server_id': serverId,
      if (pageId != null) 'page_id': pageId,
      if (textData != null) 'text_data': textData,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (syncedWithCloud != null) 'synced_with_cloud': syncedWithCloud,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CanvasTextBlocksCompanion copyWith({
    Value<String>? clientTextId,
    Value<int?>? serverId,
    Value<int>? pageId,
    Value<String>? textData,
    Value<int>? isDeleted,
    Value<int>? syncedWithCloud,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return CanvasTextBlocksCompanion(
      clientTextId: clientTextId ?? this.clientTextId,
      serverId: serverId ?? this.serverId,
      pageId: pageId ?? this.pageId,
      textData: textData ?? this.textData,
      isDeleted: isDeleted ?? this.isDeleted,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientTextId.present) {
      map['client_text_id'] = Variable<String>(clientTextId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<int>(pageId.value);
    }
    if (textData.present) {
      map['text_data'] = Variable<String>(textData.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<int>(isDeleted.value);
    }
    if (syncedWithCloud.present) {
      map['synced_with_cloud'] = Variable<int>(syncedWithCloud.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CanvasTextBlocksCompanion(')
          ..write('clientTextId: $clientTextId, ')
          ..write('serverId: $serverId, ')
          ..write('pageId: $pageId, ')
          ..write('textData: $textData, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CanvasImageBlocksTable extends CanvasImageBlocks
    with TableInfo<$CanvasImageBlocksTable, CanvasImageBlock> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CanvasImageBlocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _clientImageIdMeta = const VerificationMeta(
    'clientImageId',
  );
  @override
  late final GeneratedColumn<String> clientImageId = GeneratedColumn<String>(
    'client_image_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pageIdMeta = const VerificationMeta('pageId');
  @override
  late final GeneratedColumn<int> pageId = GeneratedColumn<int>(
    'page_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _posXMeta = const VerificationMeta('posX');
  @override
  late final GeneratedColumn<double> posX = GeneratedColumn<double>(
    'pos_x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _posYMeta = const VerificationMeta('posY');
  @override
  late final GeneratedColumn<double> posY = GeneratedColumn<double>(
    'pos_y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<double> width = GeneratedColumn<double>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<double> height = GeneratedColumn<double>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rotationMeta = const VerificationMeta(
    'rotation',
  );
  @override
  late final GeneratedColumn<double> rotation = GeneratedColumn<double>(
    'rotation',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<int> isDeleted = GeneratedColumn<int>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncedWithCloudMeta = const VerificationMeta(
    'syncedWithCloud',
  );
  @override
  late final GeneratedColumn<int> syncedWithCloud = GeneratedColumn<int>(
    'synced_with_cloud',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientImageId,
    serverId,
    pageId,
    imagePath,
    posX,
    posY,
    width,
    height,
    rotation,
    isDeleted,
    syncedWithCloud,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'canvas_image_blocks';
  @override
  VerificationContext validateIntegrity(
    Insertable<CanvasImageBlock> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('client_image_id')) {
      context.handle(
        _clientImageIdMeta,
        clientImageId.isAcceptableOrUnknown(
          data['client_image_id']!,
          _clientImageIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientImageIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('page_id')) {
      context.handle(
        _pageIdMeta,
        pageId.isAcceptableOrUnknown(data['page_id']!, _pageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_pageIdMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    } else if (isInserting) {
      context.missing(_imagePathMeta);
    }
    if (data.containsKey('pos_x')) {
      context.handle(
        _posXMeta,
        posX.isAcceptableOrUnknown(data['pos_x']!, _posXMeta),
      );
    } else if (isInserting) {
      context.missing(_posXMeta);
    }
    if (data.containsKey('pos_y')) {
      context.handle(
        _posYMeta,
        posY.isAcceptableOrUnknown(data['pos_y']!, _posYMeta),
      );
    } else if (isInserting) {
      context.missing(_posYMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    } else if (isInserting) {
      context.missing(_widthMeta);
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    } else if (isInserting) {
      context.missing(_heightMeta);
    }
    if (data.containsKey('rotation')) {
      context.handle(
        _rotationMeta,
        rotation.isAcceptableOrUnknown(data['rotation']!, _rotationMeta),
      );
    } else if (isInserting) {
      context.missing(_rotationMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('synced_with_cloud')) {
      context.handle(
        _syncedWithCloudMeta,
        syncedWithCloud.isAcceptableOrUnknown(
          data['synced_with_cloud']!,
          _syncedWithCloudMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clientImageId};
  @override
  CanvasImageBlock map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CanvasImageBlock(
      clientImageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_image_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      pageId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_id'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      )!,
      posX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pos_x'],
      )!,
      posY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pos_y'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height'],
      )!,
      rotation: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rotation'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_deleted'],
      )!,
      syncedWithCloud: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_with_cloud'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CanvasImageBlocksTable createAlias(String alias) {
    return $CanvasImageBlocksTable(attachedDatabase, alias);
  }
}

class CanvasImageBlock extends DataClass
    implements Insertable<CanvasImageBlock> {
  final String clientImageId;
  final int? serverId;
  final int pageId;
  final String imagePath;
  final double posX;
  final double posY;
  final double width;
  final double height;
  final double rotation;
  final int isDeleted;
  final int syncedWithCloud;
  final int updatedAt;
  const CanvasImageBlock({
    required this.clientImageId,
    this.serverId,
    required this.pageId,
    required this.imagePath,
    required this.posX,
    required this.posY,
    required this.width,
    required this.height,
    required this.rotation,
    required this.isDeleted,
    required this.syncedWithCloud,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['client_image_id'] = Variable<String>(clientImageId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['page_id'] = Variable<int>(pageId);
    map['image_path'] = Variable<String>(imagePath);
    map['pos_x'] = Variable<double>(posX);
    map['pos_y'] = Variable<double>(posY);
    map['width'] = Variable<double>(width);
    map['height'] = Variable<double>(height);
    map['rotation'] = Variable<double>(rotation);
    map['is_deleted'] = Variable<int>(isDeleted);
    map['synced_with_cloud'] = Variable<int>(syncedWithCloud);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  CanvasImageBlocksCompanion toCompanion(bool nullToAbsent) {
    return CanvasImageBlocksCompanion(
      clientImageId: Value(clientImageId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      pageId: Value(pageId),
      imagePath: Value(imagePath),
      posX: Value(posX),
      posY: Value(posY),
      width: Value(width),
      height: Value(height),
      rotation: Value(rotation),
      isDeleted: Value(isDeleted),
      syncedWithCloud: Value(syncedWithCloud),
      updatedAt: Value(updatedAt),
    );
  }

  factory CanvasImageBlock.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CanvasImageBlock(
      clientImageId: serializer.fromJson<String>(json['clientImageId']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      pageId: serializer.fromJson<int>(json['pageId']),
      imagePath: serializer.fromJson<String>(json['imagePath']),
      posX: serializer.fromJson<double>(json['posX']),
      posY: serializer.fromJson<double>(json['posY']),
      width: serializer.fromJson<double>(json['width']),
      height: serializer.fromJson<double>(json['height']),
      rotation: serializer.fromJson<double>(json['rotation']),
      isDeleted: serializer.fromJson<int>(json['isDeleted']),
      syncedWithCloud: serializer.fromJson<int>(json['syncedWithCloud']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clientImageId': serializer.toJson<String>(clientImageId),
      'serverId': serializer.toJson<int?>(serverId),
      'pageId': serializer.toJson<int>(pageId),
      'imagePath': serializer.toJson<String>(imagePath),
      'posX': serializer.toJson<double>(posX),
      'posY': serializer.toJson<double>(posY),
      'width': serializer.toJson<double>(width),
      'height': serializer.toJson<double>(height),
      'rotation': serializer.toJson<double>(rotation),
      'isDeleted': serializer.toJson<int>(isDeleted),
      'syncedWithCloud': serializer.toJson<int>(syncedWithCloud),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  CanvasImageBlock copyWith({
    String? clientImageId,
    Value<int?> serverId = const Value.absent(),
    int? pageId,
    String? imagePath,
    double? posX,
    double? posY,
    double? width,
    double? height,
    double? rotation,
    int? isDeleted,
    int? syncedWithCloud,
    int? updatedAt,
  }) => CanvasImageBlock(
    clientImageId: clientImageId ?? this.clientImageId,
    serverId: serverId.present ? serverId.value : this.serverId,
    pageId: pageId ?? this.pageId,
    imagePath: imagePath ?? this.imagePath,
    posX: posX ?? this.posX,
    posY: posY ?? this.posY,
    width: width ?? this.width,
    height: height ?? this.height,
    rotation: rotation ?? this.rotation,
    isDeleted: isDeleted ?? this.isDeleted,
    syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CanvasImageBlock copyWithCompanion(CanvasImageBlocksCompanion data) {
    return CanvasImageBlock(
      clientImageId: data.clientImageId.present
          ? data.clientImageId.value
          : this.clientImageId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      pageId: data.pageId.present ? data.pageId.value : this.pageId,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      posX: data.posX.present ? data.posX.value : this.posX,
      posY: data.posY.present ? data.posY.value : this.posY,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      rotation: data.rotation.present ? data.rotation.value : this.rotation,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      syncedWithCloud: data.syncedWithCloud.present
          ? data.syncedWithCloud.value
          : this.syncedWithCloud,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CanvasImageBlock(')
          ..write('clientImageId: $clientImageId, ')
          ..write('serverId: $serverId, ')
          ..write('pageId: $pageId, ')
          ..write('imagePath: $imagePath, ')
          ..write('posX: $posX, ')
          ..write('posY: $posY, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('rotation: $rotation, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    clientImageId,
    serverId,
    pageId,
    imagePath,
    posX,
    posY,
    width,
    height,
    rotation,
    isDeleted,
    syncedWithCloud,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CanvasImageBlock &&
          other.clientImageId == this.clientImageId &&
          other.serverId == this.serverId &&
          other.pageId == this.pageId &&
          other.imagePath == this.imagePath &&
          other.posX == this.posX &&
          other.posY == this.posY &&
          other.width == this.width &&
          other.height == this.height &&
          other.rotation == this.rotation &&
          other.isDeleted == this.isDeleted &&
          other.syncedWithCloud == this.syncedWithCloud &&
          other.updatedAt == this.updatedAt);
}

class CanvasImageBlocksCompanion extends UpdateCompanion<CanvasImageBlock> {
  final Value<String> clientImageId;
  final Value<int?> serverId;
  final Value<int> pageId;
  final Value<String> imagePath;
  final Value<double> posX;
  final Value<double> posY;
  final Value<double> width;
  final Value<double> height;
  final Value<double> rotation;
  final Value<int> isDeleted;
  final Value<int> syncedWithCloud;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const CanvasImageBlocksCompanion({
    this.clientImageId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.pageId = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.posX = const Value.absent(),
    this.posY = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.rotation = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CanvasImageBlocksCompanion.insert({
    required String clientImageId,
    this.serverId = const Value.absent(),
    required int pageId,
    required String imagePath,
    required double posX,
    required double posY,
    required double width,
    required double height,
    required double rotation,
    this.isDeleted = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clientImageId = Value(clientImageId),
       pageId = Value(pageId),
       imagePath = Value(imagePath),
       posX = Value(posX),
       posY = Value(posY),
       width = Value(width),
       height = Value(height),
       rotation = Value(rotation);
  static Insertable<CanvasImageBlock> custom({
    Expression<String>? clientImageId,
    Expression<int>? serverId,
    Expression<int>? pageId,
    Expression<String>? imagePath,
    Expression<double>? posX,
    Expression<double>? posY,
    Expression<double>? width,
    Expression<double>? height,
    Expression<double>? rotation,
    Expression<int>? isDeleted,
    Expression<int>? syncedWithCloud,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientImageId != null) 'client_image_id': clientImageId,
      if (serverId != null) 'server_id': serverId,
      if (pageId != null) 'page_id': pageId,
      if (imagePath != null) 'image_path': imagePath,
      if (posX != null) 'pos_x': posX,
      if (posY != null) 'pos_y': posY,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (rotation != null) 'rotation': rotation,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (syncedWithCloud != null) 'synced_with_cloud': syncedWithCloud,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CanvasImageBlocksCompanion copyWith({
    Value<String>? clientImageId,
    Value<int?>? serverId,
    Value<int>? pageId,
    Value<String>? imagePath,
    Value<double>? posX,
    Value<double>? posY,
    Value<double>? width,
    Value<double>? height,
    Value<double>? rotation,
    Value<int>? isDeleted,
    Value<int>? syncedWithCloud,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return CanvasImageBlocksCompanion(
      clientImageId: clientImageId ?? this.clientImageId,
      serverId: serverId ?? this.serverId,
      pageId: pageId ?? this.pageId,
      imagePath: imagePath ?? this.imagePath,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      isDeleted: isDeleted ?? this.isDeleted,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clientImageId.present) {
      map['client_image_id'] = Variable<String>(clientImageId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (pageId.present) {
      map['page_id'] = Variable<int>(pageId.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (posX.present) {
      map['pos_x'] = Variable<double>(posX.value);
    }
    if (posY.present) {
      map['pos_y'] = Variable<double>(posY.value);
    }
    if (width.present) {
      map['width'] = Variable<double>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<double>(height.value);
    }
    if (rotation.present) {
      map['rotation'] = Variable<double>(rotation.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<int>(isDeleted.value);
    }
    if (syncedWithCloud.present) {
      map['synced_with_cloud'] = Variable<int>(syncedWithCloud.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CanvasImageBlocksCompanion(')
          ..write('clientImageId: $clientImageId, ')
          ..write('serverId: $serverId, ')
          ..write('pageId: $pageId, ')
          ..write('imagePath: $imagePath, ')
          ..write('posX: $posX, ')
          ..write('posY: $posY, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('rotation: $rotation, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NotebookUserTable extends NotebookUser
    with TableInfo<$NotebookUserTable, NotebookUserData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotebookUserTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _notebookIdMeta = const VerificationMeta(
    'notebookId',
  );
  @override
  late final GeneratedColumn<int> notebookId = GeneratedColumn<int>(
    'notebook_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('viewer'),
  );
  static const VerificationMeta _syncedWithCloudMeta = const VerificationMeta(
    'syncedWithCloud',
  );
  @override
  late final GeneratedColumn<int> syncedWithCloud = GeneratedColumn<int>(
    'synced_with_cloud',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    notebookId,
    userId,
    role,
    syncedWithCloud,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notebook_user';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotebookUserData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('notebook_id')) {
      context.handle(
        _notebookIdMeta,
        notebookId.isAcceptableOrUnknown(data['notebook_id']!, _notebookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_notebookIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('synced_with_cloud')) {
      context.handle(
        _syncedWithCloudMeta,
        syncedWithCloud.isAcceptableOrUnknown(
          data['synced_with_cloud']!,
          _syncedWithCloudMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotebookUserData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotebookUserData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      notebookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notebook_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      syncedWithCloud: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_with_cloud'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $NotebookUserTable createAlias(String alias) {
    return $NotebookUserTable(attachedDatabase, alias);
  }
}

class NotebookUserData extends DataClass
    implements Insertable<NotebookUserData> {
  final int id;
  final int? serverId;
  final int notebookId;
  final int userId;
  final String role;
  final int syncedWithCloud;
  final int updatedAt;
  const NotebookUserData({
    required this.id,
    this.serverId,
    required this.notebookId,
    required this.userId,
    required this.role,
    required this.syncedWithCloud,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['notebook_id'] = Variable<int>(notebookId);
    map['user_id'] = Variable<int>(userId);
    map['role'] = Variable<String>(role);
    map['synced_with_cloud'] = Variable<int>(syncedWithCloud);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  NotebookUserCompanion toCompanion(bool nullToAbsent) {
    return NotebookUserCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      notebookId: Value(notebookId),
      userId: Value(userId),
      role: Value(role),
      syncedWithCloud: Value(syncedWithCloud),
      updatedAt: Value(updatedAt),
    );
  }

  factory NotebookUserData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotebookUserData(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      notebookId: serializer.fromJson<int>(json['notebookId']),
      userId: serializer.fromJson<int>(json['userId']),
      role: serializer.fromJson<String>(json['role']),
      syncedWithCloud: serializer.fromJson<int>(json['syncedWithCloud']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'notebookId': serializer.toJson<int>(notebookId),
      'userId': serializer.toJson<int>(userId),
      'role': serializer.toJson<String>(role),
      'syncedWithCloud': serializer.toJson<int>(syncedWithCloud),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  NotebookUserData copyWith({
    int? id,
    Value<int?> serverId = const Value.absent(),
    int? notebookId,
    int? userId,
    String? role,
    int? syncedWithCloud,
    int? updatedAt,
  }) => NotebookUserData(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    notebookId: notebookId ?? this.notebookId,
    userId: userId ?? this.userId,
    role: role ?? this.role,
    syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  NotebookUserData copyWithCompanion(NotebookUserCompanion data) {
    return NotebookUserData(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      notebookId: data.notebookId.present
          ? data.notebookId.value
          : this.notebookId,
      userId: data.userId.present ? data.userId.value : this.userId,
      role: data.role.present ? data.role.value : this.role,
      syncedWithCloud: data.syncedWithCloud.present
          ? data.syncedWithCloud.value
          : this.syncedWithCloud,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotebookUserData(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('notebookId: $notebookId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    notebookId,
    userId,
    role,
    syncedWithCloud,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotebookUserData &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.notebookId == this.notebookId &&
          other.userId == this.userId &&
          other.role == this.role &&
          other.syncedWithCloud == this.syncedWithCloud &&
          other.updatedAt == this.updatedAt);
}

class NotebookUserCompanion extends UpdateCompanion<NotebookUserData> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<int> notebookId;
  final Value<int> userId;
  final Value<String> role;
  final Value<int> syncedWithCloud;
  final Value<int> updatedAt;
  const NotebookUserCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.notebookId = const Value.absent(),
    this.userId = const Value.absent(),
    this.role = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  NotebookUserCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required int notebookId,
    required int userId,
    this.role = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : notebookId = Value(notebookId),
       userId = Value(userId);
  static Insertable<NotebookUserData> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<int>? notebookId,
    Expression<int>? userId,
    Expression<String>? role,
    Expression<int>? syncedWithCloud,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (notebookId != null) 'notebook_id': notebookId,
      if (userId != null) 'user_id': userId,
      if (role != null) 'role': role,
      if (syncedWithCloud != null) 'synced_with_cloud': syncedWithCloud,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  NotebookUserCompanion copyWith({
    Value<int>? id,
    Value<int?>? serverId,
    Value<int>? notebookId,
    Value<int>? userId,
    Value<String>? role,
    Value<int>? syncedWithCloud,
    Value<int>? updatedAt,
  }) {
    return NotebookUserCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      notebookId: notebookId ?? this.notebookId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (notebookId.present) {
      map['notebook_id'] = Variable<int>(notebookId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (syncedWithCloud.present) {
      map['synced_with_cloud'] = Variable<int>(syncedWithCloud.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotebookUserCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('notebookId: $notebookId, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PaymentsTable extends Payments with TableInfo<$PaymentsTable, Payment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('multicaixa'),
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _itemTypeMeta = const VerificationMeta(
    'itemType',
  );
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
    'item_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('subscription'),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedWithCloudMeta = const VerificationMeta(
    'syncedWithCloud',
  );
  @override
  late final GeneratedColumn<int> syncedWithCloud = GeneratedColumn<int>(
    'synced_with_cloud',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    userId,
    amount,
    paymentMethod,
    entity,
    reference,
    status,
    itemType,
    itemId,
    syncedWithCloud,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Payment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
      );
    } else if (isInserting) {
      context.missing(_referenceMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('item_type')) {
      context.handle(
        _itemTypeMeta,
        itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta),
      );
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    }
    if (data.containsKey('synced_with_cloud')) {
      context.handle(
        _syncedWithCloudMeta,
        syncedWithCloud.isAcceptableOrUnknown(
          data['synced_with_cloud']!,
          _syncedWithCloudMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Payment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Payment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      itemType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_type'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      ),
      syncedWithCloud: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_with_cloud'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PaymentsTable createAlias(String alias) {
    return $PaymentsTable(attachedDatabase, alias);
  }
}

class Payment extends DataClass implements Insertable<Payment> {
  final int id;
  final int? serverId;
  final int userId;
  final double amount;
  final String paymentMethod;
  final String entity;
  final String reference;
  final String status;
  final String itemType;
  final int? itemId;
  final int syncedWithCloud;
  final int updatedAt;
  const Payment({
    required this.id,
    this.serverId,
    required this.userId,
    required this.amount,
    required this.paymentMethod,
    required this.entity,
    required this.reference,
    required this.status,
    required this.itemType,
    this.itemId,
    required this.syncedWithCloud,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['user_id'] = Variable<int>(userId);
    map['amount'] = Variable<double>(amount);
    map['payment_method'] = Variable<String>(paymentMethod);
    map['entity'] = Variable<String>(entity);
    map['reference'] = Variable<String>(reference);
    map['status'] = Variable<String>(status);
    map['item_type'] = Variable<String>(itemType);
    if (!nullToAbsent || itemId != null) {
      map['item_id'] = Variable<int>(itemId);
    }
    map['synced_with_cloud'] = Variable<int>(syncedWithCloud);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  PaymentsCompanion toCompanion(bool nullToAbsent) {
    return PaymentsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      userId: Value(userId),
      amount: Value(amount),
      paymentMethod: Value(paymentMethod),
      entity: Value(entity),
      reference: Value(reference),
      status: Value(status),
      itemType: Value(itemType),
      itemId: itemId == null && nullToAbsent
          ? const Value.absent()
          : Value(itemId),
      syncedWithCloud: Value(syncedWithCloud),
      updatedAt: Value(updatedAt),
    );
  }

  factory Payment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Payment(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      userId: serializer.fromJson<int>(json['userId']),
      amount: serializer.fromJson<double>(json['amount']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      entity: serializer.fromJson<String>(json['entity']),
      reference: serializer.fromJson<String>(json['reference']),
      status: serializer.fromJson<String>(json['status']),
      itemType: serializer.fromJson<String>(json['itemType']),
      itemId: serializer.fromJson<int?>(json['itemId']),
      syncedWithCloud: serializer.fromJson<int>(json['syncedWithCloud']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'userId': serializer.toJson<int>(userId),
      'amount': serializer.toJson<double>(amount),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'entity': serializer.toJson<String>(entity),
      'reference': serializer.toJson<String>(reference),
      'status': serializer.toJson<String>(status),
      'itemType': serializer.toJson<String>(itemType),
      'itemId': serializer.toJson<int?>(itemId),
      'syncedWithCloud': serializer.toJson<int>(syncedWithCloud),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Payment copyWith({
    int? id,
    Value<int?> serverId = const Value.absent(),
    int? userId,
    double? amount,
    String? paymentMethod,
    String? entity,
    String? reference,
    String? status,
    String? itemType,
    Value<int?> itemId = const Value.absent(),
    int? syncedWithCloud,
    int? updatedAt,
  }) => Payment(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    userId: userId ?? this.userId,
    amount: amount ?? this.amount,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    entity: entity ?? this.entity,
    reference: reference ?? this.reference,
    status: status ?? this.status,
    itemType: itemType ?? this.itemType,
    itemId: itemId.present ? itemId.value : this.itemId,
    syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Payment copyWithCompanion(PaymentsCompanion data) {
    return Payment(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      userId: data.userId.present ? data.userId.value : this.userId,
      amount: data.amount.present ? data.amount.value : this.amount,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      entity: data.entity.present ? data.entity.value : this.entity,
      reference: data.reference.present ? data.reference.value : this.reference,
      status: data.status.present ? data.status.value : this.status,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      syncedWithCloud: data.syncedWithCloud.present
          ? data.syncedWithCloud.value
          : this.syncedWithCloud,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Payment(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('userId: $userId, ')
          ..write('amount: $amount, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('entity: $entity, ')
          ..write('reference: $reference, ')
          ..write('status: $status, ')
          ..write('itemType: $itemType, ')
          ..write('itemId: $itemId, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    userId,
    amount,
    paymentMethod,
    entity,
    reference,
    status,
    itemType,
    itemId,
    syncedWithCloud,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Payment &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.userId == this.userId &&
          other.amount == this.amount &&
          other.paymentMethod == this.paymentMethod &&
          other.entity == this.entity &&
          other.reference == this.reference &&
          other.status == this.status &&
          other.itemType == this.itemType &&
          other.itemId == this.itemId &&
          other.syncedWithCloud == this.syncedWithCloud &&
          other.updatedAt == this.updatedAt);
}

class PaymentsCompanion extends UpdateCompanion<Payment> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<int> userId;
  final Value<double> amount;
  final Value<String> paymentMethod;
  final Value<String> entity;
  final Value<String> reference;
  final Value<String> status;
  final Value<String> itemType;
  final Value<int?> itemId;
  final Value<int> syncedWithCloud;
  final Value<int> updatedAt;
  const PaymentsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.userId = const Value.absent(),
    this.amount = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.entity = const Value.absent(),
    this.reference = const Value.absent(),
    this.status = const Value.absent(),
    this.itemType = const Value.absent(),
    this.itemId = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PaymentsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required int userId,
    required double amount,
    this.paymentMethod = const Value.absent(),
    required String entity,
    required String reference,
    this.status = const Value.absent(),
    this.itemType = const Value.absent(),
    this.itemId = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : userId = Value(userId),
       amount = Value(amount),
       entity = Value(entity),
       reference = Value(reference);
  static Insertable<Payment> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<int>? userId,
    Expression<double>? amount,
    Expression<String>? paymentMethod,
    Expression<String>? entity,
    Expression<String>? reference,
    Expression<String>? status,
    Expression<String>? itemType,
    Expression<int>? itemId,
    Expression<int>? syncedWithCloud,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (userId != null) 'user_id': userId,
      if (amount != null) 'amount': amount,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (entity != null) 'entity': entity,
      if (reference != null) 'reference': reference,
      if (status != null) 'status': status,
      if (itemType != null) 'item_type': itemType,
      if (itemId != null) 'item_id': itemId,
      if (syncedWithCloud != null) 'synced_with_cloud': syncedWithCloud,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PaymentsCompanion copyWith({
    Value<int>? id,
    Value<int?>? serverId,
    Value<int>? userId,
    Value<double>? amount,
    Value<String>? paymentMethod,
    Value<String>? entity,
    Value<String>? reference,
    Value<String>? status,
    Value<String>? itemType,
    Value<int?>? itemId,
    Value<int>? syncedWithCloud,
    Value<int>? updatedAt,
  }) {
    return PaymentsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      entity: entity ?? this.entity,
      reference: reference ?? this.reference,
      status: status ?? this.status,
      itemType: itemType ?? this.itemType,
      itemId: itemId ?? this.itemId,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (syncedWithCloud.present) {
      map['synced_with_cloud'] = Variable<int>(syncedWithCloud.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('userId: $userId, ')
          ..write('amount: $amount, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('entity: $entity, ')
          ..write('reference: $reference, ')
          ..write('status: $status, ')
          ..write('itemType: $itemType, ')
          ..write('itemId: $itemId, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $SubjectsTable subjects = $SubjectsTable(this);
  late final $NotebooksTable notebooks = $NotebooksTable(this);
  late final $PagesTable pages = $PagesTable(this);
  late final $CanvasStrokesTable canvasStrokes = $CanvasStrokesTable(this);
  late final $CanvasTextBlocksTable canvasTextBlocks = $CanvasTextBlocksTable(
    this,
  );
  late final $CanvasImageBlocksTable canvasImageBlocks =
      $CanvasImageBlocksTable(this);
  late final $NotebookUserTable notebookUser = $NotebookUserTable(this);
  late final $PaymentsTable payments = $PaymentsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    subjects,
    notebooks,
    pages,
    canvasStrokes,
    canvasTextBlocks,
    canvasImageBlocks,
    notebookUser,
    payments,
  ];
}

typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      required String name,
      required String email,
      Value<String?> avatar,
      Value<String> planType,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<String> name,
      Value<String> email,
      Value<String?> avatar,
      Value<String> planType,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
    });

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planType => $composableBuilder(
    column: $table.planType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatar => $composableBuilder(
    column: $table.avatar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planType => $composableBuilder(
    column: $table.planType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get avatar =>
      $composableBuilder(column: $table.avatar, builder: (column) => column);

  GeneratedColumn<String> get planType =>
      $composableBuilder(column: $table.planType, builder: (column) => column);

  GeneratedColumn<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          User,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
          User,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String?> avatar = const Value.absent(),
                Value<String> planType = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                serverId: serverId,
                name: name,
                email: email,
                avatar: avatar,
                planType: planType,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                required String name,
                required String email,
                Value<String?> avatar = const Value.absent(),
                Value<String> planType = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                serverId: serverId,
                name: name,
                email: email,
                avatar: avatar,
                planType: planType,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      User,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
      User,
      PrefetchHooks Function()
    >;
typedef $$SubjectsTableCreateCompanionBuilder =
    SubjectsCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      required int userId,
      required String name,
      required String color,
      Value<String?> icon,
      Value<int> isDeleted,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
    });
typedef $$SubjectsTableUpdateCompanionBuilder =
    SubjectsCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<int> userId,
      Value<String> name,
      Value<String> color,
      Value<String?> icon,
      Value<int> isDeleted,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
    });

class $$SubjectsTableFilterComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SubjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubjectsTable> {
  $$SubjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SubjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SubjectsTable,
          Subject,
          $$SubjectsTableFilterComposer,
          $$SubjectsTableOrderingComposer,
          $$SubjectsTableAnnotationComposer,
          $$SubjectsTableCreateCompanionBuilder,
          $$SubjectsTableUpdateCompanionBuilder,
          (Subject, BaseReferences<_$AppDatabase, $SubjectsTable, Subject>),
          Subject,
          PrefetchHooks Function()
        > {
  $$SubjectsTableTableManager(_$AppDatabase db, $SubjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => SubjectsCompanion(
                id: id,
                serverId: serverId,
                userId: userId,
                name: name,
                color: color,
                icon: icon,
                isDeleted: isDeleted,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                required int userId,
                required String name,
                required String color,
                Value<String?> icon = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => SubjectsCompanion.insert(
                id: id,
                serverId: serverId,
                userId: userId,
                name: name,
                color: color,
                icon: icon,
                isDeleted: isDeleted,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SubjectsTable,
      Subject,
      $$SubjectsTableFilterComposer,
      $$SubjectsTableOrderingComposer,
      $$SubjectsTableAnnotationComposer,
      $$SubjectsTableCreateCompanionBuilder,
      $$SubjectsTableUpdateCompanionBuilder,
      (Subject, BaseReferences<_$AppDatabase, $SubjectsTable, Subject>),
      Subject,
      PrefetchHooks Function()
    >;
typedef $$NotebooksTableCreateCompanionBuilder =
    NotebooksCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<int?> subjectId,
      required String title,
      required String coverType,
      Value<String?> color,
      Value<String?> coverImage,
      Value<String?> lineType,
      Value<String?> paperSize,
      Value<int> isPublished,
      Value<double> price,
      Value<String?> description,
      Value<String?> authorName,
      Value<int> isDeleted,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
    });
typedef $$NotebooksTableUpdateCompanionBuilder =
    NotebooksCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<int?> subjectId,
      Value<String> title,
      Value<String> coverType,
      Value<String?> color,
      Value<String?> coverImage,
      Value<String?> lineType,
      Value<String?> paperSize,
      Value<int> isPublished,
      Value<double> price,
      Value<String?> description,
      Value<String?> authorName,
      Value<int> isDeleted,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
    });

class $$NotebooksTableFilterComposer
    extends Composer<_$AppDatabase, $NotebooksTable> {
  $$NotebooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverType => $composableBuilder(
    column: $table.coverType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverImage => $composableBuilder(
    column: $table.coverImage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lineType => $composableBuilder(
    column: $table.lineType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paperSize => $composableBuilder(
    column: $table.paperSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isPublished => $composableBuilder(
    column: $table.isPublished,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotebooksTableOrderingComposer
    extends Composer<_$AppDatabase, $NotebooksTable> {
  $$NotebooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subjectId => $composableBuilder(
    column: $table.subjectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverType => $composableBuilder(
    column: $table.coverType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverImage => $composableBuilder(
    column: $table.coverImage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lineType => $composableBuilder(
    column: $table.lineType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paperSize => $composableBuilder(
    column: $table.paperSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isPublished => $composableBuilder(
    column: $table.isPublished,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotebooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotebooksTable> {
  $$NotebooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get subjectId =>
      $composableBuilder(column: $table.subjectId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get coverType =>
      $composableBuilder(column: $table.coverType, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get coverImage => $composableBuilder(
    column: $table.coverImage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lineType =>
      $composableBuilder(column: $table.lineType, builder: (column) => column);

  GeneratedColumn<String> get paperSize =>
      $composableBuilder(column: $table.paperSize, builder: (column) => column);

  GeneratedColumn<int> get isPublished => $composableBuilder(
    column: $table.isPublished,
    builder: (column) => column,
  );

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authorName => $composableBuilder(
    column: $table.authorName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$NotebooksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotebooksTable,
          Notebook,
          $$NotebooksTableFilterComposer,
          $$NotebooksTableOrderingComposer,
          $$NotebooksTableAnnotationComposer,
          $$NotebooksTableCreateCompanionBuilder,
          $$NotebooksTableUpdateCompanionBuilder,
          (Notebook, BaseReferences<_$AppDatabase, $NotebooksTable, Notebook>),
          Notebook,
          PrefetchHooks Function()
        > {
  $$NotebooksTableTableManager(_$AppDatabase db, $NotebooksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotebooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotebooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotebooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<int?> subjectId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> coverType = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> coverImage = const Value.absent(),
                Value<String?> lineType = const Value.absent(),
                Value<String?> paperSize = const Value.absent(),
                Value<int> isPublished = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> authorName = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => NotebooksCompanion(
                id: id,
                serverId: serverId,
                subjectId: subjectId,
                title: title,
                coverType: coverType,
                color: color,
                coverImage: coverImage,
                lineType: lineType,
                paperSize: paperSize,
                isPublished: isPublished,
                price: price,
                description: description,
                authorName: authorName,
                isDeleted: isDeleted,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<int?> subjectId = const Value.absent(),
                required String title,
                required String coverType,
                Value<String?> color = const Value.absent(),
                Value<String?> coverImage = const Value.absent(),
                Value<String?> lineType = const Value.absent(),
                Value<String?> paperSize = const Value.absent(),
                Value<int> isPublished = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> authorName = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => NotebooksCompanion.insert(
                id: id,
                serverId: serverId,
                subjectId: subjectId,
                title: title,
                coverType: coverType,
                color: color,
                coverImage: coverImage,
                lineType: lineType,
                paperSize: paperSize,
                isPublished: isPublished,
                price: price,
                description: description,
                authorName: authorName,
                isDeleted: isDeleted,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotebooksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotebooksTable,
      Notebook,
      $$NotebooksTableFilterComposer,
      $$NotebooksTableOrderingComposer,
      $$NotebooksTableAnnotationComposer,
      $$NotebooksTableCreateCompanionBuilder,
      $$NotebooksTableUpdateCompanionBuilder,
      (Notebook, BaseReferences<_$AppDatabase, $NotebooksTable, Notebook>),
      Notebook,
      PrefetchHooks Function()
    >;
typedef $$PagesTableCreateCompanionBuilder =
    PagesCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      required int notebookId,
      required int pageNumber,
      Value<int> isLandscape,
      Value<String?> headerData,
      Value<String?> footerData,
      Value<int> isDeleted,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
    });
typedef $$PagesTableUpdateCompanionBuilder =
    PagesCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<int> notebookId,
      Value<int> pageNumber,
      Value<int> isLandscape,
      Value<String?> headerData,
      Value<String?> footerData,
      Value<int> isDeleted,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
    });

class $$PagesTableFilterComposer extends Composer<_$AppDatabase, $PagesTable> {
  $$PagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get notebookId => $composableBuilder(
    column: $table.notebookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isLandscape => $composableBuilder(
    column: $table.isLandscape,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get headerData => $composableBuilder(
    column: $table.headerData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get footerData => $composableBuilder(
    column: $table.footerData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PagesTableOrderingComposer
    extends Composer<_$AppDatabase, $PagesTable> {
  $$PagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get notebookId => $composableBuilder(
    column: $table.notebookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isLandscape => $composableBuilder(
    column: $table.isLandscape,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get headerData => $composableBuilder(
    column: $table.headerData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get footerData => $composableBuilder(
    column: $table.footerData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PagesTable> {
  $$PagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get notebookId => $composableBuilder(
    column: $table.notebookId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isLandscape => $composableBuilder(
    column: $table.isLandscape,
    builder: (column) => column,
  );

  GeneratedColumn<String> get headerData => $composableBuilder(
    column: $table.headerData,
    builder: (column) => column,
  );

  GeneratedColumn<String> get footerData => $composableBuilder(
    column: $table.footerData,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PagesTable,
          Page,
          $$PagesTableFilterComposer,
          $$PagesTableOrderingComposer,
          $$PagesTableAnnotationComposer,
          $$PagesTableCreateCompanionBuilder,
          $$PagesTableUpdateCompanionBuilder,
          (Page, BaseReferences<_$AppDatabase, $PagesTable, Page>),
          Page,
          PrefetchHooks Function()
        > {
  $$PagesTableTableManager(_$AppDatabase db, $PagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<int> notebookId = const Value.absent(),
                Value<int> pageNumber = const Value.absent(),
                Value<int> isLandscape = const Value.absent(),
                Value<String?> headerData = const Value.absent(),
                Value<String?> footerData = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => PagesCompanion(
                id: id,
                serverId: serverId,
                notebookId: notebookId,
                pageNumber: pageNumber,
                isLandscape: isLandscape,
                headerData: headerData,
                footerData: footerData,
                isDeleted: isDeleted,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                required int notebookId,
                required int pageNumber,
                Value<int> isLandscape = const Value.absent(),
                Value<String?> headerData = const Value.absent(),
                Value<String?> footerData = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => PagesCompanion.insert(
                id: id,
                serverId: serverId,
                notebookId: notebookId,
                pageNumber: pageNumber,
                isLandscape: isLandscape,
                headerData: headerData,
                footerData: footerData,
                isDeleted: isDeleted,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PagesTable,
      Page,
      $$PagesTableFilterComposer,
      $$PagesTableOrderingComposer,
      $$PagesTableAnnotationComposer,
      $$PagesTableCreateCompanionBuilder,
      $$PagesTableUpdateCompanionBuilder,
      (Page, BaseReferences<_$AppDatabase, $PagesTable, Page>),
      Page,
      PrefetchHooks Function()
    >;
typedef $$CanvasStrokesTableCreateCompanionBuilder =
    CanvasStrokesCompanion Function({
      required String clientStrokeId,
      Value<int?> serverId,
      required int pageId,
      required String strokeData,
      Value<int> isDeleted,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
      Value<int> rowid,
    });
typedef $$CanvasStrokesTableUpdateCompanionBuilder =
    CanvasStrokesCompanion Function({
      Value<String> clientStrokeId,
      Value<int?> serverId,
      Value<int> pageId,
      Value<String> strokeData,
      Value<int> isDeleted,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$CanvasStrokesTableFilterComposer
    extends Composer<_$AppDatabase, $CanvasStrokesTable> {
  $$CanvasStrokesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientStrokeId => $composableBuilder(
    column: $table.clientStrokeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageId => $composableBuilder(
    column: $table.pageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strokeData => $composableBuilder(
    column: $table.strokeData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CanvasStrokesTableOrderingComposer
    extends Composer<_$AppDatabase, $CanvasStrokesTable> {
  $$CanvasStrokesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientStrokeId => $composableBuilder(
    column: $table.clientStrokeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageId => $composableBuilder(
    column: $table.pageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strokeData => $composableBuilder(
    column: $table.strokeData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CanvasStrokesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CanvasStrokesTable> {
  $$CanvasStrokesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientStrokeId => $composableBuilder(
    column: $table.clientStrokeId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get pageId =>
      $composableBuilder(column: $table.pageId, builder: (column) => column);

  GeneratedColumn<String> get strokeData => $composableBuilder(
    column: $table.strokeData,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CanvasStrokesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CanvasStrokesTable,
          CanvasStroke,
          $$CanvasStrokesTableFilterComposer,
          $$CanvasStrokesTableOrderingComposer,
          $$CanvasStrokesTableAnnotationComposer,
          $$CanvasStrokesTableCreateCompanionBuilder,
          $$CanvasStrokesTableUpdateCompanionBuilder,
          (
            CanvasStroke,
            BaseReferences<_$AppDatabase, $CanvasStrokesTable, CanvasStroke>,
          ),
          CanvasStroke,
          PrefetchHooks Function()
        > {
  $$CanvasStrokesTableTableManager(_$AppDatabase db, $CanvasStrokesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CanvasStrokesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CanvasStrokesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CanvasStrokesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientStrokeId = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<int> pageId = const Value.absent(),
                Value<String> strokeData = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CanvasStrokesCompanion(
                clientStrokeId: clientStrokeId,
                serverId: serverId,
                pageId: pageId,
                strokeData: strokeData,
                isDeleted: isDeleted,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientStrokeId,
                Value<int?> serverId = const Value.absent(),
                required int pageId,
                required String strokeData,
                Value<int> isDeleted = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CanvasStrokesCompanion.insert(
                clientStrokeId: clientStrokeId,
                serverId: serverId,
                pageId: pageId,
                strokeData: strokeData,
                isDeleted: isDeleted,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CanvasStrokesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CanvasStrokesTable,
      CanvasStroke,
      $$CanvasStrokesTableFilterComposer,
      $$CanvasStrokesTableOrderingComposer,
      $$CanvasStrokesTableAnnotationComposer,
      $$CanvasStrokesTableCreateCompanionBuilder,
      $$CanvasStrokesTableUpdateCompanionBuilder,
      (
        CanvasStroke,
        BaseReferences<_$AppDatabase, $CanvasStrokesTable, CanvasStroke>,
      ),
      CanvasStroke,
      PrefetchHooks Function()
    >;
typedef $$CanvasTextBlocksTableCreateCompanionBuilder =
    CanvasTextBlocksCompanion Function({
      required String clientTextId,
      Value<int?> serverId,
      required int pageId,
      required String textData,
      Value<int> isDeleted,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
      Value<int> rowid,
    });
typedef $$CanvasTextBlocksTableUpdateCompanionBuilder =
    CanvasTextBlocksCompanion Function({
      Value<String> clientTextId,
      Value<int?> serverId,
      Value<int> pageId,
      Value<String> textData,
      Value<int> isDeleted,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$CanvasTextBlocksTableFilterComposer
    extends Composer<_$AppDatabase, $CanvasTextBlocksTable> {
  $$CanvasTextBlocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientTextId => $composableBuilder(
    column: $table.clientTextId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageId => $composableBuilder(
    column: $table.pageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get textData => $composableBuilder(
    column: $table.textData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CanvasTextBlocksTableOrderingComposer
    extends Composer<_$AppDatabase, $CanvasTextBlocksTable> {
  $$CanvasTextBlocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientTextId => $composableBuilder(
    column: $table.clientTextId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageId => $composableBuilder(
    column: $table.pageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get textData => $composableBuilder(
    column: $table.textData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CanvasTextBlocksTableAnnotationComposer
    extends Composer<_$AppDatabase, $CanvasTextBlocksTable> {
  $$CanvasTextBlocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientTextId => $composableBuilder(
    column: $table.clientTextId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get pageId =>
      $composableBuilder(column: $table.pageId, builder: (column) => column);

  GeneratedColumn<String> get textData =>
      $composableBuilder(column: $table.textData, builder: (column) => column);

  GeneratedColumn<int> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CanvasTextBlocksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CanvasTextBlocksTable,
          CanvasTextBlock,
          $$CanvasTextBlocksTableFilterComposer,
          $$CanvasTextBlocksTableOrderingComposer,
          $$CanvasTextBlocksTableAnnotationComposer,
          $$CanvasTextBlocksTableCreateCompanionBuilder,
          $$CanvasTextBlocksTableUpdateCompanionBuilder,
          (
            CanvasTextBlock,
            BaseReferences<
              _$AppDatabase,
              $CanvasTextBlocksTable,
              CanvasTextBlock
            >,
          ),
          CanvasTextBlock,
          PrefetchHooks Function()
        > {
  $$CanvasTextBlocksTableTableManager(
    _$AppDatabase db,
    $CanvasTextBlocksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CanvasTextBlocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CanvasTextBlocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CanvasTextBlocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clientTextId = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<int> pageId = const Value.absent(),
                Value<String> textData = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CanvasTextBlocksCompanion(
                clientTextId: clientTextId,
                serverId: serverId,
                pageId: pageId,
                textData: textData,
                isDeleted: isDeleted,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientTextId,
                Value<int?> serverId = const Value.absent(),
                required int pageId,
                required String textData,
                Value<int> isDeleted = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CanvasTextBlocksCompanion.insert(
                clientTextId: clientTextId,
                serverId: serverId,
                pageId: pageId,
                textData: textData,
                isDeleted: isDeleted,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CanvasTextBlocksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CanvasTextBlocksTable,
      CanvasTextBlock,
      $$CanvasTextBlocksTableFilterComposer,
      $$CanvasTextBlocksTableOrderingComposer,
      $$CanvasTextBlocksTableAnnotationComposer,
      $$CanvasTextBlocksTableCreateCompanionBuilder,
      $$CanvasTextBlocksTableUpdateCompanionBuilder,
      (
        CanvasTextBlock,
        BaseReferences<_$AppDatabase, $CanvasTextBlocksTable, CanvasTextBlock>,
      ),
      CanvasTextBlock,
      PrefetchHooks Function()
    >;
typedef $$CanvasImageBlocksTableCreateCompanionBuilder =
    CanvasImageBlocksCompanion Function({
      required String clientImageId,
      Value<int?> serverId,
      required int pageId,
      required String imagePath,
      required double posX,
      required double posY,
      required double width,
      required double height,
      required double rotation,
      Value<int> isDeleted,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
      Value<int> rowid,
    });
typedef $$CanvasImageBlocksTableUpdateCompanionBuilder =
    CanvasImageBlocksCompanion Function({
      Value<String> clientImageId,
      Value<int?> serverId,
      Value<int> pageId,
      Value<String> imagePath,
      Value<double> posX,
      Value<double> posY,
      Value<double> width,
      Value<double> height,
      Value<double> rotation,
      Value<int> isDeleted,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$CanvasImageBlocksTableFilterComposer
    extends Composer<_$AppDatabase, $CanvasImageBlocksTable> {
  $$CanvasImageBlocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clientImageId => $composableBuilder(
    column: $table.clientImageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageId => $composableBuilder(
    column: $table.pageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get posX => $composableBuilder(
    column: $table.posX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get posY => $composableBuilder(
    column: $table.posY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rotation => $composableBuilder(
    column: $table.rotation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CanvasImageBlocksTableOrderingComposer
    extends Composer<_$AppDatabase, $CanvasImageBlocksTable> {
  $$CanvasImageBlocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clientImageId => $composableBuilder(
    column: $table.clientImageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageId => $composableBuilder(
    column: $table.pageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get posX => $composableBuilder(
    column: $table.posX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get posY => $composableBuilder(
    column: $table.posY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rotation => $composableBuilder(
    column: $table.rotation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CanvasImageBlocksTableAnnotationComposer
    extends Composer<_$AppDatabase, $CanvasImageBlocksTable> {
  $$CanvasImageBlocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clientImageId => $composableBuilder(
    column: $table.clientImageId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get pageId =>
      $composableBuilder(column: $table.pageId, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<double> get posX =>
      $composableBuilder(column: $table.posX, builder: (column) => column);

  GeneratedColumn<double> get posY =>
      $composableBuilder(column: $table.posY, builder: (column) => column);

  GeneratedColumn<double> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<double> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<double> get rotation =>
      $composableBuilder(column: $table.rotation, builder: (column) => column);

  GeneratedColumn<int> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CanvasImageBlocksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CanvasImageBlocksTable,
          CanvasImageBlock,
          $$CanvasImageBlocksTableFilterComposer,
          $$CanvasImageBlocksTableOrderingComposer,
          $$CanvasImageBlocksTableAnnotationComposer,
          $$CanvasImageBlocksTableCreateCompanionBuilder,
          $$CanvasImageBlocksTableUpdateCompanionBuilder,
          (
            CanvasImageBlock,
            BaseReferences<
              _$AppDatabase,
              $CanvasImageBlocksTable,
              CanvasImageBlock
            >,
          ),
          CanvasImageBlock,
          PrefetchHooks Function()
        > {
  $$CanvasImageBlocksTableTableManager(
    _$AppDatabase db,
    $CanvasImageBlocksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CanvasImageBlocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CanvasImageBlocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CanvasImageBlocksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> clientImageId = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<int> pageId = const Value.absent(),
                Value<String> imagePath = const Value.absent(),
                Value<double> posX = const Value.absent(),
                Value<double> posY = const Value.absent(),
                Value<double> width = const Value.absent(),
                Value<double> height = const Value.absent(),
                Value<double> rotation = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CanvasImageBlocksCompanion(
                clientImageId: clientImageId,
                serverId: serverId,
                pageId: pageId,
                imagePath: imagePath,
                posX: posX,
                posY: posY,
                width: width,
                height: height,
                rotation: rotation,
                isDeleted: isDeleted,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientImageId,
                Value<int?> serverId = const Value.absent(),
                required int pageId,
                required String imagePath,
                required double posX,
                required double posY,
                required double width,
                required double height,
                required double rotation,
                Value<int> isDeleted = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CanvasImageBlocksCompanion.insert(
                clientImageId: clientImageId,
                serverId: serverId,
                pageId: pageId,
                imagePath: imagePath,
                posX: posX,
                posY: posY,
                width: width,
                height: height,
                rotation: rotation,
                isDeleted: isDeleted,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CanvasImageBlocksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CanvasImageBlocksTable,
      CanvasImageBlock,
      $$CanvasImageBlocksTableFilterComposer,
      $$CanvasImageBlocksTableOrderingComposer,
      $$CanvasImageBlocksTableAnnotationComposer,
      $$CanvasImageBlocksTableCreateCompanionBuilder,
      $$CanvasImageBlocksTableUpdateCompanionBuilder,
      (
        CanvasImageBlock,
        BaseReferences<
          _$AppDatabase,
          $CanvasImageBlocksTable,
          CanvasImageBlock
        >,
      ),
      CanvasImageBlock,
      PrefetchHooks Function()
    >;
typedef $$NotebookUserTableCreateCompanionBuilder =
    NotebookUserCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      required int notebookId,
      required int userId,
      Value<String> role,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
    });
typedef $$NotebookUserTableUpdateCompanionBuilder =
    NotebookUserCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<int> notebookId,
      Value<int> userId,
      Value<String> role,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
    });

class $$NotebookUserTableFilterComposer
    extends Composer<_$AppDatabase, $NotebookUserTable> {
  $$NotebookUserTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get notebookId => $composableBuilder(
    column: $table.notebookId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NotebookUserTableOrderingComposer
    extends Composer<_$AppDatabase, $NotebookUserTable> {
  $$NotebookUserTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get notebookId => $composableBuilder(
    column: $table.notebookId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotebookUserTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotebookUserTable> {
  $$NotebookUserTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get notebookId => $composableBuilder(
    column: $table.notebookId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$NotebookUserTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotebookUserTable,
          NotebookUserData,
          $$NotebookUserTableFilterComposer,
          $$NotebookUserTableOrderingComposer,
          $$NotebookUserTableAnnotationComposer,
          $$NotebookUserTableCreateCompanionBuilder,
          $$NotebookUserTableUpdateCompanionBuilder,
          (
            NotebookUserData,
            BaseReferences<_$AppDatabase, $NotebookUserTable, NotebookUserData>,
          ),
          NotebookUserData,
          PrefetchHooks Function()
        > {
  $$NotebookUserTableTableManager(_$AppDatabase db, $NotebookUserTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotebookUserTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotebookUserTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotebookUserTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<int> notebookId = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => NotebookUserCompanion(
                id: id,
                serverId: serverId,
                notebookId: notebookId,
                userId: userId,
                role: role,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                required int notebookId,
                required int userId,
                Value<String> role = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => NotebookUserCompanion.insert(
                id: id,
                serverId: serverId,
                notebookId: notebookId,
                userId: userId,
                role: role,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NotebookUserTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotebookUserTable,
      NotebookUserData,
      $$NotebookUserTableFilterComposer,
      $$NotebookUserTableOrderingComposer,
      $$NotebookUserTableAnnotationComposer,
      $$NotebookUserTableCreateCompanionBuilder,
      $$NotebookUserTableUpdateCompanionBuilder,
      (
        NotebookUserData,
        BaseReferences<_$AppDatabase, $NotebookUserTable, NotebookUserData>,
      ),
      NotebookUserData,
      PrefetchHooks Function()
    >;
typedef $$PaymentsTableCreateCompanionBuilder =
    PaymentsCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      required int userId,
      required double amount,
      Value<String> paymentMethod,
      required String entity,
      required String reference,
      Value<String> status,
      Value<String> itemType,
      Value<int?> itemId,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
    });
typedef $$PaymentsTableUpdateCompanionBuilder =
    PaymentsCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<int> userId,
      Value<double> amount,
      Value<String> paymentMethod,
      Value<String> entity,
      Value<String> reference,
      Value<String> status,
      Value<String> itemType,
      Value<int?> itemId,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
    });

class $$PaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<int> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaymentsTable,
          Payment,
          $$PaymentsTableFilterComposer,
          $$PaymentsTableOrderingComposer,
          $$PaymentsTableAnnotationComposer,
          $$PaymentsTableCreateCompanionBuilder,
          $$PaymentsTableUpdateCompanionBuilder,
          (Payment, BaseReferences<_$AppDatabase, $PaymentsTable, Payment>),
          Payment,
          PrefetchHooks Function()
        > {
  $$PaymentsTableTableManager(_$AppDatabase db, $PaymentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String> entity = const Value.absent(),
                Value<String> reference = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> itemType = const Value.absent(),
                Value<int?> itemId = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => PaymentsCompanion(
                id: id,
                serverId: serverId,
                userId: userId,
                amount: amount,
                paymentMethod: paymentMethod,
                entity: entity,
                reference: reference,
                status: status,
                itemType: itemType,
                itemId: itemId,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                required int userId,
                required double amount,
                Value<String> paymentMethod = const Value.absent(),
                required String entity,
                required String reference,
                Value<String> status = const Value.absent(),
                Value<String> itemType = const Value.absent(),
                Value<int?> itemId = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => PaymentsCompanion.insert(
                id: id,
                serverId: serverId,
                userId: userId,
                amount: amount,
                paymentMethod: paymentMethod,
                entity: entity,
                reference: reference,
                status: status,
                itemType: itemType,
                itemId: itemId,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaymentsTable,
      Payment,
      $$PaymentsTableFilterComposer,
      $$PaymentsTableOrderingComposer,
      $$PaymentsTableAnnotationComposer,
      $$PaymentsTableCreateCompanionBuilder,
      $$PaymentsTableUpdateCompanionBuilder,
      (Payment, BaseReferences<_$AppDatabase, $PaymentsTable, Payment>),
      Payment,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$SubjectsTableTableManager get subjects =>
      $$SubjectsTableTableManager(_db, _db.subjects);
  $$NotebooksTableTableManager get notebooks =>
      $$NotebooksTableTableManager(_db, _db.notebooks);
  $$PagesTableTableManager get pages =>
      $$PagesTableTableManager(_db, _db.pages);
  $$CanvasStrokesTableTableManager get canvasStrokes =>
      $$CanvasStrokesTableTableManager(_db, _db.canvasStrokes);
  $$CanvasTextBlocksTableTableManager get canvasTextBlocks =>
      $$CanvasTextBlocksTableTableManager(_db, _db.canvasTextBlocks);
  $$CanvasImageBlocksTableTableManager get canvasImageBlocks =>
      $$CanvasImageBlocksTableTableManager(_db, _db.canvasImageBlocks);
  $$NotebookUserTableTableManager get notebookUser =>
      $$NotebookUserTableTableManager(_db, _db.notebookUser);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db, _db.payments);
}
