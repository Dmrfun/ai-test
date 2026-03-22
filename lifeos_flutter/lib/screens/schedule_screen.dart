import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/schedule_model.dart';
import '../theme/app_theme.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<ScheduleModel>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(children: [
          Icon(Icons.calendar_month_outlined,
              color: AppColors.scheduleColor, size: 20),
          const SizedBox(width: 8),
          const Text('ScheduleOS'),
        ]),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.scheduleColor,
          labelColor: AppColors.scheduleColor,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [Tab(text: 'Day View'), Tab(text: 'Week View')],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.accent),
            onPressed: () => _showAddEvent(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _DayView(
              model: model,
              selectedDay: _selectedDay,
              onDayChanged: (d) => setState(() => _selectedDay = d)),
          _WeekView(model: model),
        ],
      ),
    );
  }

  void _showAddEvent(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) =>
          _AddEventDialog(initialDate: _selectedDay.toIso8601String().substring(0, 10)),
    );
  }
}

class _DayView extends StatelessWidget {
  final ScheduleModel model;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDayChanged;

  const _DayView({
    required this.model,
    required this.selectedDay,
    required this.onDayChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dayStr = selectedDay.toIso8601String().substring(0, 10);
    final events = model.forDay(dayStr);
    final label = DateFormat('EEEE, MMMM d').format(selectedDay);

    return Column(
      children: [
        // Day navigator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left,
                    color: AppColors.textSecondary),
                onPressed: () => onDayChanged(
                    selectedDay.subtract(const Duration(days: 1))),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: selectedDay,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.dark(
                              primary: AppColors.scheduleColor,
                              surface: AppColors.surfaceElevated),
                        ),
                        child: child!,
                      ),
                    );
                    if (d != null) onDayChanged(d);
                  },
                  child: Text(label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary),
                onPressed: () =>
                    onDayChanged(selectedDay.add(const Duration(days: 1))),
              ),
            ],
          ),
        ),
        Expanded(
          child: events.isEmpty
              ? const Center(
                  child: Text('No events this day',
                      style: TextStyle(color: AppColors.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: events.length,
                  itemBuilder: (_, i) =>
                      _EventTile(event: events[i], model: model),
                ),
        ),
      ],
    );
  }
}

class _WeekView extends StatelessWidget {
  final ScheduleModel model;

  const _WeekView({required this.model});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final startStr = monday.toIso8601String().substring(0, 10);
    final events = model.forWeek(startStr);

    // Group by date
    final grouped = <String, List<ScheduleEvent>>{};
    for (final e in events) {
      grouped.putIfAbsent(e.date, () => []).add(e);
    }
    final dates = grouped.keys.toList()..sort();

    if (events.isEmpty) {
      return const Center(
          child: Text('No events this week',
              style: TextStyle(color: AppColors.textMuted)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: dates.length,
      itemBuilder: (_, i) {
        final date = dates[i];
        final dayEvents = grouped[date]!;
        final dt = DateTime.parse(date);
        final isToday = date == today.toIso8601String().substring(0, 10);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isToday
                    ? AppColors.scheduleColor.withOpacity(0.2)
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                DateFormat('EEEE, MMM d').format(dt),
                style: TextStyle(
                    color: isToday
                        ? AppColors.scheduleColor
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
            ...dayEvents.map((e) => _EventTile(event: e, model: model)),
          ],
        );
      },
    );
  }
}

class _EventTile extends StatelessWidget {
  final ScheduleEvent event;
  final ScheduleModel model;

  const _EventTile({required this.event, required this.model});

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.success, AppColors.warning, AppColors.danger];
    final labels = ['Low', 'Medium', 'High'];
    final color = colors[(event.priority - 1).clamp(0, 2)];
    final label = labels[(event.priority - 1).clamp(0, 2)];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
            height: 36,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(event.time,
                        style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontFamily: 'monospace')),
                    const SizedBox(width: 8),
                    _miniChip(label, color),
                    if (event.recurring != null) ...[
                      const SizedBox(width: 6),
                      _miniChip('↻ ${event.recurring}', AppColors.textMuted),
                    ],
                    if (event.reminderMinutes != null) ...[
                      const SizedBox(width: 6),
                      _miniChip(
                          '🔔 ${event.reminderMinutes}m', AppColors.accent),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 16, color: AppColors.danger),
            onPressed: () => model.deleteEvent(event.id),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text, style: TextStyle(color: color, fontSize: 10)),
      );
}

class _AddEventDialog extends StatefulWidget {
  final String initialDate;
  const _AddEventDialog({required this.initialDate});

  @override
  State<_AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<_AddEventDialog> {
  final _titleCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController(text: '09:00');
  int _priority = 2;
  String? _recurring;
  int? _reminder;

  @override
  void initState() {
    super.initState();
    _dateCtrl.text = widget.initialDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Add Event',
          style: TextStyle(color: AppColors.textPrimary)),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Event Title'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dateCtrl,
                      readOnly: true,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration:
                          const InputDecoration(labelText: 'Date'),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                          builder: (ctx, child) => Theme(
                            data: Theme.of(ctx).copyWith(
                              colorScheme: const ColorScheme.dark(
                                  primary: AppColors.scheduleColor,
                                  surface: AppColors.surfaceElevated),
                            ),
                            child: child!,
                          ),
                        );
                        if (d != null) {
                          _dateCtrl.text =
                              d.toIso8601String().substring(0, 10);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _timeCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration:
                          const InputDecoration(labelText: 'Time (HH:MM)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Priority:',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(width: 8),
                  ...List.generate(3, (i) {
                    final colors = [
                      AppColors.success,
                      AppColors.warning,
                      AppColors.danger
                    ];
                    final labels = ['Low', 'Med', 'High'];
                    final p = i + 1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(labels[i]),
                        selected: _priority == p,
                        selectedColor: colors[i].withOpacity(0.25),
                        labelStyle: TextStyle(
                            color:
                                _priority == p ? colors[i] : AppColors.textMuted,
                            fontSize: 11),
                        onSelected: (_) => setState(() => _priority = p),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                value: _recurring,
                dropdownColor: AppColors.surfaceElevated,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Recurring'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('None')),
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                ],
                onChanged: (v) => setState(() => _recurring = v),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                value: _reminder,
                dropdownColor: AppColors.surfaceElevated,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Reminder'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('None')),
                  DropdownMenuItem(value: 15, child: Text('15 min before')),
                  DropdownMenuItem(value: 30, child: Text('30 min before')),
                  DropdownMenuItem(value: 60, child: Text('1 hour before')),
                ],
                onChanged: (v) => setState(() => _reminder = v),
              ),
            ],
          ),
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
              context.read<ScheduleModel>().addEvent(
                    title: _titleCtrl.text,
                    date: _dateCtrl.text,
                    time: _timeCtrl.text,
                    priority: _priority,
                    recurring: _recurring,
                    reminderMinutes: _reminder,
                  );
              Navigator.pop(context);
            }
          },
          child: const Text('Add Event'),
        ),
      ],
    );
  }
}
