import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/event.dart';
import '../widget/Button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController eventController = TextEditingController();
  DateTime? _selectedDay;
  DateTime today = DateTime.now();
  Map<DateTime, List<Event>> events = {};
  late final ValueNotifier<List<Event>> _selectedEvents;
  late Box<Event> eventsBox;

  @override
  void initState() {
    super.initState();
    _selectedDay = today;
    _selectedEvents = ValueNotifier(_getEventForDay(_selectedDay!));
    eventsBox = Hive.box<Event>('eventsBox');
    fetchEvents();
  }

  @override
  void dispose() {
    eventController.dispose();
    _selectedEvents.dispose();
    super.dispose();
  }

  Future<void> fetchEvents() async {
    events.clear();
    print("Fetching events. Total events in box: ${eventsBox.length}");

    for (var event in eventsBox.values) {
      try {
        // Parse the date from the key
        DateTime eventDate = DateTime.parse(event.key);
        final eventDateOnly =
            DateTime(eventDate.year, eventDate.month, eventDate.day);

        // Add event to the map
        if (events.containsKey(eventDateOnly)) {
          events[eventDateOnly]!.add(event);
        } else {
          events[eventDateOnly] = [event];
        }
        print("Added event: ${event.title} for date: ${eventDateOnly}");
      } catch (e) {
        print("Error parsing date from event key: ${event.key}. Error: $e");
      }
    }

    // Update selected events
    if (_selectedDay != null) {
      _selectedEvents.value = _getEventForDay(_selectedDay!);
      print(
          "Selected events for ${_selectedDay}: ${_selectedEvents.value.length}");
    }
    setState(() {}); // Refresh UI
  }

  Future<void> addEventToHive(String title, DateTime eventDate) async {
    try {
      final dateKey = eventDate.toIso8601String();
      print("Adding event '$title' with key: $dateKey");

      // Create event with key
      Event newEvent = Event(title, key: dateKey);

      // Add to Hive box
      await eventsBox.put(dateKey, newEvent);
      print("Event added to Hive box. Current count: ${eventsBox.length}");

      await fetchEvents();
    } catch (e) {
      print("Error adding event to Hive: $e");
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _selectedEvents.value = _getEventForDay(_selectedDay!);
      print(
          "Day selected: $selectedDay. Events: ${_selectedEvents.value.length}");
    });
  }

  List<Event> _getEventForDay(DateTime day) {
    final dayKey = DateTime(day.year, day.month, day.day);
    return events[dayKey] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                scrollable: true,
                title: Text("Event Name"),
                content: Padding(
                  padding: EdgeInsets.all(8),
                  child: TextField(controller: eventController),
                ),
                actions: [
                  CustomButton(
                    text: "Submit",
                    onPressed: () async {
                      if (_selectedDay != null &&
                          eventController.text.isNotEmpty) {
                        print("Submitting event: ${eventController.text}");
                        await addEventToHive(
                            eventController.text, _selectedDay!);
                        Navigator.of(context).pop();
                        eventController.clear();
                      } else {
                        print(
                            "Cannot add event: selected day is null or text is empty");
                      }
                    },
                    height: 35,
                    width: 100,
                  ),
                ],
              );
            },
          );
        },
        backgroundColor: Colors.red,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(50)),
        ),
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.1),
                  Text(
                    "Welcome!",
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    "Vincent",
                    style: TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  TableCalendar(
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                    selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                    availableGestures: AvailableGestures.all,
                    focusedDay: today,
                    firstDay: DateTime(2000),
                    lastDay: DateTime(2100),
                    onDaySelected: _onDaySelected,
                    eventLoader: _getEventForDay,
                  ),
                ],
              ),
            ),
          ),
          ValueListenableBuilder<List<Event>>(
            valueListenable: _selectedEvents,
            builder: (context, selectedEvents, _) {
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final event = selectedEvents[index];
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: ListTile(
                        onTap: () => print("Tapped on event: ${event.title}"),
                        title: Text(event.title),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                onPressed: () {
                                  eventController.text = event.title;
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        scrollable: true,
                                        title: Text("Edit Event"),
                                        content: Padding(
                                          padding: EdgeInsets.all(8),
                                          child: TextField(
                                              controller: eventController),
                                        ),
                                        actions: [
                                          Row(
                                            children: [
                                              CustomButton(
                                                text: "Cancel",
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  eventController.clear();
                                                },
                                                height: 35,
                                                width: 100,
                                              ),
                                              Spacer(),
                                              CustomButton(
                                                text: "Update",
                                                onPressed: () async {
                                                  if (_selectedDay != null &&
                                                      eventController
                                                          .text.isNotEmpty) {
                                                    await eventsBox.put(
                                                        event.key,
                                                        Event(
                                                            eventController
                                                                .text,
                                                            key: event.key));
                                                    Navigator.of(context).pop();
                                                    eventController.clear();
                                                    fetchEvents();
                                                  }
                                                },
                                                height: 35,
                                                width: 100,
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                icon: const Icon(Icons.edit, color: Colors.red)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await eventsBox.delete(event.key);
                                fetchEvents();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: selectedEvents.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
