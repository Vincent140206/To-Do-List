import 'package:hive/hive.dart';
import 'event.dart';

class EventRepository {
  late Box<Event> eventsBox;

  EventRepository() {
    eventsBox = Hive.box<Event>('eventsBox');
  }

  Future<void> fetchEvents(Map<DateTime, List<Event>> events) async {
    events.clear();
    for (var key in eventsBox.keys) {
      try {
        DateTime eventDate = DateTime.parse(key);
        final eventDateOnly = DateTime(eventDate.year, eventDate.month, eventDate.day);

        if (events.containsKey(eventDateOnly)) {
          events[eventDateOnly]!.add(eventsBox.get(key)!);
        } else {
          events[eventDateOnly] = [eventsBox.get(key)!];
        }
      } catch (e) {
        print("Error parsing date from event key: $key. Error: $e");
      }
    }
  }

  Future<void> addEvent(String title, DateTime eventDateTime) async {
    final dateKey = eventDateTime.toIso8601String();
    Event newEvent = Event(title, eventKey: dateKey);
    await eventsBox.put(dateKey, newEvent);
  }

  Future<void> deleteEvent(String key) async {
    await eventsBox.delete(key);
  }
}