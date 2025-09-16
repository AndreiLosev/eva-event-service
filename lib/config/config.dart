import 'package:eva_event_service/config/db.dart';
import 'package:eva_event_service/config/event_item.dart';

class Config {
  final Db db;
  final Map<String, EventItem> events;

  Config(this.db, this.events);

  factory Config.fromMap(Map map) {
    final events = <String, EventItem>{};
    for (var key in map['events'].keys) {
      events[key] = EventItem.fromMap(map['events'][key]);
    }
    return Config(Db.fromMap(map), events);
  }
}
