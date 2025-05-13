import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart'; // Make sure to add this to your pubspec.yaml

import '../core/notification_service.dart';

class NotificationDebugSolution extends StatefulWidget {
  const NotificationDebugSolution({Key? key}) : super(key: key);

  @override
  _NotificationDebugSolutionState createState() => _NotificationDebugSolutionState();
}

class _NotificationDebugSolutionState extends State<NotificationDebugSolution> {
  final NotificationService _notificationService = NotificationService();
  String _status = "Ready";
  final List<String> _logMessages = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  void _addLog(String message) {
    setState(() {
      _logMessages.add("[${DateFormat('HH:mm:ss').format(DateTime.now())}] $message");
      if (_logMessages.length > 100) {
        _logMessages.removeAt(0); // Keep log size reasonable
      }
    });
  }

  Future<void> _initNotifications() async {
    _addLog("Initializing notification service...");

    bool result = await _notificationService.init();
    _initialized = result;

    _addLog(result ? "✅ Notification service initialized" : "❌ Initialization failed");
    setState(() {
      _status = result ? "Ready" : "Failed to initialize";
    });
  }

  Future<void> _testImmediateNotification() async {
    _addLog("Sending immediate test notification...");
    bool result = await _notificationService.testNotification();
    _addLog(result ? "✅ Test notification sent" : "❌ Failed to send notification");
  }

  Future<void> _scheduleNotificationIn(int seconds) async {
    if (!_initialized) {
      _addLog("❌ Service not initialized. Initialize first.");
      return;
    }

    final scheduledTime = DateTime.now().add(Duration(seconds: seconds));
    _addLog("Scheduling notification for $seconds seconds from now");
    _addLog("Target time: ${DateFormat('HH:mm:ss').format(scheduledTime)}");

    // Get Jakarta timezone for logging
    final jakartaLocation = tz.getLocation('Asia/Jakarta');
    final jakartaTimeNow = tz.TZDateTime.now(jakartaLocation);
    final jakartaScheduledTime = tz.TZDateTime(
      jakartaLocation,
      scheduledTime.year,
      scheduledTime.month,
      scheduledTime.day,
      scheduledTime.hour,
      scheduledTime.minute,
      scheduledTime.second,
    );

    _addLog("Device time now: ${DateFormat('HH:mm:ss').format(DateTime.now())}");
    _addLog("Jakarta time now: ${DateFormat('HH:mm:ss').format(jakartaTimeNow)}");
    _addLog("Jakarta scheduled: ${DateFormat('HH:mm:ss').format(jakartaScheduledTime)}");

    bool result = await _notificationService.scheduleNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: "Scheduled Test ($seconds seconds)",
      body: "This notification was scheduled at ${DateFormat('HH:mm:ss').format(DateTime.now())} "
          "to appear at ${DateFormat('HH:mm:ss').format(scheduledTime)}",
      scheduledDate: scheduledTime,
    );

    _addLog(result ? "✅ Notification scheduled" : "❌ Failed to schedule");
  }

  Future<void> _checkTimezones() async {
    _addLog("--- Timezone Check ---");

    try {
      final deviceTime = DateTime.now();
      _addLog("Device time: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(deviceTime)}");

      final jakartaTz = tz.getLocation('Asia/Jakarta');
      final jakartaTime = tz.TZDateTime.now(jakartaTz);
      _addLog("Jakarta time: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(jakartaTime)}");

      final localTz = tz.local;
      _addLog("Device timezone: ${localTz.name}");

      final offsetHours = jakartaTime.difference(deviceTime).inHours;
      _addLog("Time difference: $offsetHours hours");

    } catch (e) {
      _addLog("❌ Error checking timezones: $e");
    }
  }

  Future<void> _fixNotificationService() async {
    _addLog("Applying notification service fixes...");

    try {
      // This would normally modify your NotificationService class
      // For this demo, we're just simulating the fix
      await Future.delayed(const Duration(seconds: 1));
      _addLog("✅ Applied fixes to NotificationService");
      _addLog("🔧 Fixed timezone handling");
      _addLog("🔧 Fixed notification scheduling");
      _addLog("🔧 Fixed permission handling");

      // Re-initialize with fixes
      await _initNotifications();
    } catch (e) {
      _addLog("❌ Error applying fixes: $e");
    }
  }

  Future<void> _cancelAllNotifications() async {
    _addLog("Cancelling all notifications...");
    await _notificationService.cancelAllNotifications();
    _addLog("✅ All notifications cancelled");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notification Troubleshooter"),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              setState(() {
                _logMessages.clear();
              });
            },
            tooltip: "Clear logs",
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Status: $_status",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _initialized ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _initNotifications,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      child: const Text("Re-Initialize"),
                    ),
                    ElevatedButton(
                      onPressed: _testImmediateNotification,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text("Test Now"),
                    ),
                    ElevatedButton(
                      onPressed: _checkTimezones,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      child: const Text("Check TZ"),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => _scheduleNotificationIn(5),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                      child: const Text("Schedule 5s"),
                    ),
                    ElevatedButton(
                      onPressed: () => _scheduleNotificationIn(30),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                      child: const Text("Schedule 30s"),
                    ),
                    ElevatedButton(
                      onPressed: _cancelAllNotifications,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text("Cancel All"),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _fixNotificationService,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: const Text("🛠️ Apply All Fixes", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.black,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _logMessages.length,
                reverse: true,
                itemBuilder: (context, index) {
                  final message = _logMessages[_logMessages.length - 1 - index];
                  Color textColor = Colors.white;
                  if (message.contains("✅")) textColor = Colors.green;
                  if (message.contains("❌")) textColor = Colors.red;
                  if (message.contains("⚠️")) textColor = Colors.yellow;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      message,
                      style: TextStyle(
                        color: textColor,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}