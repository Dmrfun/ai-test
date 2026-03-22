import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/budget_model.dart';
import '../models/goal_model.dart';
import '../models/health_model.dart';
import '../models/notes_model.dart';
import '../models/schedule_model.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const DashboardScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final budget = context.watch<BudgetModel>();
    final goals = context.watch<GoalModel>();
    final schedule = context.watch<ScheduleModel>();
    final health = context.watch<HealthModel>();
    final notes = context.watch<NotesModel>();

    final today = DateFormat('EEEE, MMMM d yyyy').format(DateTime.now());
    final todayEvents = schedule.todayEvents;
    final habits = health.habitSummaries;
    final latest = notes.latestJournal;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('LifeOS',
                        style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1)),
                    Text(today,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats row
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                StatCard(
                  label: 'Balance',
                  value:
                      '\$${NumberFormat('#,##0.00').format(budget.balance)}',
                  icon: Icons.account_balance_wallet_outlined,
                  color: budget.balance >= 0
                      ? AppColors.budgetColor
                      : AppColors.danger,
                  subtitle: '${budget.expenses.length} expenses',
                  onTap: () => onNavigate(1),
                ),
                StatCard(
                  label: 'Pending Goals',
                  value: '${goals.pendingCount}',
                  icon: Icons.flag_outlined,
                  color: AppColors.goalsColor,
                  subtitle: '${goals.goals.length} total',
                  onTap: () => onNavigate(2),
                ),
                StatCard(
                  label: "Today's Events",
                  value: '${todayEvents.length}',
                  icon: Icons.calendar_today_outlined,
                  color: AppColors.scheduleColor,
                  subtitle: todayEvents.isEmpty
                      ? 'All clear!'
                      : todayEvents.first.title,
                  onTap: () => onNavigate(3),
                ),
                StatCard(
                  label: 'Active Habits',
                  value: '${habits.length}',
                  icon: Icons.favorite_outline,
                  color: AppColors.healthColor,
                  subtitle: habits.isEmpty
                      ? 'None tracked'
                      : 'Best: ${_bestStreak(habits)} day streak',
                  onTap: () => onNavigate(4),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Today's agenda
            SectionHeader(
                title: "📅 Today's Agenda",
                action: 'View All',
                onAction: () => onNavigate(3)),
            if (todayEvents.isEmpty)
              _emptyState('No events scheduled today')
            else
              ...todayEvents.take(5).map((e) => _eventTile(e)),

            const SizedBox(height: 20),

            // Top goals
            SectionHeader(
                title: '🎯 Active Goals',
                action: 'View All',
                onAction: () => onNavigate(2)),
            () {
              final active = goals.goals
                  .where((g) => !g.completed)
                  .toList()
                ..sort((a, b) => b.priority.compareTo(a.priority));
              if (active.isEmpty) return _emptyState('No active goals');
              return Column(
                children: active.take(4).map((g) => _goalTile(g)).toList(),
              );
            }(),

            const SizedBox(height: 20),

            // Habit streaks
            SectionHeader(
                title: '💪 Habit Streaks',
                action: 'View All',
                onAction: () => onNavigate(4)),
            if (habits.isEmpty)
              _emptyState('No habits tracked yet')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: habits
                    .take(6)
                    .map((h) => _habitChip(h))
                    .toList(),
              ),

            const SizedBox(height: 20),

            // Latest journal
            if (latest != null) ...[
              SectionHeader(
                  title: '📓 Latest Journal',
                  action: 'View All',
                  onAction: () => onNavigate(5)),
              _journalCard(latest),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  int _bestStreak(List<HabitSummary> habits) {
    if (habits.isEmpty) return 0;
    return habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b);
  }

  Widget _emptyState(String msg) => Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Text(msg,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13)),
        ),
      );

  Widget _eventTile(ScheduleEvent e) {
    final colors = [AppColors.success, AppColors.warning, AppColors.danger];
    final color = colors[(e.priority - 1).clamp(0, 2)];
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Text(e.time,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontFamily: 'monospace')),
          const SizedBox(width: 12),
          Expanded(
            child: Text(e.title,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14)),
          ),
          if (e.recurring != null)
            Icon(Icons.repeat, size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }

  Widget _goalTile(Goal g) {
    final priorityColors = [
      AppColors.success,
      AppColors.accent,
      AppColors.warning,
      AppColors.accentOrange,
      AppColors.danger,
    ];
    final color = priorityColors[(g.priority - 1).clamp(0, 4)];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(g.title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('P${g.priority}',
                    style: TextStyle(color: color, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: g.progress / 100,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${g.progress}%',
                  style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Due: ${g.dueDate}  ·  ${g.category}',
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _habitChip(HabitSummary h) {
    final color = h.completedToday ? AppColors.success : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: h.completedToday ? AppColors.success : AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              h.completedToday
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              size: 14,
              color: color),
          const SizedBox(width: 6),
          Text(h.name,
              style: TextStyle(color: color, fontSize: 13)),
          if (h.streak > 0) ...[
            const SizedBox(width: 6),
            Text('🔥${h.streak}',
                style: const TextStyle(fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _journalCard(Note note) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.notesColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(note.title,
                  style: const TextStyle(
                      color: AppColors.notesColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(note.date,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note.content.length > 150
                ? '${note.content.substring(0, 150)}…'
                : note.content,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
