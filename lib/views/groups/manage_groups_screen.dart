import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/finance_group.dart';
import '../../providers/finance_provider.dart';
import 'create_edit_group_dialog.dart';
import 'group_members_screen.dart';

class ManageGroupsScreen extends StatelessWidget {
  final VoidCallback? onBackToDashboard;

  const ManageGroupsScreen({super.key, this.onBackToDashboard});

  void _openCreateGroupDialog(BuildContext context, [FinanceGroup? group]) {
    showDialog(
      context: context,
      builder: (_) => CreateEditGroupDialog(editGroup: group),
    );
  }

  @override
  Widget build(BuildContext context) {
    final financeProv = context.watch<FinanceProvider>();
    final groups = financeProv.groups;
    final activeGroup = financeProv.activeGroup;

    return Scaffold(
      appBar: AppBar(
        leading: onBackToDashboard != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back to Dashboard',
                onPressed: onBackToDashboard,
              )
            : null,
        title: const Text('Finance Circles & Groups'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner tip
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Organize your finances into separate books: Family, Friends, Business/Company, Milk & groceries. Each group maintains independent balances and members.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          ...groups.map((group) {
            final isSelected = activeGroup?.id == group.id;
            final color = Color(group.colorValue);

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: isSelected ? color : Theme.of(context).dividerColor.withOpacity(0.3),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  financeProv.selectGroup(group);
                },
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: color.withOpacity(0.2),
                        child: Icon(
                          IconData(group.iconCode, fontFamily: 'MaterialIcons'),
                          color: color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  group.name,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Active',
                                      style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (group.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                group.description,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                ...group.members.take(3).map((m) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        m.name,
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                                      ),
                                    )),
                                if (group.members.length > 3)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '+${group.members.length - 3}',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                financeProv.selectGroup(group);
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const GroupMembersScreen()),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.people_alt_rounded, size: 14, color: color),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Manage Partners (${group.members.length})',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded, size: 14, color: color),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded),
                        onSelected: (val) {
                          if (val == 'select') {
                            financeProv.selectGroup(group);
                          } else if (val == 'members') {
                            financeProv.selectGroup(group);
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const GroupMembersScreen()),
                            );
                          } else if (val == 'edit') {
                            _openCreateGroupDialog(context, group);
                          } else if (val == 'delete') {
                            _confirmDelete(context, group);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'select',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle_outline_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Set as Active'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'members',
                            child: Row(
                              children: [
                                Icon(Icons.people_rounded, size: 18),
                                SizedBox(width: 8),
                                Text('Members & Settlements'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Edit Group'),
                              ],
                            ),
                          ),
                          if (groups.length > 1)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.expense),
                                  SizedBox(width: 8),
                                  Text('Delete Group', style: TextStyle(color: AppColors.expense)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateGroupDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Finance Group'),
      ),
    );
  }

  void _confirmDelete(BuildContext context, FinanceGroup group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${group.name}"?'),
        content: const Text(
          'This will permanently delete this group and all associated transactions in it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () {
              Provider.of<FinanceProvider>(context, listen: false).deleteGroup(group.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
