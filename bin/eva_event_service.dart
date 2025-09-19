import 'dart:io';
import 'package:eva_event_service/config/config.dart';
import 'package:eva_event_service/db/data_base_client.dart';
import 'package:eva_event_service/eapi/event_acknowledge.dart';
import 'package:eva_event_service/eapi/events.dart';
import 'package:eva_event_service/event_service.dart';
import 'package:eva_sdk/eva_sdk.dart';
import 'package:eva_sdk/src/debug_log.dart';

const author = "Losev Andrei";
const version = "0.1.0";
const description = "Events service";

int exitCode = 1;

void main(List<String> arguments) async {
  final svcStart = DateTime.now();
  try {
    final info = ServiceInfo(author, version, description)
      ..addMethod(Events.createMethod())
      ..addMethod(EventAcknowledge.createMethod());

    if (arguments.contains('--local')) {
      await svc().debugLoad(
        '/home/andrei/documents/my/eva-event-service/examle-config.yaml',
        'softkip.events.alarms',
      );
      dbgInit('console');
    } else {
      await svc().load();
    }
    await svc().init(info);

    final config = Config.fromMap(svc().config.config);
    final dbc = DataBaseClient.getInstane(config.db);
    await dbc.connect();
    await dbc.makeTable();
    final es = EventService.getInstane(
      config.events,
      config.updateLvar,
      svcStart,
    );
    await es.subscribe();
    await svc().block();
    exitCode = 0;
  } catch (e, s) {
    print({"err": e, "trace": s});
  } finally {
    await DataBaseClient.getInstane().disconnect();
    exit(exitCode);
  }
}
