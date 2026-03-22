import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/goal_model.dart';
import '../theme/app_theme.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final model = context.watch<GoalModel>();
    final filtered = _filter == 'All'
        ? model.goals
        : model.goals.where((g) => g.status == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(children: [
          Icon(Icons.flag_outlined, color: AppColors.goalsColor, size: 20),
          const SizedBox(width: 8),
          const Text('GoalOS'),
        ]),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.accent),
            onPressed: () => _showAddGoal(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: ['All', 'Pending', 'Done', 'Overdue']
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                          selectedColor: AppColors.goalsColor.withOpacity(0.2),
                          checkmarkColor: AppColors.goalsColor,
                          labelStyle: TextStyle(
                              color: _filter == f
                                  ? AppColors.goalsColor
                                  : AppColors.textSecondary,
                              fontSize: 12),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text('No goals here yet',
                        style: TextStyle(color: AppColors.textMuted)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) =>
                        _GoalCard(goal: filtered[i], model: model),
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddGoal(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _AddGoalDialog(),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final GoalModel model;

  const _GoalCard({required this.goal, required this.model});

  @override
  Widget build(BuildContext context) {
    final priorityColors = [
      AppColors.success,
      AppColors.accent,
      AppColors.warning,
      AppColors.accentOrange,
      AppColors.danger,
    ];
    final priorityLabels = ['Low', 'Normal', 'Medium', 'High', 'Critical'];
    final color = priorityColors[(goal.priority - 1).clamp(0, 4)];
    final label = priorityLabels[(goal.priority - 1).clamp(0, 4)];

    Color statusColor;
    switch (goal.status) {
      case 'Done':
        statusColor = AppColors.success;
        break;
      case 'Overdue':
        statusColor = AppColors.danger;
        break;
      default:
        statusColor = AppColors.warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(goal.title,
                    style: TextStyle(
                        color: goal.completed
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        decoration: goal.completed
                            ? TextDecoration.lineThrough
                            : null)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(goal.status,
                    style: TextStyle(color: statusColor, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _chip(goal.category, AppColors.accentPurple),
              const SizedBox(width: 6),
              _chip(label, color),
              const SizedBox(width: 6),
              _chip('Due: ${goal.dueDate}', AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Progress',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                        Text('${goal.progress}%',
                            style: TextStyle(color: color, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: goal.progress / 100,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation(color),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (!goal.completed) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined,
                      size: 18, color: AppColors.textMuted),
                  onPressed: () => _showProgressDialog(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.check_circle_outline,
                      size: 18, color: AppColors.success),
                  onPressed: () => model.completeGoal(goal.id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
              ],
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.danger),
                onPressed: () => _confirmDelete(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text, style: TextStyle(color: color, fontSize: 10)),
      );

  void _showProgressDialog(BuildContext context) {
    double pct = goal.progress.toDouble();
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Update Progress',
              style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${pct.round()}%',
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 32,
                      fontWeight: FontWeight.bold)),
              Slider(
                value: pct,
                min: 0,
                max: 100,
                divisions: 20,
                activeColor: AppColors.accent,
                onChanged: (v) => setState(() => pct = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.textSecondary))),
            ElevatedButton(
              onPressed: () {
                model.updateProgress(goal.id, pct.round());
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      }),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Goal',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Delete "${goal.title}"?',
            style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              model.deleteGoal(goal.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AddGoalDialog extends StatefulWidget {
  @override
  State<_AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<_AddGoalDialog> {
  final _titleCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  String _category = 'Personal';
  int _priority = 3;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Add Goal',
          style: TextStyle(color: AppColors.textPrimary)),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Goal Title'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _dateCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                  labelText: 'Due Date', hintText: 'YYYY-MM-DD'),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.dark(
                          primary: AppColors.accent,
                          surface: AppColors.surfaceElevated),
                    ),
                    child: child!,
                  ),
                );
                if (d != null) {
                  _dateCtrl.text = d.toIso8601String().substring(0, 10);
                }
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _category,
              dropdownColor: AppColors.surfaceElevated,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Category'),
              items: kGoalCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Text('Priority: ',
                    style: TextStyle(color: AppColors.textSecondary)),
                Expanded(
                  child: Slider(
                    value: _priority.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '$_priority',
                    activeColor: AppColors.goalsColor,
                    onChanged: (v) => setState(() => _priority = v.round()),
                  ),
                ),
                Text('$_priority',
                    style: const TextStyle(color: AppColors.goalsColor)),
              ],
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
            if (_titleCtrl.text.isNotEmpty && _dateCtrl.text.isNotEmpty) {
              context.read<GoalModel>().addGoal(
                    title: _titleCtrl.text,
                    dueDate: _dateCtrl.text,
                    priority: _priority,
                    category: _category,
                  );
              Navigator.pop(context);
            }
          },
          child: const Text('Add Goal'),
        ),
      ],
    );
  }
}
