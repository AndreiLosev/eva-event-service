import 'package:eva_event_service/db/data_base_client.dart';
import 'package:eva_event_service/event_service.dart';
import 'package:eva_sdk/eva_sdk.dart';

class Events {
  static const name = "events";
  static const description = "get events by date or limit";

  Future<Map<String, dynamic>?> call(Map<String, dynamic> params) async {
    final offset = params['offset'];
    final limit = params['limit'];
    final events = await DataBaseClient.getInstane().eventList(offset, limit);
    final es = EventService.getInstane();
    for (var item in events) {
      item['name'] = es.events[item['item']]?.name;
      item['event_start'] = (item['event_start'] as DateTime).toIso8601String();
      item['event_end'] = (item['event_end'] as DateTime?)?.toIso8601String();
    }

    return {'events': events};
  }

  static ServiceMethod createMethod() {
    return ServiceMethod(name, Events().call, description)
      ..optional('offset', 'u64', 'default: 0')
      ..optional('limit', 'u64', 'default: 10');
  }
}
