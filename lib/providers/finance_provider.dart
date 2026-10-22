import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/finance_group.dart';
import '../models/group_member.dart';
import '../models/transaction_item.dart';
import '../services/database/database_helper.dart';
import '../services/drive/drive_sync_service.dart';
import '../services/preferences_service.dart';

class FinanceProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  List<FinanceGroup> _groups = [];
  FinanceGroup? _activeGroup;
  List<TransactionItem> _transactions = [];
  bool _isLoading = false;

  String _currencySymbol = '₹';

  // Overall metrics across all groups
  double _overallIncome = 0.0;
  double _overallExpense = 0.0;

  // Active group metrics
  double _groupIncome = 0.0;
  double _groupExpense = 0.0;

  // Getters
  List<FinanceGroup> get groups => _groups;
  FinanceGroup? get activeGroup => _activeGroup;
  List<TransactionItem> get transactions => _transactions;
  bool get isLoading => _isLoading;
  String get currencySymbol => _currencySymbol;

  double get overallIncome => _overallIncome;
  double get overallExpense => _overallExpense;
  double get overallBalance => _overallIncome - _overallExpense;

  double get groupIncome => _groupIncome;
  double get groupExpense => _groupExpense;
  double get groupBalance => _groupIncome - _groupExpense;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _currencySymbol = PreferencesService.getCurrencySymbol();
    await _loadGroups();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadGroups() async {
    _groups = await _db.getAllGroups();

    if (_groups.isNotEmpty) {
      final savedActiveId = PreferencesService.getActiveGroupId();
      final found = _groups.firstWhere(
        (g) => g.id == savedActiveId,
        orElse: () => _groups.first,
      );
      _activeGroup = found;
      await _loadTransactionsForActiveGroup();
    }

    await _calculateOverallSummary();
  }

  Future<void> selectGroup(FinanceGroup group) async {
    _activeGroup = group;
    await PreferencesService.setActiveGroupId(group.id);
    await _loadTransactionsForActiveGroup();
    notifyListeners();
  }

  Future<void> _loadTransactionsForActiveGroup() async {
    if (_activeGroup == null) {
      _transactions = [];
      _groupIncome = 0.0;
      _groupExpense = 0.0;
      return;
    }

    _transactions = await _db.getTransactionsForGroup(_activeGroup!.id);

    double inc = 0.0;
    double exp = 0.0;
    for (final tx in _transactions) {
      if (tx.type == TransactionType.income) {
        inc += tx.amount;
      } else {
        exp += tx.amount;
      }
    }
    _groupIncome = inc;
    _groupExpense = exp;
  }

  Future<void> _calculateOverallSummary() async {
    final summary = await _db.getOverallSummary();
    _overallIncome = summary['income'] ?? 0.0;
    _overallExpense = summary['expense'] ?? 0.0;
  }

  // --- Group Actions ---

  Future<FinanceGroup> createGroup({
    required String name,
    required String description,
    required int iconCode,
    required int colorValue,
    List<String> initialMemberNames = const [],
  }) async {
    final now = DateTime.now();
    final currentUserName = PreferencesService.getUserName() ?? 'Me';
    final currentUserEmail = PreferencesService.getUserEmail() ?? '';

    final members = [
      GroupMember(
        id: 'member_${_uuid.v4().substring(0, 8)}',
        name: currentUserName,
        email: currentUserEmail,
        isOwner: true,
        createdAt: now,
      ),
    ];

    for (final name in initialMemberNames) {
      if (name.trim().isNotEmpty && name.trim() != currentUserName) {
        members.add(GroupMember(
          id: 'member_${_uuid.v4().substring(0, 8)}',
          name: name.trim(),
          email: '',
          isOwner: false,
          createdAt: now,
        ));
      }
    }

    final newGroup = FinanceGroup(
      id: 'grp_${_uuid.v4().substring(0, 8)}',
      name: name,
      description: description,
      iconCode: iconCode,
      colorValue: colorValue,
      members: members,
      createdAt: now,
      updatedAt: now,
    );

    await _db.insertGroup(newGroup);
    _groups.add(newGroup);
    await selectGroup(newGroup);

    // Auto Google Drive sync trigger
    DriveSyncService.instance.notifyDataChanged();
    notifyListeners();
    return newGroup;
  }

  Future<void> updateGroup(FinanceGroup group) async {
    await _db.updateGroup(group);
    final index = _groups.indexWhere((g) => g.id == group.id);
    if (index != -1) {
      _groups[index] = group;
      if (_activeGroup?.id == group.id) {
        _activeGroup = group;
      }
    }

    // Auto Google Drive sync trigger
    DriveSyncService.instance.notifyDataChanged();
    notifyListeners();
  }

  Future<void> deleteGroup(String groupId) async {
    await _db.deleteGroup(groupId);
    _groups.removeWhere((g) => g.id == groupId);

    if (_activeGroup?.id == groupId) {
      _activeGroup = _groups.isNotEmpty ? _groups.first : null;
      if (_activeGroup != null) {
        await PreferencesService.setActiveGroupId(_activeGroup!.id);
        await _loadTransactionsForActiveGroup();
      }
    }

    await _calculateOverallSummary();

    // Auto Google Drive sync trigger
    DriveSyncService.instance.notifyDataChanged();
    notifyListeners();
  }

  Future<void> addMemberToActiveGroup(String name, {String email = ''}) async {
    if (_activeGroup == null) return;

    final newMember = GroupMember(
      id: 'member_${_uuid.v4().substring(0, 8)}',
      name: name.trim(),
      email: email.trim(),
      isOwner: false,
    );

    final updatedMembers = List<GroupMember>.from(_activeGroup!.members)..add(newMember);
    final updatedGroup = _activeGroup!.copyWith(
      members: updatedMembers,
      updatedAt: DateTime.now(),
    );

    await updateGroup(updatedGroup);
  }

  Future<void> addMultipleMembersToActiveGroup(List<String> names) async {
    if (_activeGroup == null) return;

    final updatedMembers = List<GroupMember>.from(_activeGroup!.members);
    final now = DateTime.now();

    for (final name in names) {
      final trimmed = name.trim();
      if (trimmed.isNotEmpty && !updatedMembers.any((m) => m.name.toLowerCase() == trimmed.toLowerCase())) {
        updatedMembers.add(GroupMember(
          id: 'member_${_uuid.v4().substring(0, 8)}',
          name: trimmed,
          email: '',
          isOwner: false,
          createdAt: now,
        ));
      }
    }

    final updatedGroup = _activeGroup!.copyWith(
      members: updatedMembers,
      updatedAt: DateTime.now(),
    );

    await updateGroup(updatedGroup);
  }

  Future<void> removeMemberFromActiveGroup(String memberId) async {
    if (_activeGroup == null) return;

    final updatedMembers = _activeGroup!.members.where((m) => m.id != memberId).toList();
    final updatedGroup = _activeGroup!.copyWith(
      members: updatedMembers,
      updatedAt: DateTime.now(),
    );

    await updateGroup(updatedGroup);
  }

  // --- Transaction Actions ---

  Future<void> addTransaction({
    required double amount,
    required TransactionType type,
    required String category,
    String note = '',
    DateTime? date,
    required String paidByName,
    String? paidById,
    required String recordedByName,
    String? recordedById,
    List<String> splitWith = const [],
    Map<String, double> splitShares = const {},
    bool isSplit = false,
  }) async {
    if (_activeGroup == null) return;

    final item = TransactionItem(
      id: 'tx_${_uuid.v4()}',
      groupId: _activeGroup!.id,
      amount: amount,
      type: type,
      category: category,
      note: note,
      date: date ?? DateTime.now(),
      paidByName: paidByName,
      paidById: paidById,
      recordedByName: recordedByName,
      recordedById: recordedById,
      splitWith: splitWith,
      splitShares: splitShares,
      isSplit: isSplit,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _db.insertTransaction(item);
    _transactions.insert(0, item);

    if (type == TransactionType.income) {
      _groupIncome += amount;
      _overallIncome += amount;
    } else {
      _groupExpense += amount;
      _overallExpense += amount;
    }

    // Auto Google Drive sync trigger
    DriveSyncService.instance.notifyDataChanged();
    notifyListeners();
  }

  Future<void> updateTransaction(TransactionItem item) async {
    await _db.updateTransaction(item.copyWith(updatedAt: DateTime.now()));
    await _loadTransactionsForActiveGroup();
    await _calculateOverallSummary();

    // Auto Google Drive sync trigger
    DriveSyncService.instance.notifyDataChanged();
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    await _db.deleteTransaction(id);
    _transactions.removeWhere((t) => t.id == id);
    await _loadTransactionsForActiveGroup();
    await _calculateOverallSummary();

    // Auto Google Drive sync trigger
    DriveSyncService.instance.notifyDataChanged();
    notifyListeners();
  }

  // --- Split Balances Calculation (Who Owes Whom) ---
  /// Returns a map of member name -> net balance.
  /// Positive value: member is owed money (they paid more than their share).
  /// Negative value: member owes money (their share exceeds what they paid).
  Map<String, double> calculateGroupSplitBalances() {
    if (_activeGroup == null) return {};

    final Map<String, double> balances = {};
    for (final member in _activeGroup!.members) {
      balances[member.name] = 0.0;
    }

    for (final tx in _transactions) {
      // Splits only apply to expense transactions
      if (tx.type != TransactionType.expense) continue;

      final payer = tx.paidByName;
      balances[payer] = (balances[payer] ?? 0.0) + tx.amount;

      // Determine who shared this expense
      List<String> participants = tx.isSplit && tx.splitWith.isNotEmpty
          ? tx.splitWith
          : [payer];

      if (tx.splitShares.isNotEmpty) {
        // Custom amounts
        tx.splitShares.forEach((member, shareAmount) {
          balances[member] = (balances[member] ?? 0.0) - shareAmount;
        });
      } else {
        // Equal split among participants
        final perPerson = tx.amount / participants.length;
        for (final p in participants) {
          balances[p] = (balances[p] ?? 0.0) - perPerson;
        }
      }
    }

    return balances;
  }

  void setCurrency(String symbol) {
    _currencySymbol = symbol;
    PreferencesService.setCurrencySymbol(symbol);
    notifyListeners();
  }

  Future<void> reloadAll() async {
    await _loadGroups();
    notifyListeners();
  }
}
