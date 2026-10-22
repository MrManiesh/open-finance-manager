import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/transaction_item.dart';
import '../../providers/finance_provider.dart';

class StatisticsScreen extends StatefulWidget {
  final VoidCallback? onBackToDashboard;

  const StatisticsScreen({super.key, this.onBackToDashboard});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final financeProv = context.watch<FinanceProvider>();
    final transactions = financeProv.transactions;
    final currency = financeProv.currencySymbol;

    // Filter expenses
    final expenses = transactions.where((t) => t.type == TransactionType.expense).toList();
    final double totalExpense = expenses.fold(0.0, (sum, t) => sum + t.amount);

    // Group expenses by category
    final Map<String, double> categoryTotals = {};
    for (final exp in expenses) {
      categoryTotals[exp.category] = (categoryTotals[exp.category] ?? 0.0) + exp.amount;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        leading: widget.onBackToDashboard != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back to Dashboard',
                onPressed: widget.onBackToDashboard,
              )
            : null,
        title: Text('${financeProv.activeGroup?.name ?? 'Group'} • Analytics'),
      ),
      body: expenses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pie_chart_outline_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('No expense data yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Add expenses in this group to view breakdown charts', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Top Overview Card
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.income.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.income.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Income', style: TextStyle(fontSize: 12, color: AppColors.income, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(financeProv.groupIncome, symbol: currency),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.expense.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.expense.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Expense', style: TextStyle(fontSize: 12, color: AppColors.expense, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(financeProv.groupExpense, symbol: currency),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Chart Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Expense Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection == null) {
                                      _touchedIndex = -1;
                                      return;
                                    }
                                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              borderData: FlBorderData(show: false),
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: List.generate(sortedCategories.length, (i) {
                                final isTouched = i == _touchedIndex;
                                final radius = isTouched ? 60.0 : 50.0;
                                final color = AppColors.groupPalette[i % AppColors.groupPalette.length];
                                final entry = sortedCategories[i];
                                final percentage = (entry.value / totalExpense) * 100;

                                return PieChartSectionData(
                                  color: color,
                                  value: entry.value,
                                  title: '${percentage.toStringAsFixed(0)}%',
                                  radius: radius,
                                  titleStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Category Breakdown List
                const Text('Category Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ...sortedCategories.asMap().entries.map((mapEntry) {
                  final index = mapEntry.key;
                  final entry = mapEntry.value;
                  final color = AppColors.groupPalette[index % AppColors.groupPalette.length];
                  final percent = totalExpense > 0 ? (entry.value / totalExpense) : 0.0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 8,
                                backgroundColor: color,
                              ),
                              const SizedBox(width: 10),
                              Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Text(
                                CurrencyFormatter.format(entry.value, symbol: currency),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: percent,
                            backgroundColor: Colors.grey.withOpacity(0.15),
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
    );
  }
}
