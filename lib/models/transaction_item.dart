import 'dart:convert';

enum TransactionType {
  income,
  expense;

  String get sign => this == TransactionType.income ? '+' : '-';
  bool get isIncome => this == TransactionType.income;
  bool get isExpense => this == TransactionType.expense;
}

class TransactionItem {
  final String id;
  final String groupId;
  final double amount;
  final TransactionType type;
  final String category;
  final String note;
  final DateTime date;
  
  // Dual attribution:
  // 1. Who actually paid the expense (e.g. Alice paid)
  final String paidByName;
  final String? paidById;
  
  // 2. Who entered this record into the app (e.g. John recorded on behalf of Alice)
  final String recordedByName;
  final String? recordedById;
  
  // Split details:
  final List<String> splitWith; // List of member names or IDs
  final Map<String, double> splitShares; // Specific amount per member if custom
  final bool isSplit;

  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  TransactionItem({
    required this.id,
    required this.groupId,
    required this.amount,
    required this.type,
    required this.category,
    this.note = '',
    required this.date,
    required this.paidByName,
    this.paidById,
    required this.recordedByName,
    this.recordedById,
    List<String>? splitWith,
    Map<String, double>? splitShares,
    this.isSplit = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
  })  : splitWith = splitWith ?? [],
        splitShares = splitShares ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'amount': amount,
      'type': type.name,
      'category': category,
      'note': note,
      'date': date.toIso8601String(),
      'paidByName': paidByName,
      'paidById': paidById,
      'recordedByName': recordedByName,
      'recordedById': recordedById,
      'splitWithJson': jsonEncode(splitWith),
      'splitSharesJson': jsonEncode(splitShares),
      'isSplit': isSplit ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    List<String> parsedSplitWith = [];
    if (map['splitWithJson'] != null && (map['splitWithJson'] as String).isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(map['splitWithJson'] as String);
        parsedSplitWith = list.map((e) => e.toString()).toList();
      } catch (_) {}
    } else if (map['splitWith'] != null && map['splitWith'] is List) {
      parsedSplitWith = (map['splitWith'] as List).map((e) => e.toString()).toList();
    }

    Map<String, double> parsedShares = {};
    if (map['splitSharesJson'] != null && (map['splitSharesJson'] as String).isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(map['splitSharesJson'] as String);
        decoded.forEach((key, value) {
          parsedShares[key] = (value as num).toDouble();
        });
      } catch (_) {}
    } else if (map['splitShares'] != null && map['splitShares'] is Map) {
      (map['splitShares'] as Map).forEach((k, v) {
        parsedShares[k.toString()] = (v as num).toDouble();
      });
    }

    return TransactionItem(
      id: map['id'] as String,
      groupId: map['groupId'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: (map['type'] == 'income') ? TransactionType.income : TransactionType.expense,
      category: map['category'] as String,
      note: (map['note'] ?? '') as String,
      date: DateTime.parse(map['date'] as String),
      paidByName: (map['paidByName'] ?? 'Me') as String,
      paidById: map['paidById'] as String?,
      recordedByName: (map['recordedByName'] ?? 'Me') as String,
      recordedById: map['recordedById'] as String?,
      splitWith: parsedSplitWith,
      splitShares: parsedShares,
      isSplit: (map['isSplit'] == 1 || map['isSplit'] == true),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : DateTime.now(),
      isSynced: (map['isSynced'] == 1 || map['isSynced'] == true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'amount': amount,
      'type': type.name,
      'category': category,
      'note': note,
      'date': date.toIso8601String(),
      'paidByName': paidByName,
      'paidById': paidById,
      'recordedByName': recordedByName,
      'recordedById': recordedById,
      'splitWith': splitWith,
      'splitShares': splitShares,
      'isSplit': isSplit,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TransactionItem.fromJson(Map<String, dynamic> json) =>
      TransactionItem.fromMap(json);

  TransactionItem copyWith({
    String? id,
    String? groupId,
    double? amount,
    TransactionType? type,
    String? category,
    String? note,
    DateTime? date,
    String? paidByName,
    String? paidById,
    String? recordedByName,
    String? recordedById,
    List<String>? splitWith,
    Map<String, double>? splitShares,
    bool? isSplit,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      note: note ?? this.note,
      date: date ?? this.date,
      paidByName: paidByName ?? this.paidByName,
      paidById: paidById ?? this.paidById,
      recordedByName: recordedByName ?? this.recordedByName,
      recordedById: recordedById ?? this.recordedById,
      splitWith: splitWith ?? this.splitWith,
      splitShares: splitShares ?? this.splitShares,
      isSplit: isSplit ?? this.isSplit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
