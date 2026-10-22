import 'package:flutter_test/flutter_test.dart';
import 'package:open_finance_manager/models/finance_group.dart';
import 'package:open_finance_manager/models/group_member.dart';
import 'package:open_finance_manager/models/transaction_item.dart';

void main() {
  test('TransactionItem attribution and serialization test', () {
    final now = DateTime.now();
    final item = TransactionItem(
      id: 'tx_1',
      groupId: 'family_group',
      amount: 150.0,
      type: TransactionType.expense,
      category: 'Groceries & Milk',
      note: 'Bought 3L milk and oats',
      date: now,
      paidByName: 'Alice',
      recordedByName: 'John', // Recorded on behalf of Alice
      isSplit: true,
      splitWith: ['Alice', 'John', 'Sam'],
    );

    expect(item.amount, 150.0);
    expect(item.type.isExpense, true);
    expect(item.paidByName, 'Alice');
    expect(item.recordedByName, 'John');
    expect(item.splitWith.length, 3);

    // Serialization round-trip
    final json = item.toJson();
    final restored = TransactionItem.fromJson(json);

    expect(restored.id, item.id);
    expect(restored.amount, 150.0);
    expect(restored.paidByName, 'Alice');
    expect(restored.recordedByName, 'John');
    expect(restored.isSplit, true);
    expect(restored.splitWith, ['Alice', 'John', 'Sam']);
  });

  test('FinanceGroup creation and member management test', () {
    final member1 = GroupMember(id: 'm1', name: 'John', email: 'john@example.com', isOwner: true);
    final member2 = GroupMember(id: 'm2', name: 'Alice', email: 'alice@example.com');

    final group = FinanceGroup(
      id: 'grp_friends',
      name: 'Friends Circle',
      description: 'Trip expenses and weekend parties',
      iconCode: 0xe2eb,
      colorValue: 0xFF8B5CF6,
      members: [member1, member2],
    );

    expect(group.members.length, 2);
    expect(group.members.first.isOwner, true);

    final json = group.toJson();
    final restored = FinanceGroup.fromJson(json);

    expect(restored.name, 'Friends Circle');
    expect(restored.members.length, 2);
    expect(restored.members.last.name, 'Alice');
  });
}
