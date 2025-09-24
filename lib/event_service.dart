import 'dart:async';

import 'package:eva_event_service/config/event_item.dart';
import 'package:eva_event_service/db/data_base_client.dart';
import 'package:eva_event_service/db/event.dart';
import 'package:eva_sdk/eva_sdk.dart';

class EventService {
  static EventService? _instanse;

  final Map<String, EventItem> events;
  final Oid lvar;
  final int currentEventLimit;
  final int removeEventsAfterDays;
  late final DataBaseClient db;
  Timer? removeTimer;

  EventService._(
    this.events,
    this.lvar,
    this.currentEventLimit,
    this.removeEventsAfterDays,
  ) {
    removeOldEvents();
    removeTimer = Timer.periodic(const Duration(days: 1), removeOldEvents);
    db = DataBaseClient.getInstane();
  }

  factory EventService.getInstane([
    Map<String, EventItem>? events,
    Oid? oid,
    int? currentEventLimit,
    int? removeEventsAfterDays,
  ]) {
    if (_instanse == null &&
        (events == null ||
            oid == null ||
            currentEventLimit == null ||
            removeEventsAfterDays == null)) {
      throw Exception(
        "EventService need initialization: events: ${events?.keys} , oid: ${oid?.asString()}, currentEventLimit: $currentEventLimit, removeEventsAfterDays: $removeEventsAfterDays",
      );
    }

    _instanse ??= EventService._(
      events!,
      oid!,
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

  Future<void> init() async {
    final startTime = DateTime.now();
    final items = await svc().getItemsState(events.keys.map((e) => Oid(e)));

    for (var item in items) {
      await _handlerEvent(item);
    }

    final inactiveItems = <String>[];
    final activeItems = <String>[];

    for (var i in items) {
      if (i.value == 1 || i.value == true) {
        activeItems.add(i.oid.asString());
      } else {
        inactiveItems.add(i.oid.asString());
      }
    }

    await db.unfinishedEvent(startTime, inactiveItems);
    for (var i in activeItems) {
      await db.unfinishedEventForActive(i);
    }

    await publishEvents();
  }

  Future<int?> _handlerEvent(ItemState payload) async {
    if (payload.value == true || payload.value == 1) {
      return await db.startEvent(payload.oid.asString(), payload.t);
    } else {
      return await db.endEvent(payload.oid.asString(), payload.t);
    }
  }

  Future<void> publishEvents() async {
    final anHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    var dbEvents = await db.eventList(
      0,
      currentEventLimit,
      "WHERE (event_end is NULL AND event_action != 100) OR event_end > '${anHourAgo.toUtc()}' OR (event_action = 100 AND event_start > '${anHourAgo.toUtc()}')",
    );

    if (events.isEmpty) {
      return;
    }

    await svc().rpc.bus.publish(
      EapiTopic.rawStateTopic.resolve(lvar.asPath()),
      serialize({'status': 1, 'value': prepareToSend(dbEvents), 't': evaNow()}),
    );
  }

  Future<void> _handler(ItemState payload, String _, String _) async {
    final id = await _handlerEvent(payload);

    if (id == null) {
      return;
    }

    await publishEvents();
  }

  void removeOldEvents([_]) {
    final start = DateTime.now().subtract(
      Duration(days: removeEventsAfterDays),
    );
    DataBaseClient.getInstane().removeByStart(start);
  }
}
