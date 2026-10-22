import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:share_plus/share_plus.dart';
import '../../models/finance_group.dart';
import '../../core/utils/currency_formatter.dart';
import 'google_auth_service.dart';

class ShareService {
  static Future<void> shareGroupInvite(FinanceGroup group) async {
    final message = '''
🎉 You're invited to join "${group.name}" on Open Finance Manager!

Manage our shared expenses and track income together seamlessly with Google Drive backup.

Group ID: ${group.id}
Created by: ${group.members.isNotEmpty ? group.members.first.name : 'A member'}
''';

    await Share.share(
      message,
      subject: 'Join my Finance Group: ${group.name}',
    );
  }

  static Future<void> shareGroupSummary({
    required FinanceGroup group,
    required double totalExpense,
    required double totalIncome,
    required Map<String, double> memberBalances,
    String currencySymbol = '₹',
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('📊 *Financial Summary for ${group.name}*');
    buffer.writeln('-----------------------------------');
    buffer.writeln('Total Income: ${CurrencyFormatter.format(totalIncome, symbol: currencySymbol)}');
    buffer.writeln('Total Expenses: ${CurrencyFormatter.format(totalExpense, symbol: currencySymbol)}');
    buffer.writeln('Net Balance: ${CurrencyFormatter.format(totalIncome - totalExpense, symbol: currencySymbol)}');
    buffer.writeln('');
    buffer.writeln('👥 *Member Balances & Settlements:*');

    memberBalances.forEach((member, balance) {
      if (balance > 0.01) {
        buffer.writeln('• $member should receive ${CurrencyFormatter.format(balance, symbol: currencySymbol)}');
      } else if (balance < -0.01) {
        buffer.writeln('• $member owes ${CurrencyFormatter.format(balance.abs(), symbol: currencySymbol)}');
      } else {
        buffer.writeln('• $member is settled up');
      }
    });

    buffer.writeln('');
    buffer.writeln('Generated via Open Finance Manager');

    await Share.share(
      buffer.toString(),
      subject: '${group.name} - Expense Summary',
    );
  }

  static Future<bool> grantDriveAccessToEmail(String email) async {
    try {
      final authClient = await GoogleAuthService.instance.getAuthenticatedClient();
      if (authClient == null) return false;

      final driveApi = drive.DriveApi(authClient);
      
      // Look up Open Finance folder
      final folderList = await driveApi.files.list(
        q: "mimeType = 'application/vnd.google-apps.folder' and name = 'Open Finance Manager' and trashed = false",
        spaces: 'drive',
      );

      if (folderList.files == null || folderList.files!.isEmpty) {
        return false;
      }

      final folderId = folderList.files!.first.id!;
      final newPermission = drive.Permission()
        ..type = 'user'
        ..role = 'writer'
        ..emailAddress = email;

      await driveApi.permissions.create(
        newPermission,
        folderId,
        sendNotificationEmail: true,
      );

      return true;
    } catch (e) {
      debugPrint('Failed to grant Drive permissions to $email: $e');
      return false;
    }
  }
}
