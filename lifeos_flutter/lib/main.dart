import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/budget_model.dart';
import 'models/goal_model.dart';
import 'models/health_model.dart';
import 'models/notes_model.dart';
import 'models/schedule_model.dart';
import 'screens/budget_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/health_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/schedule_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final budget = await BudgetModel.load();
  final goals = await GoalModel.load();
  final schedule = await ScheduleModel.load();
  final health = await HealthModel.load();
  final notes = await NotesModel.load();

  if (budget.income.isEmpty && budget.expenses.isEmpty) {
    _seedDemoData(budget, goals, schedule, health, notes);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: budget),
        ChangeNotifierProvider.value(value: goals),
        ChangeNotifierProvider.value(value: schedule),
        ChangeNotifierProvider.value(value: health),
        ChangeNotifierProvider.value(value: notes),
      ],
      child: const LifeOSApp(),
    ),
  );
}

void _seedDemoData(BudgetModel budget, GoalModel goals, ScheduleModel schedule,
    HealthModel health, NotesModel notes) {
  final today = DateTime.now();
  final todayStr = today.toIso8601String().substring(0, 10);
  final tomorrowStr =
      today.add(const Duration(days: 1)).toIso8601String().substring(0, 10);

  budget.startingAmount = 3500;
  budget.addIncome(2500, 'Monthly Salary');
  budget.addIncome(400, 'Freelance Project');
  budget.addExpense('Groceries', 180, 'Food');
  budget.addExpense('Netflix', 15, 'Entertainment');
  budget.addExpense('Bus Pass', 60, 'Transport');
  budget.addExpense('Gym Membership', 45, 'Health');
  budget.addExpense('Electricity', 90, 'Bills');
  budget.addExpense('Dinner Out', 55, 'Food');

  goals.addGoal(
      title: 'Complete Python Certification',
      dueDate: today.add(const Duration(days: 60)).toIso8601String().substring(0, 10),
      priority: 4, category: 'Career', progress: 35);
  goals.addGoal(
      title: 'Run a 5K Race',
      dueDate: today.add(const Duration(days: 45)).toIso8601String().substring(0, 10),
      priority: 3, category: 'Health', progress: 20);
  goals.addGoal(
      title: 'Save \$5,000 Emergency Fund',
      dueDate: today.add(const Duration(days: 180)).toIso8601String().substring(0, 10),
      priority: 5, category: 'Financial', progress: 50);
  goals.addGoal(
      title: 'Read 12 Books This Year',
      dueDate: today.add(const Duration(days: 270)).toIso8601String().substring(0, 10),
      priority: 2, category: 'Personal', progress: 25);

  schedule.addEvent(title: 'Morning Run', date: todayStr, time: '07:00',
      priority: 2, recurring: 'daily');
  schedule.addEvent(title: 'Team Standup', date: todayStr, time: '09:30',
      priority: 3, reminderMinutes: 15);
  schedule.addEvent(title: 'Lunch Break', date: todayStr, time: '12:30',
      priority: 1);
  schedule.addEvent(title: 'Code Review', date: todayStr, time: '14:00',
      priority: 2);
  schedule.addEvent(title: 'Doctor Appointment', date: tomorrowStr,
      time: '10:00', priority: 3, reminderMinutes: 60);

  for (int i = 0; i < 7; i++) {
    final d = today.subtract(Duration(days: i)).toIso8601String().substring(0, 10);
    health.logHabit('Morning Run', i < 5, date: d);
    health.logHabit('Meditation', i < 6, date: d);
    health.logHabit('Read 30 min', i % 2 == 0, date: d);
    health.logSleep(7.0 + (i % 2) * 0.5, i % 3 == 0 ? 3 : 4, date: d);
    if (i % 2 == 0) health.logExercise('Running', 30, date: d);
  }

  notes.addNote('Python Tips',
      '1. Use list comprehensions for clean code.\n2. f-strings are faster than .format().',
      ['python', 'programming']);
  notes.addNote('Book Recommendations',
      '- Atomic Habits by James Clear\n- Deep Work by Cal Newport',
      ['books', 'reading']);
  notes.addJournalEntry(
      'Productive day! Finished the LifeOS Flutter build. Feeling great!',
      mood: 'happy');
  notes.addJournalEntry(
      'Took it easy today. Did my habits and got some reading in.',
      mood: 'neutral');
}

class LifeOSApp extends StatelessWidget {
  const LifeOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const _AppShell(),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();
  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _selectedIndex = 0;

  static const _navItems = [
    _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', AppColors.accent),
    _NavItem(Icons.account_balance_wallet_outlined, Icons.account_balance_wallet,
        'Budget', AppColors.budgetColor),
    _NavItem(Icons.flag_outlined, Icons.flag, 'Goals', AppColors.goalsColor),
    _NavItem(Icons.calendar_month_outlined, Icons.calendar_month, 'Schedule',
        AppColors.scheduleColor),
    _NavItem(Icons.favorite_outline, Icons.favorite, 'Health', AppColors.healthColor),
    _NavItem(Icons.book_outlined, Icons.book, 'Notes', AppColors.notesColor),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;

    Widget screen;
    switch (_selectedIndex) {
      case 0:
        screen = DashboardScreen(onNavigate: (i) => setState(() => _selectedIndex = i));
      case 1:
        screen = const BudgetScreen();
      case 2:
        screen = const GoalsScreen();
      case 3:
        screen = const ScheduleScreen();
      case 4:
        screen = const HealthScreen();
      case 5:
        screen = const NotesScreen();
      default:
        screen = DashboardScreen(onNavigate: (i) => setState(() => _selectedIndex = i));
    }

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            _SideNav(
              items: _navItems,
              selected: _selectedIndex,
              onSelect: (i) => setState(() => _selectedIndex = i),
            ),
            Expanded(child: screen),
          ],
        ),
      );
    }

    return Scaffold(
      body: screen,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: _navItems[_selectedIndex].color.withOpacity(0.2),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: _navItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon, color: AppColors.textSecondary),
                  selectedIcon: Icon(item.activeIcon, color: item.color),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  final List<_NavItem> items;
  final int selected;
  final ValueChanged<int> onSelect;

  const _SideNav({required this.items, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LifeOS',
                    style: TextStyle(color: AppColors.accent, fontSize: 22,
                        fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const Text('Command Center',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 8),
          ...List.generate(items.length, (i) {
            final item = items[i];
            final isSelected = i == selected;
            return InkWell(
              onTap: () => onSelect(i),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? item.color.withOpacity(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(isSelected ? item.activeIcon : item.icon,
                        color: isSelected ? item.color : AppColors.textSecondary,
                        size: 18),
                    const SizedBox(width: 12),
                    Text(item.label,
                        style: TextStyle(
                            color: isSelected ? item.color : AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;
  const _NavItem(this.icon, this.activeIcon, this.label, this.color);
}
