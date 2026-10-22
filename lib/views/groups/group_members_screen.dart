import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/finance_provider.dart';
import '../../services/drive/share_service.dart';

class GroupMembersScreen extends StatefulWidget {
  const GroupMembersScreen({super.key});

  @override
  State<GroupMembersScreen> createState() => _GroupMembersScreenState();
}

class _GroupMembersScreenState extends State<GroupMembersScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  void _showAddMemberDialog(BuildContext context) {
    _nameController.clear();
    _emailController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Partners / Members'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter one or multiple partner names (separated by commas):',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Partner Names',
                  hintText: 'e.g. Rahul, Priya, Mom, Amit',
                  prefixIcon: Icon(Icons.group_add_rounded),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 10),
              const Text('Quick Suggestions:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: ['Mom', 'Dad', 'Partner', 'Brother', 'Roommate', 'Friend', 'Driver', 'Milkman'].map((s) {
                  return ActionChip(
                    visualDensity: VisualDensity.compact,
                    label: Text('+ $s', style: const TextStyle(fontSize: 11)),
                    onPressed: () {
                      final current = _nameController.text.trim();
                      if (current.isEmpty) {
                        _nameController.text = s;
                      } else {
                        _nameController.text = '$current, $s';
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Google Email (Optional for Drive invite)',
                  hintText: 'e.g., member@gmail.com',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final rawNames = _nameController.text.trim();
              final email = _emailController.text.trim();
              if (rawNames.isNotEmpty) {
                final names = rawNames.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                final financeProv = Provider.of<FinanceProvider>(context, listen: false);

                if (names.length == 1) {
                  await financeProv.addMemberToActiveGroup(names.first, email: email);
                } else {
                  await financeProv.addMultipleMembersToActiveGroup(names);
                }

                if (email.isNotEmpty) {
                  ShareService.grantDriveAccessToEmail(email);
                }

                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add Partners'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final financeProv = context.watch<FinanceProvider>();
    final group = financeProv.activeGroup;
    final currency = financeProv.currencySymbol;

    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group Members')),
        body: const Center(child: Text('No group selected')),
      );
    }

    final splitBalances = financeProv.calculateGroupSplitBalances();
    final groupColor = Color(group.colorValue);

    return Scaffold(
      appBar: AppBar(
        title: Text('${group.name} • Members'),
        actions: [
          IconButton(
            tooltip: 'Invite via WhatsApp / Share',
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              ShareService.shareGroupInvite(group);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Group Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: groupColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: groupColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: groupColor,
                  child: Icon(
                    IconData(group.iconCode, fontFamily: 'MaterialIcons'),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (group.description.isNotEmpty)
                        Text(
                          group.description,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        '${group.members.length} members in this circle',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: groupColor,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.person_add_rounded),
                  tooltip: 'Add Member',
                  onPressed: () => _showAddMemberDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Settlement / Split Balances Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.balance_rounded, size: 20, color: AppColors.accent),
                        SizedBox(width: 8),
                        Text(
                          'Who Owes Who (Settlements)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () {
                        ShareService.shareGroupSummary(
                          group: group,
                          totalExpense: financeProv.groupExpense,
                          totalIncome: financeProv.groupIncome,
                          memberBalances: splitBalances,
                          currencySymbol: currency,
                        );
                      },
                      icon: const Icon(Icons.send_rounded, size: 14),
                      label: const Text('Share Summary', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (splitBalances.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No expenses recorded yet in this group.', style: TextStyle(color: Colors.grey)),
                  )
                else
                  ...splitBalances.entries.map((entry) {
                    final memberName = entry.key;
                    final balance = entry.value;
                    final isOwed = balance > 0.01;
                    final owes = balance < -0.01;

                    Color statusColor = Colors.grey;
                    String statusText = 'Settled up';
                    if (isOwed) {
                      statusColor = AppColors.income;
                      statusText = 'Should receive ${CurrencyFormatter.format(balance, symbol: currency)}';
                    } else if (owes) {
                      statusColor = AppColors.expense;
                      statusText = 'Owes ${CurrencyFormatter.format(balance.abs(), symbol: currency)}';
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: statusColor.withOpacity(0.2),
                              child: Text(
                                memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              memberName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const Spacer(),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Member List Section
          const Text(
            'Members in Group',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ...group.members.map((member) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                title: Row(
                  children: [
                    Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (member.isOwner) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Owner', style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  member.email.isNotEmpty ? member.email : 'Local device member',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: member.isOwner
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
                        onPressed: () {
                          financeProv.removeMemberFromActiveGroup(member.id);
                        },
                      ),
              ),
            );
          }).toList(),
          const SizedBox(height: 24),

          // Invite link button
          ElevatedButton.icon(
            onPressed: () => ShareService.shareGroupInvite(group),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Invite More People to Share Expenses'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: groupColor,
            ),
          ),
        ],
      ),
    );
  }
}
