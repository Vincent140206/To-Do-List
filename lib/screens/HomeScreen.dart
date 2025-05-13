import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../core/event.dart';
import '../core/eventRepo.dart';
import '../widget/Button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController eventController = TextEditingController();
  DateTime? _selectedDay;
  DateTime today = DateTime.now();
  Map<DateTime, List<Event>> events = {};
  late final ValueNotifier<List<Event>> _selectedEvents;
  final EventRepository eventRepository = EventRepository();

  @override
  void initState() {
    super.initState();
    _selectedDay = today;
    _selectedEvents = ValueNotifier([]);
    fetchEvents();
  }

  @override
  void dispose() {
    eventController.dispose();
    _selectedEvents.dispose();
    super.dispose();
  }

  Future<void> fetchEvents() async {
    await eventRepository.fetchEvents(events);
    _selectedEvents.value = _getEventForDay(_selectedDay!);
    setState(() {});
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _selectedEvents.value = _getEventForDay(_selectedDay!);
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
    ScrollController scrollController = ScrollController(initialScrollOffset: initialScrollOffset);

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
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
      ),
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
                    onPressed: () => Navigator.of(context).pop(),
                    height: 35,
                    width: 100,
                  ),
                  const Spacer(),
                  CustomButton(
                    text: "Submit",
                    onPressed: () async {
                      if (_selectedDay != null && eventController.text.isNotEmpty) {
                        await eventRepository.addEvent(eventController.text, selectedTime);
                        Navigator.of(context).pop();
                        await fetchEvents();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Event created with notification at ${TimeOfDay.fromDateTime(selectedTime).format(context)}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
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

  Future<void> _showEditEventDialog(Event event) async {
    eventController.text = event.title;
    DateTime eventDateTime = DateTime.parse(event.key);
    TimeOfDay selectedEditTime = TimeOfDay(hour: eventDateTime.hour, minute: eventDateTime.minute);

    await showDialog(
      context: context,
      builder: (context) {
        TimeOfDay? localSelectedTime = selectedEditTime;
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
                        child: Text(localSelectedTime != null ? 'Selected time: ${localSelectedTime?.format(context)}' : 'No time selected'),
                      ),
                      TextButton(
                        onPressed: () async {
                          TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: localSelectedTime ?? TimeOfDay.now(),
                          );
                          if (picked != null) {
                            setStateDialog(() {
                              localSelectedTime = picked;
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
                      eventController.clear();
                      Navigator.of(context).pop();
                    },
                    height: 35,
                    width: 100,
                  ),
                  const Spacer(),
                  CustomButton(
                    text: "Update",
                    onPressed: () async {
                      if (_selectedDay != null && eventController.text.isNotEmpty && localSelectedTime != null) {
                        DateTime newDateTime = DateTime(
                          _selectedDay!.year,
                          _selectedDay!.month,
                          _selectedDay!.day,
                          localSelectedTime!.hour,
                          localSelectedTime!.minute,
                        );
                        await eventRepository.updateEvent(
                            event.key,
                            eventController.text,
                            newDateTime
                        );
                        Navigator.of(context).pop();
                        eventController.clear();
                        await fetchEvents();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Event updated with notification at ${localSelectedTime?.format(context)}'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
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
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
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
                                _showEditEventDialog(event);
                              },
                              icon: const Icon(Icons.edit, color: Colors.red),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await eventRepository.deleteEvent(event.key);
                                await fetchEvents();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Event and notification deleted'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
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