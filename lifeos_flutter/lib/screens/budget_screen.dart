import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/budget_model.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
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
    final budget = context.watch<BudgetModel>();
    final fmt = NumberFormat('#,##0.00');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(children: [
          Icon(Icons.account_balance_wallet_outlined,
              color: AppColors.budgetColor, size: 20),
          const SizedBox(width: 8),
          const Text('BudgetOS'),
        ]),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.budgetColor,
          labelColor: AppColors.budgetColor,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Expenses'),
            Tab(text: 'Income'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.accent),
            onPressed: () => _showAddDialog(context, budget),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _OverviewTab(budget: budget, fmt: fmt),
          _ExpensesTab(budget: budget, fmt: fmt),
          _IncomeTab(budget: budget, fmt: fmt),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, BudgetModel budget) {
    showDialog(
      context: context,
      builder: (_) => _AddTransactionDialog(budget: budget),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final BudgetModel budget;
  final NumberFormat fmt;

  const _OverviewTab({required this.budget, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final cats = budget.byCategory.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(children: [
            Expanded(
              child: StatCard(
                label: 'Total Income',
                value: '\$${fmt.format(budget.totalIncome)}',
                icon: Icons.trending_up,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                label: 'Total Spent',
                value: '\$${fmt.format(budget.totalExpenses)}',
                icon: Icons.trending_down,
                color: AppColors.danger,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          StatCard(
            label: 'Balance',
            value: '\$${fmt.format(budget.balance)}',
            icon: Icons.account_balance,
            color: budget.balance >= 0 ? AppColors.accent : AppColors.danger,
          ),

          const SizedBox(height: 24),
          const SectionHeader(title: 'Spending by Category'),

          if (cats.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                  child: Text('No expenses yet',
                      style: TextStyle(color: AppColors.textMuted))),
            )
          else ...[
            // Pie chart
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildSections(cats, budget.totalExpenses),
                  centerSpaceRadius: 50,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Category bars
            ...cats.map((e) => _categoryBar(e.key, e.value, budget.totalExpenses)),
          ],
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
      List<MapEntry<String, double>> cats, double total) {
    final colors = [
      AppColors.accent,
      AppColors.accentGreen,
      AppColors.accentPurple,
      AppColors.accentOrange,
      AppColors.accentYellow,
      AppColors.scheduleColor,
    ];
    return List.generate(cats.length, (i) {
      final pct = total > 0 ? cats[i].value / total * 100 : 0.0;
      return PieChartSectionData(
        color: colors[i % colors.length],
        value: cats[i].value,
        title: '${pct.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 11, color: Colors.white),
      );
    });
  }

  Widget _categoryBar(String name, double amount, double total) {
    final pct = total > 0 ? amount / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 90,
              child: Text(name,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text('\$${NumberFormat('#,##0.00').format(amount)}',
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _ExpensesTab extends StatelessWidget {
  final BudgetModel budget;
  final NumberFormat fmt;

  const _ExpensesTab({required this.budget, required this.fmt});

  @override
  Widget build(BuildContext context) {
    if (budget.expenses.isEmpty) {
      return const Center(
          child: Text('No expenses yet',
              style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: budget.expenses.length,
      itemBuilder: (ctx, i) {
        final e = budget.expenses[i];
        return _ExpenseTile(
          expense: e,
          onDelete: () => context.read<BudgetModel>().deleteExpense(e.id),
          onEdit: () => _showEditDialog(context, e),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, ExpenseEntry e) {
    final ctrl = TextEditingController(text: e.amount.toString());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Edit: ${e.name}',
            style: const TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration:
              const InputDecoration(labelText: 'New Amount', prefixText: '\$'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v != null) {
                context.read<BudgetModel>().updateExpense(e.id, v);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final ExpenseEntry expense;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ExpenseTile(
      {required this.expense, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final catColors = {
      'Food': Colors.orange,
      'Entertainment': Colors.purple,
      'Transport': Colors.blue,
      'Health': Colors.green,
      'Bills': Colors.red,
      'General': Colors.grey,
    };
    final color = catColors[expense.category] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(expense.category,
                style: TextStyle(color: color, fontSize: 11)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(expense.name,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 14)),
          ),
          Text(
              '\$${NumberFormat('#,##0.00').format(expense.amount)}',
              style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 16, color: AppColors.textMuted),
              onPressed: onEdit),
          IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 16, color: AppColors.danger),
              onPressed: onDelete),
        ],
      ),
    );
  }
}

class _IncomeTab extends StatelessWidget {
  final BudgetModel budget;
  final NumberFormat fmt;

  const _IncomeTab({required this.budget, required this.fmt});

  @override
  Widget build(BuildContext context) {
    if (budget.income.isEmpty) {
      return const Center(
          child: Text('No income recorded yet',
              style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: budget.income.length,
      itemBuilder: (ctx, i) {
        final e = budget.income[i];
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
              const Icon(Icons.arrow_downward,
                  color: AppColors.success, size: 18),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(e.source,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 14))),
              Text('+\$${fmt.format(e.amount)}',
                  style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        );
      },
    );
  }
}

class _AddTransactionDialog extends StatefulWidget {
  final BudgetModel budget;
  const _AddTransactionDialog({required this.budget});

  @override
  State<_AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<_AddTransactionDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  String _category = 'General';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _sourceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Add Transaction',
          style: TextStyle(color: AppColors.textPrimary)),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabs,
              indicatorColor: AppColors.accent,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [Tab(text: 'Expense'), Tab(text: 'Income')],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: TabBarView(
                controller: _tabs,
                children: [
                  // Expense
                  Column(children: [
                    TextField(
                      controller: _nameCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                          labelText: 'Amount', prefixText: '\$'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _category,
                      dropdownColor: AppColors.surfaceElevated,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: kCategories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                  ]),
                  // Income
                  Column(children: [
                    TextField(
                      controller: _sourceCtrl,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(labelText: 'Source'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                          labelText: 'Amount', prefixText: '\$'),
                    ),
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
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            final amount = double.tryParse(_amountCtrl.text);
            if (amount == null) return;
            if (_tabs.index == 0) {
              widget.budget.addExpense(_nameCtrl.text, amount, _category);
            } else {
              widget.budget.addIncome(amount, _sourceCtrl.text);
            }
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
