import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/sync_provider.dart';
import '../../services/database/database_helper.dart';
import '../../services/drive/google_auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const List<Map<String, String>> currencies = [
    {'name': 'Indian Rupee (INR)', 'symbol': '₹'},
    {'name': 'US Dollar (USD)', 'symbol': '\$'},
    {'name': 'Euro (EUR)', 'symbol': '€'},
    {'name': 'British Pound (GBP)', 'symbol': '£'},
    {'name': 'Pakistani / Sri Lankan Rupee', 'symbol': '₨'},
    {'name': 'Japanese Yen (JPY)', 'symbol': '¥'},
    {'name': 'Canadian Dollar (CAD)', 'symbol': 'C\$'},
    {'name': 'Australian Dollar (AUD)', 'symbol': 'A\$'},
    {'name': 'UAE Dirham (AED)', 'symbol': 'AED'},
  ];

  void _showCurrencyPicker(BuildContext context) {
    final financeProv = Provider.of<FinanceProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('Select Currency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ...currencies.map((c) {
              final isSelected = c['symbol'] == financeProv.currencySymbol;
              return ListTile(
                leading: Text(
                  c['symbol']!,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                title: Text(c['name']!),
                trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  financeProv.setCurrency(c['symbol']!);
                  Navigator.of(ctx).pop();
                },
              );
            }).toList(),
          ],
        );
      },
    );
  }

  void _showGoogleSetupHelper(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.vpn_key_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Google Cloud Credentials', style: TextStyle(fontSize: 17)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Google Sign-In on Android requires registering this app\'s SHA-1 fingerprint in your Google Cloud Console project.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 14),

              // Package Name
              const Text('Package Name:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        GoogleAuthService.appPackageName,
                        style: TextStyle(fontSize: 11, fontFamily: 'monospace'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      tooltip: 'Copy Package Name',
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: GoogleAuthService.appPackageName));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Package name copied!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // SHA-1
              const Text('SHA-1 Certificate Fingerprint:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        GoogleAuthService.appDebugSha1,
                        style: TextStyle(fontSize: 10, fontFamily: 'monospace'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      tooltip: 'Copy SHA-1',
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: GoogleAuthService.appDebugSha1));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('SHA-1 fingerprint copied!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'Steps in Google Cloud Console:\n'
                '1. Go to APIs & Services > Credentials.\n'
                '2. Click "Create Credentials" > "OAuth client ID".\n'
                '3. Choose Application Type: Android.\n'
                '4. Paste the Package Name and SHA-1 above.\n'
                '5. In "Enabled APIs", turn ON Google Drive API.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showQuickEmailConnectDialog(context);
            },
            child: const Text('Quick Link Email'),
          ),
        ],
      ),
    );
  }

  void _showQuickEmailConnectDialog(BuildContext context) {
    final emailController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Link Google Account Email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your Google account email to link your profile for Drive attribution and backups:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Google Email',
                hintText: 'e.g. user@gmail.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name (Optional)',
                hintText: 'e.g. Alex',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isNotEmpty) {
                final authProv = Provider.of<AuthProvider>(context, listen: false);
                await authProv.connectWithEmailDirectly(email, name: nameController.text.trim());
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Linked as $email')),
                  );
                }
              }
            },
            child: const Text('Link Account'),
          ),
        ],
      ),
    );
  }

  void _exportJsonBackup(BuildContext context) async {
    final data = await DatabaseHelper.instance.exportFullDatabaseToJson();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

    await Share.share(
      jsonStr,
      subject: 'Open_Finance_Manager_Backup_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json',
    );
  }

  void _importJsonBackup(BuildContext context) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from JSON Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste your exported JSON backup data here to merge into your database:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: '{\n  "app": "Open Finance Manager",\n  "groups": [...]\n}',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = textController.text.trim();
              if (text.isEmpty) return;

              try {
                final Map<String, dynamic> json = jsonDecode(text);
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(ctx);
                final financeProvider = Provider.of<FinanceProvider>(context, listen: false);

                await DatabaseHelper.instance.importFullDatabaseFromJson(json, overwrite: false);
                await financeProvider.reloadAll();
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Backup restored successfully!')),
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid JSON: $e')),
                  );
                }
              }
            },
            child: const Text('Restore & Merge'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProv = context.watch<AuthProvider>();
    final syncProv = context.watch<SyncProvider>();
    final financeProv = context.watch<FinanceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Cloud Sync'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Google Drive Cloud Sync Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add_to_drive_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Google Drive Sync',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              authProv.isSignedIn
                                  ? (authProv.userEmail ?? 'Connected')
                                  : 'Not connected. Connect to sync across devices.',
                              style: TextStyle(
                                fontSize: 12,
                                color: authProv.isSignedIn ? AppColors.income : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Connect / Disconnect button
                  if (!authProv.isSignedIn) ...[
                    ElevatedButton.icon(
                      onPressed: () async {
                        final success = await authProv.signIn();
                        if (success) {
                          await syncProv.triggerManualSync();
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(authProv.errorMessage ?? 'Google Sign-In failed'),
                                action: SnackBarAction(
                                  label: 'Setup Guide',
                                  onPressed: () => _showGoogleSetupHelper(context),
                                ),
                                duration: const Duration(seconds: 4),
                              ),
                            );
                            _showGoogleSetupHelper(context);
                          }
                        }
                      },
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Sign in with Google Play Services'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _showQuickEmailConnectDialog(context),
                      icon: const Icon(Icons.link_rounded),
                      label: const Text('Quick Link with Google Email'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _showGoogleSetupHelper(context),
                        icon: const Icon(Icons.help_outline_rounded, size: 16),
                        label: const Text('View SHA-1 & Google Cloud Setup Guide', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ] else ...[
                    // Auto-sync toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Auto-Sync on Every Change', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text(
                        'Automatically uploads changes to Google Drive whenever you add or edit transactions.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: syncProv.isAutoSyncEnabled,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        syncProv.toggleAutoSync(val);
                      },
                    ),

                    const SizedBox(height: 8),

                    // Manual Sync Now button
                    ElevatedButton.icon(
                      onPressed: syncProv.status.isSyncing
                          ? null
                          : () async {
                              final success = await syncProv.triggerManualSync();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Google Drive synchronization complete!'
                                          : (syncProv.message ?? 'Sync failed'),
                                    ),
                                  ),
                                );
                              }
                            },
                      icon: syncProv.status.isSyncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.sync_rounded),
                      label: Text(syncProv.status.isSyncing ? 'Syncing...' : 'Sync with Drive Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Last sync info
                    if (syncProv.lastSyncedAt != null)
                      Center(
                        child: Text(
                          'Last synced: ${DateFormat('d MMM yyyy, h:mm a').format(syncProv.lastSyncedAt!)}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ),

                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => authProv.signOut(),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                      child: const Text('Disconnect Account'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Google Cloud Help Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.key_rounded, color: AppColors.accent),
              title: const Text('Google Cloud & SHA-1 Credentials'),
              subtitle: const Text('Copy package name & debug SHA-1 for Google Cloud Console OAuth setup'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showGoogleSetupHelper(context),
            ),
          ),
          const SizedBox(height: 16),

          // Preferences section
          const Text('Preferences', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.currency_exchange_rounded, color: AppColors.primary),
                  title: const Text('Default Currency'),
                  subtitle: Text('Current: ${financeProv.currencySymbol}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showCurrencyPicker(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Local JSON Backup / Restore
          const Text('Offline Data & Backup', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file_rounded, color: AppColors.accent),
                  title: const Text('Export JSON Backup'),
                  subtitle: const Text('Save or share all ledgers and transactions as a JSON file to your Google Drive or WhatsApp'),
                  onTap: () => _exportJsonBackup(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_rounded, color: AppColors.income),
                  title: const Text('Import / Restore Backup'),
                  subtitle: const Text('Paste JSON data to restore or merge transactions'),
                  onTap: () => _importJsonBackup(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // App Info
          const Center(
            child: Column(
              children: [
                Text(
                  '${AppConstants.appName} v${AppConstants.appVersion}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                SizedBox(height: 4),
                Text(
                  'Privacy-First Finance Management with Google Drive',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
