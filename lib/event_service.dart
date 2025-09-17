import 'package:eva_event_service/config/event_item.dart';
import 'package:eva_event_service/db/data_base_client.dart';
import 'package:eva_sdk/eva_sdk.dart';

class EventService {
  static EventService? _instanse;

  final Map<String, EventItem> events;
  final Oid lvar;

  EventService._(this.events, this.lvar);

  factory EventService.getInstane([Map<String, EventItem>? events, Oid? oid]) {
    if (_instanse == null && events == null && oid == null) {
      throw Exception("EventService need initialization");
    }

    _instanse ??= EventService._(events!, oid!);

    return _instanse!;
  }

  Future<void> subscribe() async {
    final items = events.keys.map((k) => (Oid(k), _handler));
    await svc().subscribeOIDs(items, EventKind.local);
  }

  String getName(String oid) => events[oid]?.name ?? 'any event';

  static Future<void> _handler(ItemState payload, String _, String _) async {
    final db = DataBaseClient.getInstane();
    late final int? id;
    if (payload.value == true || payload.value == 1) {
      id = await db.startEvent(payload.oid.asString(), payload.t);
    } else {
      id = await db.endEvent(payload.oid.asString(), payload.t);
    }

    if (id == null) {
      return;
    }

    var event = await db.getEvent(id);

    if (event == null) {
      return;
    }
    final es = EventService.getInstane();
    final name = es.getName(event.item);
    event = event.addName(name);

    await svc().rpc.bus.publish(
      EapiTopic.rawStateTopic.resolve(es.lvar.asPath()),
      serialize({'status': 1, 'value': event.toMap(), 't': evaNow()}),
    );
  }
}
