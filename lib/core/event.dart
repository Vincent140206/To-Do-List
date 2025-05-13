import 'package:hive/hive.dart';

part 'event.g.dart';

@HiveType(typeId: 0)
class Event extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String eventKey;

  Event(this.title, {this.eventKey = ""});
  String getFormattedTime() {
    DateTime dateTime = DateTime.parse(key);
    return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }
}
