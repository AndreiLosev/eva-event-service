import 'dart:js_interop';

import 'package:eva_event_service/config/db.dart';
import 'package:eva_event_service/db/event.dart';
import 'package:eva_event_service/db/sql.dart' as sql;
import 'package:postgres/postgres.dart';

class DataBaseClient {
  static DataBaseClient? _instance;

  late final String _createTableSql;
  late final String _startEventSql;
  late final String _endEventSql;
  late final String _getEvents;
  late final String _acknowledge;
  late final String _getEvent;
  late final String _getEventsById;
  late final String _removeByEventStart;

  final Db _config;
  Connection? _dbConn;

  DataBaseClient._(this._config) {
    _prepareSql();
  }

  factory DataBaseClient.getInstane([Db? config]) {
    if (_instance == null && config == null) {
      throw Exception("need initialize connection");
    }
    _instance ??= DataBaseClient._(config!);

    return _instance!;
  }

  Future<void> connect() async {
    _dbConn = await Connection.open(
      Endpoint(
        host: _config.host,
        port: _config.port,
        username: _config.user,
        password: _config.password,
        database: _config.db,
      ),
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );
  }

  Future<void> disconnect() async {
    _dbConn?.close();
    _dbConn = null;
  }

  bool isConnected() => _dbConn?.isOpen ?? false;

  Future<void> makeTable() async {
    await _dbConn?.execute(_createTableSql, queryMode: QueryMode.simple);
  }

  Future<int?> startEvent(String oid, DateTime eventStart) async {
    final res = await _dbConn?.execute(
      Sql.named(_startEventSql),
      parameters: {'item': oid, 'event_start': eventStart},
    );

    if (res == null) {
      return null;
    }

    return res[0][0] as int;
  }

  Future<int?> endEvent(String oid, DateTime eventEnd) async {
    final res = await _dbConn?.execute(
      Sql.named(_endEventSql),
      parameters: {'item': oid, 'event_end': eventEnd},
    );

    if (res == null || res.isEmpty) {
      return null;
    }

    return res.first[0] as int;
  }

  Future<List<Event>> eventList([
    int? offset,
    int? limit,
    String? where,
  ]) async {
    offset ??= 0;
    limit ??= 10;

    final sql = where != null
        ? _getEvents.replaceFirst('{{ WHERE }}', where)
        : _getEvents.replaceFirst("{{ WHERE }}", "");

    final res = await _dbConn?.execute(
      Sql.named(sql),
      parameters: {'limit': limit, 'offset': offset},
    );

    if (res == null) return [];

    return res.map((e) => Event.fromMap(e.toColumnMap())).toList();
  }

  Future<List<Event>> eventsById(List<int> ids) async {
    final res = await _dbConn?.execute(
      Sql.named(_getEventsById),
      parameters: {'ids': ids},
    );

    if (res == null) return [];

    return res.map((e) => Event.fromMap(e.toColumnMap())).toList();
  }

  Future<void> acknowledge(List<int> ids) async {
    await _dbConn?.execute(Sql.named(_acknowledge), parameters: {'ids': ids});
  }

  Future<void> removeByStart(DateTime start) async {
    await _dbConn?.execute(
      Sql.named(_removeByEventStart),
      parameters: {'event_start', start},
    );
  }

  Future<Event?> getEvent(int id) async {
    final res = await _dbConn?.execute(
      Sql.named(_getEvent),
      parameters: {'id': id},
    );

    if (res == null) {
      return null;
    }

    return Event.fromMap(res.first.toColumnMap());
  }

  void _prepareSql() {
    _createTableSql = sql.addTableNameToSql(sql.createTable, _config.table);
    _startEventSql = sql
        .addTableNameToSql(sql.startEvent, _config.table)
        .replaceFirst("{{ item }}", '@item')
        .replaceFirst("{{ event_start }}", '@event_start');

    _endEventSql = sql
        .addTableNameToSql(sql.endEvent, _config.table)
        .replaceFirst("{{ item }}", '@item')
        .replaceFirst("{{ event_end }}", '@event_end');

    _getEvents = sql
        .addTableNameToSql(sql.getEvents, _config.table)
        .replaceFirst('{{ limit }}', '@limit')
        .replaceFirst('{{ offset }}', '@offset');

    _acknowledge = sql
        .addTableNameToSql(sql.acknowledge, _config.table)
        .replaceFirst('{{ ids }}', '@ids');

    _getEvent = sql
        .addTableNameToSql("${sql.selectById} limit 1", _config.table)
        .replaceFirst('ANY({{ id }})', '@id');

    _getEventsById = sql
        .addTableNameToSql(sql.selectById, _config.table)
        .replaceFirst('{{ id }}', '@ids');

    _removeByEventStart = sql
        .addTableNameToSql(sql.remove, _config.table)
        .replaceFirst('{{ event_end }}', 'event_end');
  }
}
