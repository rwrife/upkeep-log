// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upkeep_database.dart';

// ignore_for_file: type=lint
class $HomesTable extends Homes with TableInfo<$HomesTable, Home> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HomesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _addressLabelMeta = const VerificationMeta(
    'addressLabel',
  );
  @override
  late final GeneratedColumn<String> addressLabel = GeneratedColumn<String>(
    'address_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, addressLabel];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'homes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Home> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('address_label')) {
      context.handle(
        _addressLabelMeta,
        addressLabel.isAcceptableOrUnknown(
          data['address_label']!,
          _addressLabelMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Home map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Home(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      addressLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address_label'],
      ),
    );
  }

  @override
  $HomesTable createAlias(String alias) {
    return $HomesTable(attachedDatabase, alias);
  }
}

class Home extends DataClass implements Insertable<Home> {
  final String id;
  final String name;
  final String? addressLabel;
  const Home({required this.id, required this.name, this.addressLabel});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || addressLabel != null) {
      map['address_label'] = Variable<String>(addressLabel);
    }
    return map;
  }

  HomesCompanion toCompanion(bool nullToAbsent) {
    return HomesCompanion(
      id: Value(id),
      name: Value(name),
      addressLabel: addressLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(addressLabel),
    );
  }

  factory Home.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Home(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      addressLabel: serializer.fromJson<String?>(json['addressLabel']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'addressLabel': serializer.toJson<String?>(addressLabel),
    };
  }

  Home copyWith({
    String? id,
    String? name,
    Value<String?> addressLabel = const Value.absent(),
  }) => Home(
    id: id ?? this.id,
    name: name ?? this.name,
    addressLabel: addressLabel.present ? addressLabel.value : this.addressLabel,
  );
  Home copyWithCompanion(HomesCompanion data) {
    return Home(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      addressLabel: data.addressLabel.present
          ? data.addressLabel.value
          : this.addressLabel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Home(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('addressLabel: $addressLabel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, addressLabel);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Home &&
          other.id == this.id &&
          other.name == this.name &&
          other.addressLabel == this.addressLabel);
}

class HomesCompanion extends UpdateCompanion<Home> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> addressLabel;
  final Value<int> rowid;
  const HomesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.addressLabel = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HomesCompanion.insert({
    required String id,
    required String name,
    this.addressLabel = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Home> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? addressLabel,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (addressLabel != null) 'address_label': addressLabel,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HomesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? addressLabel,
    Value<int>? rowid,
  }) {
    return HomesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      addressLabel: addressLabel ?? this.addressLabel,
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
    if (addressLabel.present) {
      map['address_label'] = Variable<String>(addressLabel.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HomesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('addressLabel: $addressLabel, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RoomsTable extends Rooms with TableInfo<$RoomsTable, Room> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoomsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _homeIdMeta = const VerificationMeta('homeId');
  @override
  late final GeneratedColumn<String> homeId = GeneratedColumn<String>(
    'home_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES homes (id) ON DELETE CASCADE',
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
  @override
  List<GeneratedColumn> get $columns => [id, homeId, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rooms';
  @override
  VerificationContext validateIntegrity(
    Insertable<Room> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('home_id')) {
      context.handle(
        _homeIdMeta,
        homeId.isAcceptableOrUnknown(data['home_id']!, _homeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_homeIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Room map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Room(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      homeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}home_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $RoomsTable createAlias(String alias) {
    return $RoomsTable(attachedDatabase, alias);
  }
}

class Room extends DataClass implements Insertable<Room> {
  final String id;
  final String homeId;
  final String name;
  const Room({required this.id, required this.homeId, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['home_id'] = Variable<String>(homeId);
    map['name'] = Variable<String>(name);
    return map;
  }

  RoomsCompanion toCompanion(bool nullToAbsent) {
    return RoomsCompanion(
      id: Value(id),
      homeId: Value(homeId),
      name: Value(name),
    );
  }

  factory Room.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Room(
      id: serializer.fromJson<String>(json['id']),
      homeId: serializer.fromJson<String>(json['homeId']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'homeId': serializer.toJson<String>(homeId),
      'name': serializer.toJson<String>(name),
    };
  }

  Room copyWith({String? id, String? homeId, String? name}) => Room(
    id: id ?? this.id,
    homeId: homeId ?? this.homeId,
    name: name ?? this.name,
  );
  Room copyWithCompanion(RoomsCompanion data) {
    return Room(
      id: data.id.present ? data.id.value : this.id,
      homeId: data.homeId.present ? data.homeId.value : this.homeId,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Room(')
          ..write('id: $id, ')
          ..write('homeId: $homeId, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, homeId, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Room &&
          other.id == this.id &&
          other.homeId == this.homeId &&
          other.name == this.name);
}

class RoomsCompanion extends UpdateCompanion<Room> {
  final Value<String> id;
  final Value<String> homeId;
  final Value<String> name;
  final Value<int> rowid;
  const RoomsCompanion({
    this.id = const Value.absent(),
    this.homeId = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RoomsCompanion.insert({
    required String id,
    required String homeId,
    required String name,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       homeId = Value(homeId),
       name = Value(name);
  static Insertable<Room> custom({
    Expression<String>? id,
    Expression<String>? homeId,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (homeId != null) 'home_id': homeId,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RoomsCompanion copyWith({
    Value<String>? id,
    Value<String>? homeId,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return RoomsCompanion(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (homeId.present) {
      map['home_id'] = Variable<String>(homeId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoomsCompanion(')
          ..write('id: $id, ')
          ..write('homeId: $homeId, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssetsTable extends Assets with TableInfo<$AssetsTable, Asset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _homeIdMeta = const VerificationMeta('homeId');
  @override
  late final GeneratedColumn<String> homeId = GeneratedColumn<String>(
    'home_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES homes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<String> roomId = GeneratedColumn<String>(
    'room_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  @override
  List<GeneratedColumn> get $columns => [id, homeId, roomId, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'assets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Asset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('home_id')) {
      context.handle(
        _homeIdMeta,
        homeId.isAcceptableOrUnknown(data['home_id']!, _homeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_homeIdMeta);
    }
    if (data.containsKey('room_id')) {
      context.handle(
        _roomIdMeta,
        roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta),
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Asset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Asset(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      homeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}home_id'],
      )!,
      roomId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  $AssetsTable createAlias(String alias) {
    return $AssetsTable(attachedDatabase, alias);
  }
}

class Asset extends DataClass implements Insertable<Asset> {
  final String id;
  final String homeId;
  final String? roomId;
  final String name;
  const Asset({
    required this.id,
    required this.homeId,
    this.roomId,
    required this.name,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['home_id'] = Variable<String>(homeId);
    if (!nullToAbsent || roomId != null) {
      map['room_id'] = Variable<String>(roomId);
    }
    map['name'] = Variable<String>(name);
    return map;
  }

  AssetsCompanion toCompanion(bool nullToAbsent) {
    return AssetsCompanion(
      id: Value(id),
      homeId: Value(homeId),
      roomId: roomId == null && nullToAbsent
          ? const Value.absent()
          : Value(roomId),
      name: Value(name),
    );
  }

  factory Asset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Asset(
      id: serializer.fromJson<String>(json['id']),
      homeId: serializer.fromJson<String>(json['homeId']),
      roomId: serializer.fromJson<String?>(json['roomId']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'homeId': serializer.toJson<String>(homeId),
      'roomId': serializer.toJson<String?>(roomId),
      'name': serializer.toJson<String>(name),
    };
  }

  Asset copyWith({
    String? id,
    String? homeId,
    Value<String?> roomId = const Value.absent(),
    String? name,
  }) => Asset(
    id: id ?? this.id,
    homeId: homeId ?? this.homeId,
    roomId: roomId.present ? roomId.value : this.roomId,
    name: name ?? this.name,
  );
  Asset copyWithCompanion(AssetsCompanion data) {
    return Asset(
      id: data.id.present ? data.id.value : this.id,
      homeId: data.homeId.present ? data.homeId.value : this.homeId,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Asset(')
          ..write('id: $id, ')
          ..write('homeId: $homeId, ')
          ..write('roomId: $roomId, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, homeId, roomId, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Asset &&
          other.id == this.id &&
          other.homeId == this.homeId &&
          other.roomId == this.roomId &&
          other.name == this.name);
}

class AssetsCompanion extends UpdateCompanion<Asset> {
  final Value<String> id;
  final Value<String> homeId;
  final Value<String?> roomId;
  final Value<String> name;
  final Value<int> rowid;
  const AssetsCompanion({
    this.id = const Value.absent(),
    this.homeId = const Value.absent(),
    this.roomId = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetsCompanion.insert({
    required String id,
    required String homeId,
    this.roomId = const Value.absent(),
    required String name,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       homeId = Value(homeId),
       name = Value(name);
  static Insertable<Asset> custom({
    Expression<String>? id,
    Expression<String>? homeId,
    Expression<String>? roomId,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (homeId != null) 'home_id': homeId,
      if (roomId != null) 'room_id': roomId,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetsCompanion copyWith({
    Value<String>? id,
    Value<String>? homeId,
    Value<String?>? roomId,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return AssetsCompanion(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      roomId: roomId ?? this.roomId,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (homeId.present) {
      map['home_id'] = Variable<String>(homeId.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetsCompanion(')
          ..write('id: $id, ')
          ..write('homeId: $homeId, ')
          ..write('roomId: $roomId, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskTemplatesTable extends TaskTemplates
    with TableInfo<$TaskTemplatesTable, TaskTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _homeIdMeta = const VerificationMeta('homeId');
  @override
  late final GeneratedColumn<String> homeId = GeneratedColumn<String>(
    'home_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES homes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _roomIdMeta = const VerificationMeta('roomId');
  @override
  late final GeneratedColumn<String> roomId = GeneratedColumn<String>(
    'room_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recurrenceKindMeta = const VerificationMeta(
    'recurrenceKind',
  );
  @override
  late final GeneratedColumn<String> recurrenceKind = GeneratedColumn<String>(
    'recurrence_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recurrenceIntervalMeta =
      const VerificationMeta('recurrenceInterval');
  @override
  late final GeneratedColumn<int> recurrenceInterval = GeneratedColumn<int>(
    'recurrence_interval',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recurrenceAnchorMeta = const VerificationMeta(
    'recurrenceAnchor',
  );
  @override
  late final GeneratedColumn<String> recurrenceAnchor = GeneratedColumn<String>(
    'recurrence_anchor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recurrenceAnchorDayMeta =
      const VerificationMeta('recurrenceAnchorDay');
  @override
  late final GeneratedColumn<int> recurrenceAnchorDay = GeneratedColumn<int>(
    'recurrence_anchor_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recurrenceAnchorMonthMeta =
      const VerificationMeta('recurrenceAnchorMonth');
  @override
  late final GeneratedColumn<int> recurrenceAnchorMonth = GeneratedColumn<int>(
    'recurrence_anchor_month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reminderHourMeta = const VerificationMeta(
    'reminderHour',
  );
  @override
  late final GeneratedColumn<int> reminderHour = GeneratedColumn<int>(
    'reminder_hour',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderMinuteMeta = const VerificationMeta(
    'reminderMinute',
  );
  @override
  late final GeneratedColumn<int> reminderMinute = GeneratedColumn<int>(
    'reminder_minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderTimeZoneMeta = const VerificationMeta(
    'reminderTimeZone',
  );
  @override
  late final GeneratedColumn<String> reminderTimeZone = GeneratedColumn<String>(
    'reminder_time_zone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pausedMeta = const VerificationMeta('paused');
  @override
  late final GeneratedColumn<bool> paused = GeneratedColumn<bool>(
    'paused',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("paused" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    homeId,
    roomId,
    assetId,
    name,
    startDate,
    recurrenceKind,
    recurrenceInterval,
    recurrenceAnchor,
    recurrenceAnchorDay,
    recurrenceAnchorMonth,
    reminderHour,
    reminderMinute,
    reminderTimeZone,
    paused,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('home_id')) {
      context.handle(
        _homeIdMeta,
        homeId.isAcceptableOrUnknown(data['home_id']!, _homeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_homeIdMeta);
    }
    if (data.containsKey('room_id')) {
      context.handle(
        _roomIdMeta,
        roomId.isAcceptableOrUnknown(data['room_id']!, _roomIdMeta),
      );
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
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
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('recurrence_kind')) {
      context.handle(
        _recurrenceKindMeta,
        recurrenceKind.isAcceptableOrUnknown(
          data['recurrence_kind']!,
          _recurrenceKindMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recurrenceKindMeta);
    }
    if (data.containsKey('recurrence_interval')) {
      context.handle(
        _recurrenceIntervalMeta,
        recurrenceInterval.isAcceptableOrUnknown(
          data['recurrence_interval']!,
          _recurrenceIntervalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recurrenceIntervalMeta);
    }
    if (data.containsKey('recurrence_anchor')) {
      context.handle(
        _recurrenceAnchorMeta,
        recurrenceAnchor.isAcceptableOrUnknown(
          data['recurrence_anchor']!,
          _recurrenceAnchorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recurrenceAnchorMeta);
    }
    if (data.containsKey('recurrence_anchor_day')) {
      context.handle(
        _recurrenceAnchorDayMeta,
        recurrenceAnchorDay.isAcceptableOrUnknown(
          data['recurrence_anchor_day']!,
          _recurrenceAnchorDayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recurrenceAnchorDayMeta);
    }
    if (data.containsKey('recurrence_anchor_month')) {
      context.handle(
        _recurrenceAnchorMonthMeta,
        recurrenceAnchorMonth.isAcceptableOrUnknown(
          data['recurrence_anchor_month']!,
          _recurrenceAnchorMonthMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recurrenceAnchorMonthMeta);
    }
    if (data.containsKey('reminder_hour')) {
      context.handle(
        _reminderHourMeta,
        reminderHour.isAcceptableOrUnknown(
          data['reminder_hour']!,
          _reminderHourMeta,
        ),
      );
    }
    if (data.containsKey('reminder_minute')) {
      context.handle(
        _reminderMinuteMeta,
        reminderMinute.isAcceptableOrUnknown(
          data['reminder_minute']!,
          _reminderMinuteMeta,
        ),
      );
    }
    if (data.containsKey('reminder_time_zone')) {
      context.handle(
        _reminderTimeZoneMeta,
        reminderTimeZone.isAcceptableOrUnknown(
          data['reminder_time_zone']!,
          _reminderTimeZoneMeta,
        ),
      );
    }
    if (data.containsKey('paused')) {
      context.handle(
        _pausedMeta,
        paused.isAcceptableOrUnknown(data['paused']!, _pausedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      homeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}home_id'],
      )!,
      roomId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room_id'],
      ),
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      recurrenceKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_kind'],
      )!,
      recurrenceInterval: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recurrence_interval'],
      )!,
      recurrenceAnchor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_anchor'],
      )!,
      recurrenceAnchorDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recurrence_anchor_day'],
      )!,
      recurrenceAnchorMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recurrence_anchor_month'],
      )!,
      reminderHour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_hour'],
      ),
      reminderMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minute'],
      ),
      reminderTimeZone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_time_zone'],
      ),
      paused: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}paused'],
      )!,
    );
  }

  @override
  $TaskTemplatesTable createAlias(String alias) {
    return $TaskTemplatesTable(attachedDatabase, alias);
  }
}

class TaskTemplate extends DataClass implements Insertable<TaskTemplate> {
  final String id;
  final String homeId;
  final String? roomId;
  final String? assetId;
  final String name;
  final String startDate;
  final String recurrenceKind;
  final int recurrenceInterval;
  final String recurrenceAnchor;
  final int recurrenceAnchorDay;
  final int recurrenceAnchorMonth;
  final int? reminderHour;
  final int? reminderMinute;
  final String? reminderTimeZone;
  final bool paused;
  const TaskTemplate({
    required this.id,
    required this.homeId,
    this.roomId,
    this.assetId,
    required this.name,
    required this.startDate,
    required this.recurrenceKind,
    required this.recurrenceInterval,
    required this.recurrenceAnchor,
    required this.recurrenceAnchorDay,
    required this.recurrenceAnchorMonth,
    this.reminderHour,
    this.reminderMinute,
    this.reminderTimeZone,
    required this.paused,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['home_id'] = Variable<String>(homeId);
    if (!nullToAbsent || roomId != null) {
      map['room_id'] = Variable<String>(roomId);
    }
    if (!nullToAbsent || assetId != null) {
      map['asset_id'] = Variable<String>(assetId);
    }
    map['name'] = Variable<String>(name);
    map['start_date'] = Variable<String>(startDate);
    map['recurrence_kind'] = Variable<String>(recurrenceKind);
    map['recurrence_interval'] = Variable<int>(recurrenceInterval);
    map['recurrence_anchor'] = Variable<String>(recurrenceAnchor);
    map['recurrence_anchor_day'] = Variable<int>(recurrenceAnchorDay);
    map['recurrence_anchor_month'] = Variable<int>(recurrenceAnchorMonth);
    if (!nullToAbsent || reminderHour != null) {
      map['reminder_hour'] = Variable<int>(reminderHour);
    }
    if (!nullToAbsent || reminderMinute != null) {
      map['reminder_minute'] = Variable<int>(reminderMinute);
    }
    if (!nullToAbsent || reminderTimeZone != null) {
      map['reminder_time_zone'] = Variable<String>(reminderTimeZone);
    }
    map['paused'] = Variable<bool>(paused);
    return map;
  }

  TaskTemplatesCompanion toCompanion(bool nullToAbsent) {
    return TaskTemplatesCompanion(
      id: Value(id),
      homeId: Value(homeId),
      roomId: roomId == null && nullToAbsent
          ? const Value.absent()
          : Value(roomId),
      assetId: assetId == null && nullToAbsent
          ? const Value.absent()
          : Value(assetId),
      name: Value(name),
      startDate: Value(startDate),
      recurrenceKind: Value(recurrenceKind),
      recurrenceInterval: Value(recurrenceInterval),
      recurrenceAnchor: Value(recurrenceAnchor),
      recurrenceAnchorDay: Value(recurrenceAnchorDay),
      recurrenceAnchorMonth: Value(recurrenceAnchorMonth),
      reminderHour: reminderHour == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderHour),
      reminderMinute: reminderMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderMinute),
      reminderTimeZone: reminderTimeZone == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderTimeZone),
      paused: Value(paused),
    );
  }

  factory TaskTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskTemplate(
      id: serializer.fromJson<String>(json['id']),
      homeId: serializer.fromJson<String>(json['homeId']),
      roomId: serializer.fromJson<String?>(json['roomId']),
      assetId: serializer.fromJson<String?>(json['assetId']),
      name: serializer.fromJson<String>(json['name']),
      startDate: serializer.fromJson<String>(json['startDate']),
      recurrenceKind: serializer.fromJson<String>(json['recurrenceKind']),
      recurrenceInterval: serializer.fromJson<int>(json['recurrenceInterval']),
      recurrenceAnchor: serializer.fromJson<String>(json['recurrenceAnchor']),
      recurrenceAnchorDay: serializer.fromJson<int>(
        json['recurrenceAnchorDay'],
      ),
      recurrenceAnchorMonth: serializer.fromJson<int>(
        json['recurrenceAnchorMonth'],
      ),
      reminderHour: serializer.fromJson<int?>(json['reminderHour']),
      reminderMinute: serializer.fromJson<int?>(json['reminderMinute']),
      reminderTimeZone: serializer.fromJson<String?>(json['reminderTimeZone']),
      paused: serializer.fromJson<bool>(json['paused']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'homeId': serializer.toJson<String>(homeId),
      'roomId': serializer.toJson<String?>(roomId),
      'assetId': serializer.toJson<String?>(assetId),
      'name': serializer.toJson<String>(name),
      'startDate': serializer.toJson<String>(startDate),
      'recurrenceKind': serializer.toJson<String>(recurrenceKind),
      'recurrenceInterval': serializer.toJson<int>(recurrenceInterval),
      'recurrenceAnchor': serializer.toJson<String>(recurrenceAnchor),
      'recurrenceAnchorDay': serializer.toJson<int>(recurrenceAnchorDay),
      'recurrenceAnchorMonth': serializer.toJson<int>(recurrenceAnchorMonth),
      'reminderHour': serializer.toJson<int?>(reminderHour),
      'reminderMinute': serializer.toJson<int?>(reminderMinute),
      'reminderTimeZone': serializer.toJson<String?>(reminderTimeZone),
      'paused': serializer.toJson<bool>(paused),
    };
  }

  TaskTemplate copyWith({
    String? id,
    String? homeId,
    Value<String?> roomId = const Value.absent(),
    Value<String?> assetId = const Value.absent(),
    String? name,
    String? startDate,
    String? recurrenceKind,
    int? recurrenceInterval,
    String? recurrenceAnchor,
    int? recurrenceAnchorDay,
    int? recurrenceAnchorMonth,
    Value<int?> reminderHour = const Value.absent(),
    Value<int?> reminderMinute = const Value.absent(),
    Value<String?> reminderTimeZone = const Value.absent(),
    bool? paused,
  }) => TaskTemplate(
    id: id ?? this.id,
    homeId: homeId ?? this.homeId,
    roomId: roomId.present ? roomId.value : this.roomId,
    assetId: assetId.present ? assetId.value : this.assetId,
    name: name ?? this.name,
    startDate: startDate ?? this.startDate,
    recurrenceKind: recurrenceKind ?? this.recurrenceKind,
    recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
    recurrenceAnchor: recurrenceAnchor ?? this.recurrenceAnchor,
    recurrenceAnchorDay: recurrenceAnchorDay ?? this.recurrenceAnchorDay,
    recurrenceAnchorMonth: recurrenceAnchorMonth ?? this.recurrenceAnchorMonth,
    reminderHour: reminderHour.present ? reminderHour.value : this.reminderHour,
    reminderMinute: reminderMinute.present
        ? reminderMinute.value
        : this.reminderMinute,
    reminderTimeZone: reminderTimeZone.present
        ? reminderTimeZone.value
        : this.reminderTimeZone,
    paused: paused ?? this.paused,
  );
  TaskTemplate copyWithCompanion(TaskTemplatesCompanion data) {
    return TaskTemplate(
      id: data.id.present ? data.id.value : this.id,
      homeId: data.homeId.present ? data.homeId.value : this.homeId,
      roomId: data.roomId.present ? data.roomId.value : this.roomId,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      name: data.name.present ? data.name.value : this.name,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      recurrenceKind: data.recurrenceKind.present
          ? data.recurrenceKind.value
          : this.recurrenceKind,
      recurrenceInterval: data.recurrenceInterval.present
          ? data.recurrenceInterval.value
          : this.recurrenceInterval,
      recurrenceAnchor: data.recurrenceAnchor.present
          ? data.recurrenceAnchor.value
          : this.recurrenceAnchor,
      recurrenceAnchorDay: data.recurrenceAnchorDay.present
          ? data.recurrenceAnchorDay.value
          : this.recurrenceAnchorDay,
      recurrenceAnchorMonth: data.recurrenceAnchorMonth.present
          ? data.recurrenceAnchorMonth.value
          : this.recurrenceAnchorMonth,
      reminderHour: data.reminderHour.present
          ? data.reminderHour.value
          : this.reminderHour,
      reminderMinute: data.reminderMinute.present
          ? data.reminderMinute.value
          : this.reminderMinute,
      reminderTimeZone: data.reminderTimeZone.present
          ? data.reminderTimeZone.value
          : this.reminderTimeZone,
      paused: data.paused.present ? data.paused.value : this.paused,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskTemplate(')
          ..write('id: $id, ')
          ..write('homeId: $homeId, ')
          ..write('roomId: $roomId, ')
          ..write('assetId: $assetId, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('recurrenceKind: $recurrenceKind, ')
          ..write('recurrenceInterval: $recurrenceInterval, ')
          ..write('recurrenceAnchor: $recurrenceAnchor, ')
          ..write('recurrenceAnchorDay: $recurrenceAnchorDay, ')
          ..write('recurrenceAnchorMonth: $recurrenceAnchorMonth, ')
          ..write('reminderHour: $reminderHour, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('reminderTimeZone: $reminderTimeZone, ')
          ..write('paused: $paused')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    homeId,
    roomId,
    assetId,
    name,
    startDate,
    recurrenceKind,
    recurrenceInterval,
    recurrenceAnchor,
    recurrenceAnchorDay,
    recurrenceAnchorMonth,
    reminderHour,
    reminderMinute,
    reminderTimeZone,
    paused,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskTemplate &&
          other.id == this.id &&
          other.homeId == this.homeId &&
          other.roomId == this.roomId &&
          other.assetId == this.assetId &&
          other.name == this.name &&
          other.startDate == this.startDate &&
          other.recurrenceKind == this.recurrenceKind &&
          other.recurrenceInterval == this.recurrenceInterval &&
          other.recurrenceAnchor == this.recurrenceAnchor &&
          other.recurrenceAnchorDay == this.recurrenceAnchorDay &&
          other.recurrenceAnchorMonth == this.recurrenceAnchorMonth &&
          other.reminderHour == this.reminderHour &&
          other.reminderMinute == this.reminderMinute &&
          other.reminderTimeZone == this.reminderTimeZone &&
          other.paused == this.paused);
}

class TaskTemplatesCompanion extends UpdateCompanion<TaskTemplate> {
  final Value<String> id;
  final Value<String> homeId;
  final Value<String?> roomId;
  final Value<String?> assetId;
  final Value<String> name;
  final Value<String> startDate;
  final Value<String> recurrenceKind;
  final Value<int> recurrenceInterval;
  final Value<String> recurrenceAnchor;
  final Value<int> recurrenceAnchorDay;
  final Value<int> recurrenceAnchorMonth;
  final Value<int?> reminderHour;
  final Value<int?> reminderMinute;
  final Value<String?> reminderTimeZone;
  final Value<bool> paused;
  final Value<int> rowid;
  const TaskTemplatesCompanion({
    this.id = const Value.absent(),
    this.homeId = const Value.absent(),
    this.roomId = const Value.absent(),
    this.assetId = const Value.absent(),
    this.name = const Value.absent(),
    this.startDate = const Value.absent(),
    this.recurrenceKind = const Value.absent(),
    this.recurrenceInterval = const Value.absent(),
    this.recurrenceAnchor = const Value.absent(),
    this.recurrenceAnchorDay = const Value.absent(),
    this.recurrenceAnchorMonth = const Value.absent(),
    this.reminderHour = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.reminderTimeZone = const Value.absent(),
    this.paused = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskTemplatesCompanion.insert({
    required String id,
    required String homeId,
    this.roomId = const Value.absent(),
    this.assetId = const Value.absent(),
    required String name,
    required String startDate,
    required String recurrenceKind,
    required int recurrenceInterval,
    required String recurrenceAnchor,
    required int recurrenceAnchorDay,
    required int recurrenceAnchorMonth,
    this.reminderHour = const Value.absent(),
    this.reminderMinute = const Value.absent(),
    this.reminderTimeZone = const Value.absent(),
    this.paused = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       homeId = Value(homeId),
       name = Value(name),
       startDate = Value(startDate),
       recurrenceKind = Value(recurrenceKind),
       recurrenceInterval = Value(recurrenceInterval),
       recurrenceAnchor = Value(recurrenceAnchor),
       recurrenceAnchorDay = Value(recurrenceAnchorDay),
       recurrenceAnchorMonth = Value(recurrenceAnchorMonth);
  static Insertable<TaskTemplate> custom({
    Expression<String>? id,
    Expression<String>? homeId,
    Expression<String>? roomId,
    Expression<String>? assetId,
    Expression<String>? name,
    Expression<String>? startDate,
    Expression<String>? recurrenceKind,
    Expression<int>? recurrenceInterval,
    Expression<String>? recurrenceAnchor,
    Expression<int>? recurrenceAnchorDay,
    Expression<int>? recurrenceAnchorMonth,
    Expression<int>? reminderHour,
    Expression<int>? reminderMinute,
    Expression<String>? reminderTimeZone,
    Expression<bool>? paused,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (homeId != null) 'home_id': homeId,
      if (roomId != null) 'room_id': roomId,
      if (assetId != null) 'asset_id': assetId,
      if (name != null) 'name': name,
      if (startDate != null) 'start_date': startDate,
      if (recurrenceKind != null) 'recurrence_kind': recurrenceKind,
      if (recurrenceInterval != null) 'recurrence_interval': recurrenceInterval,
      if (recurrenceAnchor != null) 'recurrence_anchor': recurrenceAnchor,
      if (recurrenceAnchorDay != null)
        'recurrence_anchor_day': recurrenceAnchorDay,
      if (recurrenceAnchorMonth != null)
        'recurrence_anchor_month': recurrenceAnchorMonth,
      if (reminderHour != null) 'reminder_hour': reminderHour,
      if (reminderMinute != null) 'reminder_minute': reminderMinute,
      if (reminderTimeZone != null) 'reminder_time_zone': reminderTimeZone,
      if (paused != null) 'paused': paused,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskTemplatesCompanion copyWith({
    Value<String>? id,
    Value<String>? homeId,
    Value<String?>? roomId,
    Value<String?>? assetId,
    Value<String>? name,
    Value<String>? startDate,
    Value<String>? recurrenceKind,
    Value<int>? recurrenceInterval,
    Value<String>? recurrenceAnchor,
    Value<int>? recurrenceAnchorDay,
    Value<int>? recurrenceAnchorMonth,
    Value<int?>? reminderHour,
    Value<int?>? reminderMinute,
    Value<String?>? reminderTimeZone,
    Value<bool>? paused,
    Value<int>? rowid,
  }) {
    return TaskTemplatesCompanion(
      id: id ?? this.id,
      homeId: homeId ?? this.homeId,
      roomId: roomId ?? this.roomId,
      assetId: assetId ?? this.assetId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      recurrenceKind: recurrenceKind ?? this.recurrenceKind,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceAnchor: recurrenceAnchor ?? this.recurrenceAnchor,
      recurrenceAnchorDay: recurrenceAnchorDay ?? this.recurrenceAnchorDay,
      recurrenceAnchorMonth:
          recurrenceAnchorMonth ?? this.recurrenceAnchorMonth,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      reminderTimeZone: reminderTimeZone ?? this.reminderTimeZone,
      paused: paused ?? this.paused,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (homeId.present) {
      map['home_id'] = Variable<String>(homeId.value);
    }
    if (roomId.present) {
      map['room_id'] = Variable<String>(roomId.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (recurrenceKind.present) {
      map['recurrence_kind'] = Variable<String>(recurrenceKind.value);
    }
    if (recurrenceInterval.present) {
      map['recurrence_interval'] = Variable<int>(recurrenceInterval.value);
    }
    if (recurrenceAnchor.present) {
      map['recurrence_anchor'] = Variable<String>(recurrenceAnchor.value);
    }
    if (recurrenceAnchorDay.present) {
      map['recurrence_anchor_day'] = Variable<int>(recurrenceAnchorDay.value);
    }
    if (recurrenceAnchorMonth.present) {
      map['recurrence_anchor_month'] = Variable<int>(
        recurrenceAnchorMonth.value,
      );
    }
    if (reminderHour.present) {
      map['reminder_hour'] = Variable<int>(reminderHour.value);
    }
    if (reminderMinute.present) {
      map['reminder_minute'] = Variable<int>(reminderMinute.value);
    }
    if (reminderTimeZone.present) {
      map['reminder_time_zone'] = Variable<String>(reminderTimeZone.value);
    }
    if (paused.present) {
      map['paused'] = Variable<bool>(paused.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('homeId: $homeId, ')
          ..write('roomId: $roomId, ')
          ..write('assetId: $assetId, ')
          ..write('name: $name, ')
          ..write('startDate: $startDate, ')
          ..write('recurrenceKind: $recurrenceKind, ')
          ..write('recurrenceInterval: $recurrenceInterval, ')
          ..write('recurrenceAnchor: $recurrenceAnchor, ')
          ..write('recurrenceAnchorDay: $recurrenceAnchorDay, ')
          ..write('recurrenceAnchorMonth: $recurrenceAnchorMonth, ')
          ..write('reminderHour: $reminderHour, ')
          ..write('reminderMinute: $reminderMinute, ')
          ..write('reminderTimeZone: $reminderTimeZone, ')
          ..write('paused: $paused, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskOccurrencesTable extends TaskOccurrences
    with TableInfo<$TaskOccurrencesTable, TaskOccurrence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskOccurrencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskTemplateIdMeta = const VerificationMeta(
    'taskTemplateId',
  );
  @override
  late final GeneratedColumn<String> taskTemplateId = GeneratedColumn<String>(
    'task_template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES task_templates (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _scheduledDateMeta = const VerificationMeta(
    'scheduledDate',
  );
  @override
  late final GeneratedColumn<String> scheduledDate = GeneratedColumn<String>(
    'scheduled_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snoozedUntilMeta = const VerificationMeta(
    'snoozedUntil',
  );
  @override
  late final GeneratedColumn<String> snoozedUntil = GeneratedColumn<String>(
    'snoozed_until',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskTemplateId,
    scheduledDate,
    snoozedUntil,
    state,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_occurrences';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskOccurrence> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_template_id')) {
      context.handle(
        _taskTemplateIdMeta,
        taskTemplateId.isAcceptableOrUnknown(
          data['task_template_id']!,
          _taskTemplateIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_taskTemplateIdMeta);
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
        _scheduledDateMeta,
        scheduledDate.isAcceptableOrUnknown(
          data['scheduled_date']!,
          _scheduledDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledDateMeta);
    }
    if (data.containsKey('snoozed_until')) {
      context.handle(
        _snoozedUntilMeta,
        snoozedUntil.isAcceptableOrUnknown(
          data['snoozed_until']!,
          _snoozedUntilMeta,
        ),
      );
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskOccurrence map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskOccurrence(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskTemplateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_template_id'],
      )!,
      scheduledDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scheduled_date'],
      )!,
      snoozedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snoozed_until'],
      ),
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
    );
  }

  @override
  $TaskOccurrencesTable createAlias(String alias) {
    return $TaskOccurrencesTable(attachedDatabase, alias);
  }
}

class TaskOccurrence extends DataClass implements Insertable<TaskOccurrence> {
  final String id;
  final String taskTemplateId;
  final String scheduledDate;
  final String? snoozedUntil;
  final String state;
  const TaskOccurrence({
    required this.id,
    required this.taskTemplateId,
    required this.scheduledDate,
    this.snoozedUntil,
    required this.state,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['task_template_id'] = Variable<String>(taskTemplateId);
    map['scheduled_date'] = Variable<String>(scheduledDate);
    if (!nullToAbsent || snoozedUntil != null) {
      map['snoozed_until'] = Variable<String>(snoozedUntil);
    }
    map['state'] = Variable<String>(state);
    return map;
  }

  TaskOccurrencesCompanion toCompanion(bool nullToAbsent) {
    return TaskOccurrencesCompanion(
      id: Value(id),
      taskTemplateId: Value(taskTemplateId),
      scheduledDate: Value(scheduledDate),
      snoozedUntil: snoozedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozedUntil),
      state: Value(state),
    );
  }

  factory TaskOccurrence.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskOccurrence(
      id: serializer.fromJson<String>(json['id']),
      taskTemplateId: serializer.fromJson<String>(json['taskTemplateId']),
      scheduledDate: serializer.fromJson<String>(json['scheduledDate']),
      snoozedUntil: serializer.fromJson<String?>(json['snoozedUntil']),
      state: serializer.fromJson<String>(json['state']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskTemplateId': serializer.toJson<String>(taskTemplateId),
      'scheduledDate': serializer.toJson<String>(scheduledDate),
      'snoozedUntil': serializer.toJson<String?>(snoozedUntil),
      'state': serializer.toJson<String>(state),
    };
  }

  TaskOccurrence copyWith({
    String? id,
    String? taskTemplateId,
    String? scheduledDate,
    Value<String?> snoozedUntil = const Value.absent(),
    String? state,
  }) => TaskOccurrence(
    id: id ?? this.id,
    taskTemplateId: taskTemplateId ?? this.taskTemplateId,
    scheduledDate: scheduledDate ?? this.scheduledDate,
    snoozedUntil: snoozedUntil.present ? snoozedUntil.value : this.snoozedUntil,
    state: state ?? this.state,
  );
  TaskOccurrence copyWithCompanion(TaskOccurrencesCompanion data) {
    return TaskOccurrence(
      id: data.id.present ? data.id.value : this.id,
      taskTemplateId: data.taskTemplateId.present
          ? data.taskTemplateId.value
          : this.taskTemplateId,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
      snoozedUntil: data.snoozedUntil.present
          ? data.snoozedUntil.value
          : this.snoozedUntil,
      state: data.state.present ? data.state.value : this.state,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskOccurrence(')
          ..write('id: $id, ')
          ..write('taskTemplateId: $taskTemplateId, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('state: $state')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, taskTemplateId, scheduledDate, snoozedUntil, state);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskOccurrence &&
          other.id == this.id &&
          other.taskTemplateId == this.taskTemplateId &&
          other.scheduledDate == this.scheduledDate &&
          other.snoozedUntil == this.snoozedUntil &&
          other.state == this.state);
}

class TaskOccurrencesCompanion extends UpdateCompanion<TaskOccurrence> {
  final Value<String> id;
  final Value<String> taskTemplateId;
  final Value<String> scheduledDate;
  final Value<String?> snoozedUntil;
  final Value<String> state;
  final Value<int> rowid;
  const TaskOccurrencesCompanion({
    this.id = const Value.absent(),
    this.taskTemplateId = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.state = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskOccurrencesCompanion.insert({
    required String id,
    required String taskTemplateId,
    required String scheduledDate,
    this.snoozedUntil = const Value.absent(),
    required String state,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       taskTemplateId = Value(taskTemplateId),
       scheduledDate = Value(scheduledDate),
       state = Value(state);
  static Insertable<TaskOccurrence> custom({
    Expression<String>? id,
    Expression<String>? taskTemplateId,
    Expression<String>? scheduledDate,
    Expression<String>? snoozedUntil,
    Expression<String>? state,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskTemplateId != null) 'task_template_id': taskTemplateId,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (snoozedUntil != null) 'snoozed_until': snoozedUntil,
      if (state != null) 'state': state,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskOccurrencesCompanion copyWith({
    Value<String>? id,
    Value<String>? taskTemplateId,
    Value<String>? scheduledDate,
    Value<String?>? snoozedUntil,
    Value<String>? state,
    Value<int>? rowid,
  }) {
    return TaskOccurrencesCompanion(
      id: id ?? this.id,
      taskTemplateId: taskTemplateId ?? this.taskTemplateId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      state: state ?? this.state,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskTemplateId.present) {
      map['task_template_id'] = Variable<String>(taskTemplateId.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<String>(scheduledDate.value);
    }
    if (snoozedUntil.present) {
      map['snoozed_until'] = Variable<String>(snoozedUntil.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskOccurrencesCompanion(')
          ..write('id: $id, ')
          ..write('taskTemplateId: $taskTemplateId, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('state: $state, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CompletionsTable extends Completions
    with TableInfo<$CompletionsTable, Completion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompletionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurrenceIdMeta = const VerificationMeta(
    'occurrenceId',
  );
  @override
  late final GeneratedColumn<String> occurrenceId = GeneratedColumn<String>(
    'occurrence_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'UNIQUE REFERENCES task_occurrences (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _scheduledDateMeta = const VerificationMeta(
    'scheduledDate',
  );
  @override
  late final GeneratedColumn<String> scheduledDate = GeneratedColumn<String>(
    'scheduled_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, occurrenceId, scheduledDate];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'completions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Completion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('occurrence_id')) {
      context.handle(
        _occurrenceIdMeta,
        occurrenceId.isAcceptableOrUnknown(
          data['occurrence_id']!,
          _occurrenceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurrenceIdMeta);
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
        _scheduledDateMeta,
        scheduledDate.isAcceptableOrUnknown(
          data['scheduled_date']!,
          _scheduledDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledDateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Completion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Completion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      occurrenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurrence_id'],
      )!,
      scheduledDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scheduled_date'],
      )!,
    );
  }

  @override
  $CompletionsTable createAlias(String alias) {
    return $CompletionsTable(attachedDatabase, alias);
  }
}

class Completion extends DataClass implements Insertable<Completion> {
  final String id;
  final String occurrenceId;
  final String scheduledDate;
  const Completion({
    required this.id,
    required this.occurrenceId,
    required this.scheduledDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['occurrence_id'] = Variable<String>(occurrenceId);
    map['scheduled_date'] = Variable<String>(scheduledDate);
    return map;
  }

  CompletionsCompanion toCompanion(bool nullToAbsent) {
    return CompletionsCompanion(
      id: Value(id),
      occurrenceId: Value(occurrenceId),
      scheduledDate: Value(scheduledDate),
    );
  }

  factory Completion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Completion(
      id: serializer.fromJson<String>(json['id']),
      occurrenceId: serializer.fromJson<String>(json['occurrenceId']),
      scheduledDate: serializer.fromJson<String>(json['scheduledDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'occurrenceId': serializer.toJson<String>(occurrenceId),
      'scheduledDate': serializer.toJson<String>(scheduledDate),
    };
  }

  Completion copyWith({
    String? id,
    String? occurrenceId,
    String? scheduledDate,
  }) => Completion(
    id: id ?? this.id,
    occurrenceId: occurrenceId ?? this.occurrenceId,
    scheduledDate: scheduledDate ?? this.scheduledDate,
  );
  Completion copyWithCompanion(CompletionsCompanion data) {
    return Completion(
      id: data.id.present ? data.id.value : this.id,
      occurrenceId: data.occurrenceId.present
          ? data.occurrenceId.value
          : this.occurrenceId,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Completion(')
          ..write('id: $id, ')
          ..write('occurrenceId: $occurrenceId, ')
          ..write('scheduledDate: $scheduledDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, occurrenceId, scheduledDate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Completion &&
          other.id == this.id &&
          other.occurrenceId == this.occurrenceId &&
          other.scheduledDate == this.scheduledDate);
}

class CompletionsCompanion extends UpdateCompanion<Completion> {
  final Value<String> id;
  final Value<String> occurrenceId;
  final Value<String> scheduledDate;
  final Value<int> rowid;
  const CompletionsCompanion({
    this.id = const Value.absent(),
    this.occurrenceId = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CompletionsCompanion.insert({
    required String id,
    required String occurrenceId,
    required String scheduledDate,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       occurrenceId = Value(occurrenceId),
       scheduledDate = Value(scheduledDate);
  static Insertable<Completion> custom({
    Expression<String>? id,
    Expression<String>? occurrenceId,
    Expression<String>? scheduledDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (occurrenceId != null) 'occurrence_id': occurrenceId,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CompletionsCompanion copyWith({
    Value<String>? id,
    Value<String>? occurrenceId,
    Value<String>? scheduledDate,
    Value<int>? rowid,
  }) {
    return CompletionsCompanion(
      id: id ?? this.id,
      occurrenceId: occurrenceId ?? this.occurrenceId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (occurrenceId.present) {
      map['occurrence_id'] = Variable<String>(occurrenceId.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<String>(scheduledDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompletionsCompanion(')
          ..write('id: $id, ')
          ..write('occurrenceId: $occurrenceId, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CompletionRevisionsTable extends CompletionRevisions
    with TableInfo<$CompletionRevisionsTable, CompletionRevision> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompletionRevisionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _completionIdMeta = const VerificationMeta(
    'completionId',
  );
  @override
  late final GeneratedColumn<String> completionId = GeneratedColumn<String>(
    'completion_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES completions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualDateMeta = const VerificationMeta(
    'actualDate',
  );
  @override
  late final GeneratedColumn<String> actualDate = GeneratedColumn<String>(
    'actual_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partsTextMeta = const VerificationMeta(
    'partsText',
  );
  @override
  late final GeneratedColumn<String> partsText = GeneratedColumn<String>(
    'parts_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _costMinorUnitsMeta = const VerificationMeta(
    'costMinorUnits',
  );
  @override
  late final GeneratedColumn<int> costMinorUnits = GeneratedColumn<int>(
    'cost_minor_units',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _costCurrencyMeta = const VerificationMeta(
    'costCurrency',
  );
  @override
  late final GeneratedColumn<String> costCurrency = GeneratedColumn<String>(
    'cost_currency',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> revisedAtUtc =
      GeneratedColumn<int>(
        'revised_at_utc',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>(
        $CompletionRevisionsTable.$converterrevisedAtUtc,
      );
  @override
  List<GeneratedColumn> get $columns => [
    completionId,
    revision,
    actualDate,
    notes,
    partsText,
    costMinorUnits,
    costCurrency,
    revisedAtUtc,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'completion_revisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CompletionRevision> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('completion_id')) {
      context.handle(
        _completionIdMeta,
        completionId.isAcceptableOrUnknown(
          data['completion_id']!,
          _completionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completionIdMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('actual_date')) {
      context.handle(
        _actualDateMeta,
        actualDate.isAcceptableOrUnknown(data['actual_date']!, _actualDateMeta),
      );
    } else if (isInserting) {
      context.missing(_actualDateMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('parts_text')) {
      context.handle(
        _partsTextMeta,
        partsText.isAcceptableOrUnknown(data['parts_text']!, _partsTextMeta),
      );
    }
    if (data.containsKey('cost_minor_units')) {
      context.handle(
        _costMinorUnitsMeta,
        costMinorUnits.isAcceptableOrUnknown(
          data['cost_minor_units']!,
          _costMinorUnitsMeta,
        ),
      );
    }
    if (data.containsKey('cost_currency')) {
      context.handle(
        _costCurrencyMeta,
        costCurrency.isAcceptableOrUnknown(
          data['cost_currency']!,
          _costCurrencyMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {completionId, revision};
  @override
  CompletionRevision map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompletionRevision(
      completionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completion_id'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      actualDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}actual_date'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      partsText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parts_text'],
      ),
      costMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cost_minor_units'],
      ),
      costCurrency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cost_currency'],
      ),
      revisedAtUtc: $CompletionRevisionsTable.$converterrevisedAtUtc.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}revised_at_utc'],
        )!,
      ),
    );
  }

  @override
  $CompletionRevisionsTable createAlias(String alias) {
    return $CompletionRevisionsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterrevisedAtUtc =
      const UtcMicrosecondsConverter();
}

class CompletionRevision extends DataClass
    implements Insertable<CompletionRevision> {
  final String completionId;
  final int revision;
  final String actualDate;
  final String? notes;
  final String? partsText;
  final int? costMinorUnits;
  final String? costCurrency;
  final DateTime revisedAtUtc;
  const CompletionRevision({
    required this.completionId,
    required this.revision,
    required this.actualDate,
    this.notes,
    this.partsText,
    this.costMinorUnits,
    this.costCurrency,
    required this.revisedAtUtc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['completion_id'] = Variable<String>(completionId);
    map['revision'] = Variable<int>(revision);
    map['actual_date'] = Variable<String>(actualDate);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || partsText != null) {
      map['parts_text'] = Variable<String>(partsText);
    }
    if (!nullToAbsent || costMinorUnits != null) {
      map['cost_minor_units'] = Variable<int>(costMinorUnits);
    }
    if (!nullToAbsent || costCurrency != null) {
      map['cost_currency'] = Variable<String>(costCurrency);
    }
    {
      map['revised_at_utc'] = Variable<int>(
        $CompletionRevisionsTable.$converterrevisedAtUtc.toSql(revisedAtUtc),
      );
    }
    return map;
  }

  CompletionRevisionsCompanion toCompanion(bool nullToAbsent) {
    return CompletionRevisionsCompanion(
      completionId: Value(completionId),
      revision: Value(revision),
      actualDate: Value(actualDate),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      partsText: partsText == null && nullToAbsent
          ? const Value.absent()
          : Value(partsText),
      costMinorUnits: costMinorUnits == null && nullToAbsent
          ? const Value.absent()
          : Value(costMinorUnits),
      costCurrency: costCurrency == null && nullToAbsent
          ? const Value.absent()
          : Value(costCurrency),
      revisedAtUtc: Value(revisedAtUtc),
    );
  }

  factory CompletionRevision.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompletionRevision(
      completionId: serializer.fromJson<String>(json['completionId']),
      revision: serializer.fromJson<int>(json['revision']),
      actualDate: serializer.fromJson<String>(json['actualDate']),
      notes: serializer.fromJson<String?>(json['notes']),
      partsText: serializer.fromJson<String?>(json['partsText']),
      costMinorUnits: serializer.fromJson<int?>(json['costMinorUnits']),
      costCurrency: serializer.fromJson<String?>(json['costCurrency']),
      revisedAtUtc: serializer.fromJson<DateTime>(json['revisedAtUtc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'completionId': serializer.toJson<String>(completionId),
      'revision': serializer.toJson<int>(revision),
      'actualDate': serializer.toJson<String>(actualDate),
      'notes': serializer.toJson<String?>(notes),
      'partsText': serializer.toJson<String?>(partsText),
      'costMinorUnits': serializer.toJson<int?>(costMinorUnits),
      'costCurrency': serializer.toJson<String?>(costCurrency),
      'revisedAtUtc': serializer.toJson<DateTime>(revisedAtUtc),
    };
  }

  CompletionRevision copyWith({
    String? completionId,
    int? revision,
    String? actualDate,
    Value<String?> notes = const Value.absent(),
    Value<String?> partsText = const Value.absent(),
    Value<int?> costMinorUnits = const Value.absent(),
    Value<String?> costCurrency = const Value.absent(),
    DateTime? revisedAtUtc,
  }) => CompletionRevision(
    completionId: completionId ?? this.completionId,
    revision: revision ?? this.revision,
    actualDate: actualDate ?? this.actualDate,
    notes: notes.present ? notes.value : this.notes,
    partsText: partsText.present ? partsText.value : this.partsText,
    costMinorUnits: costMinorUnits.present
        ? costMinorUnits.value
        : this.costMinorUnits,
    costCurrency: costCurrency.present ? costCurrency.value : this.costCurrency,
    revisedAtUtc: revisedAtUtc ?? this.revisedAtUtc,
  );
  CompletionRevision copyWithCompanion(CompletionRevisionsCompanion data) {
    return CompletionRevision(
      completionId: data.completionId.present
          ? data.completionId.value
          : this.completionId,
      revision: data.revision.present ? data.revision.value : this.revision,
      actualDate: data.actualDate.present
          ? data.actualDate.value
          : this.actualDate,
      notes: data.notes.present ? data.notes.value : this.notes,
      partsText: data.partsText.present ? data.partsText.value : this.partsText,
      costMinorUnits: data.costMinorUnits.present
          ? data.costMinorUnits.value
          : this.costMinorUnits,
      costCurrency: data.costCurrency.present
          ? data.costCurrency.value
          : this.costCurrency,
      revisedAtUtc: data.revisedAtUtc.present
          ? data.revisedAtUtc.value
          : this.revisedAtUtc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompletionRevision(')
          ..write('completionId: $completionId, ')
          ..write('revision: $revision, ')
          ..write('actualDate: $actualDate, ')
          ..write('notes: $notes, ')
          ..write('partsText: $partsText, ')
          ..write('costMinorUnits: $costMinorUnits, ')
          ..write('costCurrency: $costCurrency, ')
          ..write('revisedAtUtc: $revisedAtUtc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    completionId,
    revision,
    actualDate,
    notes,
    partsText,
    costMinorUnits,
    costCurrency,
    revisedAtUtc,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompletionRevision &&
          other.completionId == this.completionId &&
          other.revision == this.revision &&
          other.actualDate == this.actualDate &&
          other.notes == this.notes &&
          other.partsText == this.partsText &&
          other.costMinorUnits == this.costMinorUnits &&
          other.costCurrency == this.costCurrency &&
          other.revisedAtUtc == this.revisedAtUtc);
}

class CompletionRevisionsCompanion extends UpdateCompanion<CompletionRevision> {
  final Value<String> completionId;
  final Value<int> revision;
  final Value<String> actualDate;
  final Value<String?> notes;
  final Value<String?> partsText;
  final Value<int?> costMinorUnits;
  final Value<String?> costCurrency;
  final Value<DateTime> revisedAtUtc;
  final Value<int> rowid;
  const CompletionRevisionsCompanion({
    this.completionId = const Value.absent(),
    this.revision = const Value.absent(),
    this.actualDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.partsText = const Value.absent(),
    this.costMinorUnits = const Value.absent(),
    this.costCurrency = const Value.absent(),
    this.revisedAtUtc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CompletionRevisionsCompanion.insert({
    required String completionId,
    required int revision,
    required String actualDate,
    this.notes = const Value.absent(),
    this.partsText = const Value.absent(),
    this.costMinorUnits = const Value.absent(),
    this.costCurrency = const Value.absent(),
    required DateTime revisedAtUtc,
    this.rowid = const Value.absent(),
  }) : completionId = Value(completionId),
       revision = Value(revision),
       actualDate = Value(actualDate),
       revisedAtUtc = Value(revisedAtUtc);
  static Insertable<CompletionRevision> custom({
    Expression<String>? completionId,
    Expression<int>? revision,
    Expression<String>? actualDate,
    Expression<String>? notes,
    Expression<String>? partsText,
    Expression<int>? costMinorUnits,
    Expression<String>? costCurrency,
    Expression<int>? revisedAtUtc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (completionId != null) 'completion_id': completionId,
      if (revision != null) 'revision': revision,
      if (actualDate != null) 'actual_date': actualDate,
      if (notes != null) 'notes': notes,
      if (partsText != null) 'parts_text': partsText,
      if (costMinorUnits != null) 'cost_minor_units': costMinorUnits,
      if (costCurrency != null) 'cost_currency': costCurrency,
      if (revisedAtUtc != null) 'revised_at_utc': revisedAtUtc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CompletionRevisionsCompanion copyWith({
    Value<String>? completionId,
    Value<int>? revision,
    Value<String>? actualDate,
    Value<String?>? notes,
    Value<String?>? partsText,
    Value<int?>? costMinorUnits,
    Value<String?>? costCurrency,
    Value<DateTime>? revisedAtUtc,
    Value<int>? rowid,
  }) {
    return CompletionRevisionsCompanion(
      completionId: completionId ?? this.completionId,
      revision: revision ?? this.revision,
      actualDate: actualDate ?? this.actualDate,
      notes: notes ?? this.notes,
      partsText: partsText ?? this.partsText,
      costMinorUnits: costMinorUnits ?? this.costMinorUnits,
      costCurrency: costCurrency ?? this.costCurrency,
      revisedAtUtc: revisedAtUtc ?? this.revisedAtUtc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (completionId.present) {
      map['completion_id'] = Variable<String>(completionId.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (actualDate.present) {
      map['actual_date'] = Variable<String>(actualDate.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (partsText.present) {
      map['parts_text'] = Variable<String>(partsText.value);
    }
    if (costMinorUnits.present) {
      map['cost_minor_units'] = Variable<int>(costMinorUnits.value);
    }
    if (costCurrency.present) {
      map['cost_currency'] = Variable<String>(costCurrency.value);
    }
    if (revisedAtUtc.present) {
      map['revised_at_utc'] = Variable<int>(
        $CompletionRevisionsTable.$converterrevisedAtUtc.toSql(
          revisedAtUtc.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompletionRevisionsCompanion(')
          ..write('completionId: $completionId, ')
          ..write('revision: $revision, ')
          ..write('actualDate: $actualDate, ')
          ..write('notes: $notes, ')
          ..write('partsText: $partsText, ')
          ..write('costMinorUnits: $costMinorUnits, ')
          ..write('costCurrency: $costCurrency, ')
          ..write('revisedAtUtc: $revisedAtUtc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentMetadataRowsTable extends AttachmentMetadataRows
    with TableInfo<$AttachmentMetadataRowsTable, AttachmentMetadataRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentMetadataRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completionIdMeta = const VerificationMeta(
    'completionId',
  );
  @override
  late final GeneratedColumn<String> completionId = GeneratedColumn<String>(
    'completion_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES completions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _captionMeta = const VerificationMeta(
    'caption',
  );
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
    'caption',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    completionId,
    relativePath,
    mediaType,
    sha256,
    caption,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachment_metadata_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttachmentMetadataRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('completion_id')) {
      context.handle(
        _completionIdMeta,
        completionId.isAcceptableOrUnknown(
          data['completion_id']!,
          _completionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_completionIdMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    } else if (isInserting) {
      context.missing(_sha256Meta);
    }
    if (data.containsKey('caption')) {
      context.handle(
        _captionMeta,
        caption.isAcceptableOrUnknown(data['caption']!, _captionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttachmentMetadataRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttachmentMetadataRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      completionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completion_id'],
      )!,
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      )!,
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      )!,
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      )!,
      caption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caption'],
      ),
    );
  }

  @override
  $AttachmentMetadataRowsTable createAlias(String alias) {
    return $AttachmentMetadataRowsTable(attachedDatabase, alias);
  }
}

class AttachmentMetadataRow extends DataClass
    implements Insertable<AttachmentMetadataRow> {
  final String id;
  final String completionId;
  final String relativePath;
  final String mediaType;
  final String sha256;
  final String? caption;
  const AttachmentMetadataRow({
    required this.id,
    required this.completionId,
    required this.relativePath,
    required this.mediaType,
    required this.sha256,
    this.caption,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['completion_id'] = Variable<String>(completionId);
    map['relative_path'] = Variable<String>(relativePath);
    map['media_type'] = Variable<String>(mediaType);
    map['sha256'] = Variable<String>(sha256);
    if (!nullToAbsent || caption != null) {
      map['caption'] = Variable<String>(caption);
    }
    return map;
  }

  AttachmentMetadataRowsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentMetadataRowsCompanion(
      id: Value(id),
      completionId: Value(completionId),
      relativePath: Value(relativePath),
      mediaType: Value(mediaType),
      sha256: Value(sha256),
      caption: caption == null && nullToAbsent
          ? const Value.absent()
          : Value(caption),
    );
  }

  factory AttachmentMetadataRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttachmentMetadataRow(
      id: serializer.fromJson<String>(json['id']),
      completionId: serializer.fromJson<String>(json['completionId']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      sha256: serializer.fromJson<String>(json['sha256']),
      caption: serializer.fromJson<String?>(json['caption']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'completionId': serializer.toJson<String>(completionId),
      'relativePath': serializer.toJson<String>(relativePath),
      'mediaType': serializer.toJson<String>(mediaType),
      'sha256': serializer.toJson<String>(sha256),
      'caption': serializer.toJson<String?>(caption),
    };
  }

  AttachmentMetadataRow copyWith({
    String? id,
    String? completionId,
    String? relativePath,
    String? mediaType,
    String? sha256,
    Value<String?> caption = const Value.absent(),
  }) => AttachmentMetadataRow(
    id: id ?? this.id,
    completionId: completionId ?? this.completionId,
    relativePath: relativePath ?? this.relativePath,
    mediaType: mediaType ?? this.mediaType,
    sha256: sha256 ?? this.sha256,
    caption: caption.present ? caption.value : this.caption,
  );
  AttachmentMetadataRow copyWithCompanion(
    AttachmentMetadataRowsCompanion data,
  ) {
    return AttachmentMetadataRow(
      id: data.id.present ? data.id.value : this.id,
      completionId: data.completionId.present
          ? data.completionId.value
          : this.completionId,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      caption: data.caption.present ? data.caption.value : this.caption,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentMetadataRow(')
          ..write('id: $id, ')
          ..write('completionId: $completionId, ')
          ..write('relativePath: $relativePath, ')
          ..write('mediaType: $mediaType, ')
          ..write('sha256: $sha256, ')
          ..write('caption: $caption')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, completionId, relativePath, mediaType, sha256, caption);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttachmentMetadataRow &&
          other.id == this.id &&
          other.completionId == this.completionId &&
          other.relativePath == this.relativePath &&
          other.mediaType == this.mediaType &&
          other.sha256 == this.sha256 &&
          other.caption == this.caption);
}

class AttachmentMetadataRowsCompanion
    extends UpdateCompanion<AttachmentMetadataRow> {
  final Value<String> id;
  final Value<String> completionId;
  final Value<String> relativePath;
  final Value<String> mediaType;
  final Value<String> sha256;
  final Value<String?> caption;
  final Value<int> rowid;
  const AttachmentMetadataRowsCompanion({
    this.id = const Value.absent(),
    this.completionId = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.caption = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentMetadataRowsCompanion.insert({
    required String id,
    required String completionId,
    required String relativePath,
    required String mediaType,
    required String sha256,
    this.caption = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       completionId = Value(completionId),
       relativePath = Value(relativePath),
       mediaType = Value(mediaType),
       sha256 = Value(sha256);
  static Insertable<AttachmentMetadataRow> custom({
    Expression<String>? id,
    Expression<String>? completionId,
    Expression<String>? relativePath,
    Expression<String>? mediaType,
    Expression<String>? sha256,
    Expression<String>? caption,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (completionId != null) 'completion_id': completionId,
      if (relativePath != null) 'relative_path': relativePath,
      if (mediaType != null) 'media_type': mediaType,
      if (sha256 != null) 'sha256': sha256,
      if (caption != null) 'caption': caption,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentMetadataRowsCompanion copyWith({
    Value<String>? id,
    Value<String>? completionId,
    Value<String>? relativePath,
    Value<String>? mediaType,
    Value<String>? sha256,
    Value<String?>? caption,
    Value<int>? rowid,
  }) {
    return AttachmentMetadataRowsCompanion(
      id: id ?? this.id,
      completionId: completionId ?? this.completionId,
      relativePath: relativePath ?? this.relativePath,
      mediaType: mediaType ?? this.mediaType,
      sha256: sha256 ?? this.sha256,
      caption: caption ?? this.caption,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (completionId.present) {
      map['completion_id'] = Variable<String>(completionId.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentMetadataRowsCompanion(')
          ..write('id: $id, ')
          ..write('completionId: $completionId, ')
          ..write('relativePath: $relativePath, ')
          ..write('mediaType: $mediaType, ')
          ..write('sha256: $sha256, ')
          ..write('caption: $caption, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$UpkeepDatabase extends GeneratedDatabase {
  _$UpkeepDatabase(QueryExecutor e) : super(e);
  $UpkeepDatabaseManager get managers => $UpkeepDatabaseManager(this);
  late final $HomesTable homes = $HomesTable(this);
  late final $RoomsTable rooms = $RoomsTable(this);
  late final $AssetsTable assets = $AssetsTable(this);
  late final $TaskTemplatesTable taskTemplates = $TaskTemplatesTable(this);
  late final $TaskOccurrencesTable taskOccurrences = $TaskOccurrencesTable(
    this,
  );
  late final $CompletionsTable completions = $CompletionsTable(this);
  late final $CompletionRevisionsTable completionRevisions =
      $CompletionRevisionsTable(this);
  late final $AttachmentMetadataRowsTable attachmentMetadataRows =
      $AttachmentMetadataRowsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    homes,
    rooms,
    assets,
    taskTemplates,
    taskOccurrences,
    completions,
    completionRevisions,
    attachmentMetadataRows,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'homes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('rooms', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'homes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('assets', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'homes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('task_templates', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'task_templates',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('task_occurrences', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'task_occurrences',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('completions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'completions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('completion_revisions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'completions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('attachment_metadata_rows', kind: UpdateKind.delete),
      ],
    ),
  ]);
}

typedef $$HomesTableCreateCompanionBuilder = HomesCompanion Function({
  required String id,
  required String name,
  Value<String?> addressLabel,
  Value<int> rowid,
});
typedef $$HomesTableUpdateCompanionBuilder = HomesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> addressLabel,
  Value<int> rowid,
});

final class $$HomesTableReferences
    extends BaseReferences<_$UpkeepDatabase, $HomesTable, Home> {
  $$HomesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RoomsTable, List<Room>> _roomsRefsTable(
    _$UpkeepDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.rooms,
    aliasName: 'homes__id__rooms__home_id',
  );

  $$RoomsTableProcessedTableManager get roomsRefs {
    final manager = $$RoomsTableTableManager(
      $_db,
      $_db.rooms,
    ).filter((f) => f.homeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_roomsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AssetsTable, List<Asset>> _assetsRefsTable(
    _$UpkeepDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.assets,
    aliasName: 'homes__id__assets__home_id',
  );

  $$AssetsTableProcessedTableManager get assetsRefs {
    final manager = $$AssetsTableTableManager(
      $_db,
      $_db.assets,
    ).filter((f) => f.homeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_assetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TaskTemplatesTable, List<TaskTemplate>>
  _taskTemplatesRefsTable(_$UpkeepDatabase db) => MultiTypedResultKey.fromTable(
    db.taskTemplates,
    aliasName: 'homes__id__task_templates__home_id',
  );

  $$TaskTemplatesTableProcessedTableManager get taskTemplatesRefs {
    final manager = $$TaskTemplatesTableTableManager(
      $_db,
      $_db.taskTemplates,
    ).filter((f) => f.homeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskTemplatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HomesTableFilterComposer
    extends Composer<_$UpkeepDatabase, $HomesTable> {
  $$HomesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get addressLabel => $composableBuilder(
    column: $table.addressLabel,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> roomsRefs(
    Expression<bool> Function($$RoomsTableFilterComposer f) f,
  ) {
    final $$RoomsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.homeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableFilterComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> assetsRefs(
    Expression<bool> Function($$AssetsTableFilterComposer f) f,
  ) {
    final $$AssetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.homeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableFilterComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> taskTemplatesRefs(
    Expression<bool> Function($$TaskTemplatesTableFilterComposer f) f,
  ) {
    final $$TaskTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskTemplates,
      getReferencedColumn: (t) => t.homeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.taskTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HomesTableOrderingComposer
    extends Composer<_$UpkeepDatabase, $HomesTable> {
  $$HomesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get addressLabel => $composableBuilder(
    column: $table.addressLabel,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HomesTableAnnotationComposer
    extends Composer<_$UpkeepDatabase, $HomesTable> {
  $$HomesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get addressLabel => $composableBuilder(
    column: $table.addressLabel,
    builder: (column) => column,
  );

  Expression<T> roomsRefs<T extends Object>(
    Expression<T> Function($$RoomsTableAnnotationComposer a) f,
  ) {
    final $$RoomsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rooms,
      getReferencedColumn: (t) => t.homeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoomsTableAnnotationComposer(
            $db: $db,
            $table: $db.rooms,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> assetsRefs<T extends Object>(
    Expression<T> Function($$AssetsTableAnnotationComposer a) f,
  ) {
    final $$AssetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assets,
      getReferencedColumn: (t) => t.homeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetsTableAnnotationComposer(
            $db: $db,
            $table: $db.assets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> taskTemplatesRefs<T extends Object>(
    Expression<T> Function($$TaskTemplatesTableAnnotationComposer a) f,
  ) {
    final $$TaskTemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskTemplates,
      getReferencedColumn: (t) => t.homeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskTemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.taskTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HomesTableTableManager
    extends
        RootTableManager<
          _$UpkeepDatabase,
          $HomesTable,
          Home,
          $$HomesTableFilterComposer,
          $$HomesTableOrderingComposer,
          $$HomesTableAnnotationComposer,
          $$HomesTableCreateCompanionBuilder,
          $$HomesTableUpdateCompanionBuilder,
          (Home, $$HomesTableReferences),
          Home,
          PrefetchHooks Function({
            bool roomsRefs,
            bool assetsRefs,
            bool taskTemplatesRefs,
          })
        > {
  $$HomesTableTableManager(_$UpkeepDatabase db, $HomesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HomesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HomesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HomesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> addressLabel = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HomesCompanion(
                id: id,
                name: name,
                addressLabel: addressLabel,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> addressLabel = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HomesCompanion.insert(
                id: id,
                name: name,
                addressLabel: addressLabel,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$HomesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                roomsRefs = false,
                assetsRefs = false,
                taskTemplatesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (roomsRefs) db.rooms,
                    if (assetsRefs) db.assets,
                    if (taskTemplatesRefs) db.taskTemplates,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (roomsRefs)
                        await $_getPrefetchedData<Home, $HomesTable, Room>(
                          currentTable: table,
                          referencedTable: $$HomesTableReferences
                              ._roomsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HomesTableReferences(db, table, p0).roomsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.homeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (assetsRefs)
                        await $_getPrefetchedData<Home, $HomesTable, Asset>(
                          currentTable: table,
                          referencedTable: $$HomesTableReferences
                              ._assetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HomesTableReferences(db, table, p0).assetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.homeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (taskTemplatesRefs)
                        await $_getPrefetchedData<
                          Home,
                          $HomesTable,
                          TaskTemplate
                        >(
                          currentTable: table,
                          referencedTable: $$HomesTableReferences
                              ._taskTemplatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HomesTableReferences(
                                db,
                                table,
                                p0,
                              ).taskTemplatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.homeId == item.id,
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

typedef $$HomesTableProcessedTableManager =
    ProcessedTableManager<
      _$UpkeepDatabase,
      $HomesTable,
      Home,
      $$HomesTableFilterComposer,
      $$HomesTableOrderingComposer,
      $$HomesTableAnnotationComposer,
      $$HomesTableCreateCompanionBuilder,
      $$HomesTableUpdateCompanionBuilder,
      (Home, $$HomesTableReferences),
      Home,
      PrefetchHooks Function({
        bool roomsRefs,
        bool assetsRefs,
        bool taskTemplatesRefs,
      })
    >;
typedef $$RoomsTableCreateCompanionBuilder = RoomsCompanion Function({
  required String id,
  required String homeId,
  required String name,
  Value<int> rowid,
});
typedef $$RoomsTableUpdateCompanionBuilder = RoomsCompanion Function({
  Value<String> id,
  Value<String> homeId,
  Value<String> name,
  Value<int> rowid,
});

final class $$RoomsTableReferences
    extends BaseReferences<_$UpkeepDatabase, $RoomsTable, Room> {
  $$RoomsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HomesTable _homeIdTable(_$UpkeepDatabase db) =>
      db.homes.createAlias('rooms__home_id__homes__id');

  $$HomesTableProcessedTableManager get homeId {
    final $_column = $_itemColumn<String>('home_id')!;

    final manager = $$HomesTableTableManager(
      $_db,
      $_db.homes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_homeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RoomsTableFilterComposer
    extends Composer<_$UpkeepDatabase, $RoomsTable> {
  $$RoomsTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  $$HomesTableFilterComposer get homeId {
    final $$HomesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.homeId,
      referencedTable: $db.homes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HomesTableFilterComposer(
            $db: $db,
            $table: $db.homes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoomsTableOrderingComposer
    extends Composer<_$UpkeepDatabase, $RoomsTable> {
  $$RoomsTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  $$HomesTableOrderingComposer get homeId {
    final $$HomesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.homeId,
      referencedTable: $db.homes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HomesTableOrderingComposer(
            $db: $db,
            $table: $db.homes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoomsTableAnnotationComposer
    extends Composer<_$UpkeepDatabase, $RoomsTable> {
  $$RoomsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  $$HomesTableAnnotationComposer get homeId {
    final $$HomesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.homeId,
      referencedTable: $db.homes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HomesTableAnnotationComposer(
            $db: $db,
            $table: $db.homes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoomsTableTableManager
    extends
        RootTableManager<
          _$UpkeepDatabase,
          $RoomsTable,
          Room,
          $$RoomsTableFilterComposer,
          $$RoomsTableOrderingComposer,
          $$RoomsTableAnnotationComposer,
          $$RoomsTableCreateCompanionBuilder,
          $$RoomsTableUpdateCompanionBuilder,
          (Room, $$RoomsTableReferences),
          Room,
          PrefetchHooks Function({bool homeId})
        > {
  $$RoomsTableTableManager(_$UpkeepDatabase db, $RoomsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoomsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoomsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoomsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> homeId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RoomsCompanion(
                id: id,
                homeId: homeId,
                name: name,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String homeId,
                required String name,
                Value<int> rowid = const Value.absent(),
              }) => RoomsCompanion.insert(
                id: id,
                homeId: homeId,
                name: name,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$RoomsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({homeId = false}) {
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
                    if (homeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.homeId,
                        referencedTable: $$RoomsTableReferences._homeIdTable(
                          db,
                        ),
                        referencedColumn: $$RoomsTableReferences
                            ._homeIdTable(db)
                            .id,
                      ) as T;
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

typedef $$RoomsTableProcessedTableManager =
    ProcessedTableManager<
      _$UpkeepDatabase,
      $RoomsTable,
      Room,
      $$RoomsTableFilterComposer,
      $$RoomsTableOrderingComposer,
      $$RoomsTableAnnotationComposer,
      $$RoomsTableCreateCompanionBuilder,
      $$RoomsTableUpdateCompanionBuilder,
      (Room, $$RoomsTableReferences),
      Room,
      PrefetchHooks Function({bool homeId})
    >;
typedef $$AssetsTableCreateCompanionBuilder = AssetsCompanion Function({
  required String id,
  required String homeId,
  Value<String?> roomId,
  required String name,
  Value<int> rowid,
});
typedef $$AssetsTableUpdateCompanionBuilder = AssetsCompanion Function({
  Value<String> id,
  Value<String> homeId,
  Value<String?> roomId,
  Value<String> name,
  Value<int> rowid,
});

final class $$AssetsTableReferences
    extends BaseReferences<_$UpkeepDatabase, $AssetsTable, Asset> {
  $$AssetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HomesTable _homeIdTable(_$UpkeepDatabase db) =>
      db.homes.createAlias('assets__home_id__homes__id');

  $$HomesTableProcessedTableManager get homeId {
    final $_column = $_itemColumn<String>('home_id')!;

    final manager = $$HomesTableTableManager(
      $_db,
      $_db.homes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_homeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AssetsTableFilterComposer
    extends Composer<_$UpkeepDatabase, $AssetsTable> {
  $$AssetsTableFilterComposer({
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

  ColumnFilters<String> get roomId => $composableBuilder(
    column: $table.roomId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  $$HomesTableFilterComposer get homeId {
    final $$HomesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.homeId,
      referencedTable: $db.homes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HomesTableFilterComposer(
            $db: $db,
            $table: $db.homes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetsTableOrderingComposer
    extends Composer<_$UpkeepDatabase, $AssetsTable> {
  $$AssetsTableOrderingComposer({
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

  ColumnOrderings<String> get roomId => $composableBuilder(
    column: $table.roomId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  $$HomesTableOrderingComposer get homeId {
    final $$HomesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.homeId,
      referencedTable: $db.homes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HomesTableOrderingComposer(
            $db: $db,
            $table: $db.homes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetsTableAnnotationComposer
    extends Composer<_$UpkeepDatabase, $AssetsTable> {
  $$AssetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get roomId =>
      $composableBuilder(column: $table.roomId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  $$HomesTableAnnotationComposer get homeId {
    final $$HomesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.homeId,
      referencedTable: $db.homes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HomesTableAnnotationComposer(
            $db: $db,
            $table: $db.homes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetsTableTableManager
    extends
        RootTableManager<
          _$UpkeepDatabase,
          $AssetsTable,
          Asset,
          $$AssetsTableFilterComposer,
          $$AssetsTableOrderingComposer,
          $$AssetsTableAnnotationComposer,
          $$AssetsTableCreateCompanionBuilder,
          $$AssetsTableUpdateCompanionBuilder,
          (Asset, $$AssetsTableReferences),
          Asset,
          PrefetchHooks Function({bool homeId})
        > {
  $$AssetsTableTableManager(_$UpkeepDatabase db, $AssetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> homeId = const Value.absent(),
                Value<String?> roomId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetsCompanion(
                id: id,
                homeId: homeId,
                roomId: roomId,
                name: name,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String homeId,
                Value<String?> roomId = const Value.absent(),
                required String name,
                Value<int> rowid = const Value.absent(),
              }) => AssetsCompanion.insert(
                id: id,
                homeId: homeId,
                roomId: roomId,
                name: name,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$AssetsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({homeId = false}) {
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
                    if (homeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.homeId,
                        referencedTable: $$AssetsTableReferences._homeIdTable(
                          db,
                        ),
                        referencedColumn: $$AssetsTableReferences
                            ._homeIdTable(db)
                            .id,
                      ) as T;
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

typedef $$AssetsTableProcessedTableManager =
    ProcessedTableManager<
      _$UpkeepDatabase,
      $AssetsTable,
      Asset,
      $$AssetsTableFilterComposer,
      $$AssetsTableOrderingComposer,
      $$AssetsTableAnnotationComposer,
      $$AssetsTableCreateCompanionBuilder,
      $$AssetsTableUpdateCompanionBuilder,
      (Asset, $$AssetsTableReferences),
      Asset,
      PrefetchHooks Function({bool homeId})
    >;
typedef $$TaskTemplatesTableCreateCompanionBuilder =
    TaskTemplatesCompanion Function({
      required String id,
      required String homeId,
      Value<String?> roomId,
      Value<String?> assetId,
      required String name,
      required String startDate,
      required String recurrenceKind,
      required int recurrenceInterval,
      required String recurrenceAnchor,
      required int recurrenceAnchorDay,
      required int recurrenceAnchorMonth,
      Value<int?> reminderHour,
      Value<int?> reminderMinute,
      Value<String?> reminderTimeZone,
      Value<bool> paused,
      Value<int> rowid,
    });
typedef $$TaskTemplatesTableUpdateCompanionBuilder =
    TaskTemplatesCompanion Function({
      Value<String> id,
      Value<String> homeId,
      Value<String?> roomId,
      Value<String?> assetId,
      Value<String> name,
      Value<String> startDate,
      Value<String> recurrenceKind,
      Value<int> recurrenceInterval,
      Value<String> recurrenceAnchor,
      Value<int> recurrenceAnchorDay,
      Value<int> recurrenceAnchorMonth,
      Value<int?> reminderHour,
      Value<int?> reminderMinute,
      Value<String?> reminderTimeZone,
      Value<bool> paused,
      Value<int> rowid,
    });

final class $$TaskTemplatesTableReferences
    extends
        BaseReferences<_$UpkeepDatabase, $TaskTemplatesTable, TaskTemplate> {
  $$TaskTemplatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $HomesTable _homeIdTable(_$UpkeepDatabase db) =>
      db.homes.createAlias('task_templates__home_id__homes__id');

  $$HomesTableProcessedTableManager get homeId {
    final $_column = $_itemColumn<String>('home_id')!;

    final manager = $$HomesTableTableManager(
      $_db,
      $_db.homes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_homeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TaskOccurrencesTable, List<TaskOccurrence>>
  _taskOccurrencesRefsTable(_$UpkeepDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.taskOccurrences,
        aliasName: 'task_templates__id__task_occurrences__task_template_id',
      );

  $$TaskOccurrencesTableProcessedTableManager get taskOccurrencesRefs {
    final manager = $$TaskOccurrencesTableTableManager(
      $_db,
      $_db.taskOccurrences,
    ).filter((f) => f.taskTemplateId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _taskOccurrencesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TaskTemplatesTableFilterComposer
    extends Composer<_$UpkeepDatabase, $TaskTemplatesTable> {
  $$TaskTemplatesTableFilterComposer({
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

  ColumnFilters<String> get roomId => $composableBuilder(
    column: $table.roomId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceKind => $composableBuilder(
    column: $table.recurrenceKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recurrenceInterval => $composableBuilder(
    column: $table.recurrenceInterval,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceAnchor => $composableBuilder(
    column: $table.recurrenceAnchor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recurrenceAnchorDay => $composableBuilder(
    column: $table.recurrenceAnchorDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recurrenceAnchorMonth => $composableBuilder(
    column: $table.recurrenceAnchorMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderTimeZone => $composableBuilder(
    column: $table.reminderTimeZone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get paused => $composableBuilder(
    column: $table.paused,
    builder: (column) => ColumnFilters(column),
  );

  $$HomesTableFilterComposer get homeId {
    final $$HomesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.homeId,
      referencedTable: $db.homes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HomesTableFilterComposer(
            $db: $db,
            $table: $db.homes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> taskOccurrencesRefs(
    Expression<bool> Function($$TaskOccurrencesTableFilterComposer f) f,
  ) {
    final $$TaskOccurrencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskOccurrences,
      getReferencedColumn: (t) => t.taskTemplateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskOccurrencesTableFilterComposer(
            $db: $db,
            $table: $db.taskOccurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TaskTemplatesTableOrderingComposer
    extends Composer<_$UpkeepDatabase, $TaskTemplatesTable> {
  $$TaskTemplatesTableOrderingComposer({
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

  ColumnOrderings<String> get roomId => $composableBuilder(
    column: $table.roomId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceKind => $composableBuilder(
    column: $table.recurrenceKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recurrenceInterval => $composableBuilder(
    column: $table.recurrenceInterval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceAnchor => $composableBuilder(
    column: $table.recurrenceAnchor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recurrenceAnchorDay => $composableBuilder(
    column: $table.recurrenceAnchorDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recurrenceAnchorMonth => $composableBuilder(
    column: $table.recurrenceAnchorMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderTimeZone => $composableBuilder(
    column: $table.reminderTimeZone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get paused => $composableBuilder(
    column: $table.paused,
    builder: (column) => ColumnOrderings(column),
  );

  $$HomesTableOrderingComposer get homeId {
    final $$HomesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.homeId,
      referencedTable: $db.homes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HomesTableOrderingComposer(
            $db: $db,
            $table: $db.homes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskTemplatesTableAnnotationComposer
    extends Composer<_$UpkeepDatabase, $TaskTemplatesTable> {
  $$TaskTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get roomId =>
      $composableBuilder(column: $table.roomId, builder: (column) => column);

  GeneratedColumn<String> get assetId =>
      $composableBuilder(column: $table.assetId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get recurrenceKind => $composableBuilder(
    column: $table.recurrenceKind,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recurrenceInterval => $composableBuilder(
    column: $table.recurrenceInterval,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurrenceAnchor => $composableBuilder(
    column: $table.recurrenceAnchor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recurrenceAnchorDay => $composableBuilder(
    column: $table.recurrenceAnchorDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recurrenceAnchorMonth => $composableBuilder(
    column: $table.recurrenceAnchorMonth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderHour => $composableBuilder(
    column: $table.reminderHour,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderMinute => $composableBuilder(
    column: $table.reminderMinute,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reminderTimeZone => $composableBuilder(
    column: $table.reminderTimeZone,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get paused =>
      $composableBuilder(column: $table.paused, builder: (column) => column);

  $$HomesTableAnnotationComposer get homeId {
    final $$HomesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.homeId,
      referencedTable: $db.homes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HomesTableAnnotationComposer(
            $db: $db,
            $table: $db.homes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> taskOccurrencesRefs<T extends Object>(
    Expression<T> Function($$TaskOccurrencesTableAnnotationComposer a) f,
  ) {
    final $$TaskOccurrencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskOccurrences,
      getReferencedColumn: (t) => t.taskTemplateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskOccurrencesTableAnnotationComposer(
            $db: $db,
            $table: $db.taskOccurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TaskTemplatesTableTableManager
    extends
        RootTableManager<
          _$UpkeepDatabase,
          $TaskTemplatesTable,
          TaskTemplate,
          $$TaskTemplatesTableFilterComposer,
          $$TaskTemplatesTableOrderingComposer,
          $$TaskTemplatesTableAnnotationComposer,
          $$TaskTemplatesTableCreateCompanionBuilder,
          $$TaskTemplatesTableUpdateCompanionBuilder,
          (TaskTemplate, $$TaskTemplatesTableReferences),
          TaskTemplate,
          PrefetchHooks Function({bool homeId, bool taskOccurrencesRefs})
        > {
  $$TaskTemplatesTableTableManager(
    _$UpkeepDatabase db,
    $TaskTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> homeId = const Value.absent(),
                Value<String?> roomId = const Value.absent(),
                Value<String?> assetId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String> recurrenceKind = const Value.absent(),
                Value<int> recurrenceInterval = const Value.absent(),
                Value<String> recurrenceAnchor = const Value.absent(),
                Value<int> recurrenceAnchorDay = const Value.absent(),
                Value<int> recurrenceAnchorMonth = const Value.absent(),
                Value<int?> reminderHour = const Value.absent(),
                Value<int?> reminderMinute = const Value.absent(),
                Value<String?> reminderTimeZone = const Value.absent(),
                Value<bool> paused = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskTemplatesCompanion(
                id: id,
                homeId: homeId,
                roomId: roomId,
                assetId: assetId,
                name: name,
                startDate: startDate,
                recurrenceKind: recurrenceKind,
                recurrenceInterval: recurrenceInterval,
                recurrenceAnchor: recurrenceAnchor,
                recurrenceAnchorDay: recurrenceAnchorDay,
                recurrenceAnchorMonth: recurrenceAnchorMonth,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute,
                reminderTimeZone: reminderTimeZone,
                paused: paused,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String homeId,
                Value<String?> roomId = const Value.absent(),
                Value<String?> assetId = const Value.absent(),
                required String name,
                required String startDate,
                required String recurrenceKind,
                required int recurrenceInterval,
                required String recurrenceAnchor,
                required int recurrenceAnchorDay,
                required int recurrenceAnchorMonth,
                Value<int?> reminderHour = const Value.absent(),
                Value<int?> reminderMinute = const Value.absent(),
                Value<String?> reminderTimeZone = const Value.absent(),
                Value<bool> paused = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskTemplatesCompanion.insert(
                id: id,
                homeId: homeId,
                roomId: roomId,
                assetId: assetId,
                name: name,
                startDate: startDate,
                recurrenceKind: recurrenceKind,
                recurrenceInterval: recurrenceInterval,
                recurrenceAnchor: recurrenceAnchor,
                recurrenceAnchorDay: recurrenceAnchorDay,
                recurrenceAnchorMonth: recurrenceAnchorMonth,
                reminderHour: reminderHour,
                reminderMinute: reminderMinute,
                reminderTimeZone: reminderTimeZone,
                paused: paused,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TaskTemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({homeId = false, taskOccurrencesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (taskOccurrencesRefs) db.taskOccurrences,
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
                        if (homeId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.homeId,
                            referencedTable: $$TaskTemplatesTableReferences
                                ._homeIdTable(db),
                            referencedColumn: $$TaskTemplatesTableReferences
                                ._homeIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (taskOccurrencesRefs)
                        await $_getPrefetchedData<
                          TaskTemplate,
                          $TaskTemplatesTable,
                          TaskOccurrence
                        >(
                          currentTable: table,
                          referencedTable: $$TaskTemplatesTableReferences
                              ._taskOccurrencesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TaskTemplatesTableReferences(
                                db,
                                table,
                                p0,
                              ).taskOccurrencesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.taskTemplateId == item.id,
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

typedef $$TaskTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$UpkeepDatabase,
      $TaskTemplatesTable,
      TaskTemplate,
      $$TaskTemplatesTableFilterComposer,
      $$TaskTemplatesTableOrderingComposer,
      $$TaskTemplatesTableAnnotationComposer,
      $$TaskTemplatesTableCreateCompanionBuilder,
      $$TaskTemplatesTableUpdateCompanionBuilder,
      (TaskTemplate, $$TaskTemplatesTableReferences),
      TaskTemplate,
      PrefetchHooks Function({bool homeId, bool taskOccurrencesRefs})
    >;
typedef $$TaskOccurrencesTableCreateCompanionBuilder =
    TaskOccurrencesCompanion Function({
      required String id,
      required String taskTemplateId,
      required String scheduledDate,
      Value<String?> snoozedUntil,
      required String state,
      Value<int> rowid,
    });
typedef $$TaskOccurrencesTableUpdateCompanionBuilder =
    TaskOccurrencesCompanion Function({
      Value<String> id,
      Value<String> taskTemplateId,
      Value<String> scheduledDate,
      Value<String?> snoozedUntil,
      Value<String> state,
      Value<int> rowid,
    });

final class $$TaskOccurrencesTableReferences
    extends
        BaseReferences<
          _$UpkeepDatabase,
          $TaskOccurrencesTable,
          TaskOccurrence
        > {
  $$TaskOccurrencesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TaskTemplatesTable _taskTemplateIdTable(_$UpkeepDatabase db) => db
      .taskTemplates
      .createAlias('task_occurrences__task_template_id__task_templates__id');

  $$TaskTemplatesTableProcessedTableManager get taskTemplateId {
    final $_column = $_itemColumn<String>('task_template_id')!;

    final manager = $$TaskTemplatesTableTableManager(
      $_db,
      $_db.taskTemplates,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskTemplateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CompletionsTable, List<Completion>>
  _completionsRefsTable(_$UpkeepDatabase db) => MultiTypedResultKey.fromTable(
    db.completions,
    aliasName: 'task_occurrences__id__completions__occurrence_id',
  );

  $$CompletionsTableProcessedTableManager get completionsRefs {
    final manager = $$CompletionsTableTableManager(
      $_db,
      $_db.completions,
    ).filter((f) => f.occurrenceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_completionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TaskOccurrencesTableFilterComposer
    extends Composer<_$UpkeepDatabase, $TaskOccurrencesTable> {
  $$TaskOccurrencesTableFilterComposer({
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

  ColumnFilters<String> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  $$TaskTemplatesTableFilterComposer get taskTemplateId {
    final $$TaskTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskTemplateId,
      referencedTable: $db.taskTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.taskTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> completionsRefs(
    Expression<bool> Function($$CompletionsTableFilterComposer f) f,
  ) {
    final $$CompletionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.completions,
      getReferencedColumn: (t) => t.occurrenceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionsTableFilterComposer(
            $db: $db,
            $table: $db.completions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TaskOccurrencesTableOrderingComposer
    extends Composer<_$UpkeepDatabase, $TaskOccurrencesTable> {
  $$TaskOccurrencesTableOrderingComposer({
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

  ColumnOrderings<String> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  $$TaskTemplatesTableOrderingComposer get taskTemplateId {
    final $$TaskTemplatesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskTemplateId,
      referencedTable: $db.taskTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskTemplatesTableOrderingComposer(
            $db: $db,
            $table: $db.taskTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskOccurrencesTableAnnotationComposer
    extends Composer<_$UpkeepDatabase, $TaskOccurrencesTable> {
  $$TaskOccurrencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get snoozedUntil => $composableBuilder(
    column: $table.snoozedUntil,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  $$TaskTemplatesTableAnnotationComposer get taskTemplateId {
    final $$TaskTemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskTemplateId,
      referencedTable: $db.taskTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskTemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.taskTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> completionsRefs<T extends Object>(
    Expression<T> Function($$CompletionsTableAnnotationComposer a) f,
  ) {
    final $$CompletionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.completions,
      getReferencedColumn: (t) => t.occurrenceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionsTableAnnotationComposer(
            $db: $db,
            $table: $db.completions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TaskOccurrencesTableTableManager
    extends
        RootTableManager<
          _$UpkeepDatabase,
          $TaskOccurrencesTable,
          TaskOccurrence,
          $$TaskOccurrencesTableFilterComposer,
          $$TaskOccurrencesTableOrderingComposer,
          $$TaskOccurrencesTableAnnotationComposer,
          $$TaskOccurrencesTableCreateCompanionBuilder,
          $$TaskOccurrencesTableUpdateCompanionBuilder,
          (TaskOccurrence, $$TaskOccurrencesTableReferences),
          TaskOccurrence,
          PrefetchHooks Function({bool taskTemplateId, bool completionsRefs})
        > {
  $$TaskOccurrencesTableTableManager(
    _$UpkeepDatabase db,
    $TaskOccurrencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskOccurrencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskOccurrencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskOccurrencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> taskTemplateId = const Value.absent(),
                Value<String> scheduledDate = const Value.absent(),
                Value<String?> snoozedUntil = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskOccurrencesCompanion(
                id: id,
                taskTemplateId: taskTemplateId,
                scheduledDate: scheduledDate,
                snoozedUntil: snoozedUntil,
                state: state,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String taskTemplateId,
                required String scheduledDate,
                Value<String?> snoozedUntil = const Value.absent(),
                required String state,
                Value<int> rowid = const Value.absent(),
              }) => TaskOccurrencesCompanion.insert(
                id: id,
                taskTemplateId: taskTemplateId,
                scheduledDate: scheduledDate,
                snoozedUntil: snoozedUntil,
                state: state,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TaskOccurrencesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({taskTemplateId = false, completionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (completionsRefs) db.completions,
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
                        if (taskTemplateId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.taskTemplateId,
                            referencedTable: $$TaskOccurrencesTableReferences
                                ._taskTemplateIdTable(db),
                            referencedColumn: $$TaskOccurrencesTableReferences
                                ._taskTemplateIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (completionsRefs)
                        await $_getPrefetchedData<
                          TaskOccurrence,
                          $TaskOccurrencesTable,
                          Completion
                        >(
                          currentTable: table,
                          referencedTable: $$TaskOccurrencesTableReferences
                              ._completionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TaskOccurrencesTableReferences(
                                db,
                                table,
                                p0,
                              ).completionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.occurrenceId == item.id,
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

typedef $$TaskOccurrencesTableProcessedTableManager =
    ProcessedTableManager<
      _$UpkeepDatabase,
      $TaskOccurrencesTable,
      TaskOccurrence,
      $$TaskOccurrencesTableFilterComposer,
      $$TaskOccurrencesTableOrderingComposer,
      $$TaskOccurrencesTableAnnotationComposer,
      $$TaskOccurrencesTableCreateCompanionBuilder,
      $$TaskOccurrencesTableUpdateCompanionBuilder,
      (TaskOccurrence, $$TaskOccurrencesTableReferences),
      TaskOccurrence,
      PrefetchHooks Function({bool taskTemplateId, bool completionsRefs})
    >;
typedef $$CompletionsTableCreateCompanionBuilder =
    CompletionsCompanion Function({
      required String id,
      required String occurrenceId,
      required String scheduledDate,
      Value<int> rowid,
    });
typedef $$CompletionsTableUpdateCompanionBuilder =
    CompletionsCompanion Function({
      Value<String> id,
      Value<String> occurrenceId,
      Value<String> scheduledDate,
      Value<int> rowid,
    });

final class $$CompletionsTableReferences
    extends BaseReferences<_$UpkeepDatabase, $CompletionsTable, Completion> {
  $$CompletionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TaskOccurrencesTable _occurrenceIdTable(_$UpkeepDatabase db) => db
      .taskOccurrences
      .createAlias('completions__occurrence_id__task_occurrences__id');

  $$TaskOccurrencesTableProcessedTableManager get occurrenceId {
    final $_column = $_itemColumn<String>('occurrence_id')!;

    final manager = $$TaskOccurrencesTableTableManager(
      $_db,
      $_db.taskOccurrences,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_occurrenceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $CompletionRevisionsTable,
    List<CompletionRevision>
  >
  _completionRevisionsRefsTable(_$UpkeepDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.completionRevisions,
        aliasName: 'completions__id__completion_revisions__completion_id',
      );

  $$CompletionRevisionsTableProcessedTableManager get completionRevisionsRefs {
    final manager = $$CompletionRevisionsTableTableManager(
      $_db,
      $_db.completionRevisions,
    ).filter((f) => f.completionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _completionRevisionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $AttachmentMetadataRowsTable,
    List<AttachmentMetadataRow>
  >
  _attachmentMetadataRowsRefsTable(_$UpkeepDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.attachmentMetadataRows,
        aliasName: 'completions__id__attachment_metadata_rows__completion_id',
      );

  $$AttachmentMetadataRowsTableProcessedTableManager
  get attachmentMetadataRowsRefs {
    final manager = $$AttachmentMetadataRowsTableTableManager(
      $_db,
      $_db.attachmentMetadataRows,
    ).filter((f) => f.completionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _attachmentMetadataRowsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CompletionsTableFilterComposer
    extends Composer<_$UpkeepDatabase, $CompletionsTable> {
  $$CompletionsTableFilterComposer({
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

  ColumnFilters<String> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnFilters(column),
  );

  $$TaskOccurrencesTableFilterComposer get occurrenceId {
    final $$TaskOccurrencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occurrenceId,
      referencedTable: $db.taskOccurrences,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskOccurrencesTableFilterComposer(
            $db: $db,
            $table: $db.taskOccurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> completionRevisionsRefs(
    Expression<bool> Function($$CompletionRevisionsTableFilterComposer f) f,
  ) {
    final $$CompletionRevisionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.completionRevisions,
      getReferencedColumn: (t) => t.completionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionRevisionsTableFilterComposer(
            $db: $db,
            $table: $db.completionRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> attachmentMetadataRowsRefs(
    Expression<bool> Function($$AttachmentMetadataRowsTableFilterComposer f) f,
  ) {
    final $$AttachmentMetadataRowsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.attachmentMetadataRows,
          getReferencedColumn: (t) => t.completionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AttachmentMetadataRowsTableFilterComposer(
                $db: $db,
                $table: $db.attachmentMetadataRows,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CompletionsTableOrderingComposer
    extends Composer<_$UpkeepDatabase, $CompletionsTable> {
  $$CompletionsTableOrderingComposer({
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

  ColumnOrderings<String> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnOrderings(column),
  );

  $$TaskOccurrencesTableOrderingComposer get occurrenceId {
    final $$TaskOccurrencesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occurrenceId,
      referencedTable: $db.taskOccurrences,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskOccurrencesTableOrderingComposer(
            $db: $db,
            $table: $db.taskOccurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompletionsTableAnnotationComposer
    extends Composer<_$UpkeepDatabase, $CompletionsTable> {
  $$CompletionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => column,
  );

  $$TaskOccurrencesTableAnnotationComposer get occurrenceId {
    final $$TaskOccurrencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occurrenceId,
      referencedTable: $db.taskOccurrences,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskOccurrencesTableAnnotationComposer(
            $db: $db,
            $table: $db.taskOccurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> completionRevisionsRefs<T extends Object>(
    Expression<T> Function($$CompletionRevisionsTableAnnotationComposer a) f,
  ) {
    final $$CompletionRevisionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.completionRevisions,
          getReferencedColumn: (t) => t.completionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CompletionRevisionsTableAnnotationComposer(
                $db: $db,
                $table: $db.completionRevisions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> attachmentMetadataRowsRefs<T extends Object>(
    Expression<T> Function($$AttachmentMetadataRowsTableAnnotationComposer a) f,
  ) {
    final $$AttachmentMetadataRowsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.attachmentMetadataRows,
          getReferencedColumn: (t) => t.completionId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$AttachmentMetadataRowsTableAnnotationComposer(
                $db: $db,
                $table: $db.attachmentMetadataRows,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CompletionsTableTableManager
    extends
        RootTableManager<
          _$UpkeepDatabase,
          $CompletionsTable,
          Completion,
          $$CompletionsTableFilterComposer,
          $$CompletionsTableOrderingComposer,
          $$CompletionsTableAnnotationComposer,
          $$CompletionsTableCreateCompanionBuilder,
          $$CompletionsTableUpdateCompanionBuilder,
          (Completion, $$CompletionsTableReferences),
          Completion,
          PrefetchHooks Function({
            bool occurrenceId,
            bool completionRevisionsRefs,
            bool attachmentMetadataRowsRefs,
          })
        > {
  $$CompletionsTableTableManager(_$UpkeepDatabase db, $CompletionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompletionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompletionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompletionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> occurrenceId = const Value.absent(),
                Value<String> scheduledDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CompletionsCompanion(
                id: id,
                occurrenceId: occurrenceId,
                scheduledDate: scheduledDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String occurrenceId,
                required String scheduledDate,
                Value<int> rowid = const Value.absent(),
              }) => CompletionsCompanion.insert(
                id: id,
                occurrenceId: occurrenceId,
                scheduledDate: scheduledDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CompletionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                occurrenceId = false,
                completionRevisionsRefs = false,
                attachmentMetadataRowsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (completionRevisionsRefs) db.completionRevisions,
                    if (attachmentMetadataRowsRefs) db.attachmentMetadataRows,
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
                        if (occurrenceId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.occurrenceId,
                            referencedTable: $$CompletionsTableReferences
                                ._occurrenceIdTable(db),
                            referencedColumn: $$CompletionsTableReferences
                                ._occurrenceIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (completionRevisionsRefs)
                        await $_getPrefetchedData<
                          Completion,
                          $CompletionsTable,
                          CompletionRevision
                        >(
                          currentTable: table,
                          referencedTable: $$CompletionsTableReferences
                              ._completionRevisionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CompletionsTableReferences(
                                db,
                                table,
                                p0,
                              ).completionRevisionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.completionId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (attachmentMetadataRowsRefs)
                        await $_getPrefetchedData<
                          Completion,
                          $CompletionsTable,
                          AttachmentMetadataRow
                        >(
                          currentTable: table,
                          referencedTable: $$CompletionsTableReferences
                              ._attachmentMetadataRowsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CompletionsTableReferences(
                                db,
                                table,
                                p0,
                              ).attachmentMetadataRowsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.completionId == item.id,
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

typedef $$CompletionsTableProcessedTableManager =
    ProcessedTableManager<
      _$UpkeepDatabase,
      $CompletionsTable,
      Completion,
      $$CompletionsTableFilterComposer,
      $$CompletionsTableOrderingComposer,
      $$CompletionsTableAnnotationComposer,
      $$CompletionsTableCreateCompanionBuilder,
      $$CompletionsTableUpdateCompanionBuilder,
      (Completion, $$CompletionsTableReferences),
      Completion,
      PrefetchHooks Function({
        bool occurrenceId,
        bool completionRevisionsRefs,
        bool attachmentMetadataRowsRefs,
      })
    >;
typedef $$CompletionRevisionsTableCreateCompanionBuilder =
    CompletionRevisionsCompanion Function({
      required String completionId,
      required int revision,
      required String actualDate,
      Value<String?> notes,
      Value<String?> partsText,
      Value<int?> costMinorUnits,
      Value<String?> costCurrency,
      required DateTime revisedAtUtc,
      Value<int> rowid,
    });
typedef $$CompletionRevisionsTableUpdateCompanionBuilder =
    CompletionRevisionsCompanion Function({
      Value<String> completionId,
      Value<int> revision,
      Value<String> actualDate,
      Value<String?> notes,
      Value<String?> partsText,
      Value<int?> costMinorUnits,
      Value<String?> costCurrency,
      Value<DateTime> revisedAtUtc,
      Value<int> rowid,
    });

final class $$CompletionRevisionsTableReferences
    extends
        BaseReferences<
          _$UpkeepDatabase,
          $CompletionRevisionsTable,
          CompletionRevision
        > {
  $$CompletionRevisionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CompletionsTable _completionIdTable(_$UpkeepDatabase db) => db
      .completions
      .createAlias('completion_revisions__completion_id__completions__id');

  $$CompletionsTableProcessedTableManager get completionId {
    final $_column = $_itemColumn<String>('completion_id')!;

    final manager = $$CompletionsTableTableManager(
      $_db,
      $_db.completions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_completionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CompletionRevisionsTableFilterComposer
    extends Composer<_$UpkeepDatabase, $CompletionRevisionsTable> {
  $$CompletionRevisionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get actualDate => $composableBuilder(
    column: $table.actualDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partsText => $composableBuilder(
    column: $table.partsText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get costMinorUnits => $composableBuilder(
    column: $table.costMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get costCurrency => $composableBuilder(
    column: $table.costCurrency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get revisedAtUtc =>
      $composableBuilder(
        column: $table.revisedAtUtc,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$CompletionsTableFilterComposer get completionId {
    final $$CompletionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completionId,
      referencedTable: $db.completions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionsTableFilterComposer(
            $db: $db,
            $table: $db.completions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompletionRevisionsTableOrderingComposer
    extends Composer<_$UpkeepDatabase, $CompletionRevisionsTable> {
  $$CompletionRevisionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actualDate => $composableBuilder(
    column: $table.actualDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partsText => $composableBuilder(
    column: $table.partsText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get costMinorUnits => $composableBuilder(
    column: $table.costMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get costCurrency => $composableBuilder(
    column: $table.costCurrency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revisedAtUtc => $composableBuilder(
    column: $table.revisedAtUtc,
    builder: (column) => ColumnOrderings(column),
  );

  $$CompletionsTableOrderingComposer get completionId {
    final $$CompletionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completionId,
      referencedTable: $db.completions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionsTableOrderingComposer(
            $db: $db,
            $table: $db.completions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompletionRevisionsTableAnnotationComposer
    extends Composer<_$UpkeepDatabase, $CompletionRevisionsTable> {
  $$CompletionRevisionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<String> get actualDate => $composableBuilder(
    column: $table.actualDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get partsText =>
      $composableBuilder(column: $table.partsText, builder: (column) => column);

  GeneratedColumn<int> get costMinorUnits => $composableBuilder(
    column: $table.costMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get costCurrency => $composableBuilder(
    column: $table.costCurrency,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get revisedAtUtc =>
      $composableBuilder(
        column: $table.revisedAtUtc,
        builder: (column) => column,
      );

  $$CompletionsTableAnnotationComposer get completionId {
    final $$CompletionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completionId,
      referencedTable: $db.completions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionsTableAnnotationComposer(
            $db: $db,
            $table: $db.completions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CompletionRevisionsTableTableManager
    extends
        RootTableManager<
          _$UpkeepDatabase,
          $CompletionRevisionsTable,
          CompletionRevision,
          $$CompletionRevisionsTableFilterComposer,
          $$CompletionRevisionsTableOrderingComposer,
          $$CompletionRevisionsTableAnnotationComposer,
          $$CompletionRevisionsTableCreateCompanionBuilder,
          $$CompletionRevisionsTableUpdateCompanionBuilder,
          (CompletionRevision, $$CompletionRevisionsTableReferences),
          CompletionRevision,
          PrefetchHooks Function({bool completionId})
        > {
  $$CompletionRevisionsTableTableManager(
    _$UpkeepDatabase db,
    $CompletionRevisionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompletionRevisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompletionRevisionsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CompletionRevisionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> completionId = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<String> actualDate = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> partsText = const Value.absent(),
                Value<int?> costMinorUnits = const Value.absent(),
                Value<String?> costCurrency = const Value.absent(),
                Value<DateTime> revisedAtUtc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CompletionRevisionsCompanion(
                completionId: completionId,
                revision: revision,
                actualDate: actualDate,
                notes: notes,
                partsText: partsText,
                costMinorUnits: costMinorUnits,
                costCurrency: costCurrency,
                revisedAtUtc: revisedAtUtc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String completionId,
                required int revision,
                required String actualDate,
                Value<String?> notes = const Value.absent(),
                Value<String?> partsText = const Value.absent(),
                Value<int?> costMinorUnits = const Value.absent(),
                Value<String?> costCurrency = const Value.absent(),
                required DateTime revisedAtUtc,
                Value<int> rowid = const Value.absent(),
              }) => CompletionRevisionsCompanion.insert(
                completionId: completionId,
                revision: revision,
                actualDate: actualDate,
                notes: notes,
                partsText: partsText,
                costMinorUnits: costMinorUnits,
                costCurrency: costCurrency,
                revisedAtUtc: revisedAtUtc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CompletionRevisionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({completionId = false}) {
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
                    if (completionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.completionId,
                        referencedTable: $$CompletionRevisionsTableReferences
                            ._completionIdTable(db),
                        referencedColumn: $$CompletionRevisionsTableReferences
                            ._completionIdTable(db)
                            .id,
                      ) as T;
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

typedef $$CompletionRevisionsTableProcessedTableManager =
    ProcessedTableManager<
      _$UpkeepDatabase,
      $CompletionRevisionsTable,
      CompletionRevision,
      $$CompletionRevisionsTableFilterComposer,
      $$CompletionRevisionsTableOrderingComposer,
      $$CompletionRevisionsTableAnnotationComposer,
      $$CompletionRevisionsTableCreateCompanionBuilder,
      $$CompletionRevisionsTableUpdateCompanionBuilder,
      (CompletionRevision, $$CompletionRevisionsTableReferences),
      CompletionRevision,
      PrefetchHooks Function({bool completionId})
    >;
typedef $$AttachmentMetadataRowsTableCreateCompanionBuilder =
    AttachmentMetadataRowsCompanion Function({
      required String id,
      required String completionId,
      required String relativePath,
      required String mediaType,
      required String sha256,
      Value<String?> caption,
      Value<int> rowid,
    });
typedef $$AttachmentMetadataRowsTableUpdateCompanionBuilder =
    AttachmentMetadataRowsCompanion Function({
      Value<String> id,
      Value<String> completionId,
      Value<String> relativePath,
      Value<String> mediaType,
      Value<String> sha256,
      Value<String?> caption,
      Value<int> rowid,
    });

final class $$AttachmentMetadataRowsTableReferences
    extends
        BaseReferences<
          _$UpkeepDatabase,
          $AttachmentMetadataRowsTable,
          AttachmentMetadataRow
        > {
  $$AttachmentMetadataRowsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CompletionsTable _completionIdTable(_$UpkeepDatabase db) => db
      .completions
      .createAlias('attachment_metadata_rows__completion_id__completions__id');

  $$CompletionsTableProcessedTableManager get completionId {
    final $_column = $_itemColumn<String>('completion_id')!;

    final manager = $$CompletionsTableTableManager(
      $_db,
      $_db.completions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_completionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttachmentMetadataRowsTableFilterComposer
    extends Composer<_$UpkeepDatabase, $AttachmentMetadataRowsTable> {
  $$AttachmentMetadataRowsTableFilterComposer({
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

  ColumnFilters<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnFilters(column),
  );

  $$CompletionsTableFilterComposer get completionId {
    final $$CompletionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completionId,
      referencedTable: $db.completions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionsTableFilterComposer(
            $db: $db,
            $table: $db.completions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentMetadataRowsTableOrderingComposer
    extends Composer<_$UpkeepDatabase, $AttachmentMetadataRowsTable> {
  $$AttachmentMetadataRowsTableOrderingComposer({
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

  ColumnOrderings<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnOrderings(column),
  );

  $$CompletionsTableOrderingComposer get completionId {
    final $$CompletionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completionId,
      referencedTable: $db.completions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionsTableOrderingComposer(
            $db: $db,
            $table: $db.completions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentMetadataRowsTableAnnotationComposer
    extends Composer<_$UpkeepDatabase, $AttachmentMetadataRowsTable> {
  $$AttachmentMetadataRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

  $$CompletionsTableAnnotationComposer get completionId {
    final $$CompletionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.completionId,
      referencedTable: $db.completions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CompletionsTableAnnotationComposer(
            $db: $db,
            $table: $db.completions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttachmentMetadataRowsTableTableManager
    extends
        RootTableManager<
          _$UpkeepDatabase,
          $AttachmentMetadataRowsTable,
          AttachmentMetadataRow,
          $$AttachmentMetadataRowsTableFilterComposer,
          $$AttachmentMetadataRowsTableOrderingComposer,
          $$AttachmentMetadataRowsTableAnnotationComposer,
          $$AttachmentMetadataRowsTableCreateCompanionBuilder,
          $$AttachmentMetadataRowsTableUpdateCompanionBuilder,
          (AttachmentMetadataRow, $$AttachmentMetadataRowsTableReferences),
          AttachmentMetadataRow,
          PrefetchHooks Function({bool completionId})
        > {
  $$AttachmentMetadataRowsTableTableManager(
    _$UpkeepDatabase db,
    $AttachmentMetadataRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentMetadataRowsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$AttachmentMetadataRowsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AttachmentMetadataRowsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> completionId = const Value.absent(),
                Value<String> relativePath = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<String> sha256 = const Value.absent(),
                Value<String?> caption = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentMetadataRowsCompanion(
                id: id,
                completionId: completionId,
                relativePath: relativePath,
                mediaType: mediaType,
                sha256: sha256,
                caption: caption,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String completionId,
                required String relativePath,
                required String mediaType,
                required String sha256,
                Value<String?> caption = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentMetadataRowsCompanion.insert(
                id: id,
                completionId: completionId,
                relativePath: relativePath,
                mediaType: mediaType,
                sha256: sha256,
                caption: caption,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AttachmentMetadataRowsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({completionId = false}) {
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
                    if (completionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.completionId,
                        referencedTable: $$AttachmentMetadataRowsTableReferences
                            ._completionIdTable(db),
                        referencedColumn:
                            $$AttachmentMetadataRowsTableReferences
                                ._completionIdTable(db)
                                .id,
                      ) as T;
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

typedef $$AttachmentMetadataRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$UpkeepDatabase,
      $AttachmentMetadataRowsTable,
      AttachmentMetadataRow,
      $$AttachmentMetadataRowsTableFilterComposer,
      $$AttachmentMetadataRowsTableOrderingComposer,
      $$AttachmentMetadataRowsTableAnnotationComposer,
      $$AttachmentMetadataRowsTableCreateCompanionBuilder,
      $$AttachmentMetadataRowsTableUpdateCompanionBuilder,
      (AttachmentMetadataRow, $$AttachmentMetadataRowsTableReferences),
      AttachmentMetadataRow,
      PrefetchHooks Function({bool completionId})
    >;

class $UpkeepDatabaseManager {
  final _$UpkeepDatabase _db;
  $UpkeepDatabaseManager(this._db);
  $$HomesTableTableManager get homes =>
      $$HomesTableTableManager(_db, _db.homes);
  $$RoomsTableTableManager get rooms =>
      $$RoomsTableTableManager(_db, _db.rooms);
  $$AssetsTableTableManager get assets =>
      $$AssetsTableTableManager(_db, _db.assets);
  $$TaskTemplatesTableTableManager get taskTemplates =>
      $$TaskTemplatesTableTableManager(_db, _db.taskTemplates);
  $$TaskOccurrencesTableTableManager get taskOccurrences =>
      $$TaskOccurrencesTableTableManager(_db, _db.taskOccurrences);
  $$CompletionsTableTableManager get completions =>
      $$CompletionsTableTableManager(_db, _db.completions);
  $$CompletionRevisionsTableTableManager get completionRevisions =>
      $$CompletionRevisionsTableTableManager(_db, _db.completionRevisions);
  $$AttachmentMetadataRowsTableTableManager get attachmentMetadataRows =>
      $$AttachmentMetadataRowsTableTableManager(
        _db,
        _db.attachmentMetadataRows,
      );
}
