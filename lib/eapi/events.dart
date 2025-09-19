import 'package:eva_event_service/db/data_base_client.dart';
import 'package:eva_event_service/event_service.dart';
import 'package:eva_sdk/eva_sdk.dart';

class Events {
  static const name = "events";
  static const description = "get events by date or limit";

  Future<Map<String, dynamic>?> call(Map<String, dynamic> params) async {
    final offset = params['offset'];
    final limit = params['limit'];
    final active = params['active'] ?? false;

    final es = EventService.getInstane();
    final db = DataBaseClient.getInstane();
    final events = await db.eventList(offset, limit, active);

    final activeItem = events
        .where((e) => e.eventEnd == null && es.svcStart.isBefore(e.eventStart))
        .map((e) => e.item)
        .toSet();

    if (activeItem.isNotEmpty) {
      final items = await svc().getItemsState(
        activeItem.map((e) => Oid(e)).toList(),
      );

      for (var item in items) {
        if (item.value == true || item.value == 1) {
          continue;
        }

        db.endEvent(item.oid.asString(), item.t);

        for (var (i, e) in events.indexed) {
          if (e.item == item.oid.asPath()) {
            events[i] = e.addEnd(item.t);
          }
        }
      }
    }

    return {'events': es.prepareToSend(events)};
  }

  static ServiceMethod createMethod() {
    return ServiceMethod(name, Events().call, description)
      ..optional('active', 'bool', 'default: false')
      ..optional('offset', 'u64', 'default: 0')
      ..optional('limit', 'u64', 'default: 10');
  }
}
