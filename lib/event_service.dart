import 'package:eva_event_service/config/event_item.dart';
import 'package:eva_event_service/db/data_base_client.dart';
import 'package:eva_sdk/eva_sdk.dart';

class EventService {
  static EventService? _instanse;

  final Map<String, EventItem> events;

  EventService._(this.events);

  factory EventService.getInstane([Map<String, EventItem>? events]) {
    if (_instanse == null && events == null) {
      throw Exception("EventService need initialization");
    }

    _instanse ??= EventService._(events!);

    return _instanse!;
  }

  Future<void> subscribe() async {
    final items = events.keys.map((k) => (Oid(k), _handler));
    await svc().subscribeOIDs(items, EventKind.local);
  }

  static Future<void> _handler(ItemState payload, String _, String _) async {
    final db = DataBaseClient.getInstane();
    if (payload.value == true || payload.value == 1) {
      await db.startEvent(payload.oid.asString(), payload.t);
      return;
    }

    await db.endEvent(payload.oid.asString(), payload.t);
  }
}
