import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/finance_group.dart';
import '../../models/transaction_item.dart';
import '../../providers/finance_provider.dart';
import '../../providers/sync_provider.dart';
import '../analytics/statistics_screen.dart';
import '../groups/create_edit_group_dialog.dart';
import '../groups/group_members_screen.dart';
import '../groups/manage_groups_screen.dart';
import '../settings/settings_screen.dart';
import '../transactions/add_edit_transaction_sheet.dart';
import '../transactions/transaction_list_screen.dart';
import 'widgets/balance_summary_card.dart';
import 'widgets/group_selector_bar.dart';
import 'widgets/sync_status_badge.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentNavIndex = 0;

  void _openAddTransactionSheet(TransactionType type, {bool isSplit = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditTransactionSheet(
        initialType: type,
        editItem: isSplit
            ? TransactionItem(
                id: '',
                groupId: '',
                amount: 0.0,
                type: TransactionType.expense,
                category: 'Food & Dining',
                date: DateTime.now(),
                paidByName: 'Me',
                recordedByName: 'Me',
                isSplit: true,
              )
            : null,
      ),
    );
  }

  void _openCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (_) => const CreateEditGroupDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final financeProv = context.watch<FinanceProvider>();
    final syncProv = context.watch<SyncProvider>();
    final activeGroup = financeProv.activeGroup;
    final currency = financeProv.currencySymbol;
    final transactions = financeProv.transactions;
    final recentTransactions = transactions.take(6).toList();

    return PopScope(
      canPop: _currentNavIndex == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_currentNavIndex != 0) {
          setState(() => _currentNavIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentNavIndex,
          children: [
            _buildDashboardHome(context, financeProv, syncProv, activeGroup, currency, recentTransactions),
            TransactionListScreen(onBackToDashboard: () => setState(() => _currentNavIndex = 0)),
            StatisticsScreen(onBackToDashboard: () => setState(() => _currentNavIndex = 0)),
            ManageGroupsScreen(onBackToDashboard: () => setState(() => _currentNavIndex = 0)),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentNavIndex,
          onDestinationSelected: (idx) {
            setState(() => _currentNavIndex = idx);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Transactions',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Analytics',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_shared_outlined),
              selectedIcon: Icon(Icons.folder_shared_rounded),
              label: 'Circles',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHome(
    BuildContext context,
    FinanceProvider financeProv,
    SyncProvider syncProv,
    FinanceGroup? activeGroup,
    String currency,
    List<TransactionItem> recentTransactions,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Open Finance Manager',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              activeGroup?.name != null ? 'Active Circle: ${activeGroup!.name}' : 'All Finances',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          // Google Drive Sync Badge
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SyncStatusBadge(
              onTap: () async {
                final success = await syncProv.triggerManualSync();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Google Drive synchronization complete!'
                            : (syncProv.message ?? 'Sync failed'),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings & Cloud Sync',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await financeProv.reloadAll();
          await syncProv.triggerManualSync();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            // 1. Group Selector Horizontal Bar
            GroupSelectorBar(onAddGroup: _openCreateGroupDialog),
            const SizedBox(height: 16),

            // 2. Beautiful Gradient Balance Card
            BalanceSummaryCard(
              onManageMembers: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const GroupMembersScreen()),
                );
              },
            ),
            const SizedBox(height: 18),

            // 3. Quick Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // + Add Income
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openAddTransactionSheet(TransactionType.income),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                      label: const Text('+ Income'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.income,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // - Add Expense
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openAddTransactionSheet(TransactionType.expense),
                      icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                      label: const Text('- Expense'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.expense,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Split Bill
                  ElevatedButton(
                    onPressed: () => _openAddTransactionSheet(TransactionType.expense, isSplit: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.call_split_rounded, size: 18),
                        SizedBox(width: 4),
                        Text('Split', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Recent Activity Section Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _currentNavIndex = 1);
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // 5. Recent Transactions List
            if (recentTransactions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No transactions in ${activeGroup?.name ?? 'this group'} yet',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap "+ Income" or "- Expense" above to record your first entry',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...recentTransactions.map((item) {
                final isIncome = item.type == TransactionType.income;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => AddEditTransactionSheet(editItem: item),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: (isIncome ? AppColors.income : AppColors.expense).withOpacity(0.12),
                              child: Icon(
                                isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                color: isIncome ? AppColors.income : AppColors.expense,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.category,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  if (item.note.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      item.note,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        DateFormatter.formatDate(item.date),
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                      ),
                                      const SizedBox(width: 6),
                                      Text('•', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Paid by ${item.paidByName}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                      if (item.paidByName != item.recordedByName) ...[
                                        const SizedBox(width: 4),
                                        Text(
                                          '(by ${item.recordedByName})',
                                          style: const TextStyle(fontSize: 10, color: AppColors.info, fontStyle: FontStyle.italic),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${item.type.sign}${CurrencyFormatter.format(item.amount, symbol: currency)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isIncome ? AppColors.income : AppColors.expense,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
