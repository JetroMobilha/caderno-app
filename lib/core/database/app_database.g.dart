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
  static const VerificationMeta _bioMeta = const VerificationMeta('bio');
  @override
  late final GeneratedColumn<String> bio = GeneratedColumn<String>(
    'bio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _institutionMeta = const VerificationMeta(
    'institution',
  );
  @override
  late final GeneratedColumn<String> institution = GeneratedColumn<String>(
    'institution',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _preferredColorMeta = const VerificationMeta(
    'preferredColor',
  );
  @override
  late final GeneratedColumn<String> preferredColor = GeneratedColumn<String>(
    'preferred_color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _preferredFontMeta = const VerificationMeta(
    'preferredFont',
  );
  @override
  late final GeneratedColumn<String> preferredFont = GeneratedColumn<String>(
    'preferred_font',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _specialtiesMeta = const VerificationMeta(
    'specialties',
  );
  @override
  late final GeneratedColumn<String> specialties = GeneratedColumn<String>(
    'specialties',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<int> isArchived = GeneratedColumn<int>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<int> isFavorite = GeneratedColumn<int>(
    'is_favorite',
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
    bio,
    institution,
    preferredColor,
    preferredFont,
    specialties,
    syncedWithCloud,
    updatedAt,
    version,
    isArchived,
    isFavorite,
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
    if (data.containsKey('bio')) {
      context.handle(
        _bioMeta,
        bio.isAcceptableOrUnknown(data['bio']!, _bioMeta),
      );
    }
    if (data.containsKey('institution')) {
      context.handle(
        _institutionMeta,
        institution.isAcceptableOrUnknown(
          data['institution']!,
          _institutionMeta,
        ),
      );
    }
    if (data.containsKey('preferred_color')) {
      context.handle(
        _preferredColorMeta,
        preferredColor.isAcceptableOrUnknown(
          data['preferred_color']!,
          _preferredColorMeta,
        ),
      );
    }
    if (data.containsKey('preferred_font')) {
      context.handle(
        _preferredFontMeta,
        preferredFont.isAcceptableOrUnknown(
          data['preferred_font']!,
          _preferredFontMeta,
        ),
      );
    }
    if (data.containsKey('specialties')) {
      context.handle(
        _specialtiesMeta,
        specialties.isAcceptableOrUnknown(
          data['specialties']!,
          _specialtiesMeta,
        ),
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
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
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
      bio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bio'],
      ),
      institution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}institution'],
      ),
      preferredColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_color'],
      ),
      preferredFont: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_font'],
      ),
      specialties: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}specialties'],
      ),
      syncedWithCloud: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_with_cloud'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_archived'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_favorite'],
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
  final String? bio;
  final String? institution;
  final String? preferredColor;
  final String? preferredFont;
  final String? specialties;
  final int syncedWithCloud;
  final int updatedAt;
  final int version;
  final int isArchived;
  final int isFavorite;
  const User({
    required this.id,
    this.serverId,
    required this.name,
    required this.email,
    this.avatar,
    required this.planType,
    this.bio,
    this.institution,
    this.preferredColor,
    this.preferredFont,
    this.specialties,
    required this.syncedWithCloud,
    required this.updatedAt,
    required this.version,
    required this.isArchived,
    required this.isFavorite,
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
    if (!nullToAbsent || bio != null) {
      map['bio'] = Variable<String>(bio);
    }
    if (!nullToAbsent || institution != null) {
      map['institution'] = Variable<String>(institution);
    }
    if (!nullToAbsent || preferredColor != null) {
      map['preferred_color'] = Variable<String>(preferredColor);
    }
    if (!nullToAbsent || preferredFont != null) {
      map['preferred_font'] = Variable<String>(preferredFont);
    }
    if (!nullToAbsent || specialties != null) {
      map['specialties'] = Variable<String>(specialties);
    }
    map['synced_with_cloud'] = Variable<int>(syncedWithCloud);
    map['updated_at'] = Variable<int>(updatedAt);
    map['version'] = Variable<int>(version);
    map['is_archived'] = Variable<int>(isArchived);
    map['is_favorite'] = Variable<int>(isFavorite);
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
      bio: bio == null && nullToAbsent ? const Value.absent() : Value(bio),
      institution: institution == null && nullToAbsent
          ? const Value.absent()
          : Value(institution),
      preferredColor: preferredColor == null && nullToAbsent
          ? const Value.absent()
          : Value(preferredColor),
      preferredFont: preferredFont == null && nullToAbsent
          ? const Value.absent()
          : Value(preferredFont),
      specialties: specialties == null && nullToAbsent
          ? const Value.absent()
          : Value(specialties),
      syncedWithCloud: Value(syncedWithCloud),
      updatedAt: Value(updatedAt),
      version: Value(version),
      isArchived: Value(isArchived),
      isFavorite: Value(isFavorite),
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
      bio: serializer.fromJson<String?>(json['bio']),
      institution: serializer.fromJson<String?>(json['institution']),
      preferredColor: serializer.fromJson<String?>(json['preferredColor']),
      preferredFont: serializer.fromJson<String?>(json['preferredFont']),
      specialties: serializer.fromJson<String?>(json['specialties']),
      syncedWithCloud: serializer.fromJson<int>(json['syncedWithCloud']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      version: serializer.fromJson<int>(json['version']),
      isArchived: serializer.fromJson<int>(json['isArchived']),
      isFavorite: serializer.fromJson<int>(json['isFavorite']),
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
      'bio': serializer.toJson<String?>(bio),
      'institution': serializer.toJson<String?>(institution),
      'preferredColor': serializer.toJson<String?>(preferredColor),
      'preferredFont': serializer.toJson<String?>(preferredFont),
      'specialties': serializer.toJson<String?>(specialties),
      'syncedWithCloud': serializer.toJson<int>(syncedWithCloud),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'version': serializer.toJson<int>(version),
      'isArchived': serializer.toJson<int>(isArchived),
      'isFavorite': serializer.toJson<int>(isFavorite),
    };
  }

  User copyWith({
    int? id,
    Value<int?> serverId = const Value.absent(),
    String? name,
    String? email,
    Value<String?> avatar = const Value.absent(),
    String? planType,
    Value<String?> bio = const Value.absent(),
    Value<String?> institution = const Value.absent(),
    Value<String?> preferredColor = const Value.absent(),
    Value<String?> preferredFont = const Value.absent(),
    Value<String?> specialties = const Value.absent(),
    int? syncedWithCloud,
    int? updatedAt,
    int? version,
    int? isArchived,
    int? isFavorite,
  }) => User(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    name: name ?? this.name,
    email: email ?? this.email,
    avatar: avatar.present ? avatar.value : this.avatar,
    planType: planType ?? this.planType,
    bio: bio.present ? bio.value : this.bio,
    institution: institution.present ? institution.value : this.institution,
    preferredColor: preferredColor.present
        ? preferredColor.value
        : this.preferredColor,
    preferredFont: preferredFont.present
        ? preferredFont.value
        : this.preferredFont,
    specialties: specialties.present ? specialties.value : this.specialties,
    syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
    isArchived: isArchived ?? this.isArchived,
    isFavorite: isFavorite ?? this.isFavorite,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      avatar: data.avatar.present ? data.avatar.value : this.avatar,
      planType: data.planType.present ? data.planType.value : this.planType,
      bio: data.bio.present ? data.bio.value : this.bio,
      institution: data.institution.present
          ? data.institution.value
          : this.institution,
      preferredColor: data.preferredColor.present
          ? data.preferredColor.value
          : this.preferredColor,
      preferredFont: data.preferredFont.present
          ? data.preferredFont.value
          : this.preferredFont,
      specialties: data.specialties.present
          ? data.specialties.value
          : this.specialties,
      syncedWithCloud: data.syncedWithCloud.present
          ? data.syncedWithCloud.value
          : this.syncedWithCloud,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
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
          ..write('bio: $bio, ')
          ..write('institution: $institution, ')
          ..write('preferredColor: $preferredColor, ')
          ..write('preferredFont: $preferredFont, ')
          ..write('specialties: $specialties, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('isArchived: $isArchived, ')
          ..write('isFavorite: $isFavorite')
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
    bio,
    institution,
    preferredColor,
    preferredFont,
    specialties,
    syncedWithCloud,
    updatedAt,
    version,
    isArchived,
    isFavorite,
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
          other.bio == this.bio &&
          other.institution == this.institution &&
          other.preferredColor == this.preferredColor &&
          other.preferredFont == this.preferredFont &&
          other.specialties == this.specialties &&
          other.syncedWithCloud == this.syncedWithCloud &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version &&
          other.isArchived == this.isArchived &&
          other.isFavorite == this.isFavorite);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<String> name;
  final Value<String> email;
  final Value<String?> avatar;
  final Value<String> planType;
  final Value<String?> bio;
  final Value<String?> institution;
  final Value<String?> preferredColor;
  final Value<String?> preferredFont;
  final Value<String?> specialties;
  final Value<int> syncedWithCloud;
  final Value<int> updatedAt;
  final Value<int> version;
  final Value<int> isArchived;
  final Value<int> isFavorite;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.avatar = const Value.absent(),
    this.planType = const Value.absent(),
    this.bio = const Value.absent(),
    this.institution = const Value.absent(),
    this.preferredColor = const Value.absent(),
    this.preferredFont = const Value.absent(),
    this.specialties = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isFavorite = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required String name,
    required String email,
    this.avatar = const Value.absent(),
    this.planType = const Value.absent(),
    this.bio = const Value.absent(),
    this.institution = const Value.absent(),
    this.preferredColor = const Value.absent(),
    this.preferredFont = const Value.absent(),
    this.specialties = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isFavorite = const Value.absent(),
  }) : name = Value(name),
       email = Value(email);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? avatar,
    Expression<String>? planType,
    Expression<String>? bio,
    Expression<String>? institution,
    Expression<String>? preferredColor,
    Expression<String>? preferredFont,
    Expression<String>? specialties,
    Expression<int>? syncedWithCloud,
    Expression<int>? updatedAt,
    Expression<int>? version,
    Expression<int>? isArchived,
    Expression<int>? isFavorite,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (avatar != null) 'avatar': avatar,
      if (planType != null) 'plan_type': planType,
      if (bio != null) 'bio': bio,
      if (institution != null) 'institution': institution,
      if (preferredColor != null) 'preferred_color': preferredColor,
      if (preferredFont != null) 'preferred_font': preferredFont,
      if (specialties != null) 'specialties': specialties,
      if (syncedWithCloud != null) 'synced_with_cloud': syncedWithCloud,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (isArchived != null) 'is_archived': isArchived,
      if (isFavorite != null) 'is_favorite': isFavorite,
    });
  }

  UsersCompanion copyWith({
    Value<int>? id,
    Value<int?>? serverId,
    Value<String>? name,
    Value<String>? email,
    Value<String?>? avatar,
    Value<String>? planType,
    Value<String?>? bio,
    Value<String?>? institution,
    Value<String?>? preferredColor,
    Value<String?>? preferredFont,
    Value<String?>? specialties,
    Value<int>? syncedWithCloud,
    Value<int>? updatedAt,
    Value<int>? version,
    Value<int>? isArchived,
    Value<int>? isFavorite,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      planType: planType ?? this.planType,
      bio: bio ?? this.bio,
      institution: institution ?? this.institution,
      preferredColor: preferredColor ?? this.preferredColor,
      preferredFont: preferredFont ?? this.preferredFont,
      specialties: specialties ?? this.specialties,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      isArchived: isArchived ?? this.isArchived,
      isFavorite: isFavorite ?? this.isFavorite,
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
    if (bio.present) {
      map['bio'] = Variable<String>(bio.value);
    }
    if (institution.present) {
      map['institution'] = Variable<String>(institution.value);
    }
    if (preferredColor.present) {
      map['preferred_color'] = Variable<String>(preferredColor.value);
    }
    if (preferredFont.present) {
      map['preferred_font'] = Variable<String>(preferredFont.value);
    }
    if (specialties.present) {
      map['specialties'] = Variable<String>(specialties.value);
    }
    if (syncedWithCloud.present) {
      map['synced_with_cloud'] = Variable<int>(syncedWithCloud.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<int>(isArchived.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<int>(isFavorite.value);
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
          ..write('bio: $bio, ')
          ..write('institution: $institution, ')
          ..write('preferredColor: $preferredColor, ')
          ..write('preferredFont: $preferredFont, ')
          ..write('specialties: $specialties, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('isArchived: $isArchived, ')
          ..write('isFavorite: $isFavorite')
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
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
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
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<int> isArchived = GeneratedColumn<int>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<int> isFavorite = GeneratedColumn<int>(
    'is_favorite',
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
    clientId,
    userId,
    name,
    color,
    icon,
    isDeleted,
    syncedWithCloud,
    updatedAt,
    version,
    isArchived,
    isFavorite,
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
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
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
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
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
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
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
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_archived'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_favorite'],
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
  final String? clientId;
  final int userId;
  final String name;
  final String color;
  final String? icon;
  final int isDeleted;
  final int syncedWithCloud;
  final int updatedAt;
  final int version;
  final int isArchived;
  final int isFavorite;
  const Subject({
    required this.id,
    this.serverId,
    this.clientId,
    required this.userId,
    required this.name,
    required this.color,
    this.icon,
    required this.isDeleted,
    required this.syncedWithCloud,
    required this.updatedAt,
    required this.version,
    required this.isArchived,
    required this.isFavorite,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
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
    map['version'] = Variable<int>(version);
    map['is_archived'] = Variable<int>(isArchived);
    map['is_favorite'] = Variable<int>(isFavorite);
    return map;
  }

  SubjectsCompanion toCompanion(bool nullToAbsent) {
    return SubjectsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      userId: Value(userId),
      name: Value(name),
      color: Value(color),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      isDeleted: Value(isDeleted),
      syncedWithCloud: Value(syncedWithCloud),
      updatedAt: Value(updatedAt),
      version: Value(version),
      isArchived: Value(isArchived),
      isFavorite: Value(isFavorite),
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
      clientId: serializer.fromJson<String?>(json['clientId']),
      userId: serializer.fromJson<int>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String>(json['color']),
      icon: serializer.fromJson<String?>(json['icon']),
      isDeleted: serializer.fromJson<int>(json['isDeleted']),
      syncedWithCloud: serializer.fromJson<int>(json['syncedWithCloud']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      version: serializer.fromJson<int>(json['version']),
      isArchived: serializer.fromJson<int>(json['isArchived']),
      isFavorite: serializer.fromJson<int>(json['isFavorite']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'clientId': serializer.toJson<String?>(clientId),
      'userId': serializer.toJson<int>(userId),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String>(color),
      'icon': serializer.toJson<String?>(icon),
      'isDeleted': serializer.toJson<int>(isDeleted),
      'syncedWithCloud': serializer.toJson<int>(syncedWithCloud),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'version': serializer.toJson<int>(version),
      'isArchived': serializer.toJson<int>(isArchived),
      'isFavorite': serializer.toJson<int>(isFavorite),
    };
  }

  Subject copyWith({
    int? id,
    Value<int?> serverId = const Value.absent(),
    Value<String?> clientId = const Value.absent(),
    int? userId,
    String? name,
    String? color,
    Value<String?> icon = const Value.absent(),
    int? isDeleted,
    int? syncedWithCloud,
    int? updatedAt,
    int? version,
    int? isArchived,
    int? isFavorite,
  }) => Subject(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    clientId: clientId.present ? clientId.value : this.clientId,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    color: color ?? this.color,
    icon: icon.present ? icon.value : this.icon,
    isDeleted: isDeleted ?? this.isDeleted,
    syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
    isArchived: isArchived ?? this.isArchived,
    isFavorite: isFavorite ?? this.isFavorite,
  );
  Subject copyWithCompanion(SubjectsCompanion data) {
    return Subject(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      icon: data.icon.present ? data.icon.value : this.icon,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      syncedWithCloud: data.syncedWithCloud.present
          ? data.syncedWithCloud.value
          : this.syncedWithCloud,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Subject(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('clientId: $clientId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('isArchived: $isArchived, ')
          ..write('isFavorite: $isFavorite')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    clientId,
    userId,
    name,
    color,
    icon,
    isDeleted,
    syncedWithCloud,
    updatedAt,
    version,
    isArchived,
    isFavorite,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Subject &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.clientId == this.clientId &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.color == this.color &&
          other.icon == this.icon &&
          other.isDeleted == this.isDeleted &&
          other.syncedWithCloud == this.syncedWithCloud &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version &&
          other.isArchived == this.isArchived &&
          other.isFavorite == this.isFavorite);
}

class SubjectsCompanion extends UpdateCompanion<Subject> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<String?> clientId;
  final Value<int> userId;
  final Value<String> name;
  final Value<String> color;
  final Value<String?> icon;
  final Value<int> isDeleted;
  final Value<int> syncedWithCloud;
  final Value<int> updatedAt;
  final Value<int> version;
  final Value<int> isArchived;
  final Value<int> isFavorite;
  const SubjectsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isFavorite = const Value.absent(),
  });
  SubjectsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.clientId = const Value.absent(),
    required int userId,
    required String name,
    required String color,
    this.icon = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isFavorite = const Value.absent(),
  }) : userId = Value(userId),
       name = Value(name),
       color = Value(color);
  static Insertable<Subject> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<String>? clientId,
    Expression<int>? userId,
    Expression<String>? name,
    Expression<String>? color,
    Expression<String>? icon,
    Expression<int>? isDeleted,
    Expression<int>? syncedWithCloud,
    Expression<int>? updatedAt,
    Expression<int>? version,
    Expression<int>? isArchived,
    Expression<int>? isFavorite,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (clientId != null) 'client_id': clientId,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (syncedWithCloud != null) 'synced_with_cloud': syncedWithCloud,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (isArchived != null) 'is_archived': isArchived,
      if (isFavorite != null) 'is_favorite': isFavorite,
    });
  }

  SubjectsCompanion copyWith({
    Value<int>? id,
    Value<int?>? serverId,
    Value<String?>? clientId,
    Value<int>? userId,
    Value<String>? name,
    Value<String>? color,
    Value<String?>? icon,
    Value<int>? isDeleted,
    Value<int>? syncedWithCloud,
    Value<int>? updatedAt,
    Value<int>? version,
    Value<int>? isArchived,
    Value<int>? isFavorite,
  }) {
    return SubjectsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      clientId: clientId ?? this.clientId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isDeleted: isDeleted ?? this.isDeleted,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      isArchived: isArchived ?? this.isArchived,
      isFavorite: isFavorite ?? this.isFavorite,
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
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
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
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<int>(isArchived.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<int>(isFavorite.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubjectsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('clientId: $clientId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('isArchived: $isArchived, ')
          ..write('isFavorite: $isFavorite')
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
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES subjects (id) ON DELETE CASCADE',
    ),
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
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _templateTypeMeta = const VerificationMeta(
    'templateType',
  );
  @override
  late final GeneratedColumn<String> templateType = GeneratedColumn<String>(
    'template_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('study'),
  );
  static const VerificationMeta _collaborationModeMeta = const VerificationMeta(
    'collaborationMode',
  );
  @override
  late final GeneratedColumn<String> collaborationMode =
      GeneratedColumn<String>(
        'collaboration_mode',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('study_group'),
      );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('owner'),
  );
  static const VerificationMeta _alternativeTitleMeta = const VerificationMeta(
    'alternativeTitle',
  );
  @override
  late final GeneratedColumn<String> alternativeTitle = GeneratedColumn<String>(
    'alternative_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sharingTypeMeta = const VerificationMeta(
    'sharingType',
  );
  @override
  late final GeneratedColumn<String> sharingType = GeneratedColumn<String>(
    'sharing_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('full'),
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<int> isArchived = GeneratedColumn<int>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<int> isFavorite = GeneratedColumn<int>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _participantsPreviewMeta =
      const VerificationMeta('participantsPreview');
  @override
  late final GeneratedColumn<String> participantsPreview =
      GeneratedColumn<String>(
        'participants_preview',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastUpdatedByNameMeta = const VerificationMeta(
    'lastUpdatedByName',
  );
  @override
  late final GeneratedColumn<String> lastUpdatedByName =
      GeneratedColumn<String>(
        'last_updated_by_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _notificationsEnabledMeta =
      const VerificationMeta('notificationsEnabled');
  @override
  late final GeneratedColumn<int> notificationsEnabled = GeneratedColumn<int>(
    'notifications_enabled',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _configurationMeta = const VerificationMeta(
    'configuration',
  );
  @override
  late final GeneratedColumn<String> configuration = GeneratedColumn<String>(
    'configuration',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    clientId,
    subjectId,
    title,
    coverType,
    color,
    coverImage,
    isPublished,
    price,
    description,
    authorName,
    isDeleted,
    syncedWithCloud,
    updatedAt,
    version,
    templateType,
    collaborationMode,
    role,
    alternativeTitle,
    sharingType,
    tags,
    isArchived,
    isFavorite,
    origin,
    participantsPreview,
    lastUpdatedByName,
    notificationsEnabled,
    configuration,
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
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
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
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('template_type')) {
      context.handle(
        _templateTypeMeta,
        templateType.isAcceptableOrUnknown(
          data['template_type']!,
          _templateTypeMeta,
        ),
      );
    }
    if (data.containsKey('collaboration_mode')) {
      context.handle(
        _collaborationModeMeta,
        collaborationMode.isAcceptableOrUnknown(
          data['collaboration_mode']!,
          _collaborationModeMeta,
        ),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('alternative_title')) {
      context.handle(
        _alternativeTitleMeta,
        alternativeTitle.isAcceptableOrUnknown(
          data['alternative_title']!,
          _alternativeTitleMeta,
        ),
      );
    }
    if (data.containsKey('sharing_type')) {
      context.handle(
        _sharingTypeMeta,
        sharingType.isAcceptableOrUnknown(
          data['sharing_type']!,
          _sharingTypeMeta,
        ),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    }
    if (data.containsKey('participants_preview')) {
      context.handle(
        _participantsPreviewMeta,
        participantsPreview.isAcceptableOrUnknown(
          data['participants_preview']!,
          _participantsPreviewMeta,
        ),
      );
    }
    if (data.containsKey('last_updated_by_name')) {
      context.handle(
        _lastUpdatedByNameMeta,
        lastUpdatedByName.isAcceptableOrUnknown(
          data['last_updated_by_name']!,
          _lastUpdatedByNameMeta,
        ),
      );
    }
    if (data.containsKey('notifications_enabled')) {
      context.handle(
        _notificationsEnabledMeta,
        notificationsEnabled.isAcceptableOrUnknown(
          data['notifications_enabled']!,
          _notificationsEnabledMeta,
        ),
      );
    }
    if (data.containsKey('configuration')) {
      context.handle(
        _configurationMeta,
        configuration.isAcceptableOrUnknown(
          data['configuration']!,
          _configurationMeta,
        ),
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
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
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
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      templateType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_type'],
      )!,
      collaborationMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collaboration_mode'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      alternativeTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alternative_title'],
      ),
      sharingType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sharing_type'],
      )!,
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_archived'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_favorite'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      ),
      participantsPreview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}participants_preview'],
      ),
      lastUpdatedByName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_updated_by_name'],
      ),
      notificationsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notifications_enabled'],
      )!,
      configuration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}configuration'],
      ),
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
  final String? clientId;
  final int? subjectId;
  final String title;
  final String coverType;
  final String? color;
  final String? coverImage;
  final int isPublished;
  final double price;
  final String? description;
  final String? authorName;
  final int isDeleted;
  final int syncedWithCloud;
  final int updatedAt;
  final int version;
  final String templateType;
  final String collaborationMode;
  final String role;
  final String? alternativeTitle;
  final String sharingType;
  final String? tags;
  final int isArchived;
  final int isFavorite;
  final String? origin;
  final String? participantsPreview;
  final String? lastUpdatedByName;
  final int notificationsEnabled;
  final String? configuration;
  const Notebook({
    required this.id,
    this.serverId,
    this.clientId,
    this.subjectId,
    required this.title,
    required this.coverType,
    this.color,
    this.coverImage,
    required this.isPublished,
    required this.price,
    this.description,
    this.authorName,
    required this.isDeleted,
    required this.syncedWithCloud,
    required this.updatedAt,
    required this.version,
    required this.templateType,
    required this.collaborationMode,
    required this.role,
    this.alternativeTitle,
    required this.sharingType,
    this.tags,
    required this.isArchived,
    required this.isFavorite,
    this.origin,
    this.participantsPreview,
    this.lastUpdatedByName,
    required this.notificationsEnabled,
    this.configuration,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
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
    map['version'] = Variable<int>(version);
    map['template_type'] = Variable<String>(templateType);
    map['collaboration_mode'] = Variable<String>(collaborationMode);
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || alternativeTitle != null) {
      map['alternative_title'] = Variable<String>(alternativeTitle);
    }
    map['sharing_type'] = Variable<String>(sharingType);
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    map['is_archived'] = Variable<int>(isArchived);
    map['is_favorite'] = Variable<int>(isFavorite);
    if (!nullToAbsent || origin != null) {
      map['origin'] = Variable<String>(origin);
    }
    if (!nullToAbsent || participantsPreview != null) {
      map['participants_preview'] = Variable<String>(participantsPreview);
    }
    if (!nullToAbsent || lastUpdatedByName != null) {
      map['last_updated_by_name'] = Variable<String>(lastUpdatedByName);
    }
    map['notifications_enabled'] = Variable<int>(notificationsEnabled);
    if (!nullToAbsent || configuration != null) {
      map['configuration'] = Variable<String>(configuration);
    }
    return map;
  }

  NotebooksCompanion toCompanion(bool nullToAbsent) {
    return NotebooksCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
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
      version: Value(version),
      templateType: Value(templateType),
      collaborationMode: Value(collaborationMode),
      role: Value(role),
      alternativeTitle: alternativeTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(alternativeTitle),
      sharingType: Value(sharingType),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      isArchived: Value(isArchived),
      isFavorite: Value(isFavorite),
      origin: origin == null && nullToAbsent
          ? const Value.absent()
          : Value(origin),
      participantsPreview: participantsPreview == null && nullToAbsent
          ? const Value.absent()
          : Value(participantsPreview),
      lastUpdatedByName: lastUpdatedByName == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdatedByName),
      notificationsEnabled: Value(notificationsEnabled),
      configuration: configuration == null && nullToAbsent
          ? const Value.absent()
          : Value(configuration),
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
      clientId: serializer.fromJson<String?>(json['clientId']),
      subjectId: serializer.fromJson<int?>(json['subjectId']),
      title: serializer.fromJson<String>(json['title']),
      coverType: serializer.fromJson<String>(json['coverType']),
      color: serializer.fromJson<String?>(json['color']),
      coverImage: serializer.fromJson<String?>(json['coverImage']),
      isPublished: serializer.fromJson<int>(json['isPublished']),
      price: serializer.fromJson<double>(json['price']),
      description: serializer.fromJson<String?>(json['description']),
      authorName: serializer.fromJson<String?>(json['authorName']),
      isDeleted: serializer.fromJson<int>(json['isDeleted']),
      syncedWithCloud: serializer.fromJson<int>(json['syncedWithCloud']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      version: serializer.fromJson<int>(json['version']),
      templateType: serializer.fromJson<String>(json['templateType']),
      collaborationMode: serializer.fromJson<String>(json['collaborationMode']),
      role: serializer.fromJson<String>(json['role']),
      alternativeTitle: serializer.fromJson<String?>(json['alternativeTitle']),
      sharingType: serializer.fromJson<String>(json['sharingType']),
      tags: serializer.fromJson<String?>(json['tags']),
      isArchived: serializer.fromJson<int>(json['isArchived']),
      isFavorite: serializer.fromJson<int>(json['isFavorite']),
      origin: serializer.fromJson<String?>(json['origin']),
      participantsPreview: serializer.fromJson<String?>(
        json['participantsPreview'],
      ),
      lastUpdatedByName: serializer.fromJson<String?>(
        json['lastUpdatedByName'],
      ),
      notificationsEnabled: serializer.fromJson<int>(
        json['notificationsEnabled'],
      ),
      configuration: serializer.fromJson<String?>(json['configuration']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'clientId': serializer.toJson<String?>(clientId),
      'subjectId': serializer.toJson<int?>(subjectId),
      'title': serializer.toJson<String>(title),
      'coverType': serializer.toJson<String>(coverType),
      'color': serializer.toJson<String?>(color),
      'coverImage': serializer.toJson<String?>(coverImage),
      'isPublished': serializer.toJson<int>(isPublished),
      'price': serializer.toJson<double>(price),
      'description': serializer.toJson<String?>(description),
      'authorName': serializer.toJson<String?>(authorName),
      'isDeleted': serializer.toJson<int>(isDeleted),
      'syncedWithCloud': serializer.toJson<int>(syncedWithCloud),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'version': serializer.toJson<int>(version),
      'templateType': serializer.toJson<String>(templateType),
      'collaborationMode': serializer.toJson<String>(collaborationMode),
      'role': serializer.toJson<String>(role),
      'alternativeTitle': serializer.toJson<String?>(alternativeTitle),
      'sharingType': serializer.toJson<String>(sharingType),
      'tags': serializer.toJson<String?>(tags),
      'isArchived': serializer.toJson<int>(isArchived),
      'isFavorite': serializer.toJson<int>(isFavorite),
      'origin': serializer.toJson<String?>(origin),
      'participantsPreview': serializer.toJson<String?>(participantsPreview),
      'lastUpdatedByName': serializer.toJson<String?>(lastUpdatedByName),
      'notificationsEnabled': serializer.toJson<int>(notificationsEnabled),
      'configuration': serializer.toJson<String?>(configuration),
    };
  }

  Notebook copyWith({
    int? id,
    Value<int?> serverId = const Value.absent(),
    Value<String?> clientId = const Value.absent(),
    Value<int?> subjectId = const Value.absent(),
    String? title,
    String? coverType,
    Value<String?> color = const Value.absent(),
    Value<String?> coverImage = const Value.absent(),
    int? isPublished,
    double? price,
    Value<String?> description = const Value.absent(),
    Value<String?> authorName = const Value.absent(),
    int? isDeleted,
    int? syncedWithCloud,
    int? updatedAt,
    int? version,
    String? templateType,
    String? collaborationMode,
    String? role,
    Value<String?> alternativeTitle = const Value.absent(),
    String? sharingType,
    Value<String?> tags = const Value.absent(),
    int? isArchived,
    int? isFavorite,
    Value<String?> origin = const Value.absent(),
    Value<String?> participantsPreview = const Value.absent(),
    Value<String?> lastUpdatedByName = const Value.absent(),
    int? notificationsEnabled,
    Value<String?> configuration = const Value.absent(),
  }) => Notebook(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    clientId: clientId.present ? clientId.value : this.clientId,
    subjectId: subjectId.present ? subjectId.value : this.subjectId,
    title: title ?? this.title,
    coverType: coverType ?? this.coverType,
    color: color.present ? color.value : this.color,
    coverImage: coverImage.present ? coverImage.value : this.coverImage,
    isPublished: isPublished ?? this.isPublished,
    price: price ?? this.price,
    description: description.present ? description.value : this.description,
    authorName: authorName.present ? authorName.value : this.authorName,
    isDeleted: isDeleted ?? this.isDeleted,
    syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
    templateType: templateType ?? this.templateType,
    collaborationMode: collaborationMode ?? this.collaborationMode,
    role: role ?? this.role,
    alternativeTitle: alternativeTitle.present
        ? alternativeTitle.value
        : this.alternativeTitle,
    sharingType: sharingType ?? this.sharingType,
    tags: tags.present ? tags.value : this.tags,
    isArchived: isArchived ?? this.isArchived,
    isFavorite: isFavorite ?? this.isFavorite,
    origin: origin.present ? origin.value : this.origin,
    participantsPreview: participantsPreview.present
        ? participantsPreview.value
        : this.participantsPreview,
    lastUpdatedByName: lastUpdatedByName.present
        ? lastUpdatedByName.value
        : this.lastUpdatedByName,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    configuration: configuration.present
        ? configuration.value
        : this.configuration,
  );
  Notebook copyWithCompanion(NotebooksCompanion data) {
    return Notebook(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      subjectId: data.subjectId.present ? data.subjectId.value : this.subjectId,
      title: data.title.present ? data.title.value : this.title,
      coverType: data.coverType.present ? data.coverType.value : this.coverType,
      color: data.color.present ? data.color.value : this.color,
      coverImage: data.coverImage.present
          ? data.coverImage.value
          : this.coverImage,
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
      version: data.version.present ? data.version.value : this.version,
      templateType: data.templateType.present
          ? data.templateType.value
          : this.templateType,
      collaborationMode: data.collaborationMode.present
          ? data.collaborationMode.value
          : this.collaborationMode,
      role: data.role.present ? data.role.value : this.role,
      alternativeTitle: data.alternativeTitle.present
          ? data.alternativeTitle.value
          : this.alternativeTitle,
      sharingType: data.sharingType.present
          ? data.sharingType.value
          : this.sharingType,
      tags: data.tags.present ? data.tags.value : this.tags,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      origin: data.origin.present ? data.origin.value : this.origin,
      participantsPreview: data.participantsPreview.present
          ? data.participantsPreview.value
          : this.participantsPreview,
      lastUpdatedByName: data.lastUpdatedByName.present
          ? data.lastUpdatedByName.value
          : this.lastUpdatedByName,
      notificationsEnabled: data.notificationsEnabled.present
          ? data.notificationsEnabled.value
          : this.notificationsEnabled,
      configuration: data.configuration.present
          ? data.configuration.value
          : this.configuration,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Notebook(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('clientId: $clientId, ')
          ..write('subjectId: $subjectId, ')
          ..write('title: $title, ')
          ..write('coverType: $coverType, ')
          ..write('color: $color, ')
          ..write('coverImage: $coverImage, ')
          ..write('isPublished: $isPublished, ')
          ..write('price: $price, ')
          ..write('description: $description, ')
          ..write('authorName: $authorName, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('templateType: $templateType, ')
          ..write('collaborationMode: $collaborationMode, ')
          ..write('role: $role, ')
          ..write('alternativeTitle: $alternativeTitle, ')
          ..write('sharingType: $sharingType, ')
          ..write('tags: $tags, ')
          ..write('isArchived: $isArchived, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('origin: $origin, ')
          ..write('participantsPreview: $participantsPreview, ')
          ..write('lastUpdatedByName: $lastUpdatedByName, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('configuration: $configuration')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    serverId,
    clientId,
    subjectId,
    title,
    coverType,
    color,
    coverImage,
    isPublished,
    price,
    description,
    authorName,
    isDeleted,
    syncedWithCloud,
    updatedAt,
    version,
    templateType,
    collaborationMode,
    role,
    alternativeTitle,
    sharingType,
    tags,
    isArchived,
    isFavorite,
    origin,
    participantsPreview,
    lastUpdatedByName,
    notificationsEnabled,
    configuration,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Notebook &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.clientId == this.clientId &&
          other.subjectId == this.subjectId &&
          other.title == this.title &&
          other.coverType == this.coverType &&
          other.color == this.color &&
          other.coverImage == this.coverImage &&
          other.isPublished == this.isPublished &&
          other.price == this.price &&
          other.description == this.description &&
          other.authorName == this.authorName &&
          other.isDeleted == this.isDeleted &&
          other.syncedWithCloud == this.syncedWithCloud &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version &&
          other.templateType == this.templateType &&
          other.collaborationMode == this.collaborationMode &&
          other.role == this.role &&
          other.alternativeTitle == this.alternativeTitle &&
          other.sharingType == this.sharingType &&
          other.tags == this.tags &&
          other.isArchived == this.isArchived &&
          other.isFavorite == this.isFavorite &&
          other.origin == this.origin &&
          other.participantsPreview == this.participantsPreview &&
          other.lastUpdatedByName == this.lastUpdatedByName &&
          other.notificationsEnabled == this.notificationsEnabled &&
          other.configuration == this.configuration);
}

class NotebooksCompanion extends UpdateCompanion<Notebook> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<String?> clientId;
  final Value<int?> subjectId;
  final Value<String> title;
  final Value<String> coverType;
  final Value<String?> color;
  final Value<String?> coverImage;
  final Value<int> isPublished;
  final Value<double> price;
  final Value<String?> description;
  final Value<String?> authorName;
  final Value<int> isDeleted;
  final Value<int> syncedWithCloud;
  final Value<int> updatedAt;
  final Value<int> version;
  final Value<String> templateType;
  final Value<String> collaborationMode;
  final Value<String> role;
  final Value<String?> alternativeTitle;
  final Value<String> sharingType;
  final Value<String?> tags;
  final Value<int> isArchived;
  final Value<int> isFavorite;
  final Value<String?> origin;
  final Value<String?> participantsPreview;
  final Value<String?> lastUpdatedByName;
  final Value<int> notificationsEnabled;
  final Value<String?> configuration;
  const NotebooksCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.subjectId = const Value.absent(),
    this.title = const Value.absent(),
    this.coverType = const Value.absent(),
    this.color = const Value.absent(),
    this.coverImage = const Value.absent(),
    this.isPublished = const Value.absent(),
    this.price = const Value.absent(),
    this.description = const Value.absent(),
    this.authorName = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.templateType = const Value.absent(),
    this.collaborationMode = const Value.absent(),
    this.role = const Value.absent(),
    this.alternativeTitle = const Value.absent(),
    this.sharingType = const Value.absent(),
    this.tags = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.origin = const Value.absent(),
    this.participantsPreview = const Value.absent(),
    this.lastUpdatedByName = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.configuration = const Value.absent(),
  });
  NotebooksCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.subjectId = const Value.absent(),
    required String title,
    required String coverType,
    this.color = const Value.absent(),
    this.coverImage = const Value.absent(),
    this.isPublished = const Value.absent(),
    this.price = const Value.absent(),
    this.description = const Value.absent(),
    this.authorName = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.templateType = const Value.absent(),
    this.collaborationMode = const Value.absent(),
    this.role = const Value.absent(),
    this.alternativeTitle = const Value.absent(),
    this.sharingType = const Value.absent(),
    this.tags = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.origin = const Value.absent(),
    this.participantsPreview = const Value.absent(),
    this.lastUpdatedByName = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.configuration = const Value.absent(),
  }) : title = Value(title),
       coverType = Value(coverType);
  static Insertable<Notebook> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<String>? clientId,
    Expression<int>? subjectId,
    Expression<String>? title,
    Expression<String>? coverType,
    Expression<String>? color,
    Expression<String>? coverImage,
    Expression<int>? isPublished,
    Expression<double>? price,
    Expression<String>? description,
    Expression<String>? authorName,
    Expression<int>? isDeleted,
    Expression<int>? syncedWithCloud,
    Expression<int>? updatedAt,
    Expression<int>? version,
    Expression<String>? templateType,
    Expression<String>? collaborationMode,
    Expression<String>? role,
    Expression<String>? alternativeTitle,
    Expression<String>? sharingType,
    Expression<String>? tags,
    Expression<int>? isArchived,
    Expression<int>? isFavorite,
    Expression<String>? origin,
    Expression<String>? participantsPreview,
    Expression<String>? lastUpdatedByName,
    Expression<int>? notificationsEnabled,
    Expression<String>? configuration,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (clientId != null) 'client_id': clientId,
      if (subjectId != null) 'subject_id': subjectId,
      if (title != null) 'title': title,
      if (coverType != null) 'cover_type': coverType,
      if (color != null) 'color': color,
      if (coverImage != null) 'cover_image': coverImage,
      if (isPublished != null) 'is_published': isPublished,
      if (price != null) 'price': price,
      if (description != null) 'description': description,
      if (authorName != null) 'author_name': authorName,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (syncedWithCloud != null) 'synced_with_cloud': syncedWithCloud,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (templateType != null) 'template_type': templateType,
      if (collaborationMode != null) 'collaboration_mode': collaborationMode,
      if (role != null) 'role': role,
      if (alternativeTitle != null) 'alternative_title': alternativeTitle,
      if (sharingType != null) 'sharing_type': sharingType,
      if (tags != null) 'tags': tags,
      if (isArchived != null) 'is_archived': isArchived,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (origin != null) 'origin': origin,
      if (participantsPreview != null)
        'participants_preview': participantsPreview,
      if (lastUpdatedByName != null) 'last_updated_by_name': lastUpdatedByName,
      if (notificationsEnabled != null)
        'notifications_enabled': notificationsEnabled,
      if (configuration != null) 'configuration': configuration,
    });
  }

  NotebooksCompanion copyWith({
    Value<int>? id,
    Value<int?>? serverId,
    Value<String?>? clientId,
    Value<int?>? subjectId,
    Value<String>? title,
    Value<String>? coverType,
    Value<String?>? color,
    Value<String?>? coverImage,
    Value<int>? isPublished,
    Value<double>? price,
    Value<String?>? description,
    Value<String?>? authorName,
    Value<int>? isDeleted,
    Value<int>? syncedWithCloud,
    Value<int>? updatedAt,
    Value<int>? version,
    Value<String>? templateType,
    Value<String>? collaborationMode,
    Value<String>? role,
    Value<String?>? alternativeTitle,
    Value<String>? sharingType,
    Value<String?>? tags,
    Value<int>? isArchived,
    Value<int>? isFavorite,
    Value<String?>? origin,
    Value<String?>? participantsPreview,
    Value<String?>? lastUpdatedByName,
    Value<int>? notificationsEnabled,
    Value<String?>? configuration,
  }) {
    return NotebooksCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      clientId: clientId ?? this.clientId,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      coverType: coverType ?? this.coverType,
      color: color ?? this.color,
      coverImage: coverImage ?? this.coverImage,
      isPublished: isPublished ?? this.isPublished,
      price: price ?? this.price,
      description: description ?? this.description,
      authorName: authorName ?? this.authorName,
      isDeleted: isDeleted ?? this.isDeleted,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      templateType: templateType ?? this.templateType,
      collaborationMode: collaborationMode ?? this.collaborationMode,
      role: role ?? this.role,
      alternativeTitle: alternativeTitle ?? this.alternativeTitle,
      sharingType: sharingType ?? this.sharingType,
      tags: tags ?? this.tags,
      isArchived: isArchived ?? this.isArchived,
      isFavorite: isFavorite ?? this.isFavorite,
      origin: origin ?? this.origin,
      participantsPreview: participantsPreview ?? this.participantsPreview,
      lastUpdatedByName: lastUpdatedByName ?? this.lastUpdatedByName,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      configuration: configuration ?? this.configuration,
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
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
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
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (templateType.present) {
      map['template_type'] = Variable<String>(templateType.value);
    }
    if (collaborationMode.present) {
      map['collaboration_mode'] = Variable<String>(collaborationMode.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (alternativeTitle.present) {
      map['alternative_title'] = Variable<String>(alternativeTitle.value);
    }
    if (sharingType.present) {
      map['sharing_type'] = Variable<String>(sharingType.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<int>(isArchived.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<int>(isFavorite.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (participantsPreview.present) {
      map['participants_preview'] = Variable<String>(participantsPreview.value);
    }
    if (lastUpdatedByName.present) {
      map['last_updated_by_name'] = Variable<String>(lastUpdatedByName.value);
    }
    if (notificationsEnabled.present) {
      map['notifications_enabled'] = Variable<int>(notificationsEnabled.value);
    }
    if (configuration.present) {
      map['configuration'] = Variable<String>(configuration.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotebooksCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('clientId: $clientId, ')
          ..write('subjectId: $subjectId, ')
          ..write('title: $title, ')
          ..write('coverType: $coverType, ')
          ..write('color: $color, ')
          ..write('coverImage: $coverImage, ')
          ..write('isPublished: $isPublished, ')
          ..write('price: $price, ')
          ..write('description: $description, ')
          ..write('authorName: $authorName, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('templateType: $templateType, ')
          ..write('collaborationMode: $collaborationMode, ')
          ..write('role: $role, ')
          ..write('alternativeTitle: $alternativeTitle, ')
          ..write('sharingType: $sharingType, ')
          ..write('tags: $tags, ')
          ..write('isArchived: $isArchived, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('origin: $origin, ')
          ..write('participantsPreview: $participantsPreview, ')
          ..write('lastUpdatedByName: $lastUpdatedByName, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('configuration: $configuration')
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
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES notebooks (id) ON DELETE CASCADE',
    ),
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
  static const VerificationMeta _extractedTextMeta = const VerificationMeta(
    'extractedText',
  );
  @override
  late final GeneratedColumn<String> extractedText = GeneratedColumn<String>(
    'extracted_text',
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
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isFrozenMeta = const VerificationMeta(
    'isFrozen',
  );
  @override
  late final GeneratedColumn<int> isFrozen = GeneratedColumn<int>(
    'is_frozen',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<int> isFavorite = GeneratedColumn<int>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _paperSizeMeta = const VerificationMeta(
    'paperSize',
  );
  @override
  late final GeneratedColumn<String> paperSize = GeneratedColumn<String>(
    'paper_size',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('A4'),
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
  static const VerificationMeta _lineSpacingMeta = const VerificationMeta(
    'lineSpacing',
  );
  @override
  late final GeneratedColumn<double> lineSpacing = GeneratedColumn<double>(
    'line_spacing',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backgroundPdfPathMeta = const VerificationMeta(
    'backgroundPdfPath',
  );
  @override
  late final GeneratedColumn<String> backgroundPdfPath =
      GeneratedColumn<String>(
        'background_pdf_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _backgroundConfigMeta = const VerificationMeta(
    'backgroundConfig',
  );
  @override
  late final GeneratedColumn<String> backgroundConfig = GeneratedColumn<String>(
    'background_config',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    clientId,
    notebookId,
    pageNumber,
    isLandscape,
    headerData,
    footerData,
    extractedText,
    isDeleted,
    syncedWithCloud,
    updatedAt,
    version,
    isFrozen,
    isFavorite,
    paperSize,
    lineType,
    lineSpacing,
    backgroundPdfPath,
    backgroundConfig,
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
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
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
    if (data.containsKey('extracted_text')) {
      context.handle(
        _extractedTextMeta,
        extractedText.isAcceptableOrUnknown(
          data['extracted_text']!,
          _extractedTextMeta,
        ),
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
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('is_frozen')) {
      context.handle(
        _isFrozenMeta,
        isFrozen.isAcceptableOrUnknown(data['is_frozen']!, _isFrozenMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('paper_size')) {
      context.handle(
        _paperSizeMeta,
        paperSize.isAcceptableOrUnknown(data['paper_size']!, _paperSizeMeta),
      );
    }
    if (data.containsKey('line_type')) {
      context.handle(
        _lineTypeMeta,
        lineType.isAcceptableOrUnknown(data['line_type']!, _lineTypeMeta),
      );
    }
    if (data.containsKey('line_spacing')) {
      context.handle(
        _lineSpacingMeta,
        lineSpacing.isAcceptableOrUnknown(
          data['line_spacing']!,
          _lineSpacingMeta,
        ),
      );
    }
    if (data.containsKey('background_pdf_path')) {
      context.handle(
        _backgroundPdfPathMeta,
        backgroundPdfPath.isAcceptableOrUnknown(
          data['background_pdf_path']!,
          _backgroundPdfPathMeta,
        ),
      );
    }
    if (data.containsKey('background_config')) {
      context.handle(
        _backgroundConfigMeta,
        backgroundConfig.isAcceptableOrUnknown(
          data['background_config']!,
          _backgroundConfigMeta,
        ),
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
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
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
      extractedText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}extracted_text'],
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
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      isFrozen: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_frozen'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_favorite'],
      )!,
      paperSize: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paper_size'],
      )!,
      lineType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}line_type'],
      ),
      lineSpacing: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}line_spacing'],
      ),
      backgroundPdfPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}background_pdf_path'],
      ),
      backgroundConfig: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}background_config'],
      ),
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
  final String? clientId;
  final int notebookId;
  final int pageNumber;
  final int isLandscape;
  final String? headerData;
  final String? footerData;
  final String? extractedText;
  final int isDeleted;
  final int syncedWithCloud;
  final int updatedAt;
  final int version;
  final int isFrozen;
  final int isFavorite;
  final String paperSize;
  final String? lineType;
  final double? lineSpacing;
  final String? backgroundPdfPath;
  final String? backgroundConfig;
  const Page({
    required this.id,
    this.serverId,
    this.clientId,
    required this.notebookId,
    required this.pageNumber,
    required this.isLandscape,
    this.headerData,
    this.footerData,
    this.extractedText,
    required this.isDeleted,
    required this.syncedWithCloud,
    required this.updatedAt,
    required this.version,
    required this.isFrozen,
    required this.isFavorite,
    required this.paperSize,
    this.lineType,
    this.lineSpacing,
    this.backgroundPdfPath,
    this.backgroundConfig,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
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
    if (!nullToAbsent || extractedText != null) {
      map['extracted_text'] = Variable<String>(extractedText);
    }
    map['is_deleted'] = Variable<int>(isDeleted);
    map['synced_with_cloud'] = Variable<int>(syncedWithCloud);
    map['updated_at'] = Variable<int>(updatedAt);
    map['version'] = Variable<int>(version);
    map['is_frozen'] = Variable<int>(isFrozen);
    map['is_favorite'] = Variable<int>(isFavorite);
    map['paper_size'] = Variable<String>(paperSize);
    if (!nullToAbsent || lineType != null) {
      map['line_type'] = Variable<String>(lineType);
    }
    if (!nullToAbsent || lineSpacing != null) {
      map['line_spacing'] = Variable<double>(lineSpacing);
    }
    if (!nullToAbsent || backgroundPdfPath != null) {
      map['background_pdf_path'] = Variable<String>(backgroundPdfPath);
    }
    if (!nullToAbsent || backgroundConfig != null) {
      map['background_config'] = Variable<String>(backgroundConfig);
    }
    return map;
  }

  PagesCompanion toCompanion(bool nullToAbsent) {
    return PagesCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      notebookId: Value(notebookId),
      pageNumber: Value(pageNumber),
      isLandscape: Value(isLandscape),
      headerData: headerData == null && nullToAbsent
          ? const Value.absent()
          : Value(headerData),
      footerData: footerData == null && nullToAbsent
          ? const Value.absent()
          : Value(footerData),
      extractedText: extractedText == null && nullToAbsent
          ? const Value.absent()
          : Value(extractedText),
      isDeleted: Value(isDeleted),
      syncedWithCloud: Value(syncedWithCloud),
      updatedAt: Value(updatedAt),
      version: Value(version),
      isFrozen: Value(isFrozen),
      isFavorite: Value(isFavorite),
      paperSize: Value(paperSize),
      lineType: lineType == null && nullToAbsent
          ? const Value.absent()
          : Value(lineType),
      lineSpacing: lineSpacing == null && nullToAbsent
          ? const Value.absent()
          : Value(lineSpacing),
      backgroundPdfPath: backgroundPdfPath == null && nullToAbsent
          ? const Value.absent()
          : Value(backgroundPdfPath),
      backgroundConfig: backgroundConfig == null && nullToAbsent
          ? const Value.absent()
          : Value(backgroundConfig),
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
      clientId: serializer.fromJson<String?>(json['clientId']),
      notebookId: serializer.fromJson<int>(json['notebookId']),
      pageNumber: serializer.fromJson<int>(json['pageNumber']),
      isLandscape: serializer.fromJson<int>(json['isLandscape']),
      headerData: serializer.fromJson<String?>(json['headerData']),
      footerData: serializer.fromJson<String?>(json['footerData']),
      extractedText: serializer.fromJson<String?>(json['extractedText']),
      isDeleted: serializer.fromJson<int>(json['isDeleted']),
      syncedWithCloud: serializer.fromJson<int>(json['syncedWithCloud']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      version: serializer.fromJson<int>(json['version']),
      isFrozen: serializer.fromJson<int>(json['isFrozen']),
      isFavorite: serializer.fromJson<int>(json['isFavorite']),
      paperSize: serializer.fromJson<String>(json['paperSize']),
      lineType: serializer.fromJson<String?>(json['lineType']),
      lineSpacing: serializer.fromJson<double?>(json['lineSpacing']),
      backgroundPdfPath: serializer.fromJson<String?>(
        json['backgroundPdfPath'],
      ),
      backgroundConfig: serializer.fromJson<String?>(json['backgroundConfig']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'clientId': serializer.toJson<String?>(clientId),
      'notebookId': serializer.toJson<int>(notebookId),
      'pageNumber': serializer.toJson<int>(pageNumber),
      'isLandscape': serializer.toJson<int>(isLandscape),
      'headerData': serializer.toJson<String?>(headerData),
      'footerData': serializer.toJson<String?>(footerData),
      'extractedText': serializer.toJson<String?>(extractedText),
      'isDeleted': serializer.toJson<int>(isDeleted),
      'syncedWithCloud': serializer.toJson<int>(syncedWithCloud),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'version': serializer.toJson<int>(version),
      'isFrozen': serializer.toJson<int>(isFrozen),
      'isFavorite': serializer.toJson<int>(isFavorite),
      'paperSize': serializer.toJson<String>(paperSize),
      'lineType': serializer.toJson<String?>(lineType),
      'lineSpacing': serializer.toJson<double?>(lineSpacing),
      'backgroundPdfPath': serializer.toJson<String?>(backgroundPdfPath),
      'backgroundConfig': serializer.toJson<String?>(backgroundConfig),
    };
  }

  Page copyWith({
    int? id,
    Value<int?> serverId = const Value.absent(),
    Value<String?> clientId = const Value.absent(),
    int? notebookId,
    int? pageNumber,
    int? isLandscape,
    Value<String?> headerData = const Value.absent(),
    Value<String?> footerData = const Value.absent(),
    Value<String?> extractedText = const Value.absent(),
    int? isDeleted,
    int? syncedWithCloud,
    int? updatedAt,
    int? version,
    int? isFrozen,
    int? isFavorite,
    String? paperSize,
    Value<String?> lineType = const Value.absent(),
    Value<double?> lineSpacing = const Value.absent(),
    Value<String?> backgroundPdfPath = const Value.absent(),
    Value<String?> backgroundConfig = const Value.absent(),
  }) => Page(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    clientId: clientId.present ? clientId.value : this.clientId,
    notebookId: notebookId ?? this.notebookId,
    pageNumber: pageNumber ?? this.pageNumber,
    isLandscape: isLandscape ?? this.isLandscape,
    headerData: headerData.present ? headerData.value : this.headerData,
    footerData: footerData.present ? footerData.value : this.footerData,
    extractedText: extractedText.present
        ? extractedText.value
        : this.extractedText,
    isDeleted: isDeleted ?? this.isDeleted,
    syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
    isFrozen: isFrozen ?? this.isFrozen,
    isFavorite: isFavorite ?? this.isFavorite,
    paperSize: paperSize ?? this.paperSize,
    lineType: lineType.present ? lineType.value : this.lineType,
    lineSpacing: lineSpacing.present ? lineSpacing.value : this.lineSpacing,
    backgroundPdfPath: backgroundPdfPath.present
        ? backgroundPdfPath.value
        : this.backgroundPdfPath,
    backgroundConfig: backgroundConfig.present
        ? backgroundConfig.value
        : this.backgroundConfig,
  );
  Page copyWithCompanion(PagesCompanion data) {
    return Page(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
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
      extractedText: data.extractedText.present
          ? data.extractedText.value
          : this.extractedText,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      syncedWithCloud: data.syncedWithCloud.present
          ? data.syncedWithCloud.value
          : this.syncedWithCloud,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
      isFrozen: data.isFrozen.present ? data.isFrozen.value : this.isFrozen,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      paperSize: data.paperSize.present ? data.paperSize.value : this.paperSize,
      lineType: data.lineType.present ? data.lineType.value : this.lineType,
      lineSpacing: data.lineSpacing.present
          ? data.lineSpacing.value
          : this.lineSpacing,
      backgroundPdfPath: data.backgroundPdfPath.present
          ? data.backgroundPdfPath.value
          : this.backgroundPdfPath,
      backgroundConfig: data.backgroundConfig.present
          ? data.backgroundConfig.value
          : this.backgroundConfig,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Page(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('clientId: $clientId, ')
          ..write('notebookId: $notebookId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('isLandscape: $isLandscape, ')
          ..write('headerData: $headerData, ')
          ..write('footerData: $footerData, ')
          ..write('extractedText: $extractedText, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('isFrozen: $isFrozen, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('paperSize: $paperSize, ')
          ..write('lineType: $lineType, ')
          ..write('lineSpacing: $lineSpacing, ')
          ..write('backgroundPdfPath: $backgroundPdfPath, ')
          ..write('backgroundConfig: $backgroundConfig')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    clientId,
    notebookId,
    pageNumber,
    isLandscape,
    headerData,
    footerData,
    extractedText,
    isDeleted,
    syncedWithCloud,
    updatedAt,
    version,
    isFrozen,
    isFavorite,
    paperSize,
    lineType,
    lineSpacing,
    backgroundPdfPath,
    backgroundConfig,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Page &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.clientId == this.clientId &&
          other.notebookId == this.notebookId &&
          other.pageNumber == this.pageNumber &&
          other.isLandscape == this.isLandscape &&
          other.headerData == this.headerData &&
          other.footerData == this.footerData &&
          other.extractedText == this.extractedText &&
          other.isDeleted == this.isDeleted &&
          other.syncedWithCloud == this.syncedWithCloud &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version &&
          other.isFrozen == this.isFrozen &&
          other.isFavorite == this.isFavorite &&
          other.paperSize == this.paperSize &&
          other.lineType == this.lineType &&
          other.lineSpacing == this.lineSpacing &&
          other.backgroundPdfPath == this.backgroundPdfPath &&
          other.backgroundConfig == this.backgroundConfig);
}

class PagesCompanion extends UpdateCompanion<Page> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<String?> clientId;
  final Value<int> notebookId;
  final Value<int> pageNumber;
  final Value<int> isLandscape;
  final Value<String?> headerData;
  final Value<String?> footerData;
  final Value<String?> extractedText;
  final Value<int> isDeleted;
  final Value<int> syncedWithCloud;
  final Value<int> updatedAt;
  final Value<int> version;
  final Value<int> isFrozen;
  final Value<int> isFavorite;
  final Value<String> paperSize;
  final Value<String?> lineType;
  final Value<double?> lineSpacing;
  final Value<String?> backgroundPdfPath;
  final Value<String?> backgroundConfig;
  const PagesCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.notebookId = const Value.absent(),
    this.pageNumber = const Value.absent(),
    this.isLandscape = const Value.absent(),
    this.headerData = const Value.absent(),
    this.footerData = const Value.absent(),
    this.extractedText = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.isFrozen = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.paperSize = const Value.absent(),
    this.lineType = const Value.absent(),
    this.lineSpacing = const Value.absent(),
    this.backgroundPdfPath = const Value.absent(),
    this.backgroundConfig = const Value.absent(),
  });
  PagesCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.clientId = const Value.absent(),
    required int notebookId,
    required int pageNumber,
    this.isLandscape = const Value.absent(),
    this.headerData = const Value.absent(),
    this.footerData = const Value.absent(),
    this.extractedText = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.isFrozen = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.paperSize = const Value.absent(),
    this.lineType = const Value.absent(),
    this.lineSpacing = const Value.absent(),
    this.backgroundPdfPath = const Value.absent(),
    this.backgroundConfig = const Value.absent(),
  }) : notebookId = Value(notebookId),
       pageNumber = Value(pageNumber);
  static Insertable<Page> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<String>? clientId,
    Expression<int>? notebookId,
    Expression<int>? pageNumber,
    Expression<int>? isLandscape,
    Expression<String>? headerData,
    Expression<String>? footerData,
    Expression<String>? extractedText,
    Expression<int>? isDeleted,
    Expression<int>? syncedWithCloud,
    Expression<int>? updatedAt,
    Expression<int>? version,
    Expression<int>? isFrozen,
    Expression<int>? isFavorite,
    Expression<String>? paperSize,
    Expression<String>? lineType,
    Expression<double>? lineSpacing,
    Expression<String>? backgroundPdfPath,
    Expression<String>? backgroundConfig,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (clientId != null) 'client_id': clientId,
      if (notebookId != null) 'notebook_id': notebookId,
      if (pageNumber != null) 'page_number': pageNumber,
      if (isLandscape != null) 'is_landscape': isLandscape,
      if (headerData != null) 'header_data': headerData,
      if (footerData != null) 'footer_data': footerData,
      if (extractedText != null) 'extracted_text': extractedText,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (syncedWithCloud != null) 'synced_with_cloud': syncedWithCloud,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (isFrozen != null) 'is_frozen': isFrozen,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (paperSize != null) 'paper_size': paperSize,
      if (lineType != null) 'line_type': lineType,
      if (lineSpacing != null) 'line_spacing': lineSpacing,
      if (backgroundPdfPath != null) 'background_pdf_path': backgroundPdfPath,
      if (backgroundConfig != null) 'background_config': backgroundConfig,
    });
  }

  PagesCompanion copyWith({
    Value<int>? id,
    Value<int?>? serverId,
    Value<String?>? clientId,
    Value<int>? notebookId,
    Value<int>? pageNumber,
    Value<int>? isLandscape,
    Value<String?>? headerData,
    Value<String?>? footerData,
    Value<String?>? extractedText,
    Value<int>? isDeleted,
    Value<int>? syncedWithCloud,
    Value<int>? updatedAt,
    Value<int>? version,
    Value<int>? isFrozen,
    Value<int>? isFavorite,
    Value<String>? paperSize,
    Value<String?>? lineType,
    Value<double?>? lineSpacing,
    Value<String?>? backgroundPdfPath,
    Value<String?>? backgroundConfig,
  }) {
    return PagesCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      clientId: clientId ?? this.clientId,
      notebookId: notebookId ?? this.notebookId,
      pageNumber: pageNumber ?? this.pageNumber,
      isLandscape: isLandscape ?? this.isLandscape,
      headerData: headerData ?? this.headerData,
      footerData: footerData ?? this.footerData,
      extractedText: extractedText ?? this.extractedText,
      isDeleted: isDeleted ?? this.isDeleted,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      isFrozen: isFrozen ?? this.isFrozen,
      isFavorite: isFavorite ?? this.isFavorite,
      paperSize: paperSize ?? this.paperSize,
      lineType: lineType ?? this.lineType,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      backgroundPdfPath: backgroundPdfPath ?? this.backgroundPdfPath,
      backgroundConfig: backgroundConfig ?? this.backgroundConfig,
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
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
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
    if (extractedText.present) {
      map['extracted_text'] = Variable<String>(extractedText.value);
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
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (isFrozen.present) {
      map['is_frozen'] = Variable<int>(isFrozen.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<int>(isFavorite.value);
    }
    if (paperSize.present) {
      map['paper_size'] = Variable<String>(paperSize.value);
    }
    if (lineType.present) {
      map['line_type'] = Variable<String>(lineType.value);
    }
    if (lineSpacing.present) {
      map['line_spacing'] = Variable<double>(lineSpacing.value);
    }
    if (backgroundPdfPath.present) {
      map['background_pdf_path'] = Variable<String>(backgroundPdfPath.value);
    }
    if (backgroundConfig.present) {
      map['background_config'] = Variable<String>(backgroundConfig.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PagesCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('clientId: $clientId, ')
          ..write('notebookId: $notebookId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('isLandscape: $isLandscape, ')
          ..write('headerData: $headerData, ')
          ..write('footerData: $footerData, ')
          ..write('extractedText: $extractedText, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('isFrozen: $isFrozen, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('paperSize: $paperSize, ')
          ..write('lineType: $lineType, ')
          ..write('lineSpacing: $lineSpacing, ')
          ..write('backgroundPdfPath: $backgroundPdfPath, ')
          ..write('backgroundConfig: $backgroundConfig')
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pages (id) ON DELETE CASCADE',
    ),
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
  static const VerificationMeta _deletedInSessionMeta = const VerificationMeta(
    'deletedInSession',
  );
  @override
  late final GeneratedColumn<int> deletedInSession = GeneratedColumn<int>(
    'deleted_in_session',
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
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _creatorIdMeta = const VerificationMeta(
    'creatorId',
  );
  @override
  late final GeneratedColumn<String> creatorId = GeneratedColumn<String>(
    'creator_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _layerIdMeta = const VerificationMeta(
    'layerId',
  );
  @override
  late final GeneratedColumn<String> layerId = GeneratedColumn<String>(
    'layer_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientStrokeId,
    serverId,
    pageId,
    strokeData,
    isDeleted,
    deletedInSession,
    syncedWithCloud,
    updatedAt,
    version,
    creatorId,
    layerId,
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
    if (data.containsKey('deleted_in_session')) {
      context.handle(
        _deletedInSessionMeta,
        deletedInSession.isAcceptableOrUnknown(
          data['deleted_in_session']!,
          _deletedInSessionMeta,
        ),
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
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('creator_id')) {
      context.handle(
        _creatorIdMeta,
        creatorId.isAcceptableOrUnknown(data['creator_id']!, _creatorIdMeta),
      );
    }
    if (data.containsKey('layer_id')) {
      context.handle(
        _layerIdMeta,
        layerId.isAcceptableOrUnknown(data['layer_id']!, _layerIdMeta),
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
      deletedInSession: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_in_session'],
      )!,
      syncedWithCloud: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_with_cloud'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      creatorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creator_id'],
      ),
      layerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}layer_id'],
      ),
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
  final int deletedInSession;
  final int syncedWithCloud;
  final int updatedAt;
  final int version;
  final String? creatorId;
  final String? layerId;
  const CanvasStroke({
    required this.clientStrokeId,
    this.serverId,
    required this.pageId,
    required this.strokeData,
    required this.isDeleted,
    required this.deletedInSession,
    required this.syncedWithCloud,
    required this.updatedAt,
    required this.version,
    this.creatorId,
    this.layerId,
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
    map['deleted_in_session'] = Variable<int>(deletedInSession);
    map['synced_with_cloud'] = Variable<int>(syncedWithCloud);
    map['updated_at'] = Variable<int>(updatedAt);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || creatorId != null) {
      map['creator_id'] = Variable<String>(creatorId);
    }
    if (!nullToAbsent || layerId != null) {
      map['layer_id'] = Variable<String>(layerId);
    }
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
      deletedInSession: Value(deletedInSession),
      syncedWithCloud: Value(syncedWithCloud),
      updatedAt: Value(updatedAt),
      version: Value(version),
      creatorId: creatorId == null && nullToAbsent
          ? const Value.absent()
          : Value(creatorId),
      layerId: layerId == null && nullToAbsent
          ? const Value.absent()
          : Value(layerId),
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
      deletedInSession: serializer.fromJson<int>(json['deletedInSession']),
      syncedWithCloud: serializer.fromJson<int>(json['syncedWithCloud']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      version: serializer.fromJson<int>(json['version']),
      creatorId: serializer.fromJson<String?>(json['creatorId']),
      layerId: serializer.fromJson<String?>(json['layerId']),
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
      'deletedInSession': serializer.toJson<int>(deletedInSession),
      'syncedWithCloud': serializer.toJson<int>(syncedWithCloud),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'version': serializer.toJson<int>(version),
      'creatorId': serializer.toJson<String?>(creatorId),
      'layerId': serializer.toJson<String?>(layerId),
    };
  }

  CanvasStroke copyWith({
    String? clientStrokeId,
    Value<int?> serverId = const Value.absent(),
    int? pageId,
    String? strokeData,
    int? isDeleted,
    int? deletedInSession,
    int? syncedWithCloud,
    int? updatedAt,
    int? version,
    Value<String?> creatorId = const Value.absent(),
    Value<String?> layerId = const Value.absent(),
  }) => CanvasStroke(
    clientStrokeId: clientStrokeId ?? this.clientStrokeId,
    serverId: serverId.present ? serverId.value : this.serverId,
    pageId: pageId ?? this.pageId,
    strokeData: strokeData ?? this.strokeData,
    isDeleted: isDeleted ?? this.isDeleted,
    deletedInSession: deletedInSession ?? this.deletedInSession,
    syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
    creatorId: creatorId.present ? creatorId.value : this.creatorId,
    layerId: layerId.present ? layerId.value : this.layerId,
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
      deletedInSession: data.deletedInSession.present
          ? data.deletedInSession.value
          : this.deletedInSession,
      syncedWithCloud: data.syncedWithCloud.present
          ? data.syncedWithCloud.value
          : this.syncedWithCloud,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
      creatorId: data.creatorId.present ? data.creatorId.value : this.creatorId,
      layerId: data.layerId.present ? data.layerId.value : this.layerId,
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
          ..write('deletedInSession: $deletedInSession, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('creatorId: $creatorId, ')
          ..write('layerId: $layerId')
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
    deletedInSession,
    syncedWithCloud,
    updatedAt,
    version,
    creatorId,
    layerId,
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
          other.deletedInSession == this.deletedInSession &&
          other.syncedWithCloud == this.syncedWithCloud &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version &&
          other.creatorId == this.creatorId &&
          other.layerId == this.layerId);
}

class CanvasStrokesCompanion extends UpdateCompanion<CanvasStroke> {
  final Value<String> clientStrokeId;
  final Value<int?> serverId;
  final Value<int> pageId;
  final Value<String> strokeData;
  final Value<int> isDeleted;
  final Value<int> deletedInSession;
  final Value<int> syncedWithCloud;
  final Value<int> updatedAt;
  final Value<int> version;
  final Value<String?> creatorId;
  final Value<String?> layerId;
  final Value<int> rowid;
  const CanvasStrokesCompanion({
    this.clientStrokeId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.pageId = const Value.absent(),
    this.strokeData = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedInSession = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.creatorId = const Value.absent(),
    this.layerId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CanvasStrokesCompanion.insert({
    required String clientStrokeId,
    this.serverId = const Value.absent(),
    required int pageId,
    required String strokeData,
    this.isDeleted = const Value.absent(),
    this.deletedInSession = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.creatorId = const Value.absent(),
    this.layerId = const Value.absent(),
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
    Expression<int>? deletedInSession,
    Expression<int>? syncedWithCloud,
    Expression<int>? updatedAt,
    Expression<int>? version,
    Expression<String>? creatorId,
    Expression<String>? layerId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientStrokeId != null) 'client_stroke_id': clientStrokeId,
      if (serverId != null) 'server_id': serverId,
      if (pageId != null) 'page_id': pageId,
      if (strokeData != null) 'stroke_data': strokeData,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (deletedInSession != null) 'deleted_in_session': deletedInSession,
      if (syncedWithCloud != null) 'synced_with_cloud': syncedWithCloud,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (creatorId != null) 'creator_id': creatorId,
      if (layerId != null) 'layer_id': layerId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CanvasStrokesCompanion copyWith({
    Value<String>? clientStrokeId,
    Value<int?>? serverId,
    Value<int>? pageId,
    Value<String>? strokeData,
    Value<int>? isDeleted,
    Value<int>? deletedInSession,
    Value<int>? syncedWithCloud,
    Value<int>? updatedAt,
    Value<int>? version,
    Value<String?>? creatorId,
    Value<String?>? layerId,
    Value<int>? rowid,
  }) {
    return CanvasStrokesCompanion(
      clientStrokeId: clientStrokeId ?? this.clientStrokeId,
      serverId: serverId ?? this.serverId,
      pageId: pageId ?? this.pageId,
      strokeData: strokeData ?? this.strokeData,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedInSession: deletedInSession ?? this.deletedInSession,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      creatorId: creatorId ?? this.creatorId,
      layerId: layerId ?? this.layerId,
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
    if (deletedInSession.present) {
      map['deleted_in_session'] = Variable<int>(deletedInSession.value);
    }
    if (syncedWithCloud.present) {
      map['synced_with_cloud'] = Variable<int>(syncedWithCloud.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (creatorId.present) {
      map['creator_id'] = Variable<String>(creatorId.value);
    }
    if (layerId.present) {
      map['layer_id'] = Variable<String>(layerId.value);
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
          ..write('deletedInSession: $deletedInSession, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('creatorId: $creatorId, ')
          ..write('layerId: $layerId, ')
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pages (id) ON DELETE CASCADE',
    ),
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
  static const VerificationMeta _deletedInSessionMeta = const VerificationMeta(
    'deletedInSession',
  );
  @override
  late final GeneratedColumn<int> deletedInSession = GeneratedColumn<int>(
    'deleted_in_session',
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
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _creatorIdMeta = const VerificationMeta(
    'creatorId',
  );
  @override
  late final GeneratedColumn<String> creatorId = GeneratedColumn<String>(
    'creator_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    clientTextId,
    serverId,
    pageId,
    textData,
    isDeleted,
    deletedInSession,
    syncedWithCloud,
    updatedAt,
    version,
    creatorId,
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
    if (data.containsKey('deleted_in_session')) {
      context.handle(
        _deletedInSessionMeta,
        deletedInSession.isAcceptableOrUnknown(
          data['deleted_in_session']!,
          _deletedInSessionMeta,
        ),
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
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('creator_id')) {
      context.handle(
        _creatorIdMeta,
        creatorId.isAcceptableOrUnknown(data['creator_id']!, _creatorIdMeta),
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
      deletedInSession: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_in_session'],
      )!,
      syncedWithCloud: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_with_cloud'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      creatorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creator_id'],
      ),
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
  final int deletedInSession;
  final int syncedWithCloud;
  final int updatedAt;
  final int version;
  final String? creatorId;
  const CanvasTextBlock({
    required this.clientTextId,
    this.serverId,
    required this.pageId,
    required this.textData,
    required this.isDeleted,
    required this.deletedInSession,
    required this.syncedWithCloud,
    required this.updatedAt,
    required this.version,
    this.creatorId,
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
    map['deleted_in_session'] = Variable<int>(deletedInSession);
    map['synced_with_cloud'] = Variable<int>(syncedWithCloud);
    map['updated_at'] = Variable<int>(updatedAt);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || creatorId != null) {
      map['creator_id'] = Variable<String>(creatorId);
    }
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
      deletedInSession: Value(deletedInSession),
      syncedWithCloud: Value(syncedWithCloud),
      updatedAt: Value(updatedAt),
      version: Value(version),
      creatorId: creatorId == null && nullToAbsent
          ? const Value.absent()
          : Value(creatorId),
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
      deletedInSession: serializer.fromJson<int>(json['deletedInSession']),
      syncedWithCloud: serializer.fromJson<int>(json['syncedWithCloud']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      version: serializer.fromJson<int>(json['version']),
      creatorId: serializer.fromJson<String?>(json['creatorId']),
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
      'deletedInSession': serializer.toJson<int>(deletedInSession),
      'syncedWithCloud': serializer.toJson<int>(syncedWithCloud),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'version': serializer.toJson<int>(version),
      'creatorId': serializer.toJson<String?>(creatorId),
    };
  }

  CanvasTextBlock copyWith({
    String? clientTextId,
    Value<int?> serverId = const Value.absent(),
    int? pageId,
    String? textData,
    int? isDeleted,
    int? deletedInSession,
    int? syncedWithCloud,
    int? updatedAt,
    int? version,
    Value<String?> creatorId = const Value.absent(),
  }) => CanvasTextBlock(
    clientTextId: clientTextId ?? this.clientTextId,
    serverId: serverId.present ? serverId.value : this.serverId,
    pageId: pageId ?? this.pageId,
    textData: textData ?? this.textData,
    isDeleted: isDeleted ?? this.isDeleted,
    deletedInSession: deletedInSession ?? this.deletedInSession,
    syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
    creatorId: creatorId.present ? creatorId.value : this.creatorId,
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
      deletedInSession: data.deletedInSession.present
          ? data.deletedInSession.value
          : this.deletedInSession,
      syncedWithCloud: data.syncedWithCloud.present
          ? data.syncedWithCloud.value
          : this.syncedWithCloud,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
      creatorId: data.creatorId.present ? data.creatorId.value : this.creatorId,
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
          ..write('deletedInSession: $deletedInSession, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('creatorId: $creatorId')
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
    deletedInSession,
    syncedWithCloud,
    updatedAt,
    version,
    creatorId,
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
          other.deletedInSession == this.deletedInSession &&
          other.syncedWithCloud == this.syncedWithCloud &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version &&
          other.creatorId == this.creatorId);
}

class CanvasTextBlocksCompanion extends UpdateCompanion<CanvasTextBlock> {
  final Value<String> clientTextId;
  final Value<int?> serverId;
  final Value<int> pageId;
  final Value<String> textData;
  final Value<int> isDeleted;
  final Value<int> deletedInSession;
  final Value<int> syncedWithCloud;
  final Value<int> updatedAt;
  final Value<int> version;
  final Value<String?> creatorId;
  final Value<int> rowid;
  const CanvasTextBlocksCompanion({
    this.clientTextId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.pageId = const Value.absent(),
    this.textData = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedInSession = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.creatorId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CanvasTextBlocksCompanion.insert({
    required String clientTextId,
    this.serverId = const Value.absent(),
    required int pageId,
    required String textData,
    this.isDeleted = const Value.absent(),
    this.deletedInSession = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.creatorId = const Value.absent(),
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
    Expression<int>? deletedInSession,
    Expression<int>? syncedWithCloud,
    Expression<int>? updatedAt,
    Expression<int>? version,
    Expression<String>? creatorId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clientTextId != null) 'client_text_id': clientTextId,
      if (serverId != null) 'server_id': serverId,
      if (pageId != null) 'page_id': pageId,
      if (textData != null) 'text_data': textData,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (deletedInSession != null) 'deleted_in_session': deletedInSession,
      if (syncedWithCloud != null) 'synced_with_cloud': syncedWithCloud,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (creatorId != null) 'creator_id': creatorId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CanvasTextBlocksCompanion copyWith({
    Value<String>? clientTextId,
    Value<int?>? serverId,
    Value<int>? pageId,
    Value<String>? textData,
    Value<int>? isDeleted,
    Value<int>? deletedInSession,
    Value<int>? syncedWithCloud,
    Value<int>? updatedAt,
    Value<int>? version,
    Value<String?>? creatorId,
    Value<int>? rowid,
  }) {
    return CanvasTextBlocksCompanion(
      clientTextId: clientTextId ?? this.clientTextId,
      serverId: serverId ?? this.serverId,
      pageId: pageId ?? this.pageId,
      textData: textData ?? this.textData,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedInSession: deletedInSession ?? this.deletedInSession,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      creatorId: creatorId ?? this.creatorId,
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
    if (deletedInSession.present) {
      map['deleted_in_session'] = Variable<int>(deletedInSession.value);
    }
    if (syncedWithCloud.present) {
      map['synced_with_cloud'] = Variable<int>(syncedWithCloud.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (creatorId.present) {
      map['creator_id'] = Variable<String>(creatorId.value);
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
          ..write('deletedInSession: $deletedInSession, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('creatorId: $creatorId, ')
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pages (id) ON DELETE CASCADE',
    ),
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
  static const VerificationMeta _deletedInSessionMeta = const VerificationMeta(
    'deletedInSession',
  );
  @override
  late final GeneratedColumn<int> deletedInSession = GeneratedColumn<int>(
    'deleted_in_session',
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
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _creatorIdMeta = const VerificationMeta(
    'creatorId',
  );
  @override
  late final GeneratedColumn<String> creatorId = GeneratedColumn<String>(
    'creator_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    deletedInSession,
    syncedWithCloud,
    updatedAt,
    version,
    creatorId,
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
    if (data.containsKey('deleted_in_session')) {
      context.handle(
        _deletedInSessionMeta,
        deletedInSession.isAcceptableOrUnknown(
          data['deleted_in_session']!,
          _deletedInSessionMeta,
        ),
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
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('creator_id')) {
      context.handle(
        _creatorIdMeta,
        creatorId.isAcceptableOrUnknown(data['creator_id']!, _creatorIdMeta),
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
      deletedInSession: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_in_session'],
      )!,
      syncedWithCloud: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_with_cloud'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      creatorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}creator_id'],
      ),
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
  final int deletedInSession;
  final int syncedWithCloud;
  final int updatedAt;
  final int version;
  final String? creatorId;
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
    required this.deletedInSession,
    required this.syncedWithCloud,
    required this.updatedAt,
    required this.version,
    this.creatorId,
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
    map['deleted_in_session'] = Variable<int>(deletedInSession);
    map['synced_with_cloud'] = Variable<int>(syncedWithCloud);
    map['updated_at'] = Variable<int>(updatedAt);
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || creatorId != null) {
      map['creator_id'] = Variable<String>(creatorId);
    }
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
      deletedInSession: Value(deletedInSession),
      syncedWithCloud: Value(syncedWithCloud),
      updatedAt: Value(updatedAt),
      version: Value(version),
      creatorId: creatorId == null && nullToAbsent
          ? const Value.absent()
          : Value(creatorId),
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
      deletedInSession: serializer.fromJson<int>(json['deletedInSession']),
      syncedWithCloud: serializer.fromJson<int>(json['syncedWithCloud']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      version: serializer.fromJson<int>(json['version']),
      creatorId: serializer.fromJson<String?>(json['creatorId']),
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
      'deletedInSession': serializer.toJson<int>(deletedInSession),
      'syncedWithCloud': serializer.toJson<int>(syncedWithCloud),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'version': serializer.toJson<int>(version),
      'creatorId': serializer.toJson<String?>(creatorId),
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
    int? deletedInSession,
    int? syncedWithCloud,
    int? updatedAt,
    int? version,
    Value<String?> creatorId = const Value.absent(),
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
    deletedInSession: deletedInSession ?? this.deletedInSession,
    syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
    creatorId: creatorId.present ? creatorId.value : this.creatorId,
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
      deletedInSession: data.deletedInSession.present
          ? data.deletedInSession.value
          : this.deletedInSession,
      syncedWithCloud: data.syncedWithCloud.present
          ? data.syncedWithCloud.value
          : this.syncedWithCloud,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
      creatorId: data.creatorId.present ? data.creatorId.value : this.creatorId,
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
          ..write('deletedInSession: $deletedInSession, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('creatorId: $creatorId')
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
    deletedInSession,
    syncedWithCloud,
    updatedAt,
    version,
    creatorId,
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
          other.deletedInSession == this.deletedInSession &&
          other.syncedWithCloud == this.syncedWithCloud &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version &&
          other.creatorId == this.creatorId);
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
  final Value<int> deletedInSession;
  final Value<int> syncedWithCloud;
  final Value<int> updatedAt;
  final Value<int> version;
  final Value<String?> creatorId;
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
    this.deletedInSession = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.creatorId = const Value.absent(),
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
    this.deletedInSession = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.creatorId = const Value.absent(),
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
    Expression<int>? deletedInSession,
    Expression<int>? syncedWithCloud,
    Expression<int>? updatedAt,
    Expression<int>? version,
    Expression<String>? creatorId,
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
      if (deletedInSession != null) 'deleted_in_session': deletedInSession,
      if (syncedWithCloud != null) 'synced_with_cloud': syncedWithCloud,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (creatorId != null) 'creator_id': creatorId,
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
    Value<int>? deletedInSession,
    Value<int>? syncedWithCloud,
    Value<int>? updatedAt,
    Value<int>? version,
    Value<String?>? creatorId,
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
      deletedInSession: deletedInSession ?? this.deletedInSession,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      creatorId: creatorId ?? this.creatorId,
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
    if (deletedInSession.present) {
      map['deleted_in_session'] = Variable<int>(deletedInSession.value);
    }
    if (syncedWithCloud.present) {
      map['synced_with_cloud'] = Variable<int>(syncedWithCloud.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (creatorId.present) {
      map['creator_id'] = Variable<String>(creatorId.value);
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
          ..write('deletedInSession: $deletedInSession, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('creatorId: $creatorId, ')
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES notebooks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
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
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<int> isArchived = GeneratedColumn<int>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<int> isFavorite = GeneratedColumn<int>(
    'is_favorite',
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
    version,
    isArchived,
    isFavorite,
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
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
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
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_archived'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_favorite'],
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
  final int version;
  final int isArchived;
  final int isFavorite;
  const NotebookUserData({
    required this.id,
    this.serverId,
    required this.notebookId,
    required this.userId,
    required this.role,
    required this.syncedWithCloud,
    required this.updatedAt,
    required this.version,
    required this.isArchived,
    required this.isFavorite,
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
    map['version'] = Variable<int>(version);
    map['is_archived'] = Variable<int>(isArchived);
    map['is_favorite'] = Variable<int>(isFavorite);
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
      version: Value(version),
      isArchived: Value(isArchived),
      isFavorite: Value(isFavorite),
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
      version: serializer.fromJson<int>(json['version']),
      isArchived: serializer.fromJson<int>(json['isArchived']),
      isFavorite: serializer.fromJson<int>(json['isFavorite']),
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
      'version': serializer.toJson<int>(version),
      'isArchived': serializer.toJson<int>(isArchived),
      'isFavorite': serializer.toJson<int>(isFavorite),
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
    int? version,
    int? isArchived,
    int? isFavorite,
  }) => NotebookUserData(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    notebookId: notebookId ?? this.notebookId,
    userId: userId ?? this.userId,
    role: role ?? this.role,
    syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
    isArchived: isArchived ?? this.isArchived,
    isFavorite: isFavorite ?? this.isFavorite,
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
      version: data.version.present ? data.version.value : this.version,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
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
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('isArchived: $isArchived, ')
          ..write('isFavorite: $isFavorite')
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
    version,
    isArchived,
    isFavorite,
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
          other.updatedAt == this.updatedAt &&
          other.version == this.version &&
          other.isArchived == this.isArchived &&
          other.isFavorite == this.isFavorite);
}

class NotebookUserCompanion extends UpdateCompanion<NotebookUserData> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<int> notebookId;
  final Value<int> userId;
  final Value<String> role;
  final Value<int> syncedWithCloud;
  final Value<int> updatedAt;
  final Value<int> version;
  final Value<int> isArchived;
  final Value<int> isFavorite;
  const NotebookUserCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.notebookId = const Value.absent(),
    this.userId = const Value.absent(),
    this.role = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isFavorite = const Value.absent(),
  });
  NotebookUserCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    required int notebookId,
    required int userId,
    this.role = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isFavorite = const Value.absent(),
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
    Expression<int>? version,
    Expression<int>? isArchived,
    Expression<int>? isFavorite,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (notebookId != null) 'notebook_id': notebookId,
      if (userId != null) 'user_id': userId,
      if (role != null) 'role': role,
      if (syncedWithCloud != null) 'synced_with_cloud': syncedWithCloud,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (isArchived != null) 'is_archived': isArchived,
      if (isFavorite != null) 'is_favorite': isFavorite,
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
    Value<int>? version,
    Value<int>? isArchived,
    Value<int>? isFavorite,
  }) {
    return NotebookUserCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      notebookId: notebookId ?? this.notebookId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      isArchived: isArchived ?? this.isArchived,
      isFavorite: isFavorite ?? this.isFavorite,
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
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<int>(isArchived.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<int>(isFavorite.value);
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
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('isArchived: $isArchived, ')
          ..write('isFavorite: $isFavorite')
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id) ON DELETE CASCADE',
    ),
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
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<int> isArchived = GeneratedColumn<int>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<int> isFavorite = GeneratedColumn<int>(
    'is_favorite',
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
    version,
    isArchived,
    isFavorite,
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
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
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
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_archived'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_favorite'],
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
  final int version;
  final int isArchived;
  final int isFavorite;
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
    required this.version,
    required this.isArchived,
    required this.isFavorite,
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
    map['version'] = Variable<int>(version);
    map['is_archived'] = Variable<int>(isArchived);
    map['is_favorite'] = Variable<int>(isFavorite);
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
      version: Value(version),
      isArchived: Value(isArchived),
      isFavorite: Value(isFavorite),
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
      version: serializer.fromJson<int>(json['version']),
      isArchived: serializer.fromJson<int>(json['isArchived']),
      isFavorite: serializer.fromJson<int>(json['isFavorite']),
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
      'version': serializer.toJson<int>(version),
      'isArchived': serializer.toJson<int>(isArchived),
      'isFavorite': serializer.toJson<int>(isFavorite),
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
    int? version,
    int? isArchived,
    int? isFavorite,
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
    version: version ?? this.version,
    isArchived: isArchived ?? this.isArchived,
    isFavorite: isFavorite ?? this.isFavorite,
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
      version: data.version.present ? data.version.value : this.version,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
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
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('isArchived: $isArchived, ')
          ..write('isFavorite: $isFavorite')
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
    version,
    isArchived,
    isFavorite,
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
          other.updatedAt == this.updatedAt &&
          other.version == this.version &&
          other.isArchived == this.isArchived &&
          other.isFavorite == this.isFavorite);
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
  final Value<int> version;
  final Value<int> isArchived;
  final Value<int> isFavorite;
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
    this.version = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isFavorite = const Value.absent(),
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
    this.version = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isFavorite = const Value.absent(),
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
    Expression<int>? version,
    Expression<int>? isArchived,
    Expression<int>? isFavorite,
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
      if (version != null) 'version': version,
      if (isArchived != null) 'is_archived': isArchived,
      if (isFavorite != null) 'is_favorite': isFavorite,
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
    Value<int>? version,
    Value<int>? isArchived,
    Value<int>? isFavorite,
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
      version: version ?? this.version,
      isArchived: isArchived ?? this.isArchived,
      isFavorite: isFavorite ?? this.isFavorite,
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
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<int>(isArchived.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<int>(isFavorite.value);
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
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('isArchived: $isArchived, ')
          ..write('isFavorite: $isFavorite')
          ..write(')'))
        .toString();
  }
}

class $LessonRecordingsTable extends LessonRecordings
    with TableInfo<$LessonRecordingsTable, LessonRecording> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonRecordingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _clientIdMeta = const VerificationMeta(
    'clientId',
  );
  @override
  late final GeneratedColumn<String> clientId = GeneratedColumn<String>(
    'client_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES notebooks (id) ON DELETE CASCADE',
    ),
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
  static const VerificationMeta _audioUrlMeta = const VerificationMeta(
    'audioUrl',
  );
  @override
  late final GeneratedColumn<String> audioUrl = GeneratedColumn<String>(
    'audio_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
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
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<int> isArchived = GeneratedColumn<int>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<int> isFavorite = GeneratedColumn<int>(
    'is_favorite',
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
    clientId,
    notebookId,
    title,
    audioUrl,
    durationSeconds,
    syncedWithCloud,
    updatedAt,
    version,
    isArchived,
    isFavorite,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lesson_recordings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LessonRecording> instance, {
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
    if (data.containsKey('client_id')) {
      context.handle(
        _clientIdMeta,
        clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta),
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
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('audio_url')) {
      context.handle(
        _audioUrlMeta,
        audioUrl.isAcceptableOrUnknown(data['audio_url']!, _audioUrlMeta),
      );
    } else if (isInserting) {
      context.missing(_audioUrlMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
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
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LessonRecording map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonRecording(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      clientId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_id'],
      ),
      notebookId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notebook_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      audioUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_url'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      syncedWithCloud: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_with_cloud'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_archived'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_favorite'],
      )!,
    );
  }

  @override
  $LessonRecordingsTable createAlias(String alias) {
    return $LessonRecordingsTable(attachedDatabase, alias);
  }
}

class LessonRecording extends DataClass implements Insertable<LessonRecording> {
  final int id;
  final int? serverId;
  final String? clientId;
  final int notebookId;
  final String title;
  final String audioUrl;
  final int durationSeconds;
  final int syncedWithCloud;
  final int updatedAt;
  final int version;
  final int isArchived;
  final int isFavorite;
  const LessonRecording({
    required this.id,
    this.serverId,
    this.clientId,
    required this.notebookId,
    required this.title,
    required this.audioUrl,
    required this.durationSeconds,
    required this.syncedWithCloud,
    required this.updatedAt,
    required this.version,
    required this.isArchived,
    required this.isFavorite,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<String>(clientId);
    }
    map['notebook_id'] = Variable<int>(notebookId);
    map['title'] = Variable<String>(title);
    map['audio_url'] = Variable<String>(audioUrl);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['synced_with_cloud'] = Variable<int>(syncedWithCloud);
    map['updated_at'] = Variable<int>(updatedAt);
    map['version'] = Variable<int>(version);
    map['is_archived'] = Variable<int>(isArchived);
    map['is_favorite'] = Variable<int>(isFavorite);
    return map;
  }

  LessonRecordingsCompanion toCompanion(bool nullToAbsent) {
    return LessonRecordingsCompanion(
      id: Value(id),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      notebookId: Value(notebookId),
      title: Value(title),
      audioUrl: Value(audioUrl),
      durationSeconds: Value(durationSeconds),
      syncedWithCloud: Value(syncedWithCloud),
      updatedAt: Value(updatedAt),
      version: Value(version),
      isArchived: Value(isArchived),
      isFavorite: Value(isFavorite),
    );
  }

  factory LessonRecording.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonRecording(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      clientId: serializer.fromJson<String?>(json['clientId']),
      notebookId: serializer.fromJson<int>(json['notebookId']),
      title: serializer.fromJson<String>(json['title']),
      audioUrl: serializer.fromJson<String>(json['audioUrl']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      syncedWithCloud: serializer.fromJson<int>(json['syncedWithCloud']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      version: serializer.fromJson<int>(json['version']),
      isArchived: serializer.fromJson<int>(json['isArchived']),
      isFavorite: serializer.fromJson<int>(json['isFavorite']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<int?>(serverId),
      'clientId': serializer.toJson<String?>(clientId),
      'notebookId': serializer.toJson<int>(notebookId),
      'title': serializer.toJson<String>(title),
      'audioUrl': serializer.toJson<String>(audioUrl),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'syncedWithCloud': serializer.toJson<int>(syncedWithCloud),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'version': serializer.toJson<int>(version),
      'isArchived': serializer.toJson<int>(isArchived),
      'isFavorite': serializer.toJson<int>(isFavorite),
    };
  }

  LessonRecording copyWith({
    int? id,
    Value<int?> serverId = const Value.absent(),
    Value<String?> clientId = const Value.absent(),
    int? notebookId,
    String? title,
    String? audioUrl,
    int? durationSeconds,
    int? syncedWithCloud,
    int? updatedAt,
    int? version,
    int? isArchived,
    int? isFavorite,
  }) => LessonRecording(
    id: id ?? this.id,
    serverId: serverId.present ? serverId.value : this.serverId,
    clientId: clientId.present ? clientId.value : this.clientId,
    notebookId: notebookId ?? this.notebookId,
    title: title ?? this.title,
    audioUrl: audioUrl ?? this.audioUrl,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
    isArchived: isArchived ?? this.isArchived,
    isFavorite: isFavorite ?? this.isFavorite,
  );
  LessonRecording copyWithCompanion(LessonRecordingsCompanion data) {
    return LessonRecording(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      notebookId: data.notebookId.present
          ? data.notebookId.value
          : this.notebookId,
      title: data.title.present ? data.title.value : this.title,
      audioUrl: data.audioUrl.present ? data.audioUrl.value : this.audioUrl,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      syncedWithCloud: data.syncedWithCloud.present
          ? data.syncedWithCloud.value
          : this.syncedWithCloud,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonRecording(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('clientId: $clientId, ')
          ..write('notebookId: $notebookId, ')
          ..write('title: $title, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('isArchived: $isArchived, ')
          ..write('isFavorite: $isFavorite')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    clientId,
    notebookId,
    title,
    audioUrl,
    durationSeconds,
    syncedWithCloud,
    updatedAt,
    version,
    isArchived,
    isFavorite,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonRecording &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.clientId == this.clientId &&
          other.notebookId == this.notebookId &&
          other.title == this.title &&
          other.audioUrl == this.audioUrl &&
          other.durationSeconds == this.durationSeconds &&
          other.syncedWithCloud == this.syncedWithCloud &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version &&
          other.isArchived == this.isArchived &&
          other.isFavorite == this.isFavorite);
}

class LessonRecordingsCompanion extends UpdateCompanion<LessonRecording> {
  final Value<int> id;
  final Value<int?> serverId;
  final Value<String?> clientId;
  final Value<int> notebookId;
  final Value<String> title;
  final Value<String> audioUrl;
  final Value<int> durationSeconds;
  final Value<int> syncedWithCloud;
  final Value<int> updatedAt;
  final Value<int> version;
  final Value<int> isArchived;
  final Value<int> isFavorite;
  const LessonRecordingsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.notebookId = const Value.absent(),
    this.title = const Value.absent(),
    this.audioUrl = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isFavorite = const Value.absent(),
  });
  LessonRecordingsCompanion.insert({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.clientId = const Value.absent(),
    required int notebookId,
    required String title,
    required String audioUrl,
    this.durationSeconds = const Value.absent(),
    this.syncedWithCloud = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isFavorite = const Value.absent(),
  }) : notebookId = Value(notebookId),
       title = Value(title),
       audioUrl = Value(audioUrl);
  static Insertable<LessonRecording> custom({
    Expression<int>? id,
    Expression<int>? serverId,
    Expression<String>? clientId,
    Expression<int>? notebookId,
    Expression<String>? title,
    Expression<String>? audioUrl,
    Expression<int>? durationSeconds,
    Expression<int>? syncedWithCloud,
    Expression<int>? updatedAt,
    Expression<int>? version,
    Expression<int>? isArchived,
    Expression<int>? isFavorite,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (clientId != null) 'client_id': clientId,
      if (notebookId != null) 'notebook_id': notebookId,
      if (title != null) 'title': title,
      if (audioUrl != null) 'audio_url': audioUrl,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (syncedWithCloud != null) 'synced_with_cloud': syncedWithCloud,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (isArchived != null) 'is_archived': isArchived,
      if (isFavorite != null) 'is_favorite': isFavorite,
    });
  }

  LessonRecordingsCompanion copyWith({
    Value<int>? id,
    Value<int?>? serverId,
    Value<String?>? clientId,
    Value<int>? notebookId,
    Value<String>? title,
    Value<String>? audioUrl,
    Value<int>? durationSeconds,
    Value<int>? syncedWithCloud,
    Value<int>? updatedAt,
    Value<int>? version,
    Value<int>? isArchived,
    Value<int>? isFavorite,
  }) {
    return LessonRecordingsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      clientId: clientId ?? this.clientId,
      notebookId: notebookId ?? this.notebookId,
      title: title ?? this.title,
      audioUrl: audioUrl ?? this.audioUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      isArchived: isArchived ?? this.isArchived,
      isFavorite: isFavorite ?? this.isFavorite,
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
    if (clientId.present) {
      map['client_id'] = Variable<String>(clientId.value);
    }
    if (notebookId.present) {
      map['notebook_id'] = Variable<int>(notebookId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (audioUrl.present) {
      map['audio_url'] = Variable<String>(audioUrl.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (syncedWithCloud.present) {
      map['synced_with_cloud'] = Variable<int>(syncedWithCloud.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<int>(isArchived.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<int>(isFavorite.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonRecordingsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('clientId: $clientId, ')
          ..write('notebookId: $notebookId, ')
          ..write('title: $title, ')
          ..write('audioUrl: $audioUrl, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('syncedWithCloud: $syncedWithCloud, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('isArchived: $isArchived, ')
          ..write('isFavorite: $isFavorite')
          ..write(')'))
        .toString();
  }
}

class $NotebookTemplatesTable extends NotebookTemplates
    with TableInfo<$NotebookTemplatesTable, NotebookTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotebookTemplatesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _coverMeta = const VerificationMeta('cover');
  @override
  late final GeneratedColumn<String> cover = GeneratedColumn<String>(
    'cover',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSystemMeta = const VerificationMeta(
    'isSystem',
  );
  @override
  late final GeneratedColumn<int> isSystem = GeneratedColumn<int>(
    'is_system',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<int> createdBy = GeneratedColumn<int>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    category,
    icon,
    cover,
    isSystem,
    createdBy,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notebook_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotebookTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
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
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('cover')) {
      context.handle(
        _coverMeta,
        cover.isAcceptableOrUnknown(data['cover']!, _coverMeta),
      );
    }
    if (data.containsKey('is_system')) {
      context.handle(
        _isSystemMeta,
        isSystem.isAcceptableOrUnknown(data['is_system']!, _isSystemMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotebookTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotebookTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      cover: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover'],
      ),
      isSystem: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_system'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_by'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $NotebookTemplatesTable createAlias(String alias) {
    return $NotebookTemplatesTable(attachedDatabase, alias);
  }
}

class NotebookTemplate extends DataClass
    implements Insertable<NotebookTemplate> {
  final int id;
  final String name;
  final String? description;
  final String? category;
  final String? icon;
  final String? cover;
  final int isSystem;
  final int? createdBy;
  final int createdAt;
  final int updatedAt;
  const NotebookTemplate({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.icon,
    this.cover,
    required this.isSystem,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || cover != null) {
      map['cover'] = Variable<String>(cover);
    }
    map['is_system'] = Variable<int>(isSystem);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<int>(createdBy);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  NotebookTemplatesCompanion toCompanion(bool nullToAbsent) {
    return NotebookTemplatesCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      cover: cover == null && nullToAbsent
          ? const Value.absent()
          : Value(cover),
      isSystem: Value(isSystem),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory NotebookTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotebookTemplate(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      category: serializer.fromJson<String?>(json['category']),
      icon: serializer.fromJson<String?>(json['icon']),
      cover: serializer.fromJson<String?>(json['cover']),
      isSystem: serializer.fromJson<int>(json['isSystem']),
      createdBy: serializer.fromJson<int?>(json['createdBy']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'category': serializer.toJson<String?>(category),
      'icon': serializer.toJson<String?>(icon),
      'cover': serializer.toJson<String?>(cover),
      'isSystem': serializer.toJson<int>(isSystem),
      'createdBy': serializer.toJson<int?>(createdBy),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  NotebookTemplate copyWith({
    int? id,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> category = const Value.absent(),
    Value<String?> icon = const Value.absent(),
    Value<String?> cover = const Value.absent(),
    int? isSystem,
    Value<int?> createdBy = const Value.absent(),
    int? createdAt,
    int? updatedAt,
  }) => NotebookTemplate(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    category: category.present ? category.value : this.category,
    icon: icon.present ? icon.value : this.icon,
    cover: cover.present ? cover.value : this.cover,
    isSystem: isSystem ?? this.isSystem,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  NotebookTemplate copyWithCompanion(NotebookTemplatesCompanion data) {
    return NotebookTemplate(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      category: data.category.present ? data.category.value : this.category,
      icon: data.icon.present ? data.icon.value : this.icon,
      cover: data.cover.present ? data.cover.value : this.cover,
      isSystem: data.isSystem.present ? data.isSystem.value : this.isSystem,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotebookTemplate(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('icon: $icon, ')
          ..write('cover: $cover, ')
          ..write('isSystem: $isSystem, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    category,
    icon,
    cover,
    isSystem,
    createdBy,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotebookTemplate &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.category == this.category &&
          other.icon == this.icon &&
          other.cover == this.cover &&
          other.isSystem == this.isSystem &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class NotebookTemplatesCompanion extends UpdateCompanion<NotebookTemplate> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> category;
  final Value<String?> icon;
  final Value<String?> cover;
  final Value<int> isSystem;
  final Value<int?> createdBy;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const NotebookTemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.icon = const Value.absent(),
    this.cover = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  NotebookTemplatesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.icon = const Value.absent(),
    this.cover = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.createdBy = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<NotebookTemplate> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? category,
    Expression<String>? icon,
    Expression<String>? cover,
    Expression<int>? isSystem,
    Expression<int>? createdBy,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (icon != null) 'icon': icon,
      if (cover != null) 'cover': cover,
      if (isSystem != null) 'is_system': isSystem,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  NotebookTemplatesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? category,
    Value<String?>? icon,
    Value<String?>? cover,
    Value<int>? isSystem,
    Value<int?>? createdBy,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return NotebookTemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      cover: cover ?? this.cover,
      isSystem: isSystem ?? this.isSystem,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (cover.present) {
      map['cover'] = Variable<String>(cover.value);
    }
    if (isSystem.present) {
      map['is_system'] = Variable<int>(isSystem.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<int>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotebookTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('icon: $icon, ')
          ..write('cover: $cover, ')
          ..write('isSystem: $isSystem, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $NotebookTemplateVersionsTable extends NotebookTemplateVersions
    with TableInfo<$NotebookTemplateVersionsTable, NotebookTemplateVersion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NotebookTemplateVersionsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<int> templateId = GeneratedColumn<int>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES notebook_templates (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _configurationMeta = const VerificationMeta(
    'configuration',
  );
  @override
  late final GeneratedColumn<String> configuration = GeneratedColumn<String>(
    'configuration',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    templateId,
    version,
    configuration,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notebook_template_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotebookTemplateVersion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('configuration')) {
      context.handle(
        _configurationMeta,
        configuration.isAcceptableOrUnknown(
          data['configuration']!,
          _configurationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_configurationMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NotebookTemplateVersion map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotebookTemplateVersion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      configuration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}configuration'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $NotebookTemplateVersionsTable createAlias(String alias) {
    return $NotebookTemplateVersionsTable(attachedDatabase, alias);
  }
}

class NotebookTemplateVersion extends DataClass
    implements Insertable<NotebookTemplateVersion> {
  final int id;
  final int templateId;
  final int version;
  final String configuration;
  final int createdAt;
  final int updatedAt;
  const NotebookTemplateVersion({
    required this.id,
    required this.templateId,
    required this.version,
    required this.configuration,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['template_id'] = Variable<int>(templateId);
    map['version'] = Variable<int>(version);
    map['configuration'] = Variable<String>(configuration);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  NotebookTemplateVersionsCompanion toCompanion(bool nullToAbsent) {
    return NotebookTemplateVersionsCompanion(
      id: Value(id),
      templateId: Value(templateId),
      version: Value(version),
      configuration: Value(configuration),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory NotebookTemplateVersion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotebookTemplateVersion(
      id: serializer.fromJson<int>(json['id']),
      templateId: serializer.fromJson<int>(json['templateId']),
      version: serializer.fromJson<int>(json['version']),
      configuration: serializer.fromJson<String>(json['configuration']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'templateId': serializer.toJson<int>(templateId),
      'version': serializer.toJson<int>(version),
      'configuration': serializer.toJson<String>(configuration),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  NotebookTemplateVersion copyWith({
    int? id,
    int? templateId,
    int? version,
    String? configuration,
    int? createdAt,
    int? updatedAt,
  }) => NotebookTemplateVersion(
    id: id ?? this.id,
    templateId: templateId ?? this.templateId,
    version: version ?? this.version,
    configuration: configuration ?? this.configuration,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  NotebookTemplateVersion copyWithCompanion(
    NotebookTemplateVersionsCompanion data,
  ) {
    return NotebookTemplateVersion(
      id: data.id.present ? data.id.value : this.id,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      version: data.version.present ? data.version.value : this.version,
      configuration: data.configuration.present
          ? data.configuration.value
          : this.configuration,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotebookTemplateVersion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('version: $version, ')
          ..write('configuration: $configuration, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, templateId, version, configuration, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotebookTemplateVersion &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.version == this.version &&
          other.configuration == this.configuration &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class NotebookTemplateVersionsCompanion
    extends UpdateCompanion<NotebookTemplateVersion> {
  final Value<int> id;
  final Value<int> templateId;
  final Value<int> version;
  final Value<String> configuration;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const NotebookTemplateVersionsCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.version = const Value.absent(),
    this.configuration = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  NotebookTemplateVersionsCompanion.insert({
    this.id = const Value.absent(),
    required int templateId,
    required int version,
    required String configuration,
    required int createdAt,
    required int updatedAt,
  }) : templateId = Value(templateId),
       version = Value(version),
       configuration = Value(configuration),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<NotebookTemplateVersion> custom({
    Expression<int>? id,
    Expression<int>? templateId,
    Expression<int>? version,
    Expression<String>? configuration,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (version != null) 'version': version,
      if (configuration != null) 'configuration': configuration,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  NotebookTemplateVersionsCompanion copyWith({
    Value<int>? id,
    Value<int>? templateId,
    Value<int>? version,
    Value<String>? configuration,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return NotebookTemplateVersionsCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      version: version ?? this.version,
      configuration: configuration ?? this.configuration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<int>(templateId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (configuration.present) {
      map['configuration'] = Variable<String>(configuration.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotebookTemplateVersionsCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('version: $version, ')
          ..write('configuration: $configuration, ')
          ..write('createdAt: $createdAt, ')
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
  late final $LessonRecordingsTable lessonRecordings = $LessonRecordingsTable(
    this,
  );
  late final $NotebookTemplatesTable notebookTemplates =
      $NotebookTemplatesTable(this);
  late final $NotebookTemplateVersionsTable notebookTemplateVersions =
      $NotebookTemplateVersionsTable(this);
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
    lessonRecordings,
    notebookTemplates,
    notebookTemplateVersions,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('subjects', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'subjects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('notebooks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'notebooks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('pages', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'pages',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('canvas_strokes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'pages',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('canvas_text_blocks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'pages',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('canvas_image_blocks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'notebooks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('notebook_user', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('notebook_user', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'users',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('payments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'notebooks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lesson_recordings', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'notebook_templates',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('notebook_template_versions', kind: UpdateKind.delete),
      ],
    ),
  ]);
}

typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      required String name,
      required String email,
      Value<String?> avatar,
      Value<String> planType,
      Value<String?> bio,
      Value<String?> institution,
      Value<String?> preferredColor,
      Value<String?> preferredFont,
      Value<String?> specialties,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
      Value<int> version,
      Value<int> isArchived,
      Value<int> isFavorite,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<String> name,
      Value<String> email,
      Value<String?> avatar,
      Value<String> planType,
      Value<String?> bio,
      Value<String?> institution,
      Value<String?> preferredColor,
      Value<String?> preferredFont,
      Value<String?> specialties,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
      Value<int> version,
      Value<int> isArchived,
      Value<int> isFavorite,
    });

final class $$UsersTableReferences
    extends BaseReferences<_$AppDatabase, $UsersTable, User> {
  $$UsersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SubjectsTable, List<Subject>> _subjectsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.subjects,
    aliasName: 'users__id__subjects__user_id',
  );

  $$SubjectsTableProcessedTableManager get subjectsRefs {
    final manager = $$SubjectsTableTableManager(
      $_db,
      $_db.subjects,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_subjectsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$NotebookUserTable, List<NotebookUserData>>
  _notebookUserRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.notebookUser,
    aliasName: 'users__id__notebook_user__user_id',
  );

  $$NotebookUserTableProcessedTableManager get notebookUserRefs {
    final manager = $$NotebookUserTableTableManager(
      $_db,
      $_db.notebookUser,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_notebookUserRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PaymentsTable, List<Payment>> _paymentsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.payments,
    aliasName: 'users__id__payments__user_id',
  );

  $$PaymentsTableProcessedTableManager get paymentsRefs {
    final manager = $$PaymentsTableTableManager(
      $_db,
      $_db.payments,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_paymentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

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

  ColumnFilters<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get institution => $composableBuilder(
    column: $table.institution,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredColor => $composableBuilder(
    column: $table.preferredColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredFont => $composableBuilder(
    column: $table.preferredFont,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get specialties => $composableBuilder(
    column: $table.specialties,
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

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> subjectsRefs(
    Expression<bool> Function($$SubjectsTableFilterComposer f) f,
  ) {
    final $$SubjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableFilterComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> notebookUserRefs(
    Expression<bool> Function($$NotebookUserTableFilterComposer f) f,
  ) {
    final $$NotebookUserTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notebookUser,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebookUserTableFilterComposer(
            $db: $db,
            $table: $db.notebookUser,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> paymentsRefs(
    Expression<bool> Function($$PaymentsTableFilterComposer f) f,
  ) {
    final $$PaymentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payments,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentsTableFilterComposer(
            $db: $db,
            $table: $db.payments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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

  ColumnOrderings<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get institution => $composableBuilder(
    column: $table.institution,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredColor => $composableBuilder(
    column: $table.preferredColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredFont => $composableBuilder(
    column: $table.preferredFont,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get specialties => $composableBuilder(
    column: $table.specialties,
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

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
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

  GeneratedColumn<String> get bio =>
      $composableBuilder(column: $table.bio, builder: (column) => column);

  GeneratedColumn<String> get institution => $composableBuilder(
    column: $table.institution,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preferredColor => $composableBuilder(
    column: $table.preferredColor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preferredFont => $composableBuilder(
    column: $table.preferredFont,
    builder: (column) => column,
  );

  GeneratedColumn<String> get specialties => $composableBuilder(
    column: $table.specialties,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  Expression<T> subjectsRefs<T extends Object>(
    Expression<T> Function($$SubjectsTableAnnotationComposer a) f,
  ) {
    final $$SubjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> notebookUserRefs<T extends Object>(
    Expression<T> Function($$NotebookUserTableAnnotationComposer a) f,
  ) {
    final $$NotebookUserTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notebookUser,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebookUserTableAnnotationComposer(
            $db: $db,
            $table: $db.notebookUser,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> paymentsRefs<T extends Object>(
    Expression<T> Function($$PaymentsTableAnnotationComposer a) f,
  ) {
    final $$PaymentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payments,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentsTableAnnotationComposer(
            $db: $db,
            $table: $db.payments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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
          (User, $$UsersTableReferences),
          User,
          PrefetchHooks Function({
            bool subjectsRefs,
            bool notebookUserRefs,
            bool paymentsRefs,
          })
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
                Value<String?> bio = const Value.absent(),
                Value<String?> institution = const Value.absent(),
                Value<String?> preferredColor = const Value.absent(),
                Value<String?> preferredFont = const Value.absent(),
                Value<String?> specialties = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> isArchived = const Value.absent(),
                Value<int> isFavorite = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                serverId: serverId,
                name: name,
                email: email,
                avatar: avatar,
                planType: planType,
                bio: bio,
                institution: institution,
                preferredColor: preferredColor,
                preferredFont: preferredFont,
                specialties: specialties,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
                version: version,
                isArchived: isArchived,
                isFavorite: isFavorite,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                required String name,
                required String email,
                Value<String?> avatar = const Value.absent(),
                Value<String> planType = const Value.absent(),
                Value<String?> bio = const Value.absent(),
                Value<String?> institution = const Value.absent(),
                Value<String?> preferredColor = const Value.absent(),
                Value<String?> preferredFont = const Value.absent(),
                Value<String?> specialties = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> isArchived = const Value.absent(),
                Value<int> isFavorite = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                serverId: serverId,
                name: name,
                email: email,
                avatar: avatar,
                planType: planType,
                bio: bio,
                institution: institution,
                preferredColor: preferredColor,
                preferredFont: preferredFont,
                specialties: specialties,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
                version: version,
                isArchived: isArchived,
                isFavorite: isFavorite,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$UsersTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                subjectsRefs = false,
                notebookUserRefs = false,
                paymentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (subjectsRefs) db.subjects,
                    if (notebookUserRefs) db.notebookUser,
                    if (paymentsRefs) db.payments,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (subjectsRefs)
                        await $_getPrefetchedData<User, $UsersTable, Subject>(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._subjectsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(
                                db,
                                table,
                                p0,
                              ).subjectsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (notebookUserRefs)
                        await $_getPrefetchedData<
                          User,
                          $UsersTable,
                          NotebookUserData
                        >(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._notebookUserRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(
                                db,
                                table,
                                p0,
                              ).notebookUserRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (paymentsRefs)
                        await $_getPrefetchedData<User, $UsersTable, Payment>(
                          currentTable: table,
                          referencedTable: $$UsersTableReferences
                              ._paymentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$UsersTableReferences(
                                db,
                                table,
                                p0,
                              ).paymentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
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
      (User, $$UsersTableReferences),
      User,
      PrefetchHooks Function({
        bool subjectsRefs,
        bool notebookUserRefs,
        bool paymentsRefs,
      })
    >;
typedef $$SubjectsTableCreateCompanionBuilder =
    SubjectsCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<String?> clientId,
      required int userId,
      required String name,
      required String color,
      Value<String?> icon,
      Value<int> isDeleted,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
      Value<int> version,
      Value<int> isArchived,
      Value<int> isFavorite,
    });
typedef $$SubjectsTableUpdateCompanionBuilder =
    SubjectsCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<String?> clientId,
      Value<int> userId,
      Value<String> name,
      Value<String> color,
      Value<String?> icon,
      Value<int> isDeleted,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
      Value<int> version,
      Value<int> isArchived,
      Value<int> isFavorite,
    });

final class $$SubjectsTableReferences
    extends BaseReferences<_$AppDatabase, $SubjectsTable, Subject> {
  $$SubjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) =>
      db.users.createAlias('subjects__user_id__users__id');

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$NotebooksTable, List<Notebook>>
  _notebooksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.notebooks,
    aliasName: 'subjects__id__notebooks__subject_id',
  );

  $$NotebooksTableProcessedTableManager get notebooksRefs {
    final manager = $$NotebooksTableTableManager(
      $_db,
      $_db.notebooks,
    ).filter((f) => f.subjectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_notebooksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

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

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
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

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> notebooksRefs(
    Expression<bool> Function($$NotebooksTableFilterComposer f) f,
  ) {
    final $$NotebooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notebooks,
      getReferencedColumn: (t) => t.subjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebooksTableFilterComposer(
            $db: $db,
            $table: $db.notebooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
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

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

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

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> notebooksRefs<T extends Object>(
    Expression<T> Function($$NotebooksTableAnnotationComposer a) f,
  ) {
    final $$NotebooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notebooks,
      getReferencedColumn: (t) => t.subjectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebooksTableAnnotationComposer(
            $db: $db,
            $table: $db.notebooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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
          (Subject, $$SubjectsTableReferences),
          Subject,
          PrefetchHooks Function({bool userId, bool notebooksRefs})
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
                Value<String?> clientId = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> isArchived = const Value.absent(),
                Value<int> isFavorite = const Value.absent(),
              }) => SubjectsCompanion(
                id: id,
                serverId: serverId,
                clientId: clientId,
                userId: userId,
                name: name,
                color: color,
                icon: icon,
                isDeleted: isDeleted,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
                version: version,
                isArchived: isArchived,
                isFavorite: isFavorite,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                required int userId,
                required String name,
                required String color,
                Value<String?> icon = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> isArchived = const Value.absent(),
                Value<int> isFavorite = const Value.absent(),
              }) => SubjectsCompanion.insert(
                id: id,
                serverId: serverId,
                clientId: clientId,
                userId: userId,
                name: name,
                color: color,
                icon: icon,
                isDeleted: isDeleted,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
                version: version,
                isArchived: isArchived,
                isFavorite: isFavorite,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SubjectsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false, notebooksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (notebooksRefs) db.notebooks],
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
                    if (userId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.userId,
                                referencedTable: $$SubjectsTableReferences
                                    ._userIdTable(db),
                                referencedColumn: $$SubjectsTableReferences
                                    ._userIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (notebooksRefs)
                    await $_getPrefetchedData<
                      Subject,
                      $SubjectsTable,
                      Notebook
                    >(
                      currentTable: table,
                      referencedTable: $$SubjectsTableReferences
                          ._notebooksRefsTable(db),
                      managerFromTypedResult: (p0) => $$SubjectsTableReferences(
                        db,
                        table,
                        p0,
                      ).notebooksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.subjectId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
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
      (Subject, $$SubjectsTableReferences),
      Subject,
      PrefetchHooks Function({bool userId, bool notebooksRefs})
    >;
typedef $$NotebooksTableCreateCompanionBuilder =
    NotebooksCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<String?> clientId,
      Value<int?> subjectId,
      required String title,
      required String coverType,
      Value<String?> color,
      Value<String?> coverImage,
      Value<int> isPublished,
      Value<double> price,
      Value<String?> description,
      Value<String?> authorName,
      Value<int> isDeleted,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
      Value<int> version,
      Value<String> templateType,
      Value<String> collaborationMode,
      Value<String> role,
      Value<String?> alternativeTitle,
      Value<String> sharingType,
      Value<String?> tags,
      Value<int> isArchived,
      Value<int> isFavorite,
      Value<String?> origin,
      Value<String?> participantsPreview,
      Value<String?> lastUpdatedByName,
      Value<int> notificationsEnabled,
      Value<String?> configuration,
    });
typedef $$NotebooksTableUpdateCompanionBuilder =
    NotebooksCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<String?> clientId,
      Value<int?> subjectId,
      Value<String> title,
      Value<String> coverType,
      Value<String?> color,
      Value<String?> coverImage,
      Value<int> isPublished,
      Value<double> price,
      Value<String?> description,
      Value<String?> authorName,
      Value<int> isDeleted,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
      Value<int> version,
      Value<String> templateType,
      Value<String> collaborationMode,
      Value<String> role,
      Value<String?> alternativeTitle,
      Value<String> sharingType,
      Value<String?> tags,
      Value<int> isArchived,
      Value<int> isFavorite,
      Value<String?> origin,
      Value<String?> participantsPreview,
      Value<String?> lastUpdatedByName,
      Value<int> notificationsEnabled,
      Value<String?> configuration,
    });

final class $$NotebooksTableReferences
    extends BaseReferences<_$AppDatabase, $NotebooksTable, Notebook> {
  $$NotebooksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SubjectsTable _subjectIdTable(_$AppDatabase db) =>
      db.subjects.createAlias('notebooks__subject_id__subjects__id');

  $$SubjectsTableProcessedTableManager? get subjectId {
    final $_column = $_itemColumn<int>('subject_id');
    if ($_column == null) return null;
    final manager = $$SubjectsTableTableManager(
      $_db,
      $_db.subjects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_subjectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PagesTable, List<Page>> _pagesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.pages,
    aliasName: 'notebooks__id__pages__notebook_id',
  );

  $$PagesTableProcessedTableManager get pagesRefs {
    final manager = $$PagesTableTableManager(
      $_db,
      $_db.pages,
    ).filter((f) => f.notebookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_pagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$NotebookUserTable, List<NotebookUserData>>
  _notebookUserRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.notebookUser,
    aliasName: 'notebooks__id__notebook_user__notebook_id',
  );

  $$NotebookUserTableProcessedTableManager get notebookUserRefs {
    final manager = $$NotebookUserTableTableManager(
      $_db,
      $_db.notebookUser,
    ).filter((f) => f.notebookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_notebookUserRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LessonRecordingsTable, List<LessonRecording>>
  _lessonRecordingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.lessonRecordings,
    aliasName: 'notebooks__id__lesson_recordings__notebook_id',
  );

  $$LessonRecordingsTableProcessedTableManager get lessonRecordingsRefs {
    final manager = $$LessonRecordingsTableTableManager(
      $_db,
      $_db.lessonRecordings,
    ).filter((f) => f.notebookId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _lessonRecordingsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

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

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
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

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateType => $composableBuilder(
    column: $table.templateType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collaborationMode => $composableBuilder(
    column: $table.collaborationMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alternativeTitle => $composableBuilder(
    column: $table.alternativeTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sharingType => $composableBuilder(
    column: $table.sharingType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get participantsPreview => $composableBuilder(
    column: $table.participantsPreview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastUpdatedByName => $composableBuilder(
    column: $table.lastUpdatedByName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get configuration => $composableBuilder(
    column: $table.configuration,
    builder: (column) => ColumnFilters(column),
  );

  $$SubjectsTableFilterComposer get subjectId {
    final $$SubjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableFilterComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> pagesRefs(
    Expression<bool> Function($$PagesTableFilterComposer f) f,
  ) {
    final $$PagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pages,
      getReferencedColumn: (t) => t.notebookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableFilterComposer(
            $db: $db,
            $table: $db.pages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> notebookUserRefs(
    Expression<bool> Function($$NotebookUserTableFilterComposer f) f,
  ) {
    final $$NotebookUserTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notebookUser,
      getReferencedColumn: (t) => t.notebookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebookUserTableFilterComposer(
            $db: $db,
            $table: $db.notebookUser,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> lessonRecordingsRefs(
    Expression<bool> Function($$LessonRecordingsTableFilterComposer f) f,
  ) {
    final $$LessonRecordingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lessonRecordings,
      getReferencedColumn: (t) => t.notebookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LessonRecordingsTableFilterComposer(
            $db: $db,
            $table: $db.lessonRecordings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
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

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateType => $composableBuilder(
    column: $table.templateType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collaborationMode => $composableBuilder(
    column: $table.collaborationMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alternativeTitle => $composableBuilder(
    column: $table.alternativeTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sharingType => $composableBuilder(
    column: $table.sharingType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get participantsPreview => $composableBuilder(
    column: $table.participantsPreview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastUpdatedByName => $composableBuilder(
    column: $table.lastUpdatedByName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get configuration => $composableBuilder(
    column: $table.configuration,
    builder: (column) => ColumnOrderings(column),
  );

  $$SubjectsTableOrderingComposer get subjectId {
    final $$SubjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableOrderingComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

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

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get templateType => $composableBuilder(
    column: $table.templateType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get collaborationMode => $composableBuilder(
    column: $table.collaborationMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get alternativeTitle => $composableBuilder(
    column: $table.alternativeTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sharingType => $composableBuilder(
    column: $table.sharingType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<int> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get participantsPreview => $composableBuilder(
    column: $table.participantsPreview,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastUpdatedByName => $composableBuilder(
    column: $table.lastUpdatedByName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<String> get configuration => $composableBuilder(
    column: $table.configuration,
    builder: (column) => column,
  );

  $$SubjectsTableAnnotationComposer get subjectId {
    final $$SubjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.subjectId,
      referencedTable: $db.subjects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SubjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.subjects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> pagesRefs<T extends Object>(
    Expression<T> Function($$PagesTableAnnotationComposer a) f,
  ) {
    final $$PagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pages,
      getReferencedColumn: (t) => t.notebookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableAnnotationComposer(
            $db: $db,
            $table: $db.pages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> notebookUserRefs<T extends Object>(
    Expression<T> Function($$NotebookUserTableAnnotationComposer a) f,
  ) {
    final $$NotebookUserTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.notebookUser,
      getReferencedColumn: (t) => t.notebookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebookUserTableAnnotationComposer(
            $db: $db,
            $table: $db.notebookUser,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> lessonRecordingsRefs<T extends Object>(
    Expression<T> Function($$LessonRecordingsTableAnnotationComposer a) f,
  ) {
    final $$LessonRecordingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lessonRecordings,
      getReferencedColumn: (t) => t.notebookId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LessonRecordingsTableAnnotationComposer(
            $db: $db,
            $table: $db.lessonRecordings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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
          (Notebook, $$NotebooksTableReferences),
          Notebook,
          PrefetchHooks Function({
            bool subjectId,
            bool pagesRefs,
            bool notebookUserRefs,
            bool lessonRecordingsRefs,
          })
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
                Value<String?> clientId = const Value.absent(),
                Value<int?> subjectId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> coverType = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<String?> coverImage = const Value.absent(),
                Value<int> isPublished = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> authorName = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> templateType = const Value.absent(),
                Value<String> collaborationMode = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String?> alternativeTitle = const Value.absent(),
                Value<String> sharingType = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<int> isArchived = const Value.absent(),
                Value<int> isFavorite = const Value.absent(),
                Value<String?> origin = const Value.absent(),
                Value<String?> participantsPreview = const Value.absent(),
                Value<String?> lastUpdatedByName = const Value.absent(),
                Value<int> notificationsEnabled = const Value.absent(),
                Value<String?> configuration = const Value.absent(),
              }) => NotebooksCompanion(
                id: id,
                serverId: serverId,
                clientId: clientId,
                subjectId: subjectId,
                title: title,
                coverType: coverType,
                color: color,
                coverImage: coverImage,
                isPublished: isPublished,
                price: price,
                description: description,
                authorName: authorName,
                isDeleted: isDeleted,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
                version: version,
                templateType: templateType,
                collaborationMode: collaborationMode,
                role: role,
                alternativeTitle: alternativeTitle,
                sharingType: sharingType,
                tags: tags,
                isArchived: isArchived,
                isFavorite: isFavorite,
                origin: origin,
                participantsPreview: participantsPreview,
                lastUpdatedByName: lastUpdatedByName,
                notificationsEnabled: notificationsEnabled,
                configuration: configuration,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<int?> subjectId = const Value.absent(),
                required String title,
                required String coverType,
                Value<String?> color = const Value.absent(),
                Value<String?> coverImage = const Value.absent(),
                Value<int> isPublished = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> authorName = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> templateType = const Value.absent(),
                Value<String> collaborationMode = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String?> alternativeTitle = const Value.absent(),
                Value<String> sharingType = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<int> isArchived = const Value.absent(),
                Value<int> isFavorite = const Value.absent(),
                Value<String?> origin = const Value.absent(),
                Value<String?> participantsPreview = const Value.absent(),
                Value<String?> lastUpdatedByName = const Value.absent(),
                Value<int> notificationsEnabled = const Value.absent(),
                Value<String?> configuration = const Value.absent(),
              }) => NotebooksCompanion.insert(
                id: id,
                serverId: serverId,
                clientId: clientId,
                subjectId: subjectId,
                title: title,
                coverType: coverType,
                color: color,
                coverImage: coverImage,
                isPublished: isPublished,
                price: price,
                description: description,
                authorName: authorName,
                isDeleted: isDeleted,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
                version: version,
                templateType: templateType,
                collaborationMode: collaborationMode,
                role: role,
                alternativeTitle: alternativeTitle,
                sharingType: sharingType,
                tags: tags,
                isArchived: isArchived,
                isFavorite: isFavorite,
                origin: origin,
                participantsPreview: participantsPreview,
                lastUpdatedByName: lastUpdatedByName,
                notificationsEnabled: notificationsEnabled,
                configuration: configuration,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$NotebooksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                subjectId = false,
                pagesRefs = false,
                notebookUserRefs = false,
                lessonRecordingsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (pagesRefs) db.pages,
                    if (notebookUserRefs) db.notebookUser,
                    if (lessonRecordingsRefs) db.lessonRecordings,
                  ],
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
                        if (subjectId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.subjectId,
                                    referencedTable: $$NotebooksTableReferences
                                        ._subjectIdTable(db),
                                    referencedColumn: $$NotebooksTableReferences
                                        ._subjectIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (pagesRefs)
                        await $_getPrefetchedData<
                          Notebook,
                          $NotebooksTable,
                          Page
                        >(
                          currentTable: table,
                          referencedTable: $$NotebooksTableReferences
                              ._pagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NotebooksTableReferences(
                                db,
                                table,
                                p0,
                              ).pagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.notebookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (notebookUserRefs)
                        await $_getPrefetchedData<
                          Notebook,
                          $NotebooksTable,
                          NotebookUserData
                        >(
                          currentTable: table,
                          referencedTable: $$NotebooksTableReferences
                              ._notebookUserRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NotebooksTableReferences(
                                db,
                                table,
                                p0,
                              ).notebookUserRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.notebookId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (lessonRecordingsRefs)
                        await $_getPrefetchedData<
                          Notebook,
                          $NotebooksTable,
                          LessonRecording
                        >(
                          currentTable: table,
                          referencedTable: $$NotebooksTableReferences
                              ._lessonRecordingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NotebooksTableReferences(
                                db,
                                table,
                                p0,
                              ).lessonRecordingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.notebookId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
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
      (Notebook, $$NotebooksTableReferences),
      Notebook,
      PrefetchHooks Function({
        bool subjectId,
        bool pagesRefs,
        bool notebookUserRefs,
        bool lessonRecordingsRefs,
      })
    >;
typedef $$PagesTableCreateCompanionBuilder =
    PagesCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<String?> clientId,
      required int notebookId,
      required int pageNumber,
      Value<int> isLandscape,
      Value<String?> headerData,
      Value<String?> footerData,
      Value<String?> extractedText,
      Value<int> isDeleted,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
      Value<int> version,
      Value<int> isFrozen,
      Value<int> isFavorite,
      Value<String> paperSize,
      Value<String?> lineType,
      Value<double?> lineSpacing,
      Value<String?> backgroundPdfPath,
      Value<String?> backgroundConfig,
    });
typedef $$PagesTableUpdateCompanionBuilder =
    PagesCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<String?> clientId,
      Value<int> notebookId,
      Value<int> pageNumber,
      Value<int> isLandscape,
      Value<String?> headerData,
      Value<String?> footerData,
      Value<String?> extractedText,
      Value<int> isDeleted,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
      Value<int> version,
      Value<int> isFrozen,
      Value<int> isFavorite,
      Value<String> paperSize,
      Value<String?> lineType,
      Value<double?> lineSpacing,
      Value<String?> backgroundPdfPath,
      Value<String?> backgroundConfig,
    });

final class $$PagesTableReferences
    extends BaseReferences<_$AppDatabase, $PagesTable, Page> {
  $$PagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NotebooksTable _notebookIdTable(_$AppDatabase db) =>
      db.notebooks.createAlias('pages__notebook_id__notebooks__id');

  $$NotebooksTableProcessedTableManager get notebookId {
    final $_column = $_itemColumn<int>('notebook_id')!;

    final manager = $$NotebooksTableTableManager(
      $_db,
      $_db.notebooks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_notebookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CanvasStrokesTable, List<CanvasStroke>>
  _canvasStrokesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.canvasStrokes,
    aliasName: 'pages__id__canvas_strokes__page_id',
  );

  $$CanvasStrokesTableProcessedTableManager get canvasStrokesRefs {
    final manager = $$CanvasStrokesTableTableManager(
      $_db,
      $_db.canvasStrokes,
    ).filter((f) => f.pageId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_canvasStrokesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CanvasTextBlocksTable, List<CanvasTextBlock>>
  _canvasTextBlocksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.canvasTextBlocks,
    aliasName: 'pages__id__canvas_text_blocks__page_id',
  );

  $$CanvasTextBlocksTableProcessedTableManager get canvasTextBlocksRefs {
    final manager = $$CanvasTextBlocksTableTableManager(
      $_db,
      $_db.canvasTextBlocks,
    ).filter((f) => f.pageId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _canvasTextBlocksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CanvasImageBlocksTable, List<CanvasImageBlock>>
  _canvasImageBlocksRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.canvasImageBlocks,
        aliasName: 'pages__id__canvas_image_blocks__page_id',
      );

  $$CanvasImageBlocksTableProcessedTableManager get canvasImageBlocksRefs {
    final manager = $$CanvasImageBlocksTableTableManager(
      $_db,
      $_db.canvasImageBlocks,
    ).filter((f) => f.pageId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _canvasImageBlocksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

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

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
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

  ColumnFilters<String> get extractedText => $composableBuilder(
    column: $table.extractedText,
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

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isFrozen => $composableBuilder(
    column: $table.isFrozen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paperSize => $composableBuilder(
    column: $table.paperSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lineType => $composableBuilder(
    column: $table.lineType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lineSpacing => $composableBuilder(
    column: $table.lineSpacing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backgroundPdfPath => $composableBuilder(
    column: $table.backgroundPdfPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backgroundConfig => $composableBuilder(
    column: $table.backgroundConfig,
    builder: (column) => ColumnFilters(column),
  );

  $$NotebooksTableFilterComposer get notebookId {
    final $$NotebooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notebookId,
      referencedTable: $db.notebooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebooksTableFilterComposer(
            $db: $db,
            $table: $db.notebooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> canvasStrokesRefs(
    Expression<bool> Function($$CanvasStrokesTableFilterComposer f) f,
  ) {
    final $$CanvasStrokesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.canvasStrokes,
      getReferencedColumn: (t) => t.pageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasStrokesTableFilterComposer(
            $db: $db,
            $table: $db.canvasStrokes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> canvasTextBlocksRefs(
    Expression<bool> Function($$CanvasTextBlocksTableFilterComposer f) f,
  ) {
    final $$CanvasTextBlocksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.canvasTextBlocks,
      getReferencedColumn: (t) => t.pageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasTextBlocksTableFilterComposer(
            $db: $db,
            $table: $db.canvasTextBlocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> canvasImageBlocksRefs(
    Expression<bool> Function($$CanvasImageBlocksTableFilterComposer f) f,
  ) {
    final $$CanvasImageBlocksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.canvasImageBlocks,
      getReferencedColumn: (t) => t.pageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasImageBlocksTableFilterComposer(
            $db: $db,
            $table: $db.canvasImageBlocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
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

  ColumnOrderings<String> get extractedText => $composableBuilder(
    column: $table.extractedText,
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

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isFrozen => $composableBuilder(
    column: $table.isFrozen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paperSize => $composableBuilder(
    column: $table.paperSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lineType => $composableBuilder(
    column: $table.lineType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lineSpacing => $composableBuilder(
    column: $table.lineSpacing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backgroundPdfPath => $composableBuilder(
    column: $table.backgroundPdfPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backgroundConfig => $composableBuilder(
    column: $table.backgroundConfig,
    builder: (column) => ColumnOrderings(column),
  );

  $$NotebooksTableOrderingComposer get notebookId {
    final $$NotebooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notebookId,
      referencedTable: $db.notebooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebooksTableOrderingComposer(
            $db: $db,
            $table: $db.notebooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

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

  GeneratedColumn<String> get extractedText => $composableBuilder(
    column: $table.extractedText,
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

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get isFrozen =>
      $composableBuilder(column: $table.isFrozen, builder: (column) => column);

  GeneratedColumn<int> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paperSize =>
      $composableBuilder(column: $table.paperSize, builder: (column) => column);

  GeneratedColumn<String> get lineType =>
      $composableBuilder(column: $table.lineType, builder: (column) => column);

  GeneratedColumn<double> get lineSpacing => $composableBuilder(
    column: $table.lineSpacing,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backgroundPdfPath => $composableBuilder(
    column: $table.backgroundPdfPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backgroundConfig => $composableBuilder(
    column: $table.backgroundConfig,
    builder: (column) => column,
  );

  $$NotebooksTableAnnotationComposer get notebookId {
    final $$NotebooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notebookId,
      referencedTable: $db.notebooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebooksTableAnnotationComposer(
            $db: $db,
            $table: $db.notebooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> canvasStrokesRefs<T extends Object>(
    Expression<T> Function($$CanvasStrokesTableAnnotationComposer a) f,
  ) {
    final $$CanvasStrokesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.canvasStrokes,
      getReferencedColumn: (t) => t.pageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasStrokesTableAnnotationComposer(
            $db: $db,
            $table: $db.canvasStrokes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> canvasTextBlocksRefs<T extends Object>(
    Expression<T> Function($$CanvasTextBlocksTableAnnotationComposer a) f,
  ) {
    final $$CanvasTextBlocksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.canvasTextBlocks,
      getReferencedColumn: (t) => t.pageId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CanvasTextBlocksTableAnnotationComposer(
            $db: $db,
            $table: $db.canvasTextBlocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> canvasImageBlocksRefs<T extends Object>(
    Expression<T> Function($$CanvasImageBlocksTableAnnotationComposer a) f,
  ) {
    final $$CanvasImageBlocksTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.canvasImageBlocks,
          getReferencedColumn: (t) => t.pageId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CanvasImageBlocksTableAnnotationComposer(
                $db: $db,
                $table: $db.canvasImageBlocks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
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
          (Page, $$PagesTableReferences),
          Page,
          PrefetchHooks Function({
            bool notebookId,
            bool canvasStrokesRefs,
            bool canvasTextBlocksRefs,
            bool canvasImageBlocksRefs,
          })
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
                Value<String?> clientId = const Value.absent(),
                Value<int> notebookId = const Value.absent(),
                Value<int> pageNumber = const Value.absent(),
                Value<int> isLandscape = const Value.absent(),
                Value<String?> headerData = const Value.absent(),
                Value<String?> footerData = const Value.absent(),
                Value<String?> extractedText = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> isFrozen = const Value.absent(),
                Value<int> isFavorite = const Value.absent(),
                Value<String> paperSize = const Value.absent(),
                Value<String?> lineType = const Value.absent(),
                Value<double?> lineSpacing = const Value.absent(),
                Value<String?> backgroundPdfPath = const Value.absent(),
                Value<String?> backgroundConfig = const Value.absent(),
              }) => PagesCompanion(
                id: id,
                serverId: serverId,
                clientId: clientId,
                notebookId: notebookId,
                pageNumber: pageNumber,
                isLandscape: isLandscape,
                headerData: headerData,
                footerData: footerData,
                extractedText: extractedText,
                isDeleted: isDeleted,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
                version: version,
                isFrozen: isFrozen,
                isFavorite: isFavorite,
                paperSize: paperSize,
                lineType: lineType,
                lineSpacing: lineSpacing,
                backgroundPdfPath: backgroundPdfPath,
                backgroundConfig: backgroundConfig,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                required int notebookId,
                required int pageNumber,
                Value<int> isLandscape = const Value.absent(),
                Value<String?> headerData = const Value.absent(),
                Value<String?> footerData = const Value.absent(),
                Value<String?> extractedText = const Value.absent(),
                Value<int> isDeleted = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> isFrozen = const Value.absent(),
                Value<int> isFavorite = const Value.absent(),
                Value<String> paperSize = const Value.absent(),
                Value<String?> lineType = const Value.absent(),
                Value<double?> lineSpacing = const Value.absent(),
                Value<String?> backgroundPdfPath = const Value.absent(),
                Value<String?> backgroundConfig = const Value.absent(),
              }) => PagesCompanion.insert(
                id: id,
                serverId: serverId,
                clientId: clientId,
                notebookId: notebookId,
                pageNumber: pageNumber,
                isLandscape: isLandscape,
                headerData: headerData,
                footerData: footerData,
                extractedText: extractedText,
                isDeleted: isDeleted,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
                version: version,
                isFrozen: isFrozen,
                isFavorite: isFavorite,
                paperSize: paperSize,
                lineType: lineType,
                lineSpacing: lineSpacing,
                backgroundPdfPath: backgroundPdfPath,
                backgroundConfig: backgroundConfig,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$PagesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                notebookId = false,
                canvasStrokesRefs = false,
                canvasTextBlocksRefs = false,
                canvasImageBlocksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (canvasStrokesRefs) db.canvasStrokes,
                    if (canvasTextBlocksRefs) db.canvasTextBlocks,
                    if (canvasImageBlocksRefs) db.canvasImageBlocks,
                  ],
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
                        if (notebookId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.notebookId,
                                    referencedTable: $$PagesTableReferences
                                        ._notebookIdTable(db),
                                    referencedColumn: $$PagesTableReferences
                                        ._notebookIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (canvasStrokesRefs)
                        await $_getPrefetchedData<
                          Page,
                          $PagesTable,
                          CanvasStroke
                        >(
                          currentTable: table,
                          referencedTable: $$PagesTableReferences
                              ._canvasStrokesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PagesTableReferences(
                                db,
                                table,
                                p0,
                              ).canvasStrokesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.pageId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (canvasTextBlocksRefs)
                        await $_getPrefetchedData<
                          Page,
                          $PagesTable,
                          CanvasTextBlock
                        >(
                          currentTable: table,
                          referencedTable: $$PagesTableReferences
                              ._canvasTextBlocksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PagesTableReferences(
                                db,
                                table,
                                p0,
                              ).canvasTextBlocksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.pageId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (canvasImageBlocksRefs)
                        await $_getPrefetchedData<
                          Page,
                          $PagesTable,
                          CanvasImageBlock
                        >(
                          currentTable: table,
                          referencedTable: $$PagesTableReferences
                              ._canvasImageBlocksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PagesTableReferences(
                                db,
                                table,
                                p0,
                              ).canvasImageBlocksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.pageId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
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
      (Page, $$PagesTableReferences),
      Page,
      PrefetchHooks Function({
        bool notebookId,
        bool canvasStrokesRefs,
        bool canvasTextBlocksRefs,
        bool canvasImageBlocksRefs,
      })
    >;
typedef $$CanvasStrokesTableCreateCompanionBuilder =
    CanvasStrokesCompanion Function({
      required String clientStrokeId,
      Value<int?> serverId,
      required int pageId,
      required String strokeData,
      Value<int> isDeleted,
      Value<int> deletedInSession,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
      Value<int> version,
      Value<String?> creatorId,
      Value<String?> layerId,
      Value<int> rowid,
    });
typedef $$CanvasStrokesTableUpdateCompanionBuilder =
    CanvasStrokesCompanion Function({
      Value<String> clientStrokeId,
      Value<int?> serverId,
      Value<int> pageId,
      Value<String> strokeData,
      Value<int> isDeleted,
      Value<int> deletedInSession,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
      Value<int> version,
      Value<String?> creatorId,
      Value<String?> layerId,
      Value<int> rowid,
    });

final class $$CanvasStrokesTableReferences
    extends BaseReferences<_$AppDatabase, $CanvasStrokesTable, CanvasStroke> {
  $$CanvasStrokesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PagesTable _pageIdTable(_$AppDatabase db) =>
      db.pages.createAlias('canvas_strokes__page_id__pages__id');

  $$PagesTableProcessedTableManager get pageId {
    final $_column = $_itemColumn<int>('page_id')!;

    final manager = $$PagesTableTableManager(
      $_db,
      $_db.pages,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

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

  ColumnFilters<String> get strokeData => $composableBuilder(
    column: $table.strokeData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedInSession => $composableBuilder(
    column: $table.deletedInSession,
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

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creatorId => $composableBuilder(
    column: $table.creatorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get layerId => $composableBuilder(
    column: $table.layerId,
    builder: (column) => ColumnFilters(column),
  );

  $$PagesTableFilterComposer get pageId {
    final $$PagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableFilterComposer(
            $db: $db,
            $table: $db.pages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  ColumnOrderings<String> get strokeData => $composableBuilder(
    column: $table.strokeData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedInSession => $composableBuilder(
    column: $table.deletedInSession,
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

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creatorId => $composableBuilder(
    column: $table.creatorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get layerId => $composableBuilder(
    column: $table.layerId,
    builder: (column) => ColumnOrderings(column),
  );

  $$PagesTableOrderingComposer get pageId {
    final $$PagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableOrderingComposer(
            $db: $db,
            $table: $db.pages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  GeneratedColumn<String> get strokeData => $composableBuilder(
    column: $table.strokeData,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get deletedInSession => $composableBuilder(
    column: $table.deletedInSession,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get creatorId =>
      $composableBuilder(column: $table.creatorId, builder: (column) => column);

  GeneratedColumn<String> get layerId =>
      $composableBuilder(column: $table.layerId, builder: (column) => column);

  $$PagesTableAnnotationComposer get pageId {
    final $$PagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableAnnotationComposer(
            $db: $db,
            $table: $db.pages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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
          (CanvasStroke, $$CanvasStrokesTableReferences),
          CanvasStroke,
          PrefetchHooks Function({bool pageId})
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
                Value<int> deletedInSession = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> creatorId = const Value.absent(),
                Value<String?> layerId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CanvasStrokesCompanion(
                clientStrokeId: clientStrokeId,
                serverId: serverId,
                pageId: pageId,
                strokeData: strokeData,
                isDeleted: isDeleted,
                deletedInSession: deletedInSession,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
                version: version,
                creatorId: creatorId,
                layerId: layerId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientStrokeId,
                Value<int?> serverId = const Value.absent(),
                required int pageId,
                required String strokeData,
                Value<int> isDeleted = const Value.absent(),
                Value<int> deletedInSession = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> creatorId = const Value.absent(),
                Value<String?> layerId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CanvasStrokesCompanion.insert(
                clientStrokeId: clientStrokeId,
                serverId: serverId,
                pageId: pageId,
                strokeData: strokeData,
                isDeleted: isDeleted,
                deletedInSession: deletedInSession,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
                version: version,
                creatorId: creatorId,
                layerId: layerId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CanvasStrokesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({pageId = false}) {
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
                    if (pageId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.pageId,
                                referencedTable: $$CanvasStrokesTableReferences
                                    ._pageIdTable(db),
                                referencedColumn: $$CanvasStrokesTableReferences
                                    ._pageIdTable(db)
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
      (CanvasStroke, $$CanvasStrokesTableReferences),
      CanvasStroke,
      PrefetchHooks Function({bool pageId})
    >;
typedef $$CanvasTextBlocksTableCreateCompanionBuilder =
    CanvasTextBlocksCompanion Function({
      required String clientTextId,
      Value<int?> serverId,
      required int pageId,
      required String textData,
      Value<int> isDeleted,
      Value<int> deletedInSession,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
      Value<int> version,
      Value<String?> creatorId,
      Value<int> rowid,
    });
typedef $$CanvasTextBlocksTableUpdateCompanionBuilder =
    CanvasTextBlocksCompanion Function({
      Value<String> clientTextId,
      Value<int?> serverId,
      Value<int> pageId,
      Value<String> textData,
      Value<int> isDeleted,
      Value<int> deletedInSession,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
      Value<int> version,
      Value<String?> creatorId,
      Value<int> rowid,
    });

final class $$CanvasTextBlocksTableReferences
    extends
        BaseReferences<_$AppDatabase, $CanvasTextBlocksTable, CanvasTextBlock> {
  $$CanvasTextBlocksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PagesTable _pageIdTable(_$AppDatabase db) =>
      db.pages.createAlias('canvas_text_blocks__page_id__pages__id');

  $$PagesTableProcessedTableManager get pageId {
    final $_column = $_itemColumn<int>('page_id')!;

    final manager = $$PagesTableTableManager(
      $_db,
      $_db.pages,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

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

  ColumnFilters<String> get textData => $composableBuilder(
    column: $table.textData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedInSession => $composableBuilder(
    column: $table.deletedInSession,
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

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creatorId => $composableBuilder(
    column: $table.creatorId,
    builder: (column) => ColumnFilters(column),
  );

  $$PagesTableFilterComposer get pageId {
    final $$PagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableFilterComposer(
            $db: $db,
            $table: $db.pages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  ColumnOrderings<String> get textData => $composableBuilder(
    column: $table.textData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedInSession => $composableBuilder(
    column: $table.deletedInSession,
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

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creatorId => $composableBuilder(
    column: $table.creatorId,
    builder: (column) => ColumnOrderings(column),
  );

  $$PagesTableOrderingComposer get pageId {
    final $$PagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableOrderingComposer(
            $db: $db,
            $table: $db.pages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  GeneratedColumn<String> get textData =>
      $composableBuilder(column: $table.textData, builder: (column) => column);

  GeneratedColumn<int> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get deletedInSession => $composableBuilder(
    column: $table.deletedInSession,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get creatorId =>
      $composableBuilder(column: $table.creatorId, builder: (column) => column);

  $$PagesTableAnnotationComposer get pageId {
    final $$PagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableAnnotationComposer(
            $db: $db,
            $table: $db.pages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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
          (CanvasTextBlock, $$CanvasTextBlocksTableReferences),
          CanvasTextBlock,
          PrefetchHooks Function({bool pageId})
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
                Value<int> deletedInSession = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> creatorId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CanvasTextBlocksCompanion(
                clientTextId: clientTextId,
                serverId: serverId,
                pageId: pageId,
                textData: textData,
                isDeleted: isDeleted,
                deletedInSession: deletedInSession,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
                version: version,
                creatorId: creatorId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clientTextId,
                Value<int?> serverId = const Value.absent(),
                required int pageId,
                required String textData,
                Value<int> isDeleted = const Value.absent(),
                Value<int> deletedInSession = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> creatorId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CanvasTextBlocksCompanion.insert(
                clientTextId: clientTextId,
                serverId: serverId,
                pageId: pageId,
                textData: textData,
                isDeleted: isDeleted,
                deletedInSession: deletedInSession,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
                version: version,
                creatorId: creatorId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CanvasTextBlocksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({pageId = false}) {
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
                    if (pageId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.pageId,
                                referencedTable:
                                    $$CanvasTextBlocksTableReferences
                                        ._pageIdTable(db),
                                referencedColumn:
                                    $$CanvasTextBlocksTableReferences
                                        ._pageIdTable(db)
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
      (CanvasTextBlock, $$CanvasTextBlocksTableReferences),
      CanvasTextBlock,
      PrefetchHooks Function({bool pageId})
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
      Value<int> deletedInSession,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
      Value<int> version,
      Value<String?> creatorId,
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
      Value<int> deletedInSession,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
      Value<int> version,
      Value<String?> creatorId,
      Value<int> rowid,
    });

final class $$CanvasImageBlocksTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CanvasImageBlocksTable,
          CanvasImageBlock
        > {
  $$CanvasImageBlocksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PagesTable _pageIdTable(_$AppDatabase db) =>
      db.pages.createAlias('canvas_image_blocks__page_id__pages__id');

  $$PagesTableProcessedTableManager get pageId {
    final $_column = $_itemColumn<int>('page_id')!;

    final manager = $$PagesTableTableManager(
      $_db,
      $_db.pages,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

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

  ColumnFilters<int> get deletedInSession => $composableBuilder(
    column: $table.deletedInSession,
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

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get creatorId => $composableBuilder(
    column: $table.creatorId,
    builder: (column) => ColumnFilters(column),
  );

  $$PagesTableFilterComposer get pageId {
    final $$PagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableFilterComposer(
            $db: $db,
            $table: $db.pages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  ColumnOrderings<int> get deletedInSession => $composableBuilder(
    column: $table.deletedInSession,
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

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get creatorId => $composableBuilder(
    column: $table.creatorId,
    builder: (column) => ColumnOrderings(column),
  );

  $$PagesTableOrderingComposer get pageId {
    final $$PagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableOrderingComposer(
            $db: $db,
            $table: $db.pages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  GeneratedColumn<int> get deletedInSession => $composableBuilder(
    column: $table.deletedInSession,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get creatorId =>
      $composableBuilder(column: $table.creatorId, builder: (column) => column);

  $$PagesTableAnnotationComposer get pageId {
    final $$PagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pageId,
      referencedTable: $db.pages,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PagesTableAnnotationComposer(
            $db: $db,
            $table: $db.pages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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
          (CanvasImageBlock, $$CanvasImageBlocksTableReferences),
          CanvasImageBlock,
          PrefetchHooks Function({bool pageId})
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
                Value<int> deletedInSession = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> creatorId = const Value.absent(),
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
                deletedInSession: deletedInSession,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
                version: version,
                creatorId: creatorId,
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
                Value<int> deletedInSession = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> creatorId = const Value.absent(),
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
                deletedInSession: deletedInSession,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
                version: version,
                creatorId: creatorId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CanvasImageBlocksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({pageId = false}) {
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
                    if (pageId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.pageId,
                                referencedTable:
                                    $$CanvasImageBlocksTableReferences
                                        ._pageIdTable(db),
                                referencedColumn:
                                    $$CanvasImageBlocksTableReferences
                                        ._pageIdTable(db)
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
      (CanvasImageBlock, $$CanvasImageBlocksTableReferences),
      CanvasImageBlock,
      PrefetchHooks Function({bool pageId})
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
      Value<int> version,
      Value<int> isArchived,
      Value<int> isFavorite,
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
      Value<int> version,
      Value<int> isArchived,
      Value<int> isFavorite,
    });

final class $$NotebookUserTableReferences
    extends
        BaseReferences<_$AppDatabase, $NotebookUserTable, NotebookUserData> {
  $$NotebookUserTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NotebooksTable _notebookIdTable(_$AppDatabase db) =>
      db.notebooks.createAlias('notebook_user__notebook_id__notebooks__id');

  $$NotebooksTableProcessedTableManager get notebookId {
    final $_column = $_itemColumn<int>('notebook_id')!;

    final manager = $$NotebooksTableTableManager(
      $_db,
      $_db.notebooks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_notebookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $UsersTable _userIdTable(_$AppDatabase db) =>
      db.users.createAlias('notebook_user__user_id__users__id');

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

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

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  $$NotebooksTableFilterComposer get notebookId {
    final $$NotebooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notebookId,
      referencedTable: $db.notebooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebooksTableFilterComposer(
            $db: $db,
            $table: $db.notebooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  $$NotebooksTableOrderingComposer get notebookId {
    final $$NotebooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notebookId,
      referencedTable: $db.notebooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebooksTableOrderingComposer(
            $db: $db,
            $table: $db.notebooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  $$NotebooksTableAnnotationComposer get notebookId {
    final $$NotebooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notebookId,
      referencedTable: $db.notebooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebooksTableAnnotationComposer(
            $db: $db,
            $table: $db.notebooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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
          (NotebookUserData, $$NotebookUserTableReferences),
          NotebookUserData,
          PrefetchHooks Function({bool notebookId, bool userId})
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
                Value<int> version = const Value.absent(),
                Value<int> isArchived = const Value.absent(),
                Value<int> isFavorite = const Value.absent(),
              }) => NotebookUserCompanion(
                id: id,
                serverId: serverId,
                notebookId: notebookId,
                userId: userId,
                role: role,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
                version: version,
                isArchived: isArchived,
                isFavorite: isFavorite,
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
                Value<int> version = const Value.absent(),
                Value<int> isArchived = const Value.absent(),
                Value<int> isFavorite = const Value.absent(),
              }) => NotebookUserCompanion.insert(
                id: id,
                serverId: serverId,
                notebookId: notebookId,
                userId: userId,
                role: role,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
                version: version,
                isArchived: isArchived,
                isFavorite: isFavorite,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$NotebookUserTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({notebookId = false, userId = false}) {
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
                    if (notebookId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.notebookId,
                                referencedTable: $$NotebookUserTableReferences
                                    ._notebookIdTable(db),
                                referencedColumn: $$NotebookUserTableReferences
                                    ._notebookIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (userId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.userId,
                                referencedTable: $$NotebookUserTableReferences
                                    ._userIdTable(db),
                                referencedColumn: $$NotebookUserTableReferences
                                    ._userIdTable(db)
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
      (NotebookUserData, $$NotebookUserTableReferences),
      NotebookUserData,
      PrefetchHooks Function({bool notebookId, bool userId})
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
      Value<int> version,
      Value<int> isArchived,
      Value<int> isFavorite,
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
      Value<int> version,
      Value<int> isArchived,
      Value<int> isFavorite,
    });

final class $$PaymentsTableReferences
    extends BaseReferences<_$AppDatabase, $PaymentsTable, Payment> {
  $$PaymentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $UsersTable _userIdTable(_$AppDatabase db) =>
      db.users.createAlias('payments__user_id__users__id');

  $$UsersTableProcessedTableManager get userId {
    final $_column = $_itemColumn<int>('user_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

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

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get userId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get userId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  $$UsersTableAnnotationComposer get userId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
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
          (Payment, $$PaymentsTableReferences),
          Payment,
          PrefetchHooks Function({bool userId})
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
                Value<int> version = const Value.absent(),
                Value<int> isArchived = const Value.absent(),
                Value<int> isFavorite = const Value.absent(),
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
                version: version,
                isArchived: isArchived,
                isFavorite: isFavorite,
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
                Value<int> version = const Value.absent(),
                Value<int> isArchived = const Value.absent(),
                Value<int> isFavorite = const Value.absent(),
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
                version: version,
                isArchived: isArchived,
                isFavorite: isFavorite,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PaymentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
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
                    if (userId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.userId,
                                referencedTable: $$PaymentsTableReferences
                                    ._userIdTable(db),
                                referencedColumn: $$PaymentsTableReferences
                                    ._userIdTable(db)
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
      (Payment, $$PaymentsTableReferences),
      Payment,
      PrefetchHooks Function({bool userId})
    >;
typedef $$LessonRecordingsTableCreateCompanionBuilder =
    LessonRecordingsCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<String?> clientId,
      required int notebookId,
      required String title,
      required String audioUrl,
      Value<int> durationSeconds,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
      Value<int> version,
      Value<int> isArchived,
      Value<int> isFavorite,
    });
typedef $$LessonRecordingsTableUpdateCompanionBuilder =
    LessonRecordingsCompanion Function({
      Value<int> id,
      Value<int?> serverId,
      Value<String?> clientId,
      Value<int> notebookId,
      Value<String> title,
      Value<String> audioUrl,
      Value<int> durationSeconds,
      Value<int> syncedWithCloud,
      Value<int> updatedAt,
      Value<int> version,
      Value<int> isArchived,
      Value<int> isFavorite,
    });

final class $$LessonRecordingsTableReferences
    extends
        BaseReferences<_$AppDatabase, $LessonRecordingsTable, LessonRecording> {
  $$LessonRecordingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $NotebooksTable _notebookIdTable(_$AppDatabase db) =>
      db.notebooks.createAlias('lesson_recordings__notebook_id__notebooks__id');

  $$NotebooksTableProcessedTableManager get notebookId {
    final $_column = $_itemColumn<int>('notebook_id')!;

    final manager = $$NotebooksTableTableManager(
      $_db,
      $_db.notebooks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_notebookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LessonRecordingsTableFilterComposer
    extends Composer<_$AppDatabase, $LessonRecordingsTable> {
  $$LessonRecordingsTableFilterComposer({
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

  ColumnFilters<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioUrl => $composableBuilder(
    column: $table.audioUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
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

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  $$NotebooksTableFilterComposer get notebookId {
    final $$NotebooksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notebookId,
      referencedTable: $db.notebooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebooksTableFilterComposer(
            $db: $db,
            $table: $db.notebooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LessonRecordingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LessonRecordingsTable> {
  $$LessonRecordingsTableOrderingComposer({
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

  ColumnOrderings<String> get clientId => $composableBuilder(
    column: $table.clientId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioUrl => $composableBuilder(
    column: $table.audioUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
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

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  $$NotebooksTableOrderingComposer get notebookId {
    final $$NotebooksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notebookId,
      referencedTable: $db.notebooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebooksTableOrderingComposer(
            $db: $db,
            $table: $db.notebooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LessonRecordingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LessonRecordingsTable> {
  $$LessonRecordingsTableAnnotationComposer({
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

  GeneratedColumn<String> get clientId =>
      $composableBuilder(column: $table.clientId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get audioUrl =>
      $composableBuilder(column: $table.audioUrl, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncedWithCloud => $composableBuilder(
    column: $table.syncedWithCloud,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<int> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  $$NotebooksTableAnnotationComposer get notebookId {
    final $$NotebooksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.notebookId,
      referencedTable: $db.notebooks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebooksTableAnnotationComposer(
            $db: $db,
            $table: $db.notebooks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LessonRecordingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LessonRecordingsTable,
          LessonRecording,
          $$LessonRecordingsTableFilterComposer,
          $$LessonRecordingsTableOrderingComposer,
          $$LessonRecordingsTableAnnotationComposer,
          $$LessonRecordingsTableCreateCompanionBuilder,
          $$LessonRecordingsTableUpdateCompanionBuilder,
          (LessonRecording, $$LessonRecordingsTableReferences),
          LessonRecording,
          PrefetchHooks Function({bool notebookId})
        > {
  $$LessonRecordingsTableTableManager(
    _$AppDatabase db,
    $LessonRecordingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonRecordingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LessonRecordingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LessonRecordingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                Value<int> notebookId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> audioUrl = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> isArchived = const Value.absent(),
                Value<int> isFavorite = const Value.absent(),
              }) => LessonRecordingsCompanion(
                id: id,
                serverId: serverId,
                clientId: clientId,
                notebookId: notebookId,
                title: title,
                audioUrl: audioUrl,
                durationSeconds: durationSeconds,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
                version: version,
                isArchived: isArchived,
                isFavorite: isFavorite,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String?> clientId = const Value.absent(),
                required int notebookId,
                required String title,
                required String audioUrl,
                Value<int> durationSeconds = const Value.absent(),
                Value<int> syncedWithCloud = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<int> isArchived = const Value.absent(),
                Value<int> isFavorite = const Value.absent(),
              }) => LessonRecordingsCompanion.insert(
                id: id,
                serverId: serverId,
                clientId: clientId,
                notebookId: notebookId,
                title: title,
                audioUrl: audioUrl,
                durationSeconds: durationSeconds,
                syncedWithCloud: syncedWithCloud,
                updatedAt: updatedAt,
                version: version,
                isArchived: isArchived,
                isFavorite: isFavorite,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LessonRecordingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({notebookId = false}) {
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
                    if (notebookId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.notebookId,
                                referencedTable:
                                    $$LessonRecordingsTableReferences
                                        ._notebookIdTable(db),
                                referencedColumn:
                                    $$LessonRecordingsTableReferences
                                        ._notebookIdTable(db)
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

typedef $$LessonRecordingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LessonRecordingsTable,
      LessonRecording,
      $$LessonRecordingsTableFilterComposer,
      $$LessonRecordingsTableOrderingComposer,
      $$LessonRecordingsTableAnnotationComposer,
      $$LessonRecordingsTableCreateCompanionBuilder,
      $$LessonRecordingsTableUpdateCompanionBuilder,
      (LessonRecording, $$LessonRecordingsTableReferences),
      LessonRecording,
      PrefetchHooks Function({bool notebookId})
    >;
typedef $$NotebookTemplatesTableCreateCompanionBuilder =
    NotebookTemplatesCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> description,
      Value<String?> category,
      Value<String?> icon,
      Value<String?> cover,
      Value<int> isSystem,
      Value<int?> createdBy,
      required int createdAt,
      required int updatedAt,
    });
typedef $$NotebookTemplatesTableUpdateCompanionBuilder =
    NotebookTemplatesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> description,
      Value<String?> category,
      Value<String?> icon,
      Value<String?> cover,
      Value<int> isSystem,
      Value<int?> createdBy,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$NotebookTemplatesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $NotebookTemplatesTable,
          NotebookTemplate
        > {
  $$NotebookTemplatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $NotebookTemplateVersionsTable,
    List<NotebookTemplateVersion>
  >
  _notebookTemplateVersionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.notebookTemplateVersions,
        aliasName:
            'notebook_templates__id__notebook_template_versions__template_id',
      );

  $$NotebookTemplateVersionsTableProcessedTableManager
  get notebookTemplateVersionsRefs {
    final manager = $$NotebookTemplateVersionsTableTableManager(
      $_db,
      $_db.notebookTemplateVersions,
    ).filter((f) => f.templateId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _notebookTemplateVersionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$NotebookTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $NotebookTemplatesTable> {
  $$NotebookTemplatesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> notebookTemplateVersionsRefs(
    Expression<bool> Function($$NotebookTemplateVersionsTableFilterComposer f)
    f,
  ) {
    final $$NotebookTemplateVersionsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.notebookTemplateVersions,
          getReferencedColumn: (t) => t.templateId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$NotebookTemplateVersionsTableFilterComposer(
                $db: $db,
                $table: $db.notebookTemplateVersions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$NotebookTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $NotebookTemplatesTable> {
  $$NotebookTemplatesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cover => $composableBuilder(
    column: $table.cover,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NotebookTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotebookTemplatesTable> {
  $$NotebookTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get cover =>
      $composableBuilder(column: $table.cover, builder: (column) => column);

  GeneratedColumn<int> get isSystem =>
      $composableBuilder(column: $table.isSystem, builder: (column) => column);

  GeneratedColumn<int> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> notebookTemplateVersionsRefs<T extends Object>(
    Expression<T> Function($$NotebookTemplateVersionsTableAnnotationComposer a)
    f,
  ) {
    final $$NotebookTemplateVersionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.notebookTemplateVersions,
          getReferencedColumn: (t) => t.templateId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$NotebookTemplateVersionsTableAnnotationComposer(
                $db: $db,
                $table: $db.notebookTemplateVersions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$NotebookTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotebookTemplatesTable,
          NotebookTemplate,
          $$NotebookTemplatesTableFilterComposer,
          $$NotebookTemplatesTableOrderingComposer,
          $$NotebookTemplatesTableAnnotationComposer,
          $$NotebookTemplatesTableCreateCompanionBuilder,
          $$NotebookTemplatesTableUpdateCompanionBuilder,
          (NotebookTemplate, $$NotebookTemplatesTableReferences),
          NotebookTemplate,
          PrefetchHooks Function({bool notebookTemplateVersionsRefs})
        > {
  $$NotebookTemplatesTableTableManager(
    _$AppDatabase db,
    $NotebookTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotebookTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NotebookTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NotebookTemplatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> cover = const Value.absent(),
                Value<int> isSystem = const Value.absent(),
                Value<int?> createdBy = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => NotebookTemplatesCompanion(
                id: id,
                name: name,
                description: description,
                category: category,
                icon: icon,
                cover: cover,
                isSystem: isSystem,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> cover = const Value.absent(),
                Value<int> isSystem = const Value.absent(),
                Value<int?> createdBy = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => NotebookTemplatesCompanion.insert(
                id: id,
                name: name,
                description: description,
                category: category,
                icon: icon,
                cover: cover,
                isSystem: isSystem,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$NotebookTemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({notebookTemplateVersionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (notebookTemplateVersionsRefs) db.notebookTemplateVersions,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (notebookTemplateVersionsRefs)
                    await $_getPrefetchedData<
                      NotebookTemplate,
                      $NotebookTemplatesTable,
                      NotebookTemplateVersion
                    >(
                      currentTable: table,
                      referencedTable: $$NotebookTemplatesTableReferences
                          ._notebookTemplateVersionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$NotebookTemplatesTableReferences(
                            db,
                            table,
                            p0,
                          ).notebookTemplateVersionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.templateId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$NotebookTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotebookTemplatesTable,
      NotebookTemplate,
      $$NotebookTemplatesTableFilterComposer,
      $$NotebookTemplatesTableOrderingComposer,
      $$NotebookTemplatesTableAnnotationComposer,
      $$NotebookTemplatesTableCreateCompanionBuilder,
      $$NotebookTemplatesTableUpdateCompanionBuilder,
      (NotebookTemplate, $$NotebookTemplatesTableReferences),
      NotebookTemplate,
      PrefetchHooks Function({bool notebookTemplateVersionsRefs})
    >;
typedef $$NotebookTemplateVersionsTableCreateCompanionBuilder =
    NotebookTemplateVersionsCompanion Function({
      Value<int> id,
      required int templateId,
      required int version,
      required String configuration,
      required int createdAt,
      required int updatedAt,
    });
typedef $$NotebookTemplateVersionsTableUpdateCompanionBuilder =
    NotebookTemplateVersionsCompanion Function({
      Value<int> id,
      Value<int> templateId,
      Value<int> version,
      Value<String> configuration,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

final class $$NotebookTemplateVersionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $NotebookTemplateVersionsTable,
          NotebookTemplateVersion
        > {
  $$NotebookTemplateVersionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $NotebookTemplatesTable _templateIdTable(_$AppDatabase db) =>
      db.notebookTemplates.createAlias(
        'notebook_template_versions__template_id__notebook_templates__id',
      );

  $$NotebookTemplatesTableProcessedTableManager get templateId {
    final $_column = $_itemColumn<int>('template_id')!;

    final manager = $$NotebookTemplatesTableTableManager(
      $_db,
      $_db.notebookTemplates,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NotebookTemplateVersionsTableFilterComposer
    extends Composer<_$AppDatabase, $NotebookTemplateVersionsTable> {
  $$NotebookTemplateVersionsTableFilterComposer({
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

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get configuration => $composableBuilder(
    column: $table.configuration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$NotebookTemplatesTableFilterComposer get templateId {
    final $$NotebookTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.notebookTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebookTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.notebookTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotebookTemplateVersionsTableOrderingComposer
    extends Composer<_$AppDatabase, $NotebookTemplateVersionsTable> {
  $$NotebookTemplateVersionsTableOrderingComposer({
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

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get configuration => $composableBuilder(
    column: $table.configuration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$NotebookTemplatesTableOrderingComposer get templateId {
    final $$NotebookTemplatesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.notebookTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NotebookTemplatesTableOrderingComposer(
            $db: $db,
            $table: $db.notebookTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NotebookTemplateVersionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NotebookTemplateVersionsTable> {
  $$NotebookTemplateVersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get configuration => $composableBuilder(
    column: $table.configuration,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$NotebookTemplatesTableAnnotationComposer get templateId {
    final $$NotebookTemplatesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.templateId,
          referencedTable: $db.notebookTemplates,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$NotebookTemplatesTableAnnotationComposer(
                $db: $db,
                $table: $db.notebookTemplates,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$NotebookTemplateVersionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NotebookTemplateVersionsTable,
          NotebookTemplateVersion,
          $$NotebookTemplateVersionsTableFilterComposer,
          $$NotebookTemplateVersionsTableOrderingComposer,
          $$NotebookTemplateVersionsTableAnnotationComposer,
          $$NotebookTemplateVersionsTableCreateCompanionBuilder,
          $$NotebookTemplateVersionsTableUpdateCompanionBuilder,
          (NotebookTemplateVersion, $$NotebookTemplateVersionsTableReferences),
          NotebookTemplateVersion,
          PrefetchHooks Function({bool templateId})
        > {
  $$NotebookTemplateVersionsTableTableManager(
    _$AppDatabase db,
    $NotebookTemplateVersionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NotebookTemplateVersionsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$NotebookTemplateVersionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$NotebookTemplateVersionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> templateId = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> configuration = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => NotebookTemplateVersionsCompanion(
                id: id,
                templateId: templateId,
                version: version,
                configuration: configuration,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int templateId,
                required int version,
                required String configuration,
                required int createdAt,
                required int updatedAt,
              }) => NotebookTemplateVersionsCompanion.insert(
                id: id,
                templateId: templateId,
                version: version,
                configuration: configuration,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$NotebookTemplateVersionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({templateId = false}) {
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
                    if (templateId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.templateId,
                                referencedTable:
                                    $$NotebookTemplateVersionsTableReferences
                                        ._templateIdTable(db),
                                referencedColumn:
                                    $$NotebookTemplateVersionsTableReferences
                                        ._templateIdTable(db)
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

typedef $$NotebookTemplateVersionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NotebookTemplateVersionsTable,
      NotebookTemplateVersion,
      $$NotebookTemplateVersionsTableFilterComposer,
      $$NotebookTemplateVersionsTableOrderingComposer,
      $$NotebookTemplateVersionsTableAnnotationComposer,
      $$NotebookTemplateVersionsTableCreateCompanionBuilder,
      $$NotebookTemplateVersionsTableUpdateCompanionBuilder,
      (NotebookTemplateVersion, $$NotebookTemplateVersionsTableReferences),
      NotebookTemplateVersion,
      PrefetchHooks Function({bool templateId})
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
  $$LessonRecordingsTableTableManager get lessonRecordings =>
      $$LessonRecordingsTableTableManager(_db, _db.lessonRecordings);
  $$NotebookTemplatesTableTableManager get notebookTemplates =>
      $$NotebookTemplatesTableTableManager(_db, _db.notebookTemplates);
  $$NotebookTemplateVersionsTableTableManager get notebookTemplateVersions =>
      $$NotebookTemplateVersionsTableTableManager(
        _db,
        _db.notebookTemplateVersions,
      );
}
