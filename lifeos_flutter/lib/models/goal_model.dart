import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kGoalsKey = 'lifeos_goals';

const kGoalCategories = ['Career', 'Health', 'Financial', 'Personal'];

class Goal {
  final String id;
  String title;
  String dueDate;
  bool completed;
  int priority; // 1-5
  String category;
  int progress; // 0-100
  final DateTime createdAt;
  DateTime? completedAt;

  Goal({
    required this.id,
    required this.title,
    required this.dueDate,
    this.completed = false,
    this.priority = 3,
    this.category = 'Personal',
    this.progress = 0,
    required this.createdAt,
    this.completedAt,
  });

  bool get isOverdue {
    if (completed) return false;
    try {
      final due = DateTime.parse(dueDate);
      return due.isBefore(DateTime.now().copyWith(
          hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0));
    } catch (_) {
      return false;
    }
  }

  String get status {
    if (completed) return 'Done';
    if (isOverdue) return 'Overdue';
    return 'Pending';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'dueDate': dueDate,
        'completed': completed,
        'priority': priority,
        'category': category,
        'progress': progress,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory Goal.fromJson(Map<String, dynamic> j) => Goal(
        id: j['id'] as String,
        title: j['title'] as String,
        dueDate: j['dueDate'] as String,
        completed: j['completed'] as bool? ?? false,
        priority: j['priority'] as int? ?? 3,
        category: j['category'] as String? ?? 'Personal',
        progress: j['progress'] as int? ?? 0,
        createdAt: DateTime.parse(j['createdAt'] as String),
        completedAt: j['completedAt'] != null
            ? DateTime.parse(j['completedAt'] as String)
            : null,
      );
}

class GoalModel extends ChangeNotifier {
  List<Goal> goals;

  GoalModel({List<Goal>? goals}) : goals = goals ?? [];

  int get pendingCount => goals.where((g) => !g.completed).length;

  void addGoal({
    required String title,
    required String dueDate,
    int priority = 3,
    String category = 'Personal',
    int progress = 0,
  }) {
    goals.add(Goal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      dueDate: dueDate,
      priority: priority.clamp(1, 5),
      category: kGoalCategories.contains(category) ? category : 'Personal',
      progress: progress.clamp(0, 100),
      createdAt: DateTime.now(),
    ));
    _save();
    notifyListeners();
  }

  void completeGoal(String id) {
    final g = goals.firstWhere((g) => g.id == id);
    g.completed = true;
    g.progress = 100;
    g.completedAt = DateTime.now();
    _save();
    notifyListeners();
  }

  void updateProgress(String id, int progress) {
    final g = goals.firstWhere((g) => g.id == id);
    g.progress = progress.clamp(0, 100);
    if (g.progress == 100) {
      g.completed = true;
      g.completedAt = DateTime.now();
    }
    _save();
    notifyListeners();
  }

  void deleteGoal(String id) {
    goals.removeWhere((g) => g.id == id);
    _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_kGoalsKey, jsonEncode(goals.map((g) => g.toJson()).toList()));
  }

  static Future<GoalModel> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kGoalsKey);
    if (raw == null) return GoalModel();
    final list = jsonDecode(raw) as List;
    return GoalModel(
        goals: list.map((e) => Goal.fromJson(e as Map<String, dynamic>)).toList());
  }
}
