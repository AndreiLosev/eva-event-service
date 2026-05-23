import 'package:eva_event_service/db/data_base_client.dart';
import 'package:eva_event_service/event_service.dart';
import 'package:eva_sdk/eva_sdk.dart';

class Events {
  static const name = "events";
  static const description = "get events by date or limit";

  static const operators = ['=', '!=', '>', '>=', '<', '<='];
  static const whereKeys = ['event_start', 'event_end'];

  Future<Map<String, dynamic>?> call(Map<String, dynamic> params) async {
    final offset = params['offset'];
    final limit = params['limit'];
    final es = EventService.getInstane();
    final db = DataBaseClient.getInstane();
    final where = _parse(params);
    final events = await db.eventList(offset, limit, where);
    final count = await db.getCount(where);

    return {'events': es.prepareToSend(events), 'count': count};
  }

  static ServiceMethod createMethod() {
    return ServiceMethod(name, Events().call, description)
      ..optional('offset', 'u64', 'default: 0')
      ..optional('limit', 'u64', 'default: 10')
      ..optional('event_start:operator', 'timestamp')
      ..optional('event_end:operator', 'timestamp');
  }

  String? _parse(Map<String, dynamic> params) {
    final res = [];
    final keys = params.keys.where(
      (key) => key.startsWith('event_start:') || key.startsWith('event_end:'),
    );
    if (keys.isEmpty) return null;
    for (final key in keys) {
      final [nKey, operator1] = key.split(':');
      if (!whereKeys.contains(nKey) || !operators.contains(operator1)) {
        continue;
      }

      res.add('$nKey $operator1 ${params[key]}');
    }

    if (res.isEmpty) return null;

    return "{WHERE ${_parse(params)}";
  }
}
