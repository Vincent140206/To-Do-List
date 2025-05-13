import 'dart:math';

import 'package:calendar_app/core/notificationServices.dart';
import 'package:hive/hive.dart';
import 'event.dart';

class EventRepository {
  late Box<Event> eventsBox;
  final NotificationServices _notificationService = NotificationServices();

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
    final notificationId = Random().nextInt(2147483647);
    final dateKey = eventDateTime.toIso8601String();
    Event newEvent = Event(title, key: dateKey, notificationId: notificationId);
    await eventsBox.put(dateKey, newEvent);
    await scheduleEventNotification(newEvent, eventDateTime);
  }

  Future<void> updateEvent(String oldKey, String title, DateTime newDateTime) async {
    final event = eventsBox.get(oldKey);

    if (event != null) {
      if (event.notificationId != null) {
        await _notificationService.cancelNotification(event.notificationId!);
      }
      await eventsBox.delete(oldKey);
      final dateKey = newDateTime.toIso8601String();
      final notificationId = Random().nextInt(2147483647);
      Event updatedEvent = Event(title, key: dateKey, notificationId: notificationId);
      await eventsBox.put(dateKey, updatedEvent);
      await scheduleEventNotification(updatedEvent, newDateTime);
    }
  }

  Future<void> deleteEvent(String key) async {
    final event = eventsBox.get(key);
    if (event != null && event.notificationId != null) {
      await _notificationService.cancelNotification(event.notificationId!);
    }

    await eventsBox.delete(key);
  }

  Future<void> scheduleEventNotification(Event event, DateTime eventDateTime) async {
    if (event.notificationId != null) {
      await _notificationService.scheduleNotification(
        id: event.notificationId!,
        title: 'Event Reminder',
        body: event.title,
        scheduledTime: eventDateTime,
        payload: event.key,
      );

      print('Scheduled notification for event: ${event.title} at $eventDateTime');
    }
  }
}