import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/transaction_item.dart';
import '../../providers/finance_provider.dart';
import '../../providers/auth_provider.dart';

class AddEditTransactionSheet extends StatefulWidget {
  final TransactionItem? editItem;
  final TransactionType initialType;

  const AddEditTransactionSheet({
    super.key,
    this.editItem,
    this.initialType = TransactionType.expense,
  });

  @override
  State<AddEditTransactionSheet> createState() => _AddEditTransactionSheetState();
}

class _AddEditTransactionSheetState extends State<AddEditTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  late TransactionType _type;
  late String _selectedCategory;
  late DateTime _selectedDate;
  late String _paidByName;
  late String _recordedByName;
  late bool _isSplit;
  late List<String> _splitWith;

  @override
  void initState() {
    super.initState();
    final edit = widget.editItem;
    _type = edit?.type ?? widget.initialType;
    _amountController = TextEditingController(
      text: edit != null ? edit.amount.toStringAsFixed(edit.amount.truncateToDouble() == edit.amount ? 0 : 2) : '',
    );
    _noteController = TextEditingController(text: edit?.note ?? '');
    _selectedCategory = edit?.category ?? (_type.isExpense ? 'Food & Dining' : 'Salary');
    _selectedDate = edit?.date ?? DateTime.now();

    final financeProv = Provider.of<FinanceProvider>(context, listen: false);
    final authProv = Provider.of<AuthProvider>(context, listen: false);

    final currentUserName = authProv.userName ?? 'Me';
    _recordedByName = edit?.recordedByName ?? currentUserName;
    _paidByName = edit?.paidByName ?? currentUserName;

    _isSplit = edit?.isSplit ?? false;
    _splitWith = edit != null
        ? List<String>.from(edit.splitWith)
        : (financeProv.activeGroup?.members.map((m) => m.name).toList() ?? [_paidByName]);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than 0')),
      );
      return;
    }

    final financeProv = Provider.of<FinanceProvider>(context, listen: false);

    if (widget.editItem != null) {
      final updated = widget.editItem!.copyWith(
        amount: amount,
        type: _type,
        category: _selectedCategory,
        note: _noteController.text.trim(),
        date: _selectedDate,
        paidByName: _paidByName,
        recordedByName: _recordedByName,
        isSplit: _isSplit && _type.isExpense,
        splitWith: _isSplit && _type.isExpense ? _splitWith : [],
      );
      await financeProv.updateTransaction(updated);
    } else {
      await financeProv.addTransaction(
        amount: amount,
        type: _type,
        category: _selectedCategory,
        note: _noteController.text.trim(),
        date: _selectedDate,
        paidByName: _paidByName,
        recordedByName: _recordedByName,
        isSplit: _isSplit && _type.isExpense,
        splitWith: _isSplit && _type.isExpense ? _splitWith : [],
      );
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final financeProv = context.watch<FinanceProvider>();
    final activeGroup = financeProv.activeGroup;
    final members = activeGroup?.members.map((m) => m.name).toList() ?? ['Me'];
    final currency = financeProv.currencySymbol;

    // Ensure paidBy & recordedBy are in members list
    if (!members.contains(_paidByName) && members.isNotEmpty) {
      _paidByName = members.first;
    }
    if (!members.contains(_recordedByName) && members.isNotEmpty) {
      _recordedByName = members.first;
    }

    final categories = _type.isExpense
        ? AppConstants.defaultExpenseCategories
        : AppConstants.defaultIncomeCategories;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title & Group Name
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.editItem != null ? 'Edit Transaction' : 'New Transaction',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (activeGroup != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(activeGroup.colorValue).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              IconData(activeGroup.iconCode, fontFamily: 'MaterialIcons'),
                              size: 14,
                              color: Color(activeGroup.colorValue),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              activeGroup.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(activeGroup.colorValue),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Segmented Type Switcher (- Expense / + Income)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkBg
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _type = TransactionType.expense;
                              _selectedCategory = AppConstants.defaultExpenseCategories.first['name'] as String;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _type.isExpense ? AppColors.expense : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _type.isExpense
                                  ? [
                                      BoxShadow(
                                        color: AppColors.expense.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.remove_circle_outline_rounded,
                                  size: 18,
                                  color: _type.isExpense ? Colors.white : AppColors.expense,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '- Expense',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _type.isExpense ? Colors.white : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _type = TransactionType.income;
                              _selectedCategory = AppConstants.defaultIncomeCategories.first['name'] as String;
                              _isSplit = false;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _type.isIncome ? AppColors.income : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _type.isIncome
                                  ? [
                                      BoxShadow(
                                        color: AppColors.income.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 18,
                                  color: _type.isIncome ? Colors.white : AppColors.income,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '+ Income',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _type.isIncome ? Colors.white : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Amount Input Field
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _type.isIncome ? AppColors.income : AppColors.expense,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: Text(
                        '$currency ',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: _type.isIncome ? AppColors.income : AppColors.expense,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    hintText: '0.00',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Enter amount';
                    if (double.tryParse(value) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category Selector Chips
                Text(
                  'Category',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = cat['name'] == _selectedCategory;
                      return ChoiceChip(
                        selected: isSelected,
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat['icon'] as IconData,
                              size: 16,
                              color: isSelected ? Colors.white : Color(cat['color'] as int),
                            ),
                            const SizedBox(width: 6),
                            Text(cat['name'] as String),
                          ],
                        ),
                        selectedColor: _type.isIncome ? AppColors.income : AppColors.primary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = cat['name'] as String;
                            });
                          }
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Note / Description
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.notes_rounded, size: 20),
                    labelText: 'Note / Description',
                    hintText: 'e.g., Dinner with team, Milk bill for Oct, Salary',
                  ),
                ),
                const SizedBox(height: 16),

                // Date & Time Picker Row
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          _selectedDate.hour,
                          _selectedDate.minute,
                        );
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withOpacity(0.4),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('EEEE, d MMM yyyy').format(_selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down_rounded),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Dual Attribution Section: "Who Paid" vs "Recorded On Behalf Of"
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkBg
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.attribution_rounded, size: 18, color: AppColors.accent),
                          const SizedBox(width: 6),
                          Text(
                            'Member Attribution',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Who Paid Dropdown
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Who Paid?',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: members.contains(_paidByName) ? _paidByName : (members.isNotEmpty ? members.first : 'Me'),
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    fillColor: Theme.of(context).cardColor,
                                  ),
                                  items: members.map((m) {
                                    return DropdownMenuItem(
                                      value: m,
                                      child: Text(m, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _paidByName = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Who Entered Data (Recorded By / On Behalf Of)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Entered By (Recorder)',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  value: members.contains(_recordedByName) ? _recordedByName : (members.isNotEmpty ? members.first : 'Me'),
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    fillColor: Theme.of(context).cardColor,
                                  ),
                                  items: members.map((m) {
                                    return DropdownMenuItem(
                                      value: m,
                                      child: Text(m, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _recordedByName = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_paidByName != _recordedByName)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.info),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '$_recordedByName is recording this transaction on behalf of $_paidByName',
                                  style: const TextStyle(fontSize: 11, color: AppColors.info),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Split Options (Only if Expense)
                if (_type.isExpense && members.length > 1) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Split among group members', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      _isSplit ? 'Splitting equally among selected members' : 'Paid for whole group / individual',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: _isSplit,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _isSplit = val;
                        if (val && _splitWith.isEmpty) {
                          _splitWith = List<String>.from(members);
                        }
                      });
                    },
                  ),

                  if (_isSplit) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: members.map((member) {
                        final isIncluded = _splitWith.contains(member);
                        return FilterChip(
                          label: Text(member),
                          selected: isIncluded,
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          checkmarkColor: AppColors.primary,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _splitWith.add(member);
                              } else {
                                if (_splitWith.length > 1) {
                                  _splitWith.remove(member);
                                }
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    if (_splitWith.isNotEmpty && double.tryParse(_amountController.text) != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Each person owes: $currency ${(double.parse(_amountController.text) / _splitWith.length).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                ],

                // Save Button
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _type.isIncome ? AppColors.income : AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    widget.editItem != null ? 'Update Transaction' : 'Save Transaction',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
