import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/health_model.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<HealthModel>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(children: [
          Icon(Icons.favorite_outline,
              color: AppColors.healthColor, size: 20),
          const SizedBox(width: 8),
          const Text('HealthOS'),
        ]),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.healthColor,
          labelColor: AppColors.healthColor,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Habits'),
            Tab(text: 'Sleep'),
            Tab(text: 'Exercise'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.accent),
            onPressed: () => _showLogDialog(context, model),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _HabitsTab(model: model, tabController: _tabs),
          _SleepTab(model: model),
          _ExerciseTab(model: model),
        ],
      ),
    );
  }

  void _showLogDialog(BuildContext context, HealthModel model) {
    showDialog(
      context: context,
      builder: (_) => _LogDialog(model: model, initialTab: _tabs.index),
    );
  }
}

class _HabitsTab extends StatelessWidget {
  final HealthModel model;
  final TabController tabController;

  const _HabitsTab({required this.model, required this.tabController});

  @override
  Widget build(BuildContext context) {
    final habits = model.habitSummaries;
    final week = model.weeklySummary();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly stats
          Row(children: [
            Expanded(
              child: StatCard(
                label: 'Avg Sleep',
                value: '${week['avgSleepHours']}h',
                icon: Icons.bedtime_outlined,
                color: AppColors.accent,
                subtitle: 'Quality: ${week['avgSleepQuality']}/5',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: 'Exercise',
                value: '${week['totalExerciseMinutes']}m',
                icon: Icons.directions_run,
                color: AppColors.healthColor,
                subtitle: '${week['exerciseSessions']} sessions',
              ),
            ),
          ]),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Habit Streaks'),
          if (habits.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                  child: Text('No habits tracked yet. Log a habit!',
                      style: TextStyle(color: AppColors.textMuted))),
            )
          else
            ...habits.map((h) => _HabitCard(habit: h)),
        ],
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final HabitSummary habit;

  const _HabitCard({required this.habit});

  @override
  Widget build(BuildContext context) {
    final rate = habit.completionRate;
    final rateColor = rate >= 80
        ? AppColors.success
        : (rate >= 50 ? AppColors.warning : AppColors.danger);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: habit.completedToday
              ? AppColors.healthColor.withOpacity(0.4)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: habit.completedToday
                  ? AppColors.healthColor.withOpacity(0.15)
                  : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              habit.completedToday ? Icons.check : Icons.close,
              color: habit.completedToday
                  ? AppColors.healthColor
                  : AppColors.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(habit.name,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('$rate% completion',
                        style: TextStyle(color: rateColor, fontSize: 11)),
                    const SizedBox(width: 8),
                    Text('${habit.completedLogs}/${habit.totalLogs} days',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          if (habit.streak > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentYellow.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text('${habit.streak}d',
                      style: const TextStyle(
                          color: AppColors.accentYellow,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SleepTab extends StatelessWidget {
  final HealthModel model;

  const _SleepTab({required this.model});

  @override
  Widget build(BuildContext context) {
    final logs = model.sleepLogs.reversed.take(14).toList();
    if (logs.isEmpty) {
      return const Center(
          child: Text('No sleep logs yet',
              style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: logs.length,
      itemBuilder: (_, i) {
        final s = logs[i];
        final qualityColors = [
          AppColors.danger,
          AppColors.accentOrange,
          AppColors.warning,
          AppColors.accent,
          AppColors.success,
        ];
        final color = qualityColors[(s.quality - 1).clamp(0, 4)];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.bedtime_outlined,
                  color: AppColors.accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.date,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    Text('${s.hours}h sleep',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Column(
                children: [
                  Text('Quality',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
                  Row(
                    children: List.generate(
                        5,
                        (j) => Icon(Icons.star,
                            size: 14,
                            color: j < s.quality
                                ? color
                                : AppColors.border)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExerciseTab extends StatelessWidget {
  final HealthModel model;

  const _ExerciseTab({required this.model});

  @override
  Widget build(BuildContext context) {
    final logs = model.exerciseLogs.reversed.take(14).toList();
    if (logs.isEmpty) {
      return const Center(
          child: Text('No exercise logs yet',
              style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: logs.length,
      itemBuilder: (_, i) {
        final e = logs[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.healthColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.directions_run,
                    color: AppColors.healthColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.type,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                    Text(e.date,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              Text('${e.durationMinutes} min',
                  style: const TextStyle(
                      color: AppColors.healthColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        );
      },
    );
  }
}

class _LogDialog extends StatefulWidget {
  final HealthModel model;
  final int initialTab;
  const _LogDialog({required this.model, required this.initialTab});

  @override
  State<_LogDialog> createState() => _LogDialogState();
}

class _LogDialogState extends State<_LogDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _habitCtrl = TextEditingController();
  bool _habitDone = true;
  double _sleepHours = 7;
  int _sleepQuality = 4;
  final _exTypeCtrl = TextEditingController();
  int _exDuration = 30;

  @override
  void initState() {
    super.initState();
    _tabs =
        TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _habitCtrl.dispose();
    _exTypeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Log Health Data',
          style: TextStyle(color: AppColors.textPrimary)),
      content: SizedBox(
        width: 340,
        height: 240,
        child: Column(
          children: [
            TabBar(
              controller: _tabs,
              indicatorColor: AppColors.healthColor,
              labelColor: AppColors.healthColor,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(text: 'Habit'),
                Tab(text: 'Sleep'),
                Tab(text: 'Exercise'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  // Habit tab
                  Column(children: [
                    TextField(
                      controller: _habitCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration:
                          const InputDecoration(labelText: 'Habit Name'),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      const Text('Completed:',
                          style: TextStyle(color: AppColors.textSecondary)),
                      const Spacer(),
                      Switch(
                          value: _habitDone,
                          activeColor: AppColors.healthColor,
                          onChanged: (v) => setState(() => _habitDone = v)),
                    ]),
                  ]),
                  // Sleep tab
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${_sleepHours.toStringAsFixed(1)}h sleep',
                          style: const TextStyle(
                              color: AppColors.accent, fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      Slider(
                          value: _sleepHours,
                          min: 0,
                          max: 12,
                          divisions: 24,
                          activeColor: AppColors.accent,
                          onChanged: (v) =>
                              setState(() => _sleepHours = v)),
                      Text('Quality: $_sleepQuality/5',
                          style: const TextStyle(
                              color: AppColors.textSecondary)),
                      Slider(
                          value: _sleepQuality.toDouble(),
                          min: 1,
                          max: 5,
                          divisions: 4,
                          activeColor: AppColors.healthColor,
                          onChanged: (v) =>
                              setState(() => _sleepQuality = v.round())),
                    ],
                  ),
                  // Exercise tab
                  Column(children: [
                    TextField(
                      controller: _exTypeCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration:
                          const InputDecoration(labelText: 'Exercise Type'),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Text('Duration:',
                          style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(width: 8),
                      Text('${_exDuration}min',
                          style: const TextStyle(
                              color: AppColors.healthColor,
                              fontWeight: FontWeight.w600)),
                    ]),
                    Slider(
                        value: _exDuration.toDouble(),
                        min: 5,
                        max: 180,
                        divisions: 35,
                        activeColor: AppColors.healthColor,
                        onChanged: (v) =>
                            setState(() => _exDuration = v.round())),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary))),
        ElevatedButton(
          onPressed: () {
            switch (_tabs.index) {
              case 0:
                if (_habitCtrl.text.isNotEmpty) {
                  widget.model.logHabit(_habitCtrl.text, _habitDone);
                }
              case 1:
                widget.model.logSleep(_sleepHours, _sleepQuality);
              case 2:
                if (_exTypeCtrl.text.isNotEmpty) {
                  widget.model.logExercise(_exTypeCtrl.text, _exDuration);
                }
            }
            Navigator.pop(context);
          },
          child: const Text('Log'),
        ),
      ],
    );
  }
}
