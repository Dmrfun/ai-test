import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kScheduleKey = 'lifeos_schedule';

class ScheduleEvent {
  final String id;
  String title;
  String date;
  String time;
  int priority; // 1-3
  String? recurring; // null, 'daily', 'weekly'
  int? reminderMinutes;
  final DateTime createdAt;

  ScheduleEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    this.priority = 2,
    this.recurring,
    this.reminderMinutes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'date': date,
        'time': time,
        'priority': priority,
        'recurring': recurring,
        'reminderMinutes': reminderMinutes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ScheduleEvent.fromJson(Map<String, dynamic> j) => ScheduleEvent(
        id: j['id'] as String,
        title: j['title'] as String,
        date: j['date'] as String,
        time: j['time'] as String,
        priority: j['priority'] as int? ?? 2,
        recurring: j['recurring'] as String?,
        reminderMinutes: j['reminderMinutes'] as int?,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

class ScheduleModel extends ChangeNotifier {
  List<ScheduleEvent> events;

  ScheduleModel({List<ScheduleEvent>? events}) : events = events ?? [];

  List<ScheduleEvent> forDay(String dateStr) {
    final list = events.where((e) => e.date == dateStr).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    return list;
  }

  List<ScheduleEvent> forWeek(String startDateStr) {
    try {
      final start = DateTime.parse(startDateStr);
      final end = start.add(const Duration(days: 6));
      return events.where((e) {
        final d = DateTime.parse(e.date);
        return !d.isBefore(start) && !d.isAfter(end);
      }).toList()
        ..sort((a, b) {
          final dc = a.date.compareTo(b.date);
          return dc != 0 ? dc : a.time.compareTo(b.time);
        });
    } catch (_) {
      return [];
    }
  }

  List<ScheduleEvent> get todayEvents {
    final today =
        DateTime.now().toIso8601String().substring(0, 10);
    return forDay(today);
  }

  void addEvent({
    required String title,
    required String date,
    required String time,
    int priority = 2,
    String? recurring,
    int? reminderMinutes,
  }) {
    final base = ScheduleEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      date: date,
      time: time,
      priority: priority.clamp(1, 3),
      recurring: recurring,
      reminderMinutes: reminderMinutes,
      createdAt: DateTime.now(),
    );
    events.add(base);
    if (recurring != null) {
      _expandRecurring(base);
    }
    _save();
    notifyListeners();
  }

  void _expandRecurring(ScheduleEvent base) {
    final baseDate = DateTime.parse(base.date);
    final end = DateTime.now().add(const Duration(days: 30));
    final delta = base.recurring == 'daily'
        ? const Duration(days: 1)
        : const Duration(days: 7);
    var current = baseDate.add(delta);
    while (!current.isAfter(end)) {
      final dateStr = current.toIso8601String().substring(0, 10);
      final alreadyExists = events.any(
          (e) => e.title == base.title && e.date == dateStr && e.time == base.time);
      if (!alreadyExists) {
        events.add(ScheduleEvent(
          id: '${base.id}_${dateStr}',
          title: base.title,
          date: dateStr,
          time: base.time,
          priority: base.priority,
          recurring: base.recurring,
          reminderMinutes: base.reminderMinutes,
          createdAt: DateTime.now(),
        ));
      }
      current = current.add(delta);
    }
  }

  void deleteEvent(String id) {
    events.removeWhere((e) => e.id == id);
    _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
        _kScheduleKey, jsonEncode(events.map((e) => e.toJson()).toList()));
  }

  static Future<ScheduleModel> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kScheduleKey);
    if (raw == null) return ScheduleModel();
    final list = jsonDecode(raw) as List;
    return ScheduleModel(
        events: list
            .map((e) => ScheduleEvent.fromJson(e as Map<String, dynamic>))
            .toList());
  }
}
