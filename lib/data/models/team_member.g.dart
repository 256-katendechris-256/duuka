// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_member.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTeamMemberCollection on Isar {
  IsarCollection<TeamMember> get teamMembers => this.collection();
}

const TeamMemberSchema = CollectionSchema(
  name: r'TeamMember',
  id: 4507196394957692968,
  properties: {
    r'age': PropertySchema(
      id: 0,
      name: r'age',
      type: IsarType.long,
    ),
    r'businessId': PropertySchema(
      id: 1,
      name: r'businessId',
      type: IsarType.long,
    ),
    r'canAddTeam': PropertySchema(
      id: 2,
      name: r'canAddTeam',
      type: IsarType.bool,
    ),
    r'canDelete': PropertySchema(
      id: 3,
      name: r'canDelete',
      type: IsarType.bool,
    ),
    r'canEditProducts': PropertySchema(
      id: 4,
      name: r'canEditProducts',
      type: IsarType.bool,
    ),
    r'canMakeSales': PropertySchema(
      id: 5,
      name: r'canMakeSales',
      type: IsarType.bool,
    ),
    r'canManageCredit': PropertySchema(
      id: 6,
      name: r'canManageCredit',
      type: IsarType.bool,
    ),
    r'canManageDevices': PropertySchema(
      id: 7,
      name: r'canManageDevices',
      type: IsarType.bool,
    ),
    r'canViewProducts': PropertySchema(
      id: 8,
      name: r'canViewProducts',
      type: IsarType.bool,
    ),
    r'canViewReports': PropertySchema(
      id: 9,
      name: r'canViewReports',
      type: IsarType.bool,
    ),
    r'createdAt': PropertySchema(
      id: 10,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'gender': PropertySchema(
      id: 11,
      name: r'gender',
      type: IsarType.string,
      enumMap: _TeamMembergenderEnumValueMap,
    ),
    r'isActive': PropertySchema(
      id: 12,
      name: r'isActive',
      type: IsarType.bool,
    ),
    r'joinedAt': PropertySchema(
      id: 13,
      name: r'joinedAt',
      type: IsarType.dateTime,
    ),
    r'remoteId': PropertySchema(
      id: 14,
      name: r'remoteId',
      type: IsarType.string,
    ),
    r'role': PropertySchema(
      id: 15,
      name: r'role',
      type: IsarType.string,
      enumMap: _TeamMemberroleEnumValueMap,
    ),
    r'syncStatus': PropertySchema(
      id: 16,
      name: r'syncStatus',
      type: IsarType.string,
      enumMap: _TeamMembersyncStatusEnumValueMap,
    ),
    r'userId': PropertySchema(
      id: 17,
      name: r'userId',
      type: IsarType.long,
    ),
    r'userName': PropertySchema(
      id: 18,
      name: r'userName',
      type: IsarType.string,
    ),
    r'userPhone': PropertySchema(
      id: 19,
      name: r'userPhone',
      type: IsarType.string,
    )
  },
  estimateSize: _teamMemberEstimateSize,
  serialize: _teamMemberSerialize,
  deserialize: _teamMemberDeserialize,
  deserializeProp: _teamMemberDeserializeProp,
  idName: r'id',
  indexes: {
    r'userId': IndexSchema(
      id: -2005826577402374815,
      name: r'userId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'userId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'businessId': IndexSchema(
      id: 2228048290814354584,
      name: r'businessId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'businessId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _teamMemberGetId,
  getLinks: _teamMemberGetLinks,
  attach: _teamMemberAttach,
  version: '3.1.0+1',
);

int _teamMemberEstimateSize(
  TeamMember object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.gender;
    if (value != null) {
      bytesCount += 3 + value.name.length * 3;
    }
  }
  {
    final value = object.remoteId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.role.name.length * 3;
  bytesCount += 3 + object.syncStatus.name.length * 3;
  {
    final value = object.userName;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.userPhone.length * 3;
  return bytesCount;
}

void _teamMemberSerialize(
  TeamMember object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.age);
  writer.writeLong(offsets[1], object.businessId);
  writer.writeBool(offsets[2], object.canAddTeam);
  writer.writeBool(offsets[3], object.canDelete);
  writer.writeBool(offsets[4], object.canEditProducts);
  writer.writeBool(offsets[5], object.canMakeSales);
  writer.writeBool(offsets[6], object.canManageCredit);
  writer.writeBool(offsets[7], object.canManageDevices);
  writer.writeBool(offsets[8], object.canViewProducts);
  writer.writeBool(offsets[9], object.canViewReports);
  writer.writeDateTime(offsets[10], object.createdAt);
  writer.writeString(offsets[11], object.gender?.name);
  writer.writeBool(offsets[12], object.isActive);
  writer.writeDateTime(offsets[13], object.joinedAt);
  writer.writeString(offsets[14], object.remoteId);
  writer.writeString(offsets[15], object.role.name);
  writer.writeString(offsets[16], object.syncStatus.name);
  writer.writeLong(offsets[17], object.userId);
  writer.writeString(offsets[18], object.userName);
  writer.writeString(offsets[19], object.userPhone);
}

TeamMember _teamMemberDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TeamMember();
  object.age = reader.readLongOrNull(offsets[0]);
  object.businessId = reader.readLong(offsets[1]);
  object.canAddTeam = reader.readBool(offsets[2]);
  object.canDelete = reader.readBool(offsets[3]);
  object.canEditProducts = reader.readBool(offsets[4]);
  object.canMakeSales = reader.readBool(offsets[5]);
  object.canManageCredit = reader.readBool(offsets[6]);
  object.canManageDevices = reader.readBool(offsets[7]);
  object.canViewProducts = reader.readBool(offsets[8]);
  object.canViewReports = reader.readBool(offsets[9]);
  object.createdAt = reader.readDateTime(offsets[10]);
  object.gender =
      _TeamMembergenderValueEnumMap[reader.readStringOrNull(offsets[11])];
  object.id = id;
  object.isActive = reader.readBool(offsets[12]);
  object.joinedAt = reader.readDateTime(offsets[13]);
  object.remoteId = reader.readStringOrNull(offsets[14]);
  object.role =
      _TeamMemberroleValueEnumMap[reader.readStringOrNull(offsets[15])] ??
          UserRole.owner;
  object.syncStatus =
      _TeamMembersyncStatusValueEnumMap[reader.readStringOrNull(offsets[16])] ??
          SyncStatus.synced;
  object.userId = reader.readLong(offsets[17]);
  object.userName = reader.readStringOrNull(offsets[18]);
  object.userPhone = reader.readString(offsets[19]);
  return object;
}

P _teamMemberDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readBool(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readBool(offset)) as P;
    case 10:
      return (reader.readDateTime(offset)) as P;
    case 11:
      return (_TeamMembergenderValueEnumMap[reader.readStringOrNull(offset)])
          as P;
    case 12:
      return (reader.readBool(offset)) as P;
    case 13:
      return (reader.readDateTime(offset)) as P;
    case 14:
      return (reader.readStringOrNull(offset)) as P;
    case 15:
      return (_TeamMemberroleValueEnumMap[reader.readStringOrNull(offset)] ??
          UserRole.owner) as P;
    case 16:
      return (_TeamMembersyncStatusValueEnumMap[
              reader.readStringOrNull(offset)] ??
          SyncStatus.synced) as P;
    case 17:
      return (reader.readLong(offset)) as P;
    case 18:
      return (reader.readStringOrNull(offset)) as P;
    case 19:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _TeamMembergenderEnumValueMap = {
  r'male': r'male',
  r'female': r'female',
  r'other': r'other',
};
const _TeamMembergenderValueEnumMap = {
  r'male': Gender.male,
  r'female': Gender.female,
  r'other': Gender.other,
};
const _TeamMemberroleEnumValueMap = {
  r'owner': r'owner',
  r'manager': r'manager',
  r'cashier': r'cashier',
  r'viewer': r'viewer',
};
const _TeamMemberroleValueEnumMap = {
  r'owner': UserRole.owner,
  r'manager': UserRole.manager,
  r'cashier': UserRole.cashier,
  r'viewer': UserRole.viewer,
};
const _TeamMembersyncStatusEnumValueMap = {
  r'synced': r'synced',
  r'pending': r'pending',
  r'failed': r'failed',
};
const _TeamMembersyncStatusValueEnumMap = {
  r'synced': SyncStatus.synced,
  r'pending': SyncStatus.pending,
  r'failed': SyncStatus.failed,
};

Id _teamMemberGetId(TeamMember object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _teamMemberGetLinks(TeamMember object) {
  return [];
}

void _teamMemberAttach(IsarCollection<dynamic> col, Id id, TeamMember object) {
  object.id = id;
}

extension TeamMemberQueryWhereSort
    on QueryBuilder<TeamMember, TeamMember, QWhere> {
  QueryBuilder<TeamMember, TeamMember, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterWhere> anyUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'userId'),
      );
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterWhere> anyBusinessId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'businessId'),
      );
    });
  }
}

extension TeamMemberQueryWhere
    on QueryBuilder<TeamMember, TeamMember, QWhereClause> {
  QueryBuilder<TeamMember, TeamMember, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterWhereClause> userIdEqualTo(
      int userId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userId',
        value: [userId],
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterWhereClause> userIdNotEqualTo(
      int userId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [userId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [userId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userId',
              lower: [],
              upper: [userId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterWhereClause> userIdGreaterThan(
    int userId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'userId',
        lower: [userId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterWhereClause> userIdLessThan(
    int userId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'userId',
        lower: [],
        upper: [userId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterWhereClause> userIdBetween(
    int lowerUserId,
    int upperUserId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'userId',
        lower: [lowerUserId],
        includeLower: includeLower,
        upper: [upperUserId],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterWhereClause> businessIdEqualTo(
      int businessId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'businessId',
        value: [businessId],
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterWhereClause> businessIdNotEqualTo(
      int businessId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'businessId',
              lower: [],
              upper: [businessId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'businessId',
              lower: [businessId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'businessId',
              lower: [businessId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'businessId',
              lower: [],
              upper: [businessId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterWhereClause> businessIdGreaterThan(
    int businessId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'businessId',
        lower: [businessId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterWhereClause> businessIdLessThan(
    int businessId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'businessId',
        lower: [],
        upper: [businessId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterWhereClause> businessIdBetween(
    int lowerBusinessId,
    int upperBusinessId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'businessId',
        lower: [lowerBusinessId],
        includeLower: includeLower,
        upper: [upperBusinessId],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension TeamMemberQueryFilter
    on QueryBuilder<TeamMember, TeamMember, QFilterCondition> {
  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> ageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'age',
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> ageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'age',
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> ageEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'age',
        value: value,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> ageGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'age',
        value: value,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> ageLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'age',
        value: value,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> ageBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'age',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> businessIdEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'businessId',
        value: value,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      businessIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'businessId',
        value: value,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      businessIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'businessId',
        value: value,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> businessIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'businessId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> canAddTeamEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'canAddTeam',
        value: value,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> canDeleteEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'canDelete',
        value: value,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      canEditProductsEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'canEditProducts',
        value: value,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      canMakeSalesEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'canMakeSales',
        value: value,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      canManageCreditEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'canManageCredit',
        value: value,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      canManageDevicesEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'canManageDevices',
        value: value,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      canViewProductsEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'canViewProducts',
        value: value,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      canViewReportsEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'canViewReports',
        value: value,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> createdAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> genderIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'gender',
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      genderIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'gender',
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> genderEqualTo(
    Gender? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gender',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> genderGreaterThan(
    Gender? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'gender',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> genderLessThan(
    Gender? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'gender',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> genderBetween(
    Gender? lower,
    Gender? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'gender',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> genderStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'gender',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> genderEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'gender',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> genderContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'gender',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> genderMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'gender',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> genderIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'gender',
        value: '',
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      genderIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'gender',
        value: '',
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> isActiveEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isActive',
        value: value,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> joinedAtEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'joinedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      joinedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'joinedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> joinedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'joinedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> joinedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'joinedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> remoteIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'remoteId',
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      remoteIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'remoteId',
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> remoteIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      remoteIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> remoteIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> remoteIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remoteId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      remoteIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> remoteIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> remoteIdContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> remoteIdMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'remoteId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      remoteIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remoteId',
        value: '',
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      remoteIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'remoteId',
        value: '',
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> roleEqualTo(
    UserRole value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'role',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> roleGreaterThan(
    UserRole value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'role',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> roleLessThan(
    UserRole value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'role',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> roleBetween(
    UserRole lower,
    UserRole upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'role',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> roleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'role',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> roleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'role',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> roleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'role',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> roleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'role',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> roleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'role',
        value: '',
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> roleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'role',
        value: '',
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> syncStatusEqualTo(
    SyncStatus value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      syncStatusGreaterThan(
    SyncStatus value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      syncStatusLessThan(
    SyncStatus value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> syncStatusBetween(
    SyncStatus lower,
    SyncStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      syncStatusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'syncStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      syncStatusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'syncStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      syncStatusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'syncStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> syncStatusMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'syncStatus',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      syncStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      syncStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'syncStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> userIdEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userId',
        value: value,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> userIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userId',
        value: value,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> userIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userId',
        value: value,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> userIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> userNameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'userName',
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      userNameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'userName',
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> userNameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      userNameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> userNameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> userNameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      userNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> userNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> userNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> userNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      userNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userName',
        value: '',
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      userNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userName',
        value: '',
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> userPhoneEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      userPhoneGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> userPhoneLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> userPhoneBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userPhone',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      userPhoneStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> userPhoneEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> userPhoneContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userPhone',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition> userPhoneMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userPhone',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      userPhoneIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userPhone',
        value: '',
      ));
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterFilterCondition>
      userPhoneIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userPhone',
        value: '',
      ));
    });
  }
}

extension TeamMemberQueryObject
    on QueryBuilder<TeamMember, TeamMember, QFilterCondition> {}

extension TeamMemberQueryLinks
    on QueryBuilder<TeamMember, TeamMember, QFilterCondition> {}

extension TeamMemberQuerySortBy
    on QueryBuilder<TeamMember, TeamMember, QSortBy> {
  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByAge() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'age', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByAgeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'age', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByBusinessId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'businessId', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByBusinessIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'businessId', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByCanAddTeam() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canAddTeam', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByCanAddTeamDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canAddTeam', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByCanDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canDelete', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByCanDeleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canDelete', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByCanEditProducts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canEditProducts', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy>
      sortByCanEditProductsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canEditProducts', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByCanMakeSales() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canMakeSales', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByCanMakeSalesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canMakeSales', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByCanManageCredit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canManageCredit', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy>
      sortByCanManageCreditDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canManageCredit', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByCanManageDevices() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canManageDevices', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy>
      sortByCanManageDevicesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canManageDevices', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByCanViewProducts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canViewProducts', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy>
      sortByCanViewProductsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canViewProducts', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByCanViewReports() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canViewReports', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy>
      sortByCanViewReportsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canViewReports', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByGender() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gender', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByGenderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gender', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByJoinedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'joinedAt', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByJoinedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'joinedAt', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByRole() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByRoleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByUserName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByUserNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByUserPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userPhone', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> sortByUserPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userPhone', Sort.desc);
    });
  }
}

extension TeamMemberQuerySortThenBy
    on QueryBuilder<TeamMember, TeamMember, QSortThenBy> {
  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByAge() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'age', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByAgeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'age', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByBusinessId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'businessId', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByBusinessIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'businessId', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByCanAddTeam() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canAddTeam', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByCanAddTeamDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canAddTeam', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByCanDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canDelete', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByCanDeleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canDelete', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByCanEditProducts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canEditProducts', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy>
      thenByCanEditProductsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canEditProducts', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByCanMakeSales() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canMakeSales', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByCanMakeSalesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canMakeSales', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByCanManageCredit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canManageCredit', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy>
      thenByCanManageCreditDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canManageCredit', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByCanManageDevices() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canManageDevices', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy>
      thenByCanManageDevicesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canManageDevices', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByCanViewProducts() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canViewProducts', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy>
      thenByCanViewProductsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canViewProducts', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByCanViewReports() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canViewReports', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy>
      thenByCanViewReportsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'canViewReports', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByGender() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gender', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByGenderDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'gender', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByIsActiveDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isActive', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByJoinedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'joinedAt', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByJoinedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'joinedAt', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByRole() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByRoleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'role', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByUserName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByUserNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.desc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByUserPhone() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userPhone', Sort.asc);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QAfterSortBy> thenByUserPhoneDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userPhone', Sort.desc);
    });
  }
}

extension TeamMemberQueryWhereDistinct
    on QueryBuilder<TeamMember, TeamMember, QDistinct> {
  QueryBuilder<TeamMember, TeamMember, QDistinct> distinctByAge() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'age');
    });
  }

  QueryBuilder<TeamMember, TeamMember, QDistinct> distinctByBusinessId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'businessId');
    });
  }

  QueryBuilder<TeamMember, TeamMember, QDistinct> distinctByCanAddTeam() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'canAddTeam');
    });
  }

  QueryBuilder<TeamMember, TeamMember, QDistinct> distinctByCanDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'canDelete');
    });
  }

  QueryBuilder<TeamMember, TeamMember, QDistinct> distinctByCanEditProducts() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'canEditProducts');
    });
  }

  QueryBuilder<TeamMember, TeamMember, QDistinct> distinctByCanMakeSales() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'canMakeSales');
    });
  }

  QueryBuilder<TeamMember, TeamMember, QDistinct> distinctByCanManageCredit() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'canManageCredit');
    });
  }

  QueryBuilder<TeamMember, TeamMember, QDistinct> distinctByCanManageDevices() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'canManageDevices');
    });
  }

  QueryBuilder<TeamMember, TeamMember, QDistinct> distinctByCanViewProducts() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'canViewProducts');
    });
  }

  QueryBuilder<TeamMember, TeamMember, QDistinct> distinctByCanViewReports() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'canViewReports');
    });
  }

  QueryBuilder<TeamMember, TeamMember, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<TeamMember, TeamMember, QDistinct> distinctByGender(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'gender', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QDistinct> distinctByIsActive() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isActive');
    });
  }

  QueryBuilder<TeamMember, TeamMember, QDistinct> distinctByJoinedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'joinedAt');
    });
  }

  QueryBuilder<TeamMember, TeamMember, QDistinct> distinctByRemoteId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QDistinct> distinctByRole(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'role', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QDistinct> distinctBySyncStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QDistinct> distinctByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId');
    });
  }

  QueryBuilder<TeamMember, TeamMember, QDistinct> distinctByUserName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TeamMember, TeamMember, QDistinct> distinctByUserPhone(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userPhone', caseSensitive: caseSensitive);
    });
  }
}

extension TeamMemberQueryProperty
    on QueryBuilder<TeamMember, TeamMember, QQueryProperty> {
  QueryBuilder<TeamMember, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TeamMember, int?, QQueryOperations> ageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'age');
    });
  }

  QueryBuilder<TeamMember, int, QQueryOperations> businessIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'businessId');
    });
  }

  QueryBuilder<TeamMember, bool, QQueryOperations> canAddTeamProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'canAddTeam');
    });
  }

  QueryBuilder<TeamMember, bool, QQueryOperations> canDeleteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'canDelete');
    });
  }

  QueryBuilder<TeamMember, bool, QQueryOperations> canEditProductsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'canEditProducts');
    });
  }

  QueryBuilder<TeamMember, bool, QQueryOperations> canMakeSalesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'canMakeSales');
    });
  }

  QueryBuilder<TeamMember, bool, QQueryOperations> canManageCreditProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'canManageCredit');
    });
  }

  QueryBuilder<TeamMember, bool, QQueryOperations> canManageDevicesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'canManageDevices');
    });
  }

  QueryBuilder<TeamMember, bool, QQueryOperations> canViewProductsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'canViewProducts');
    });
  }

  QueryBuilder<TeamMember, bool, QQueryOperations> canViewReportsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'canViewReports');
    });
  }

  QueryBuilder<TeamMember, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<TeamMember, Gender?, QQueryOperations> genderProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'gender');
    });
  }

  QueryBuilder<TeamMember, bool, QQueryOperations> isActiveProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isActive');
    });
  }

  QueryBuilder<TeamMember, DateTime, QQueryOperations> joinedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'joinedAt');
    });
  }

  QueryBuilder<TeamMember, String?, QQueryOperations> remoteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteId');
    });
  }

  QueryBuilder<TeamMember, UserRole, QQueryOperations> roleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'role');
    });
  }

  QueryBuilder<TeamMember, SyncStatus, QQueryOperations> syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<TeamMember, int, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }

  QueryBuilder<TeamMember, String?, QQueryOperations> userNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userName');
    });
  }

  QueryBuilder<TeamMember, String, QQueryOperations> userPhoneProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userPhone');
    });
  }
}
