// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_schemas.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetHistorySchemaCollection on Isar {
  IsarCollection<HistorySchema> get historySchemas => this.collection();
}

const HistorySchemaSchema = CollectionSchema(
  name: r'HistorySchema',
  id: -204224817947645094,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'foundCount': PropertySchema(
      id: 1,
      name: r'foundCount',
      type: IsarType.long,
    ),
    r'sourceUrl': PropertySchema(
      id: 2,
      name: r'sourceUrl',
      type: IsarType.string,
    ),
  },

  estimateSize: _historySchemaEstimateSize,
  serialize: _historySchemaSerialize,
  deserialize: _historySchemaDeserialize,
  deserializeProp: _historySchemaDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _historySchemaGetId,
  getLinks: _historySchemaGetLinks,
  attach: _historySchemaAttach,
  version: '3.3.2',
);

int _historySchemaEstimateSize(
  HistorySchema object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.sourceUrl.length * 3;
  return bytesCount;
}

void _historySchemaSerialize(
  HistorySchema object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeLong(offsets[1], object.foundCount);
  writer.writeString(offsets[2], object.sourceUrl);
}

HistorySchema _historySchemaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = HistorySchema();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.foundCount = reader.readLong(offsets[1]);
  object.id = id;
  object.sourceUrl = reader.readString(offsets[2]);
  return object;
}

P _historySchemaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _historySchemaGetId(HistorySchema object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _historySchemaGetLinks(HistorySchema object) {
  return [];
}

void _historySchemaAttach(
  IsarCollection<dynamic> col,
  Id id,
  HistorySchema object,
) {
  object.id = id;
}

extension HistorySchemaQueryWhereSort
    on QueryBuilder<HistorySchema, HistorySchema, QWhere> {
  QueryBuilder<HistorySchema, HistorySchema, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension HistorySchemaQueryWhere
    on QueryBuilder<HistorySchema, HistorySchema, QWhereClause> {
  QueryBuilder<HistorySchema, HistorySchema, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
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

  QueryBuilder<HistorySchema, HistorySchema, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension HistorySchemaQueryFilter
    on QueryBuilder<HistorySchema, HistorySchema, QFilterCondition> {
  QueryBuilder<HistorySchema, HistorySchema, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterFilterCondition>
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterFilterCondition>
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterFilterCondition>
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterFilterCondition>
  foundCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'foundCount', value: value),
      );
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterFilterCondition>
  foundCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'foundCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterFilterCondition>
  foundCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'foundCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterFilterCondition>
  foundCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'foundCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterFilterCondition>
  sourceUrlEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sourceUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterFilterCondition>
  sourceUrlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterFilterCondition>
  sourceUrlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterFilterCondition>
  sourceUrlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceUrl',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterFilterCondition>
  sourceUrlStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sourceUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterFilterCondition>
  sourceUrlEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sourceUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterFilterCondition>
  sourceUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sourceUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterFilterCondition>
  sourceUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sourceUrl',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterFilterCondition>
  sourceUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceUrl', value: ''),
      );
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterFilterCondition>
  sourceUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceUrl', value: ''),
      );
    });
  }
}

extension HistorySchemaQueryObject
    on QueryBuilder<HistorySchema, HistorySchema, QFilterCondition> {}

extension HistorySchemaQueryLinks
    on QueryBuilder<HistorySchema, HistorySchema, QFilterCondition> {}

extension HistorySchemaQuerySortBy
    on QueryBuilder<HistorySchema, HistorySchema, QSortBy> {
  QueryBuilder<HistorySchema, HistorySchema, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterSortBy> sortByFoundCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'foundCount', Sort.asc);
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterSortBy>
  sortByFoundCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'foundCount', Sort.desc);
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterSortBy> sortBySourceUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceUrl', Sort.asc);
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterSortBy>
  sortBySourceUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceUrl', Sort.desc);
    });
  }
}

extension HistorySchemaQuerySortThenBy
    on QueryBuilder<HistorySchema, HistorySchema, QSortThenBy> {
  QueryBuilder<HistorySchema, HistorySchema, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterSortBy> thenByFoundCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'foundCount', Sort.asc);
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterSortBy>
  thenByFoundCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'foundCount', Sort.desc);
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterSortBy> thenBySourceUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceUrl', Sort.asc);
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QAfterSortBy>
  thenBySourceUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceUrl', Sort.desc);
    });
  }
}

extension HistorySchemaQueryWhereDistinct
    on QueryBuilder<HistorySchema, HistorySchema, QDistinct> {
  QueryBuilder<HistorySchema, HistorySchema, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QDistinct> distinctByFoundCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'foundCount');
    });
  }

  QueryBuilder<HistorySchema, HistorySchema, QDistinct> distinctBySourceUrl({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceUrl', caseSensitive: caseSensitive);
    });
  }
}

extension HistorySchemaQueryProperty
    on QueryBuilder<HistorySchema, HistorySchema, QQueryProperty> {
  QueryBuilder<HistorySchema, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<HistorySchema, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<HistorySchema, int, QQueryOperations> foundCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'foundCount');
    });
  }

  QueryBuilder<HistorySchema, String, QQueryOperations> sourceUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceUrl');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLogSchemaCollection on Isar {
  IsarCollection<LogSchema> get logSchemas => this.collection();
}

const LogSchemaSchema = CollectionSchema(
  name: r'LogSchema',
  id: 2306422738563465626,
  properties: {
    r'level': PropertySchema(id: 0, name: r'level', type: IsarType.string),
    r'message': PropertySchema(id: 1, name: r'message', type: IsarType.string),
    r'source': PropertySchema(id: 2, name: r'source', type: IsarType.string),
    r'timestamp': PropertySchema(
      id: 3,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _logSchemaEstimateSize,
  serialize: _logSchemaSerialize,
  deserialize: _logSchemaDeserialize,
  deserializeProp: _logSchemaDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _logSchemaGetId,
  getLinks: _logSchemaGetLinks,
  attach: _logSchemaAttach,
  version: '3.3.2',
);

int _logSchemaEstimateSize(
  LogSchema object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.level.length * 3;
  bytesCount += 3 + object.message.length * 3;
  {
    final value = object.source;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _logSchemaSerialize(
  LogSchema object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.level);
  writer.writeString(offsets[1], object.message);
  writer.writeString(offsets[2], object.source);
  writer.writeDateTime(offsets[3], object.timestamp);
}

LogSchema _logSchemaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LogSchema();
  object.id = id;
  object.level = reader.readString(offsets[0]);
  object.message = reader.readString(offsets[1]);
  object.source = reader.readStringOrNull(offsets[2]);
  object.timestamp = reader.readDateTime(offsets[3]);
  return object;
}

P _logSchemaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _logSchemaGetId(LogSchema object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _logSchemaGetLinks(LogSchema object) {
  return [];
}

void _logSchemaAttach(IsarCollection<dynamic> col, Id id, LogSchema object) {
  object.id = id;
}

extension LogSchemaQueryWhereSort
    on QueryBuilder<LogSchema, LogSchema, QWhere> {
  QueryBuilder<LogSchema, LogSchema, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LogSchemaQueryWhere
    on QueryBuilder<LogSchema, LogSchema, QWhereClause> {
  QueryBuilder<LogSchema, LogSchema, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<LogSchema, LogSchema, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension LogSchemaQueryFilter
    on QueryBuilder<LogSchema, LogSchema, QFilterCondition> {
  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> levelEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'level',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> levelGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'level',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> levelLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'level',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> levelBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'level',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> levelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'level',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> levelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'level',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> levelContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'level',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> levelMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'level',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> levelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'level', value: ''),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> levelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'level', value: ''),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> messageEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'message',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> messageGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'message',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> messageLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'message',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> messageBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'message',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> messageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'message',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> messageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'message',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> messageContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'message',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> messageMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'message',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> messageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'message', value: ''),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition>
  messageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'message', value: ''),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> sourceIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'source'),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> sourceIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'source'),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> sourceEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> sourceGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> sourceLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> sourceBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'source',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> sourceStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> sourceEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> sourceContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'source',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> sourceMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'source',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> sourceIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'source', value: ''),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> sourceIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'source', value: ''),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> timestampEqualTo(
    DateTime value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'timestamp', value: value),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition>
  timestampGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'timestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'timestamp',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterFilterCondition> timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'timestamp',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension LogSchemaQueryObject
    on QueryBuilder<LogSchema, LogSchema, QFilterCondition> {}

extension LogSchemaQueryLinks
    on QueryBuilder<LogSchema, LogSchema, QFilterCondition> {}

extension LogSchemaQuerySortBy on QueryBuilder<LogSchema, LogSchema, QSortBy> {
  QueryBuilder<LogSchema, LogSchema, QAfterSortBy> sortByLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.asc);
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterSortBy> sortByLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.desc);
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterSortBy> sortByMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.asc);
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterSortBy> sortByMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.desc);
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterSortBy> sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterSortBy> sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterSortBy> sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension LogSchemaQuerySortThenBy
    on QueryBuilder<LogSchema, LogSchema, QSortThenBy> {
  QueryBuilder<LogSchema, LogSchema, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterSortBy> thenByLevel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.asc);
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterSortBy> thenByLevelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'level', Sort.desc);
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterSortBy> thenByMessage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.asc);
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterSortBy> thenByMessageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'message', Sort.desc);
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterSortBy> thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterSortBy> thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterSortBy> thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<LogSchema, LogSchema, QAfterSortBy> thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension LogSchemaQueryWhereDistinct
    on QueryBuilder<LogSchema, LogSchema, QDistinct> {
  QueryBuilder<LogSchema, LogSchema, QDistinct> distinctByLevel({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'level', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LogSchema, LogSchema, QDistinct> distinctByMessage({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'message', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LogSchema, LogSchema, QDistinct> distinctBySource({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LogSchema, LogSchema, QDistinct> distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }
}

extension LogSchemaQueryProperty
    on QueryBuilder<LogSchema, LogSchema, QQueryProperty> {
  QueryBuilder<LogSchema, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LogSchema, String, QQueryOperations> levelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'level');
    });
  }

  QueryBuilder<LogSchema, String, QQueryOperations> messageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'message');
    });
  }

  QueryBuilder<LogSchema, String?, QQueryOperations> sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<LogSchema, DateTime, QQueryOperations> timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDownloadedFileSchemaCollection on Isar {
  IsarCollection<DownloadedFileSchema> get downloadedFileSchemas =>
      this.collection();
}

const DownloadedFileSchemaSchema = CollectionSchema(
  name: r'DownloadedFileSchema',
  id: 6239594457499999639,
  properties: {
    r'downloadedAt': PropertySchema(
      id: 0,
      name: r'downloadedAt',
      type: IsarType.dateTime,
    ),
    r'extension': PropertySchema(
      id: 1,
      name: r'extension',
      type: IsarType.string,
    ),
    r'fileName': PropertySchema(
      id: 2,
      name: r'fileName',
      type: IsarType.string,
    ),
    r'savedPath': PropertySchema(
      id: 3,
      name: r'savedPath',
      type: IsarType.string,
    ),
    r'sourceUrl': PropertySchema(
      id: 4,
      name: r'sourceUrl',
      type: IsarType.string,
    ),
    r'url': PropertySchema(id: 5, name: r'url', type: IsarType.string),
  },

  estimateSize: _downloadedFileSchemaEstimateSize,
  serialize: _downloadedFileSchemaSerialize,
  deserialize: _downloadedFileSchemaDeserialize,
  deserializeProp: _downloadedFileSchemaDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _downloadedFileSchemaGetId,
  getLinks: _downloadedFileSchemaGetLinks,
  attach: _downloadedFileSchemaAttach,
  version: '3.3.2',
);

int _downloadedFileSchemaEstimateSize(
  DownloadedFileSchema object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.extension.length * 3;
  bytesCount += 3 + object.fileName.length * 3;
  bytesCount += 3 + object.savedPath.length * 3;
  {
    final value = object.sourceUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.url.length * 3;
  return bytesCount;
}

void _downloadedFileSchemaSerialize(
  DownloadedFileSchema object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.downloadedAt);
  writer.writeString(offsets[1], object.extension);
  writer.writeString(offsets[2], object.fileName);
  writer.writeString(offsets[3], object.savedPath);
  writer.writeString(offsets[4], object.sourceUrl);
  writer.writeString(offsets[5], object.url);
}

DownloadedFileSchema _downloadedFileSchemaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DownloadedFileSchema();
  object.downloadedAt = reader.readDateTime(offsets[0]);
  object.extension = reader.readString(offsets[1]);
  object.fileName = reader.readString(offsets[2]);
  object.id = id;
  object.savedPath = reader.readString(offsets[3]);
  object.sourceUrl = reader.readStringOrNull(offsets[4]);
  object.url = reader.readString(offsets[5]);
  return object;
}

P _downloadedFileSchemaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _downloadedFileSchemaGetId(DownloadedFileSchema object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _downloadedFileSchemaGetLinks(
  DownloadedFileSchema object,
) {
  return [];
}

void _downloadedFileSchemaAttach(
  IsarCollection<dynamic> col,
  Id id,
  DownloadedFileSchema object,
) {
  object.id = id;
}

extension DownloadedFileSchemaQueryWhereSort
    on QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QWhere> {
  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DownloadedFileSchemaQueryWhere
    on QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QWhereClause> {
  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterWhereClause>
  idNotEqualTo(Id id) {
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

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension DownloadedFileSchemaQueryFilter
    on
        QueryBuilder<
          DownloadedFileSchema,
          DownloadedFileSchema,
          QFilterCondition
        > {
  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  downloadedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'downloadedAt', value: value),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  downloadedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'downloadedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  downloadedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'downloadedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  downloadedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'downloadedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  extensionEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'extension',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  extensionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'extension',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  extensionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'extension',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  extensionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'extension',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  extensionStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'extension',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  extensionEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'extension',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  extensionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'extension',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  extensionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'extension',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  extensionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'extension', value: ''),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  extensionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'extension', value: ''),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  fileNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  fileNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  fileNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  fileNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'fileName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  fileNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  fileNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  fileNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'fileName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  fileNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'fileName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  fileNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'fileName', value: ''),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  fileNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'fileName', value: ''),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  savedPathEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'savedPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  savedPathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'savedPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  savedPathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'savedPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  savedPathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'savedPath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  savedPathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'savedPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  savedPathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'savedPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  savedPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'savedPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  savedPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'savedPath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  savedPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'savedPath', value: ''),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  savedPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'savedPath', value: ''),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  sourceUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'sourceUrl'),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  sourceUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'sourceUrl'),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  sourceUrlEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sourceUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  sourceUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  sourceUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  sourceUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceUrl',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  sourceUrlStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sourceUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  sourceUrlEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sourceUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  sourceUrlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sourceUrl',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  sourceUrlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sourceUrl',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  sourceUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceUrl', value: ''),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  sourceUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceUrl', value: ''),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  urlEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  urlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  urlLessThan(String value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  urlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'url',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  urlStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  urlEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  urlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  urlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'url',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  urlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'url', value: ''),
      );
    });
  }

  QueryBuilder<
    DownloadedFileSchema,
    DownloadedFileSchema,
    QAfterFilterCondition
  >
  urlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'url', value: ''),
      );
    });
  }
}

extension DownloadedFileSchemaQueryObject
    on
        QueryBuilder<
          DownloadedFileSchema,
          DownloadedFileSchema,
          QFilterCondition
        > {}

extension DownloadedFileSchemaQueryLinks
    on
        QueryBuilder<
          DownloadedFileSchema,
          DownloadedFileSchema,
          QFilterCondition
        > {}

extension DownloadedFileSchemaQuerySortBy
    on QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QSortBy> {
  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterSortBy>
  sortByDownloadedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadedAt', Sort.asc);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterSortBy>
  sortByDownloadedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadedAt', Sort.desc);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterSortBy>
  sortByExtension() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extension', Sort.asc);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterSortBy>
  sortByExtensionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extension', Sort.desc);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterSortBy>
  sortByFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.asc);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterSortBy>
  sortByFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.desc);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterSortBy>
  sortBySavedPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedPath', Sort.asc);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterSortBy>
  sortBySavedPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedPath', Sort.desc);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterSortBy>
  sortBySourceUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceUrl', Sort.asc);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterSortBy>
  sortBySourceUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceUrl', Sort.desc);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterSortBy>
  sortByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterSortBy>
  sortByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }
}

extension DownloadedFileSchemaQuerySortThenBy
    on QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QSortThenBy> {
  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterSortBy>
  thenByDownloadedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadedAt', Sort.asc);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterSortBy>
  thenByDownloadedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadedAt', Sort.desc);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterSortBy>
  thenByExtension() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extension', Sort.asc);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterSortBy>
  thenByExtensionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'extension', Sort.desc);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterSortBy>
  thenByFileName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.asc);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterSortBy>
  thenByFileNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'fileName', Sort.desc);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterSortBy>
  thenBySavedPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedPath', Sort.asc);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterSortBy>
  thenBySavedPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'savedPath', Sort.desc);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterSortBy>
  thenBySourceUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceUrl', Sort.asc);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterSortBy>
  thenBySourceUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceUrl', Sort.desc);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterSortBy>
  thenByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QAfterSortBy>
  thenByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }
}

extension DownloadedFileSchemaQueryWhereDistinct
    on QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QDistinct> {
  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QDistinct>
  distinctByDownloadedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'downloadedAt');
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QDistinct>
  distinctByExtension({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'extension', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QDistinct>
  distinctByFileName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'fileName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QDistinct>
  distinctBySavedPath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'savedPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QDistinct>
  distinctBySourceUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sourceUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DownloadedFileSchema, DownloadedFileSchema, QDistinct>
  distinctByUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'url', caseSensitive: caseSensitive);
    });
  }
}

extension DownloadedFileSchemaQueryProperty
    on
        QueryBuilder<
          DownloadedFileSchema,
          DownloadedFileSchema,
          QQueryProperty
        > {
  QueryBuilder<DownloadedFileSchema, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DownloadedFileSchema, DateTime, QQueryOperations>
  downloadedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'downloadedAt');
    });
  }

  QueryBuilder<DownloadedFileSchema, String, QQueryOperations>
  extensionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'extension');
    });
  }

  QueryBuilder<DownloadedFileSchema, String, QQueryOperations>
  fileNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'fileName');
    });
  }

  QueryBuilder<DownloadedFileSchema, String, QQueryOperations>
  savedPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'savedPath');
    });
  }

  QueryBuilder<DownloadedFileSchema, String?, QQueryOperations>
  sourceUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceUrl');
    });
  }

  QueryBuilder<DownloadedFileSchema, String, QQueryOperations> urlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'url');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFilterSettingsSchemaCollection on Isar {
  IsarCollection<FilterSettingsSchema> get filterSettingsSchemas =>
      this.collection();
}

const FilterSettingsSchemaSchema = CollectionSchema(
  name: r'FilterSettingsSchema',
  id: -8114639879770297664,
  properties: {
    r'allowedExtensions': PropertySchema(
      id: 0,
      name: r'allowedExtensions',
      type: IsarType.stringList,
    ),
    r'downloadLimit': PropertySchema(
      id: 1,
      name: r'downloadLimit',
      type: IsarType.long,
    ),
    r'ignoreSmallFiles': PropertySchema(
      id: 2,
      name: r'ignoreSmallFiles',
      type: IsarType.bool,
    ),
    r'minSizeBytes': PropertySchema(
      id: 3,
      name: r'minSizeBytes',
      type: IsarType.long,
    ),
    r'onlyVideo': PropertySchema(
      id: 4,
      name: r'onlyVideo',
      type: IsarType.bool,
    ),
  },

  estimateSize: _filterSettingsSchemaEstimateSize,
  serialize: _filterSettingsSchemaSerialize,
  deserialize: _filterSettingsSchemaDeserialize,
  deserializeProp: _filterSettingsSchemaDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},

  getId: _filterSettingsSchemaGetId,
  getLinks: _filterSettingsSchemaGetLinks,
  attach: _filterSettingsSchemaAttach,
  version: '3.3.2',
);

int _filterSettingsSchemaEstimateSize(
  FilterSettingsSchema object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.allowedExtensions.length * 3;
  {
    for (var i = 0; i < object.allowedExtensions.length; i++) {
      final value = object.allowedExtensions[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _filterSettingsSchemaSerialize(
  FilterSettingsSchema object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.allowedExtensions);
  writer.writeLong(offsets[1], object.downloadLimit);
  writer.writeBool(offsets[2], object.ignoreSmallFiles);
  writer.writeLong(offsets[3], object.minSizeBytes);
  writer.writeBool(offsets[4], object.onlyVideo);
}

FilterSettingsSchema _filterSettingsSchemaDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FilterSettingsSchema();
  object.allowedExtensions = reader.readStringList(offsets[0]) ?? [];
  object.downloadLimit = reader.readLongOrNull(offsets[1]);
  object.id = id;
  object.ignoreSmallFiles = reader.readBool(offsets[2]);
  object.minSizeBytes = reader.readLongOrNull(offsets[3]);
  object.onlyVideo = reader.readBool(offsets[4]);
  return object;
}

P _filterSettingsSchemaDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringList(offset) ?? []) as P;
    case 1:
      return (reader.readLongOrNull(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _filterSettingsSchemaGetId(FilterSettingsSchema object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _filterSettingsSchemaGetLinks(
  FilterSettingsSchema object,
) {
  return [];
}

void _filterSettingsSchemaAttach(
  IsarCollection<dynamic> col,
  Id id,
  FilterSettingsSchema object,
) {
  object.id = id;
}

extension FilterSettingsSchemaQueryWhereSort
    on QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QWhere> {
  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension FilterSettingsSchemaQueryWhere
    on QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QWhereClause> {
  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QAfterWhereClause>
  idNotEqualTo(Id id) {
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

  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QAfterWhereClause>
  idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension FilterSettingsSchemaQueryFilter
    on
        QueryBuilder<
          FilterSettingsSchema,
          FilterSettingsSchema,
          QFilterCondition
        > {
  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  allowedExtensionsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'allowedExtensions',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  allowedExtensionsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'allowedExtensions',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  allowedExtensionsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'allowedExtensions',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  allowedExtensionsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'allowedExtensions',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  allowedExtensionsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'allowedExtensions',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  allowedExtensionsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'allowedExtensions',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  allowedExtensionsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'allowedExtensions',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  allowedExtensionsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'allowedExtensions',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  allowedExtensionsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'allowedExtensions', value: ''),
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  allowedExtensionsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'allowedExtensions', value: ''),
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  allowedExtensionsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'allowedExtensions', length, true, length, true);
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  allowedExtensionsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'allowedExtensions', 0, true, 0, true);
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  allowedExtensionsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'allowedExtensions', 0, false, 999999, true);
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  allowedExtensionsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'allowedExtensions', 0, true, length, include);
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  allowedExtensionsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'allowedExtensions',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  allowedExtensionsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'allowedExtensions',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  downloadLimitIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'downloadLimit'),
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  downloadLimitIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'downloadLimit'),
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  downloadLimitEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'downloadLimit', value: value),
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  downloadLimitGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'downloadLimit',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  downloadLimitLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'downloadLimit',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  downloadLimitBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'downloadLimit',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  ignoreSmallFilesEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ignoreSmallFiles', value: value),
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  minSizeBytesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'minSizeBytes'),
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  minSizeBytesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'minSizeBytes'),
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  minSizeBytesEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'minSizeBytes', value: value),
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  minSizeBytesGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'minSizeBytes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  minSizeBytesLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'minSizeBytes',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  minSizeBytesBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'minSizeBytes',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    FilterSettingsSchema,
    FilterSettingsSchema,
    QAfterFilterCondition
  >
  onlyVideoEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'onlyVideo', value: value),
      );
    });
  }
}

extension FilterSettingsSchemaQueryObject
    on
        QueryBuilder<
          FilterSettingsSchema,
          FilterSettingsSchema,
          QFilterCondition
        > {}

extension FilterSettingsSchemaQueryLinks
    on
        QueryBuilder<
          FilterSettingsSchema,
          FilterSettingsSchema,
          QFilterCondition
        > {}

extension FilterSettingsSchemaQuerySortBy
    on QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QSortBy> {
  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QAfterSortBy>
  sortByDownloadLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadLimit', Sort.asc);
    });
  }

  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QAfterSortBy>
  sortByDownloadLimitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadLimit', Sort.desc);
    });
  }

  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QAfterSortBy>
  sortByIgnoreSmallFiles() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ignoreSmallFiles', Sort.asc);
    });
  }

  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QAfterSortBy>
  sortByIgnoreSmallFilesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ignoreSmallFiles', Sort.desc);
    });
  }

  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QAfterSortBy>
  sortByMinSizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minSizeBytes', Sort.asc);
    });
  }

  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QAfterSortBy>
  sortByMinSizeBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minSizeBytes', Sort.desc);
    });
  }

  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QAfterSortBy>
  sortByOnlyVideo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlyVideo', Sort.asc);
    });
  }

  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QAfterSortBy>
  sortByOnlyVideoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlyVideo', Sort.desc);
    });
  }
}

extension FilterSettingsSchemaQuerySortThenBy
    on QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QSortThenBy> {
  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QAfterSortBy>
  thenByDownloadLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadLimit', Sort.asc);
    });
  }

  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QAfterSortBy>
  thenByDownloadLimitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'downloadLimit', Sort.desc);
    });
  }

  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QAfterSortBy>
  thenByIgnoreSmallFiles() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ignoreSmallFiles', Sort.asc);
    });
  }

  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QAfterSortBy>
  thenByIgnoreSmallFilesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ignoreSmallFiles', Sort.desc);
    });
  }

  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QAfterSortBy>
  thenByMinSizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minSizeBytes', Sort.asc);
    });
  }

  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QAfterSortBy>
  thenByMinSizeBytesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'minSizeBytes', Sort.desc);
    });
  }

  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QAfterSortBy>
  thenByOnlyVideo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlyVideo', Sort.asc);
    });
  }

  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QAfterSortBy>
  thenByOnlyVideoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'onlyVideo', Sort.desc);
    });
  }
}

extension FilterSettingsSchemaQueryWhereDistinct
    on QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QDistinct> {
  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QDistinct>
  distinctByAllowedExtensions() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'allowedExtensions');
    });
  }

  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QDistinct>
  distinctByDownloadLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'downloadLimit');
    });
  }

  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QDistinct>
  distinctByIgnoreSmallFiles() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ignoreSmallFiles');
    });
  }

  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QDistinct>
  distinctByMinSizeBytes() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'minSizeBytes');
    });
  }

  QueryBuilder<FilterSettingsSchema, FilterSettingsSchema, QDistinct>
  distinctByOnlyVideo() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'onlyVideo');
    });
  }
}

extension FilterSettingsSchemaQueryProperty
    on
        QueryBuilder<
          FilterSettingsSchema,
          FilterSettingsSchema,
          QQueryProperty
        > {
  QueryBuilder<FilterSettingsSchema, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<FilterSettingsSchema, List<String>, QQueryOperations>
  allowedExtensionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'allowedExtensions');
    });
  }

  QueryBuilder<FilterSettingsSchema, int?, QQueryOperations>
  downloadLimitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'downloadLimit');
    });
  }

  QueryBuilder<FilterSettingsSchema, bool, QQueryOperations>
  ignoreSmallFilesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ignoreSmallFiles');
    });
  }

  QueryBuilder<FilterSettingsSchema, int?, QQueryOperations>
  minSizeBytesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'minSizeBytes');
    });
  }

  QueryBuilder<FilterSettingsSchema, bool, QQueryOperations>
  onlyVideoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'onlyVideo');
    });
  }
}
