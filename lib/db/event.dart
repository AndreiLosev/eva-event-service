class Event {
  final int id;
  final String item;
  final DateTime eventStart;
  final DateTime? eventEnd;
  final int eventAction;
  final String? name;

  Event(
    this.id,
    this.item,
    this.eventStart,
    this.eventEnd,
    this.eventAction,
    this.name,
  );

  Event.fromMap(Map map)
    : id = map['id'],
      item = map['item'],
      eventStart = map['event_start'],
      eventEnd = map['event_end'],
      eventAction = map['event_action'],
      name = map['name'];

  Event addName(String name) {
    return Event(id, item, eventStart, eventEnd, eventAction, name);
  }

  Event addEnd(DateTime end) {
    return Event(id, item, eventStart, end, eventAction, name);
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'iten': item,
    'event_start': eventStart.toIso8601String(),
    'event_end': eventEnd?.toIso8601String(),
    'event_action': eventAction,
    'name': name,
  };
}
