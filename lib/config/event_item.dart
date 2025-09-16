class EventItem {
  final String name;

  EventItem(this.name);

  factory EventItem.fromMap(Map map) {
    return EventItem(map['name']);
  }

  Map<String, dynamic> toMap() => {'name': name};
}
