import 'package:eva_event_service/db/data_base_client.dart';
import 'package:eva_sdk/eva_sdk.dart';

class EventSet {
  static const name = "event.set";
  static const description = "set event, return event id";

  Future<Map<String, dynamic>?> call(Map<String, dynamic> params) async {
    final oid = params['oid'] as String;
    final eventStart = (params['event_start'] as num).toDouble().toDateTime();
    final eventEnd = (params['event_end'] as num?)?.toDouble().toDateTime();
    final eventAction =
        (params['event_action'] as int?) ?? (eventEnd == null ? 0 : 1);

    final id = await DataBaseClient.getInstane().setEvent(
      oid,
      eventStart,
      eventEnd,
      eventAction,
    );

    return {'id': id};
  }

  static ServiceMethod createMethod() {
    return ServiceMethod(name, EventSet().call, description)
      ..required('oid', 'String')
      ..required('event_start', 'timestamp', 'default: now()')
      ..optional('event_end', 'timestamp')
      ..optional(
        'event_action',
        'int',
        'default: if event_end != null then 1 else 0',
      );
  }
}
