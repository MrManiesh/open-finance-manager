import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/ambient_background.dart';
import '../../core/widgets/glass_container.dart';
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

    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: widget.onBackToDashboard != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back to Dashboard',
                  onPressed: widget.onBackToDashboard,
                )
              : null,
          title: Text(
            '${financeProv.activeGroup?.name ?? 'Group'} • Analytics',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: expenses.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: GlassContainer(
                    borderRadius: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pie_chart_outline_rounded, size: 64, color: Colors.white.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text(
                          'No expense data yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add expenses in this group to view luminous breakdown charts',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // Top Overview Card (Income & Expense Capsules)
                  Row(
                    children: [
                      Expanded(
                        child: GlassContainer(
                          borderRadius: 20,
                          tintColor: AppColors.income,
                          opacity: 0.15,
                          borderColor: AppColors.income.withOpacity(0.35),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.income,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Total Income',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.income,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  CurrencyFormatter.format(financeProv.groupIncome, symbol: currency),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassContainer(
                          borderRadius: 20,
                          tintColor: AppColors.expense,
                          opacity: 0.15,
                          borderColor: AppColors.expense.withOpacity(0.35),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppColors.expense,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Total Expense',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.expense,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  CurrencyFormatter.format(financeProv.groupExpense, symbol: currency),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Chart Card
                  GlassContainer(
                    borderRadius: 24,
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.pie_chart_rounded, size: 20, color: AppColors.primaryLight),
                            const SizedBox(width: 8),
                            const Text(
                              'Expense Distribution',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${sortedCategories.length} categories',
                                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 210,
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
                              sectionsSpace: 3,
                              centerSpaceRadius: 42,
                              sections: List.generate(sortedCategories.length, (i) {
                                final isTouched = i == _touchedIndex;
                                final radius = isTouched ? 65.0 : 54.0;
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
                                    shadows: [
                                      Shadow(color: Colors.black45, blurRadius: 4),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Category Breakdown List
                  Text(
                    'CATEGORY BREAKDOWN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...sortedCategories.asMap().entries.map((mapEntry) {
                    final index = mapEntry.key;
                    final entry = mapEntry.value;
                    final color = AppColors.groupPalette[index % AppColors.groupPalette.length];
                    final percent = totalExpense > 0 ? (entry.value / totalExpense) : 0.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassContainer(
                        borderRadius: 16,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withOpacity(0.5),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  entry.key,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                                ),
                                const Spacer(),
                                Text(
                                  CurrencyFormatter.format(entry.value, symbol: currency),
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 15),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: percent,
                                minHeight: 6,
                                backgroundColor: Colors.white.withOpacity(0.08),
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }
}

