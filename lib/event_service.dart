import 'dart:async';

import 'package:eva_event_service/config/event_item.dart';
import 'package:eva_event_service/db/data_base_client.dart';
import 'package:eva_event_service/db/event.dart';
import 'package:eva_sdk/eva_sdk.dart';

class EventService {
  static EventService? _instanse;

  final Map<String, EventItem> events;
  final Oid lvar;
  final DateTime svcStart;
  final int currentEventLimit;
  final int removeEventsAfterDays;
  Timer? removeTimer;

  EventService._(
    this.events,
    this.lvar,
    this.svcStart,
    this.currentEventLimit,
    this.removeEventsAfterDays,
  ) {
    removeOldEvents();
    removeTimer = Timer.periodic(const Duration(days: 1), removeOldEvents);
  }

  factory EventService.getInstane([
    Map<String, EventItem>? events,
    Oid? oid,
    DateTime? svcStart,
    int? currentEventLimit,
    int? removeEventsAfterDays,
  ]) {
    if (_instanse == null &&
        (events == null ||
            oid == null ||
            svcStart == null ||
            currentEventLimit == null ||
            removeEventsAfterDays == null)) {
      throw Exception(
        "EventService need initialization: events: ${events?.keys} , oid: ${oid?.asString()}, svcStart: $svcStart",
      );
    }

    _instanse ??= EventService._(
      events!,
      oid!,
      svcStart!,
      currentEventLimit!,
      removeEventsAfterDays!,
    );

    return _instanse!;
  }

  void cansel() {
    removeTimer?.cancel();
  }

  Future<void> subscribe() async {
    final items = events.keys.map((k) => (Oid(k), _handler));
    await svc().subscribeOIDs(items, EventKind.local);
  }

  List<Map<String, dynamic>> prepareToSend(List<Event> events) {
    return events.map((e) => e.addName(getName(e.item)).toMap()).toList();
  }

  String getName(String oid) => events[oid]?.name ?? 'any event';

  Future<void> _handler(ItemState payload, String _, String _) async {
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

    final anHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    var events = await db.eventList(
      0,
      100,
      'WHERE event_end is NULL OR event_end > $anHourAgo',
    );

    if (events.isEmpty) {
      return;
    }

    await svc().rpc.bus.publish(
      EapiTopic.rawStateTopic.resolve(lvar.asPath()),
      serialize({'status': 1, 'value': prepareToSend(events), 't': evaNow()}),
    );
  }

  void removeOldEvents([_]) {
    final start = DateTime.now().subtract(
      Duration(days: removeEventsAfterDays),
    );
    DataBaseClient.getInstane().removeByStart(start);
  }
}
