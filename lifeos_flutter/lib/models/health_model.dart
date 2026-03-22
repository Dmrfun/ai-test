import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kHealthKey = 'lifeos_health';

class HabitLog {
  final String id;
  final String name;
  final bool completed;
  final String date;

  HabitLog({
    required this.id,
    required this.name,
    required this.completed,
    required this.date,
  });

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'completed': completed, 'date': date};

  factory HabitLog.fromJson(Map<String, dynamic> j) => HabitLog(
        id: j['id'] as String,
        name: j['name'] as String,
        completed: j['completed'] as bool,
        date: j['date'] as String,
      );
}

class SleepLog {
  final String id;
  final double hours;
  final int quality; // 1-5
  final String date;

  SleepLog({
    required this.id,
    required this.hours,
    required this.quality,
    required this.date,
  });

  Map<String, dynamic> toJson() =>
      {'id': id, 'hours': hours, 'quality': quality, 'date': date};

  factory SleepLog.fromJson(Map<String, dynamic> j) => SleepLog(
        id: j['id'] as String,
        hours: (j['hours'] as num).toDouble(),
        quality: j['quality'] as int,
        date: j['date'] as String,
      );
}

class ExerciseLog {
  final String id;
  final String type;
  final int durationMinutes;
  final String date;

  ExerciseLog({
    required this.id,
    required this.type,
    required this.durationMinutes,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'durationMinutes': durationMinutes,
        'date': date,
      };

  factory ExerciseLog.fromJson(Map<String, dynamic> j) => ExerciseLog(
        id: j['id'] as String,
        type: j['type'] as String,
        durationMinutes: j['durationMinutes'] as int,
        date: j['date'] as String,
      );
}

class HabitSummary {
  final String name;
  final int streak;
  final bool completedToday;
  final int totalLogs;
  final int completedLogs;

  int get completionRate =>
      totalLogs == 0 ? 0 : (completedLogs * 100 ~/ totalLogs);

  HabitSummary({
    required this.name,
    required this.streak,
    required this.completedToday,
    required this.totalLogs,
    required this.completedLogs,
  });
}

class HealthModel extends ChangeNotifier {
  List<HabitLog> habitLogs;
  List<SleepLog> sleepLogs;
  List<ExerciseLog> exerciseLogs;

  HealthModel({
    List<HabitLog>? habitLogs,
    List<SleepLog>? sleepLogs,
    List<ExerciseLog>? exerciseLogs,
  })  : habitLogs = habitLogs ?? [],
        sleepLogs = sleepLogs ?? [],
        exerciseLogs = exerciseLogs ?? [];

  void logHabit(String name, bool completed, {String? date}) {
    final d = date ?? DateTime.now().toIso8601String().substring(0, 10);
    habitLogs.add(HabitLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      completed: completed,
      date: d,
    ));
    _save();
    notifyListeners();
  }

  void logSleep(double hours, int quality, {String? date}) {
    final d = date ?? DateTime.now().toIso8601String().substring(0, 10);
    sleepLogs.add(SleepLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      hours: hours,
      quality: quality.clamp(1, 5),
      date: d,
    ));
    _save();
    notifyListeners();
  }

  void logExercise(String type, int durationMinutes, {String? date}) {
    final d = date ?? DateTime.now().toIso8601String().substring(0, 10);
    exerciseLogs.add(ExerciseLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      durationMinutes: durationMinutes,
      date: d,
    ));
    _save();
    notifyListeners();
  }

  int _streak(String habitName) {
    final today = DateTime.now();
    final completedDates = habitLogs
        .where((h) => h.name == habitName && h.completed)
        .map((h) => h.date)
        .toSet();

    int streak = 0;
    var check = DateTime(today.year, today.month, today.day);
    while (completedDates.contains(check.toIso8601String().substring(0, 10))) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    }
    return streak;
  }

  List<HabitSummary> get habitSummaries {
    final names = habitLogs.map((h) => h.name).toSet().toList();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return names.map((name) {
      final logs = habitLogs.where((h) => h.name == name).toList();
      return HabitSummary(
        name: name,
        streak: _streak(name),
        completedToday:
            logs.any((h) => h.date == today && h.completed),
        totalLogs: logs.length,
        completedLogs: logs.where((h) => h.completed).length,
      );
    }).toList();
  }

  Map<String, dynamic> weeklySummary() {
    final today = DateTime.now();
    final start = today.subtract(Duration(days: today.weekday - 1));
    final startStr = DateTime(start.year, start.month, start.day)
        .toIso8601String()
        .substring(0, 10);
    final endStr = DateTime(start.year, start.month, start.day)
        .add(const Duration(days: 6))
        .toIso8601String()
        .substring(0, 10);

    bool inRange(String date) => date.compareTo(startStr) >= 0 && date.compareTo(endStr) <= 0;

    final ws = sleepLogs.where((s) => inRange(s.date)).toList();
    final we = exerciseLogs.where((e) => inRange(e.date)).toList();

    final avgSleep = ws.isEmpty
        ? 0.0
        : ws.fold(0.0, (s, e) => s + e.hours) / ws.length;
    final avgQuality = ws.isEmpty
        ? 0.0
        : ws.fold(0.0, (s, e) => s + e.quality) / ws.length;
    final totalExercise = we.fold(0, (s, e) => s + e.durationMinutes);

    return {
      'period': '$startStr → $endStr',
      'avgSleepHours': double.parse(avgSleep.toStringAsFixed(1)),
      'avgSleepQuality': double.parse(avgQuality.toStringAsFixed(1)),
      'totalExerciseMinutes': totalExercise,
      'exerciseSessions': we.length,
      'sleepLogs': ws,
      'exerciseLogs': we,
    };
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
        _kHealthKey,
        jsonEncode({
          'habitLogs': habitLogs.map((e) => e.toJson()).toList(),
          'sleepLogs': sleepLogs.map((e) => e.toJson()).toList(),
          'exerciseLogs': exerciseLogs.map((e) => e.toJson()).toList(),
        }));
  }

  static Future<HealthModel> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kHealthKey);
    if (raw == null) return HealthModel();
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return HealthModel(
      habitLogs: (j['habitLogs'] as List)
          .map((e) => HabitLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      sleepLogs: (j['sleepLogs'] as List)
          .map((e) => SleepLog.fromJson(e as Map<String, dynamic>))
          .toList(),
      exerciseLogs: (j['exerciseLogs'] as List)
          .map((e) => ExerciseLog.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
