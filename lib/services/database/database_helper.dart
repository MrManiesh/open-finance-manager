import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/finance_group.dart';
import '../../models/group_member.dart';
import '../../models/transaction_item.dart';
import '../../core/constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('open_finance_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Groups Table
    await db.execute('''
      CREATE TABLE groups (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        iconCode INTEGER NOT NULL,
        colorValue INTEGER NOT NULL,
        membersJson TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Transactions Table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        groupId TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        paidByName TEXT NOT NULL,
        paidById TEXT,
        recordedByName TEXT NOT NULL,
        recordedById TEXT,
        splitWithJson TEXT,
        splitSharesJson TEXT,
        isSplit INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (groupId) REFERENCES groups (id) ON DELETE CASCADE
      )
    ''');

    // Pre-populate with default groups (Family, Friends, Company, Milk & Daily Needs)
    final now = DateTime.now();
    for (final preset in AppConstants.presetGroups) {
      final defaultMembers = [
        GroupMember(
          id: 'member_me',
          name: 'Me',
          email: '',
          isOwner: true,
          createdAt: now,
        ),
      ];

      // Add a couple of sample members for Family and Friends to showcase splitting immediately
      if (preset['id'] == 'family_group') {
        defaultMembers.add(GroupMember(id: 'member_fam1', name: 'Partner', email: ''));
      } else if (preset['id'] == 'friends_group') {
        defaultMembers.add(GroupMember(id: 'member_fr1', name: 'Alex', email: ''));
        defaultMembers.add(GroupMember(id: 'member_fr2', name: 'Sam', email: ''));
      }

      await db.insert('groups', {
        'id': preset['id'],
        'name': preset['name'],
        'description': preset['description'],
        'iconCode': preset['iconCode'],
        'colorValue': preset['colorValue'],
        'membersJson': jsonEncode(defaultMembers.map((m) => m.toJson()).toList()),
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });
    }
  }

  // --- Groups Operations ---

  Future<List<FinanceGroup>> getAllGroups() async {
    final db = await instance.database;
    final result = await db.query('groups', orderBy: 'createdAt ASC');
    return result.map((json) => FinanceGroup.fromMap(json)).toList();
  }

  Future<FinanceGroup?> getGroupById(String id) async {
    final db = await instance.database;
    final result = await db.query(
      'groups',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return FinanceGroup.fromMap(result.first);
    }
    return null;
  }

  Future<int> insertGroup(FinanceGroup group) async {
    final db = await instance.database;
    return await db.insert(
      'groups',
      group.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateGroup(FinanceGroup group) async {
    final db = await instance.database;
    return await db.update(
      'groups',
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  Future<int> deleteGroup(String groupId) async {
    final db = await instance.database;
    // Delete transactions in this group
    await db.delete('transactions', where: 'groupId = ?', whereArgs: [groupId]);
    return await db.delete('groups', where: 'id = ?', whereArgs: [groupId]);
  }

  // --- Transactions Operations ---

  Future<List<TransactionItem>> getTransactionsForGroup(String groupId) async {
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      where: 'groupId = ?',
      whereArgs: [groupId],
      orderBy: 'date DESC, createdAt DESC',
    );
    return result.map((json) => TransactionItem.fromMap(json)).toList();
  }

  Future<List<TransactionItem>> getAllTransactions() async {
    final db = await instance.database;
    final result = await db.query(
      'transactions',
      orderBy: 'date DESC, createdAt DESC',
    );
    return result.map((json) => TransactionItem.fromMap(json)).toList();
  }

  Future<int> insertTransaction(TransactionItem item) async {
    final db = await instance.database;
    return await db.insert(
      'transactions',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateTransaction(TransactionItem item) async {
    final db = await instance.database;
    return await db.update(
      'transactions',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteTransaction(String id) async {
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Summary Calculations ---

  Future<Map<String, double>> getGroupSummary(String groupId) async {
    final transactions = await getTransactionsForGroup(groupId);
    double income = 0.0;
    double expense = 0.0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }

    return {
      'income': income,
      'expense': expense,
      'balance': income - expense,
    };
  }

  Future<Map<String, double>> getOverallSummary() async {
    final transactions = await getAllTransactions();
    double income = 0.0;
    double expense = 0.0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }

    return {
      'income': income,
      'expense': expense,
      'balance': income - expense,
    };
  }

  // Raw dump for Google Drive JSON Sync
  Future<Map<String, dynamic>> exportFullDatabaseToJson() async {
    final groups = await getAllGroups();
    final transactions = await getAllTransactions();

    return {
      'app': AppConstants.appName,
      'version': AppConstants.appVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'groups': groups.map((g) => g.toJson()).toList(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
  }

  // Restore or merge from Google Drive JSON
  Future<void> importFullDatabaseFromJson(Map<String, dynamic> json, {bool overwrite = false}) async {
    final db = await instance.database;

    if (overwrite) {
      await db.delete('transactions');
      await db.delete('groups');
    }

    if (json['groups'] != null && json['groups'] is List) {
      for (final g in json['groups']) {
        final group = FinanceGroup.fromJson(g as Map<String, dynamic>);
        await insertGroup(group);
      }
    }

    if (json['transactions'] != null && json['transactions'] is List) {
      for (final t in json['transactions']) {
        final tx = TransactionItem.fromJson(t as Map<String, dynamic>);
        await insertTransaction(tx);
      }
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}
