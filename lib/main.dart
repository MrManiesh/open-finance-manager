import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/finance_provider.dart';
import 'providers/sync_provider.dart';
import 'services/drive/drive_sync_service.dart';
import 'services/preferences_service.dart';
import 'views/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent settings and Drive Sync service
  await PreferencesService.init();
  DriveSyncService.instance.init();

  runApp(const OpenFinanceApp());
}

class OpenFinanceApp extends StatelessWidget {
  const OpenFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => SyncProvider()),
        ChangeNotifierProvider(create: (_) => FinanceProvider()..init()),
      ],
      child: Consumer<FinanceProvider>(
        builder: (context, financeProv, child) {
          final isDark = PreferencesService.isDarkMode();
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: isDark ? ThemeMode.dark : ThemeMode.system,
            home: const DashboardScreen(),
          );
        },
      ),
    );
  }
}
