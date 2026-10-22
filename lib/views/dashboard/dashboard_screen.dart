import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/ambient_background.dart';
import '../../core/widgets/glass_container.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: _currentNavIndex == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_currentNavIndex != 0) {
          setState(() => _currentNavIndex = 0);
        }
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _currentNavIndex,
          children: [
            _buildDashboardHome(context, financeProv, syncProv, activeGroup, currency, recentTransactions, isDark),
            TransactionListScreen(onBackToDashboard: () => setState(() => _currentNavIndex = 0)),
            StatisticsScreen(onBackToDashboard: () => setState(() => _currentNavIndex = 0)),
            ManageGroupsScreen(onBackToDashboard: () => setState(() => _currentNavIndex = 0)),
          ],
        ),
        bottomNavigationBar: _buildGlassNavigationBar(isDark),
      ),
    );
  }

  Widget _buildGlassNavigationBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.5) : AppColors.glassLightShadow,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.45) : Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.16 : 0.65),
                width: 1.2,
              ),
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              height: 64,
              selectedIndex: _currentNavIndex,
              onDestinationSelected: (idx) {
                setState(() => _currentNavIndex = idx);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined, size: 22),
                  selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary, size: 24),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined, size: 22),
                  selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 24),
                  label: 'Transactions',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined, size: 22),
                  selectedIcon: Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 24),
                  label: 'Analytics',
                ),
                NavigationDestination(
                  icon: Icon(Icons.folder_shared_outlined, size: 22),
                  selectedIcon: Icon(Icons.folder_shared_rounded, color: AppColors.primary, size: 24),
                  label: 'Circles',
                ),
              ],
            ),
          ),
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
    bool isDark,
  ) {
    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              // Custom App Logo Icon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Open Finance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                  Text(
                    activeGroup?.name != null ? 'Circle: ${activeGroup!.name}' : 'All Finances',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            // Frosted Glass Drive Sync Badge
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
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
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 100),
            children: [
              // 1. Group Selector Horizontal Bar
              GroupSelectorBar(onAddGroup: _openCreateGroupDialog),
              const SizedBox(height: 16),

              // 2. Glassmorphic Gradient Balance Card
              BalanceSummaryCard(
                onManageMembers: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GroupMembersScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),

              // 3. Quick Action Buttons (Glass Capsules with subtle glows)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // + Add Income
                    Expanded(
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        borderRadius: 18,
                        color: AppColors.income.withOpacity(isDark ? 0.22 : 0.85),
                        borderColor: AppColors.incomeGlow.withOpacity(0.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.income.withOpacity(0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        onTap: () => _openAddTransactionSheet(TransactionType.income),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_rounded, size: 18, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              '+ Income',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // - Add Expense
                    Expanded(
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        borderRadius: 18,
                        color: AppColors.expense.withOpacity(isDark ? 0.22 : 0.85),
                        borderColor: AppColors.expenseGlow.withOpacity(0.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.expense.withOpacity(0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        onTap: () => _openAddTransactionSheet(TransactionType.expense),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.remove_circle_rounded, size: 18, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              '- Expense',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Split Bill Capsule
                    GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      borderRadius: 18,
                      color: AppColors.accent.withOpacity(isDark ? 0.22 : 0.85),
                      borderColor: AppColors.accentLight.withOpacity(0.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.25),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      onTap: () => _openAddTransactionSheet(TransactionType.expense, isSplit: true),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.call_split_rounded, size: 18, color: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            'Split',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),

              // 4. Section Header: Recent Transactions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Activity',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _currentNavIndex = 1);
                      },
                      child: const Row(
                        children: [
                          Text('View All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_forward_rounded, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // 5. Recent Transactions List (Frosted Glass Items)
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(14),
                      borderRadius: 18,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => AddEditTransactionSheet(editItem: item),
                        );
                      },
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
                                Wrap(
                                  spacing: 6,
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
                                    if (item.paidByName != item.recordedByName) ...[
                                      Text(
                                        '(by ${item.recordedByName})',
                                        style: const TextStyle(fontSize: 10, color: AppColors.info, fontStyle: FontStyle.italic),
                                      ),
                                    ],
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
                  );
                }).toList(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
