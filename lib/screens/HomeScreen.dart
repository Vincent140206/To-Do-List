import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:to_do_list/widget/Button.dart';

import '../core/event.dart';

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

  @override
  void initState() {
    super.initState();
    _selectedDay = today;
    _selectedEvents = ValueNotifier(_getEventForDay(_selectedDay!));
  }

  @override
  void dispose() {
    eventController.dispose();
    super.dispose();
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
    final crossAxisCount = 3;
    final itemHeight = 90.0;
    final row = scrollToIndex ~/ crossAxisCount;
    final initialScrollOffset = row * itemHeight;
    ScrollController scrollController = ScrollController(initialScrollOffset: initialScrollOffset);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Select Year'),
          content: SizedBox(
            height: 300,
            width: 300,
            child: GridView.builder(
              controller: scrollController,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
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
                        _selectedDay = selectedDate; // Update the selected day
                        today = selectedDate; // Update the focused day to the selected year
                      });
                    }
                    Navigator.of(context).pop();
                  },
                  child: Card(
                    shadowColor: Colors.black,
                    color: Colors.white,
                    child: Center(
                      child: Text(year.toString()),
                    ),
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
    return events[day] ?? [];
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
                    onPressed: () {
                      if (_selectedDay != null && eventController.text.isNotEmpty) {
                        if (events.containsKey(_selectedDay)) {
                          events[_selectedDay]!.add(Event(eventController.text));
                        } else {
                          events[_selectedDay!] = [Event(eventController.text)];
                        }
                        Navigator.of(context).pop();
                        _selectedEvents.value = _getEventForDay(_selectedDay!);
                        eventController.clear();
                      }
                    },
                    height: 35,
                    width: 90,
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
                    onHeaderTapped: (focusedDay) => _showYearPicker(context),
                  ),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final event = _selectedEvents.value[index];
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                  ),
                  child: ListTile(
                    onTap: () => print(event.title),
                    title: Text(event.title),
                  ),
                );
              },
              childCount: _selectedEvents.value.length,
            ),
          ),
        ],
      ),
    );
  }
}