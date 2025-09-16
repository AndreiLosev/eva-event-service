import 'package:eva_event_service/db/data_base_client.dart';
import 'package:eva_sdk/eva_sdk.dart';

class EventAcknowledge {
  static const name = "event.acknowledge";
  static const description = "event acknowledge";

  Future<Map<String, dynamic>?> call(Map<String, dynamic> params) async {
    final ids = params['ids'] as List;
    await DataBaseClient.getInstane().acknowledge(ids.cast());
    return null;
  }

  static ServiceMethod createMethod() {
    return ServiceMethod(name, EventAcknowledge().call, description)
      ..required('ids', 'Vek<int>', "even ids list");
  }
}
