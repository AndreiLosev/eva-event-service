import 'package:eva_event_service/eapi/event_acknowledge.dart';
import 'package:eva_event_service/eapi/events.dart';
import 'package:eva_sdk/eva_sdk.dart';

class X {
  static const name = "x";
  static const description = "execute method events or event.acknowledge";

  Future<Map<String, dynamic>?> call(Map<String, dynamic> params) async {
    final method = params['method'];
    final params1 = params['params'] as Map;

    return switch (method) {
      'events' => Events().call(params1.cast()),
      'event.acknowledge' => EventAcknowledge().call(params1.cast()),
      _ => throw EvaError(
        EvaErrorKind.methodNotFound,
        'undefined method: $method',
      ),
    };
  }

  static ServiceMethod createMethod() {
    return ServiceMethod(name, X().call, description)
      ..required('method', 'string', "events or event.acknowledge")
      ..required('params', 'dict', 'see method events or event.acknowledge');
  }
}
