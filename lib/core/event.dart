import 'package:hive/hive.dart';

part 'event.g.dart';

@HiveType(typeId: 0)
class Event extends HiveObject {
  @HiveField(0)
  String title;

  @override
  @HiveField(1)
  String key;

  @HiveField(2)
  int? notificationId;

  Event(this.title, {this.key = "", this.notificationId});
}