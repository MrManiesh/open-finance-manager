import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/ambient_background.dart';
import '../../core/widgets/glass_container.dart';
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
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return GlassContainer(
          borderRadius: 24,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Select Currency',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              ...currencies.map((c) {
                final isSelected = c['symbol'] == financeProv.currencySymbol;
                return ListTile(
                  leading: Text(
                    c['symbol']!,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                  ),
                  title: Text(c['name']!, style: const TextStyle(color: Colors.white)),
                  trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.accent) : null,
                  onTap: () {
                    financeProv.setCurrency(c['symbol']!);
                    Navigator.of(ctx).pop();
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _showGoogleSetupHelper(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF131A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        title: const Row(
          children: [
            Icon(Icons.vpn_key_rounded, color: AppColors.primaryLight),
            SizedBox(width: 8),
            Text('Google Cloud Credentials', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Google Sign-In on Android requires registering this app\'s SHA-1 fingerprint in your Google Cloud Console project.',
                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7)),
              ),
              const SizedBox(height: 14),

              // Package Name
              const Text('Package Name:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        GoogleAuthService.appPackageName,
                        style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.accent),
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
              const Text('SHA-1 Certificate Fingerprint:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        GoogleAuthService.appDebugSha1,
                        style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.accent),
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

              Text(
                'Steps in Google Cloud Console:\n'
                '1. Go to APIs & Services > Credentials.\n'
                '2. Click "Create Credentials" > "OAuth client ID".\n'
                '3. Choose Application Type: Android.\n'
                '4. Paste the Package Name and SHA-1 above.\n'
                '5. In "Enabled APIs", turn ON Google Drive API.',
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close', style: TextStyle(color: Colors.white.withOpacity(0.7))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showQuickEmailConnectDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
        backgroundColor: const Color(0xFF131A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        title: const Text('Link Google Account Email', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your Google account email to link your profile for Drive attribution and backups:',
              style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Google Email',
                hintText: 'e.g. user@gmail.com',
                prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
              ),
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name (Optional)',
                hintText: 'e.g. Alex',
                prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.accent),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.7))),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
        backgroundColor: const Color(0xFF131A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        title: const Text('Restore from JSON Backup', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste your exported JSON backup data here to merge into your database:',
              style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 6,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(
                hintText: '{\n  "app": "Open Finance Manager",\n  "groups": [...]\n}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.7))),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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

    return AmbientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Settings & Cloud Sync', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          children: [
            // Google Drive Cloud Sync Card
            GlassContainer(
              borderRadius: 24,
              padding: const EdgeInsets.all(20),
              tintColor: AppColors.primary,
              opacity: 0.16,
              borderColor: AppColors.primary.withOpacity(0.35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                        ),
                        child: const Icon(Icons.add_to_drive_rounded, color: AppColors.accent, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Google Drive Sync',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              authProv.isSignedIn
                                  ? (authProv.userEmail ?? 'Connected')
                                  : 'Not connected. Connect to sync across devices.',
                              style: TextStyle(
                                fontSize: 12,
                                color: authProv.isSignedIn ? AppColors.income : Colors.white.withOpacity(0.6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withOpacity(0.12)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () => _showQuickEmailConnectDialog(context),
                      icon: const Icon(Icons.link_rounded),
                      label: const Text('Quick Link with Google Email'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: () => _showGoogleSetupHelper(context),
                        icon: const Icon(Icons.help_outline_rounded, size: 16, color: AppColors.accent),
                        label: const Text(
                          'View SHA-1 & Google Cloud Setup Guide',
                          style: TextStyle(fontSize: 12, color: AppColors.accent),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Auto-sync toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Auto-Sync on Every Change',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      subtitle: Text(
                        'Automatically uploads changes to Google Drive whenever you add or edit transactions.',
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                      ),
                      value: syncProv.isAutoSyncEnabled,
                      activeColor: AppColors.accent,
                      onChanged: (val) {
                        syncProv.toggleAutoSync(val);
                      },
                    ),

                    const SizedBox(height: 10),

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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Last sync info
                    if (syncProv.lastSyncedAt != null)
                      Center(
                        child: Text(
                          'Last synced: ${DateFormat('d MMM yyyy, h:mm a').format(syncProv.lastSyncedAt!)}',
                          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
                        ),
                      ),

                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => authProv.signOut(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        foregroundColor: AppColors.expense,
                        side: BorderSide(color: AppColors.expense.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Disconnect Account'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Google Cloud Help Card
            GlassContainer(
              borderRadius: 18,
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.key_rounded, color: AppColors.accent),
                ),
                title: const Text('Google Cloud & SHA-1 Credentials', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                subtitle: Text('Copy package name & debug SHA-1 for Google Cloud Console OAuth setup', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
                trailing: Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.5)),
                onTap: () => _showGoogleSetupHelper(context),
              ),
            ),
            const SizedBox(height: 20),

            // Preferences section
            Text(
              'PREFERENCES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 10),

            GlassContainer(
              borderRadius: 18,
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.currency_exchange_rounded, color: AppColors.primaryLight),
                ),
                title: const Text('Default Currency', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                subtitle: Text('Current: ${financeProv.currencySymbol}', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
                trailing: Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.5)),
                onTap: () => _showCurrencyPicker(context),
              ),
            ),
            const SizedBox(height: 20),

            // Local JSON Backup / Restore
            Text(
              'OFFLINE DATA & BACKUP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 10),

            GlassContainer(
              borderRadius: 18,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.upload_file_rounded, color: AppColors.accent),
                    ),
                    title: const Text('Export JSON Backup', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    subtitle: Text('Save or share all ledgers and transactions as a JSON file to your Google Drive or WhatsApp', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
                    onTap: () => _exportJsonBackup(context),
                  ),
                  Divider(height: 1, color: Colors.white.withOpacity(0.08)),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.income.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.download_rounded, color: AppColors.income),
                    ),
                    title: const Text('Import / Restore Backup', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    subtitle: Text('Paste JSON data to restore or merge transactions', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
                    onTap: () => _importJsonBackup(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // App Info with App Logo
            Center(
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '${AppConstants.appName} v${AppConstants.appVersion}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Privacy-First Finance Management with Google Drive',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}

