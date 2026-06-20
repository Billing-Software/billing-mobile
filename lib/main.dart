import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/billing_provider.dart';
import 'providers/theme_provider.dart';
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

    return MaterialApp(
      title: 'SmartBill Pro Mobile',
      theme: themeProvider.currentTheme,
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? const DashboardScreen() : const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => isLoggedIn ? const DashboardScreen() : const LoginScreen(),
        '/billing': (context) => isLoggedIn ? const BillingScreen() : const LoginScreen(),
        '/customers': (context) => isLoggedIn ? const CustomerScreen() : const LoginScreen(),
        '/services': (context) => isLoggedIn ? const ServiceScreen() : const LoginScreen(),
        '/inventory': (context) => isLoggedIn ? const InventoryScreen() : const LoginScreen(),
        '/staff': (context) => isLoggedIn ? const StaffScreen() : const LoginScreen(),
        '/settings': (context) => isLoggedIn ? const SettingsScreen() : const LoginScreen(),
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => isLoggedIn ? const DashboardScreen() : const LoginScreen(),
      ),
    );
  }
}
