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

    for (var key in eventsBox.keys) {
      try {
        DateTime eventDate = DateTime.parse(key);
        final eventDateOnly = DateTime(eventDate.year, eventDate.month, eventDate.day);

        if (events.containsKey(eventDateOnly)) {
          events[eventDateOnly]!.add(eventsBox.get(key)!);
        } else {
          events[eventDateOnly] = [eventsBox.get(key)!];
        }
        print("Added event: ${eventsBox.get(key)!.title} for date: $eventDateOnly");
      } catch (e) {
        print("Error parsing date from event key: $key. Error: $e");
      }
    }

    if (_selectedDay != null) {
      _selectedEvents.value = _getEventForDay(_selectedDay!);
      print("Selected events for $_selectedDay: ${_selectedEvents.value.length}");
    }
    setState(() {});
  }

  Future<void> addEventToHive(String title, DateTime eventDateTime) async {
    try {
      final dateKey = eventDateTime.toIso8601String();
      print("Adding event '$title' with key: $dateKey");

      Event newEvent = Event(title, key: dateKey);

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
      print("Day selected: $selectedDay. Events: ${_selectedEvents.value.length}");
    });
  }

  void _showYearPicker(BuildContext context) {
    int endYear = DateTime(2100).year;
    int startYear = endYear - 99;
    List<int> yearList = List.generate(100, (index) => startYear + index);
    DateTime lastDay = DateTime(endYear, 12, 31);
    final scrollToYear = _selectedDay?.year ?? DateTime.now().year;
    final scrollToIndex = yearList.indexOf(scrollToYear);
    const crossAxisCount = 3;
    const itemHeight = 90.0;
    final row = scrollToIndex ~/ crossAxisCount;
    final initialScrollOffset = row * itemHeight;
    ScrollController scrollController =
    ScrollController(initialScrollOffset: initialScrollOffset);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Select Year'),
          content: SizedBox(
            height: 300,
            width: 300,
            child: GridView.builder(
              controller: scrollController,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 1,
              ),
              itemCount: yearList.length,
              itemBuilder: (BuildContext context, int index) {
                int year = yearList[index];
                return GestureDetector(
                  onTap: () {
                    DateTime selectedDate = DateTime(year, DateTime.now().month, DateTime.now().day);
                    if (selectedDate.isBefore(lastDay) || selectedDate.isAtSameMomentAs(lastDay)) {
                      setState(() {
                        _selectedDay = selectedDate;
                        today = selectedDate;
                        _selectedEvents.value = _getEventForDay(_selectedDay!);
                      });
                    }
                    Navigator.of(context).pop();
                  },
                  child: Card(
                    shadowColor: Colors.black,
                    color: Colors.white,
                    child: Center(child: Text(year.toString())),
                  ),
                );
              },
            ),
          ),
          actions: [
            CustomButton(
              text: "Cancel",
              onPressed: () => Navigator.of(context).pop(),
              height: 35,
              width: 100,
            ),
          ],
        );
      },
    );
  }

  List<Event> _getEventForDay(DateTime day) {
    final dayKey = DateTime(day.year, day.month, day.day);
    return events[dayKey] ?? [];
  }

  Future<void> _showAddEventDialog() async {
    eventController.clear();
    DateTime initialDateTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      12, 0,
    );
    DateTime selectedTime = initialDateTime;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.white,
            scrollable: true,
            title: const Text("Add Event"),
            content: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: eventController,
                    decoration: const InputDecoration(labelText: 'Event title'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Selected time: ${TimeOfDay.fromDateTime(selectedTime).format(context)}'),
                      ),
                      TextButton(
                        onPressed: () async {
                          TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(selectedTime),
                          );
                          if (picked != null) {
                            setStateDialog(() {
                              selectedTime = DateTime(
                                selectedTime.year,
                                selectedTime.month,
                                selectedTime.day,
                                picked.hour,
                                picked.minute,
                              );
                            });
                          }
                        },
                        child: const Text('Choose Time'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              Row(
                children: [
                  CustomButton(
                    text: "Cancel",
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    height: 35,
                    width: 100,
                  ),
                  const Spacer(),
                  CustomButton(
                    text: "Submit",
                    onPressed: () async {
                      if (_selectedDay != null && eventController.text.isNotEmpty) {
                        await addEventToHive(eventController.text, selectedTime);
                        Navigator.of(context).pop();
                      }
                    },
                    height: 35,
                    width: 100,
                  ),
                ],
              )
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(),
        backgroundColor: Colors.red,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(50)),
        ),
        child: const Icon(Icons.add, color: Colors.white),
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
                  const Text(
                    "Welcome!",
                    style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                  const Text(
                    "Vincent",
                    style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  TableCalendar(
                    headerStyle: const HeaderStyle(
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
                    onHeaderTapped: (focusedDay) => _showYearPicker(context),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (events.isNotEmpty) {
                          Color dotColor = Colors.red;
                          return Positioned(
                            bottom: 10,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    calendarStyle: CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: Colors.red.shade700,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.redAccent.shade100,
                        shape: BoxShape.circle,
                      ),
                      defaultDecoration: const BoxDecoration(shape: BoxShape.circle),
                      weekendDecoration: const BoxDecoration(shape: BoxShape.circle),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Events",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 1),
                  if (_selectedEvents.value.isEmpty)
                    const Text("No events for this day", style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            ),
          ),
          ValueListenableBuilder<List<Event>>(
            valueListenable: _selectedEvents,
            builder: (context, selectedEvents, _) {
              selectedEvents.sort((a, b) {
                DateTime aTime = DateTime.parse(a.key);
                DateTime bTime = DateTime.parse(b.key);
                return aTime.compareTo(bTime);
              });
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final event = selectedEvents[index];
                    DateTime eventDateTime = DateTime.parse(event.key);
                    String eventTimeString =
                        "${eventDateTime.hour.toString().padLeft(2, '0')}:${eventDateTime.minute.toString().padLeft(2, '0')}";
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      child: ListTile(
                        onTap: () => print("Tapped on event: ${event.title}"),
                        title: Text(event.title),
                        subtitle: Text("Time: $eventTimeString"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                onPressed: () {
                                  eventController.text = event.title;
                                  DateTime eventDateTime = DateTime.parse(event.key);
                                  TimeOfDay editingTime = TimeOfDay(hour: eventDateTime.hour, minute: eventDateTime.minute);
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      TimeOfDay? selectedEditTime = editingTime;
                                      return StatefulBuilder(builder: (context, setStateDialog) {
                                        return AlertDialog(
                                          backgroundColor: Colors.white,
                                          scrollable: true,
                                          title: const Text("Edit Event"),
                                          content: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextField(controller: eventController),
                                                const SizedBox(height: 20),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(selectedEditTime != null
                                                          ? 'Selected time: ${selectedEditTime?.format(context)}'
                                                          : 'No time selected'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        TimeOfDay? picked = await showTimePicker(
                                                          context: context,
                                                          initialTime: selectedEditTime ?? TimeOfDay.now(),
                                                        );
                                                        if (picked != null) {
                                                          setStateDialog(() {
                                                            selectedEditTime = picked;
                                                          });
                                                        }
                                                      },
                                                      child: const Text('Choose Time'),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
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
                                                const Spacer(),
                                                CustomButton(
                                                  text: "Update",
                                                  onPressed: () async {
                                                    if (_selectedDay != null &&
                                                        eventController.text.isNotEmpty &&
                                                        selectedEditTime != null) {
                                                      DateTime newDateTime = DateTime(
                                                        _selectedDay!.year,
                                                        _selectedDay!.month,
                                                        _selectedDay!.day,
                                                        selectedEditTime!.hour,
                                                        selectedEditTime!.minute,
                                                      );
                                                      await eventsBox.delete(event.key);
                                                      final newKey = newDateTime.toIso8601String();
                                                      await eventsBox.put(
                                                          newKey,
                                                          Event(eventController.text, key: newKey));
                                                      Navigator.of(context).pop();
                                                      eventController.clear();
                                                      await fetchEvents();
                                                    }
                                                  },
                                                  height: 35,
                                                  width: 100,
                                                ),
                                              ],
                                            ),
                                          ],
                                        );
                                      });
                                    },
                                  );
                                },
                                icon: const Icon(Icons.edit, color: Colors.red)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await eventsBox.delete(event.key);
                                await fetchEvents();
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
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}