import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/finance_provider.dart';

class GroupSelectorBar extends StatelessWidget {
  final VoidCallback onAddGroup;

  const GroupSelectorBar({
    super.key,
    required this.onAddGroup,
  });

  @override
  Widget build(BuildContext context) {
    final financeProv = context.watch<FinanceProvider>();
    final groups = financeProv.groups;
    final activeGroup = financeProv.activeGroup;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: groups.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == groups.length) {
            // "+ New Group" button
            return ActionChip(
              avatar: const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
              label: const Text('Add Group'),
              backgroundColor: Theme.of(context).cardColor,
              side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              onPressed: onAddGroup,
            );
          }

          final group = groups[index];
          final isSelected = activeGroup?.id == group.id;
          final groupColor = Color(group.colorValue);

          return FilterChip(
            selected: isSelected,
            avatar: CircleAvatar(
              radius: 12,
              backgroundColor: isSelected ? Colors.white.withOpacity(0.2) : groupColor.withOpacity(0.15),
              child: Icon(
                IconData(group.iconCode, fontFamily: 'MaterialIcons'),
                size: 14,
                color: isSelected ? Colors.white : groupColor,
              ),
            ),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  group.name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
                if (group.members.length > 1) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withOpacity(0.25) : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${group.members.length}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            selectedColor: groupColor,
            showCheckmark: false,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: isSelected ? groupColor : Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            onSelected: (_) => financeProv.selectGroup(group),
          );
        },
      ),
    );
  }
}
