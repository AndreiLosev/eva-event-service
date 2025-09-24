import 'package:eva_event_service/config/db.dart';
import 'package:eva_event_service/config/event_item.dart';
import 'package:eva_sdk/eva_sdk.dart';

class Config {
  final Db db;
  final Map<String, EventItem> events;
  final Oid updateLvar;
  final int currentEventLimit;
  final int removeEventsAfterDays;

  Config(
    this.db,
    this.events,
    this.updateLvar,
    this.currentEventLimit,
    this.removeEventsAfterDays,
  );

  factory Config.fromMap(Map map) {
    final events = <String, EventItem>{};
    for (var key in map['events'].keys) {
      events[key] = EventItem.fromMap(map['events'][key]);
    }
    return Config(
      Db.fromString(map['db']),
      events,
      Oid(map['update_lvar']),
      map['current_event_limit'],
      map['remove_events_after_days'],
    );
  }
}
