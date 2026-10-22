import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/ambient_background.dart';
import '../../core/widgets/glass_container.dart';
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
        backgroundColor: const Color(0xFF131A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        title: const Text('Add Partners / Members', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter one or multiple partner names (separated by commas):',
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Partner Names',
                  hintText: 'e.g. Rahul, Priya, Mom, Amit',
                  prefixIcon: Icon(Icons.group_add_rounded, color: AppColors.accent),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 14),
              Text(
                'Quick Suggestions:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.7)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ['Mom', 'Dad', 'Partner', 'Brother', 'Roommate', 'Friend', 'Driver', 'Milkman'].map((s) {
                  return ActionChip(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.white.withOpacity(0.06),
                    side: BorderSide(color: Colors.white.withOpacity(0.12)),
                    label: Text('+ $s', style: const TextStyle(fontSize: 11, color: Colors.white)),
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
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.7))),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
      return const AmbientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: Text('No group selected', style: TextStyle(color: Colors.white))),
        ),
      );
    }

    final splitBalances = financeProv.calculateGroupSplitBalances();
    final groupColor = Color(group.colorValue);

    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('${group.name} • Members', style: const TextStyle(fontWeight: FontWeight.bold)),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Frosted Group Header Card
            GlassContainer(
              borderRadius: 22,
              tintColor: groupColor,
              opacity: 0.16,
              borderColor: groupColor.withOpacity(0.4),
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [groupColor, groupColor.withOpacity(0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: groupColor.withOpacity(0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      IconData(group.iconCode, fontFamily: 'MaterialIcons'),
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        if (group.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            group.description,
                            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: groupColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: groupColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            '${group.members.length} members in circle',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: groupColor.computeLuminance() < 0.4 ? Colors.white : groupColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.12),
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    icon: const Icon(Icons.person_add_rounded, color: Colors.white),
                    tooltip: 'Add Member',
                    onPressed: () => _showAddMemberDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Settlement / Split Balances Card
            GlassContainer(
              borderRadius: 22,
              padding: const EdgeInsets.all(18),
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
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
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
                        icon: const Icon(Icons.send_rounded, size: 14, color: AppColors.accent),
                        label: const Text('Share Summary', style: TextStyle(fontSize: 12, color: AppColors.accent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (splitBalances.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No expenses recorded yet in this group.',
                        style: TextStyle(color: Colors.white.withOpacity(0.6)),
                      ),
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
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: GlassContainer(
                          borderRadius: 14,
                          tintColor: statusColor,
                          opacity: 0.12,
                          borderColor: statusColor.withOpacity(0.28),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: statusColor.withOpacity(0.25),
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
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
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
            const SizedBox(height: 22),

            // Member List Section
            Text(
              'MEMBERS IN GROUP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 10),
            ...group.members.map((member) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.6),
                            ],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  member.name,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white),
                                ),
                                if (member.isOwner) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                                    ),
                                    child: const Text(
                                      'Owner',
                                      style: TextStyle(fontSize: 10, color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              member.email.isNotEmpty ? member.email : 'Local device member',
                              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                            ),
                          ],
                        ),
                      ),
                      if (!member.isOwner)
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded, color: Colors.white.withOpacity(0.5)),
                          onPressed: () {
                            financeProv.removeMemberFromActiveGroup(member.id);
                          },
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 20),

            // Invite link button
            GlassContainer(
              borderRadius: 16,
              tintColor: groupColor,
              opacity: 0.25,
              borderColor: groupColor.withOpacity(0.5),
              padding: EdgeInsets.zero,
              child: InkWell(
                onTap: () => ShareService.shareGroupInvite(group),
                borderRadius: BorderRadius.circular(16),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Invite More People to Share Expenses',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

