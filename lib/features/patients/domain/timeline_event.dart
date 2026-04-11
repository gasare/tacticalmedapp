import 'package:hive/hive.dart';

part 'timeline_event.g.dart';

@HiveType(typeId: 4)
class TimelineEvent {
  @HiveField(0)
  final String action;

  @HiveField(1)
  final DateTime timestamp;

  TimelineEvent({
    required this.action,
    required this.timestamp,
  });
}
