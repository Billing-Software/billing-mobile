import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/billing_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/bluetooth_printer_provider.dart';
import 'screens/login_screen.dart';
import 'screens/expense_screen.dart';
import 'screens/staff_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/main_shell.dart';
import 'screens/customer_screen.dart';

import 'services/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient().getBaseUrl();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BillingProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => BluetoothPrinterProvider()),
      ],
      child: const BillComApp(),
    ),
  );
}

class BillComApp extends StatelessWidget {
  const BillComApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.currentUser != null;

    Widget getScreen(BuildContext context, Widget screen) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      return auth.currentUser != null ? screen : const LoginScreen();
    }

    return MaterialApp(
      title: 'BillCom Mobile',
      theme: themeProvider.currentTheme,
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? const MainShell() : const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => getScreen(context, const MainShell(initialIndex: 0)),
        '/catalog': (context) => getScreen(context, const MainShell(initialIndex: 1)),
        '/billing': (context) => getScreen(context, const MainShell(initialIndex: 2)),
        '/invoices': (context) => getScreen(context, const MainShell(initialIndex: 3)),
        '/customers': (context) => getScreen(context, const CustomerScreen()),
        '/expenses': (context) => getScreen(context, const ExpenseScreen()),
        '/staff': (context) => getScreen(context, const StaffScreen()),
        '/settings': (context) => getScreen(context, const SettingsScreen()),
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => getScreen(context, const MainShell(initialIndex: 0)),
      ),
    );
  }
}
