import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/ambient_background.dart';
import '../../core/widgets/glass_container.dart';
import '../../models/transaction_item.dart';
import '../../providers/finance_provider.dart';
import 'add_edit_transaction_sheet.dart';

class TransactionListScreen extends StatefulWidget {
  final VoidCallback? onBackToDashboard;

  const TransactionListScreen({super.key, this.onBackToDashboard});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  String _filterType = 'all'; // 'all', 'income', 'expense'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openEditSheet(BuildContext context, TransactionItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditTransactionSheet(editItem: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final financeProv = context.watch<FinanceProvider>();
    final activeGroup = financeProv.activeGroup;
    final currency = financeProv.currencySymbol;
    final allTransactions = financeProv.transactions;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter by type
    var filtered = allTransactions.where((t) {
      if (_filterType == 'income') return t.type == TransactionType.income;
      if (_filterType == 'expense') return t.type == TransactionType.expense;
      return true;
    }).toList();

    // Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((t) {
        return t.category.toLowerCase().contains(q) ||
            t.note.toLowerCase().contains(q) ||
            t.paidByName.toLowerCase().contains(q) ||
            t.recordedByName.toLowerCase().contains(q);
      }).toList();
    }

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
            '${activeGroup?.name ?? 'Ledger'} • Transactions',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ),
        body: Column(
          children: [
            // Search Input (Glassmorphic)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                borderRadius: 18,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by note, category, or partner...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
            ),

            // Filter chips: All, Expenses (-), Income (+)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _filterType == 'all',
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: _filterType == 'all' ? Colors.white : null,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) => setState(() => _filterType = 'all'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('- Expenses'),
                    selected: _filterType == 'expense',
                    selectedColor: AppColors.expense,
                    labelStyle: TextStyle(
                      color: _filterType == 'expense' ? Colors.white : null,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) => setState(() => _filterType = 'expense'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('+ Income'),
                    selected: _filterType == 'income',
                    selectedColor: AppColors.income,
                    labelStyle: TextStyle(
                      color: _filterType == 'income' ? Colors.white : null,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) => setState(() => _filterType = 'income'),
                  ),
                  const Spacer(),
                  Text(
                    '${filtered.length} entries',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Transactions List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_rounded, size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'No transactions found',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          const Text('Tap + or - to add an entry', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final isIncome = item.type == TransactionType.income;

                        return Dismissible(
                          key: Key(item.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: AppColors.expense,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.delete_rounded, color: Colors.white),
                          ),
                          onDismissed: (_) {
                            financeProv.deleteTransaction(item.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Deleted "${item.category}"'),
                                action: SnackBarAction(
                                  label: 'Undo',
                                  onPressed: () {
                                    financeProv.addTransaction(
                                      amount: item.amount,
                                      type: item.type,
                                      category: item.category,
                                      note: item.note,
                                      date: item.date,
                                      paidByName: item.paidByName,
                                      recordedByName: item.recordedByName,
                                      isSplit: item.isSplit,
                                      splitWith: item.splitWith,
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GlassContainer(
                              padding: const EdgeInsets.all(14),
                              borderRadius: 18,
                              onTap: () => _openEditSheet(context, item),
                              child: Row(
                                children: [
                                  // Category Icon circle
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: (isIncome ? AppColors.income : AppColors.expense).withOpacity(0.16),
                                    child: Icon(
                                      isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                      color: isIncome ? AppColors.incomeGlow : AppColors.expenseGlow,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.category,
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                        ),
                                        if (item.note.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            item.note,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        const SizedBox(height: 4),

                                        // Attribution & Date
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 2,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              DateFormatter.formatDate(item.date),
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                            ),
                                            Text('•', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                            Text(
                                              'Paid: ${item.paidByName}',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                            if (item.paidByName != item.recordedByName)
                                              Text(
                                                '(by ${item.recordedByName})',
                                                style: const TextStyle(fontSize: 10, color: AppColors.info, fontStyle: FontStyle.italic),
                                              ),
                                            if (item.isSplit) ...[
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: AppColors.accent.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  'Split (${item.splitWith.length})',
                                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.accentLight),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Amount
                                  Text(
                                    '${item.type.sign}${CurrencyFormatter.format(item.amount, symbol: currency)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: isIncome ? AppColors.incomeGlow : AppColors.expenseGlow,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 70),
          child: FloatingActionButton.extended(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AddEditTransactionSheet(initialType: TransactionType.expense),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Entry', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
