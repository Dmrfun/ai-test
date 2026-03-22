import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kBudgetKey = 'lifeos_budget';

const kCategories = [
  'Food',
  'Entertainment',
  'Transport',
  'Health',
  'Bills',
  'General',
];

class IncomeEntry {
  final String id;
  final double amount;
  final String source;
  final DateTime date;

  IncomeEntry({
    required this.id,
    required this.amount,
    required this.source,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'source': source,
        'date': date.toIso8601String(),
      };

  factory IncomeEntry.fromJson(Map<String, dynamic> j) => IncomeEntry(
        id: j['id'] as String,
        amount: (j['amount'] as num).toDouble(),
        source: j['source'] as String,
        date: DateTime.parse(j['date'] as String),
      );
}

class ExpenseEntry {
  final String id;
  final String name;
  double amount;
  final String category;
  final DateTime date;

  ExpenseEntry({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
      };

  factory ExpenseEntry.fromJson(Map<String, dynamic> j) => ExpenseEntry(
        id: j['id'] as String,
        name: j['name'] as String,
        amount: (j['amount'] as num).toDouble(),
        category: j['category'] as String,
        date: DateTime.parse(j['date'] as String),
      );
}

class BudgetModel extends ChangeNotifier {
  double startingAmount;
  List<IncomeEntry> income;
  List<ExpenseEntry> expenses;

  BudgetModel({
    this.startingAmount = 1000,
    List<IncomeEntry>? income,
    List<ExpenseEntry>? expenses,
  })  : income = income ?? [],
        expenses = expenses ?? [];

  double get totalIncome =>
      startingAmount + income.fold(0, (s, e) => s + e.amount);
  double get totalExpenses => expenses.fold(0, (s, e) => s + e.amount);
  double get balance => totalIncome - totalExpenses;

  Map<String, double> get byCategory {
    final map = {for (var c in kCategories) c: 0.0};
    for (final e in expenses) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  void addIncome(double amount, String source) {
    income.add(IncomeEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      source: source,
      date: DateTime.now(),
    ));
    _save();
    notifyListeners();
  }

  void addExpense(String name, double amount, String category) {
    expenses.add(ExpenseEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      amount: amount,
      category: kCategories.contains(category) ? category : 'General',
      date: DateTime.now(),
    ));
    _save();
    notifyListeners();
  }

  void updateExpense(String id, double newAmount) {
    final e = expenses.firstWhere((e) => e.id == id);
    e.amount = newAmount;
    _save();
    notifyListeners();
  }

  void deleteExpense(String id) {
    expenses.removeWhere((e) => e.id == id);
    _save();
    notifyListeners();
  }

  Map<String, dynamic> monthlySummary(int year, int month) {
    final inc = income
        .where((e) => e.date.year == year && e.date.month == month)
        .fold(0.0, (s, e) => s + e.amount);
    final exp = expenses
        .where((e) => e.date.year == year && e.date.month == month)
        .fold(0.0, (s, e) => s + e.amount);
    return {'income': inc, 'expenses': exp, 'net': inc - exp};
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_kBudgetKey, jsonEncode({
      'startingAmount': startingAmount,
      'income': income.map((e) => e.toJson()).toList(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
    }));
  }

  static Future<BudgetModel> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kBudgetKey);
    if (raw == null) return BudgetModel();
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return BudgetModel(
      startingAmount: (j['startingAmount'] as num).toDouble(),
      income: (j['income'] as List)
          .map((e) => IncomeEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      expenses: (j['expenses'] as List)
          .map((e) => ExpenseEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
