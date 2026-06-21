import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/billing_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/bluetooth_printer_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/billing_screen.dart';
import 'screens/customer_screen.dart';
import 'screens/service_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/staff_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BillingProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => BluetoothPrinterProvider()),
      ],
      child: const SmartBillApp(),
    ),
  );
}

class SmartBillApp extends StatelessWidget {
  const SmartBillApp({Key? key}) : super(key: key);

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
      title: 'SmartBill Pro Mobile',
      theme: themeProvider.currentTheme,
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? const DashboardScreen() : const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => getScreen(context, const DashboardScreen()),
        '/billing': (context) => getScreen(context, const BillingScreen()),
        '/customers': (context) => getScreen(context, const CustomerScreen()),
        '/services': (context) => getScreen(context, const ServiceScreen()),
        '/inventory': (context) => getScreen(context, const InventoryScreen()),
        '/staff': (context) => getScreen(context, const StaffScreen()),
        '/settings': (context) => getScreen(context, const SettingsScreen()),
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => getScreen(context, const DashboardScreen()),
      ),
    );
  }
}
