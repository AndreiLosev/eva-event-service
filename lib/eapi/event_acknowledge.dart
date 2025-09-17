import 'package:eva_event_service/db/data_base_client.dart';
import 'package:eva_event_service/event_service.dart';
import 'package:eva_sdk/eva_sdk.dart';

class EventAcknowledge {
  static const name = "event.acknowledge";
  static const description = "event acknowledge";

  Future<Map<String, dynamic>?> call(Map<String, dynamic> params) async {
    final ids = params['ids'] as List;
    final db = DataBaseClient.getInstane();
    final es = EventService.getInstane();

    await db.acknowledge(ids.cast());
    final events = await db.eventsById(ids.cast());
    for (var e in events) {
      await svc().rpc.bus.publish(
        EapiTopic.rawStateTopic.resolve(es.lvar.asPath()),
        serialize({
          'status': 1,
          'value': e.addName(es.getName(e.item)).toMap(),
          't': evaNow(),
        }),
      );
    }
    return null;
  }

  static ServiceMethod createMethod() {
    return ServiceMethod(name, EventAcknowledge().call, description)
      ..required('ids', 'Vek<int>', "even ids list");
  }
}
