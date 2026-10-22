import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/finance_group.dart';
import '../../models/group_member.dart';
import '../../providers/finance_provider.dart';

class CreateEditGroupDialog extends StatefulWidget {
  final FinanceGroup? editGroup;

  const CreateEditGroupDialog({super.key, this.editGroup});

  @override
  State<CreateEditGroupDialog> createState() => _CreateEditGroupDialogState();
}

class _CreateEditGroupDialogState extends State<CreateEditGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  final TextEditingController _partnerInputController = TextEditingController();

  late int _selectedIconCode;
  late int _selectedColorValue;
  final List<String> _partners = [];

  static const List<Map<String, dynamic>> availableIcons = [
    {'name': 'Home', 'icon': Icons.home_rounded, 'code': 0xe318},
    {'name': 'Friends', 'icon': Icons.group_rounded, 'code': 0xe2eb},
    {'name': 'Company', 'icon': Icons.business_center_rounded, 'code': 0xe11e},
    {'name': 'Milk/Dairy', 'icon': Icons.local_drink_rounded, 'code': 0xe3c0},
    {'name': 'Groceries', 'icon': Icons.shopping_basket_rounded, 'code': 0xe59c},
    {'name': 'Travel', 'icon': Icons.flight_takeoff_rounded, 'code': 0xe2a2},
    {'name': 'Car', 'icon': Icons.directions_car_rounded, 'code': 0xe1d7},
    {'name': 'Food', 'icon': Icons.restaurant_rounded, 'code': 0xe532},
    {'name': 'Savings', 'icon': Icons.savings_rounded, 'code': 0xe556},
    {'name': 'Party', 'icon': Icons.celebration_rounded, 'code': 0xe14f},
  ];

  static const List<String> partnerSuggestions = [
    'Mom',
    'Dad',
    'Partner',
    'Brother',
    'Sister',
    'Roommate',
    'Friend',
    'Colleague',
    'Driver',
    'Milkman',
    'Landlord',
  ];

  @override
  void initState() {
    super.initState();
    final edit = widget.editGroup;
    _nameController = TextEditingController(text: edit?.name ?? '');
    _descController = TextEditingController(text: edit?.description ?? '');

    _selectedIconCode = edit?.iconCode ?? availableIcons.first['code'] as int;
    _selectedColorValue = edit?.colorValue ?? AppColors.groupPalette.first.value;

    if (edit != null) {
      for (final m in edit.members) {
        if (!_partners.contains(m.name)) {
          _partners.add(m.name);
        }
      }
    } else {
      _partners.add('Me');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _partnerInputController.dispose();
    super.dispose();
  }

  void _addPartnerFromInput() {
    final text = _partnerInputController.text.trim();
    if (text.isEmpty) return;

    // Support comma-separated additions e.g. "Rahul, Amit, Priya"
    final names = text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
    setState(() {
      for (final name in names) {
        if (!_partners.any((p) => p.toLowerCase() == name.toLowerCase())) {
          _partners.add(name);
        }
      }
      _partnerInputController.clear();
    });
  }

  void _addSuggestedPartner(String suggestion) {
    if (!_partners.any((p) => p.toLowerCase() == suggestion.toLowerCase())) {
      setState(() {
        _partners.add(suggestion);
      });
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final financeProv = Provider.of<FinanceProvider>(context, listen: false);

    if (widget.editGroup != null) {
      // Synchronize members while preserving owner & existing member IDs
      final existingMembers = widget.editGroup!.members;
      final List<GroupMember> updatedMembers = [];

      for (final name in _partners) {
        final found = existingMembers.where((m) => m.name.toLowerCase() == name.toLowerCase());
        if (found.isNotEmpty) {
          updatedMembers.add(found.first);
        } else {
          updatedMembers.add(GroupMember(
            id: 'member_${DateTime.now().millisecondsSinceEpoch}_${name.hashCode.abs()}',
            name: name,
            email: '',
            isOwner: false,
          ));
        }
      }

      final updated = widget.editGroup!.copyWith(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        iconCode: _selectedIconCode,
        colorValue: _selectedColorValue,
        members: updatedMembers,
      );
      await financeProv.updateGroup(updated);
    } else {
      final additionalMembers = _partners.where((p) => p != 'Me').toList();

      await financeProv.createGroup(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        iconCode: _selectedIconCode,
        colorValue: _selectedColorValue,
        initialMemberNames: additionalMembers,
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.editGroup != null ? 'Edit Finance Group' : 'New Finance Group',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Group Name
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Group Name',
                            hintText: 'e.g. Family, College Friends, Flat Rent, Milk Daily',
                            prefixIcon: Icon(Icons.label_outline_rounded),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Please enter group name';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Description
                        TextFormField(
                          controller: _descController,
                          decoration: const InputDecoration(
                            labelText: 'Description (Optional)',
                            hintText: 'e.g. Household bills, grocery splits, dairy deliveries',
                            prefixIcon: Icon(Icons.info_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // PARTNERS / MEMBERS SECTION
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? AppColors.darkBg
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.people_rounded, size: 18, color: AppColors.accent),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Group Partners & Members (${_partners.length})',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accent),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Add Partner Input + Button
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _partnerInputController,
                                      decoration: InputDecoration(
                                        hintText: 'Type name (e.g. Rahul, Priya)',
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        fillColor: Theme.of(context).cardColor,
                                      ),
                                      onSubmitted: (_) => _addPartnerFromInput(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: _addPartnerFromInput,
                                    icon: const Icon(Icons.person_add_rounded, size: 16),
                                    label: const Text('Add'),
                                    style: ElevatedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Quick suggestions
                              const Text('Quick Add Suggestions:', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: partnerSuggestions.map((s) {
                                  final isAdded = _partners.any((p) => p.toLowerCase() == s.toLowerCase());
                                  return ActionChip(
                                    label: Text(
                                      '+ $s',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isAdded ? Colors.grey : AppColors.primary,
                                        fontWeight: isAdded ? FontWeight.normal : FontWeight.bold,
                                      ),
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: isAdded ? Colors.grey.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                                    side: BorderSide(color: isAdded ? Colors.transparent : AppColors.primary.withOpacity(0.3)),
                                    onPressed: isAdded ? null : () => _addSuggestedPartner(s),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),

                              // Current Partners Chips
                              const Text('Current Partners in this Group:', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _partners.map((partner) {
                                  final isMe = partner.toLowerCase() == 'me';
                                  return Chip(
                                    avatar: CircleAvatar(
                                      radius: 10,
                                      backgroundColor: AppColors.primary,
                                      child: Text(
                                        partner.isNotEmpty ? partner[0].toUpperCase() : '?',
                                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    label: Text(
                                      partner,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    onDeleted: isMe
                                        ? null
                                        : () {
                                            setState(() {
                                              _partners.remove(partner);
                                            });
                                          },
                                    deleteIconColor: Colors.grey,
                                    backgroundColor: Theme.of(context).cardColor,
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Icon Picker
                        const Text('Select Icon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 48,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: availableIcons.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final item = availableIcons[index];
                              final code = item['code'] as int;
                              final isSelected = code == _selectedIconCode;

                              return InkWell(
                                onTap: () => setState(() => _selectedIconCode = code),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 48,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Color(_selectedColorValue).withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                                    border: Border.all(
                                      color: isSelected ? Color(_selectedColorValue) : Colors.transparent,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    item['icon'] as IconData,
                                    color: isSelected ? Color(_selectedColorValue) : Colors.grey,
                                    size: 24,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Color Palette Picker
                        const Text('Select Theme Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: AppColors.groupPalette.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final color = AppColors.groupPalette[index];
                              final isSelected = color.value == _selectedColorValue;

                              return GestureDetector(
                                onTap: () => setState(() => _selectedColorValue = color.value),
                                child: Container(
                                  width: 38,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? Colors.white : Colors.transparent,
                                      width: 3,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: color.withOpacity(0.5),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, size: 20, color: Colors.white)
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(_selectedColorValue),
                      ),
                      child: Text(widget.editGroup != null ? 'Update Circle' : 'Create Circle'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
