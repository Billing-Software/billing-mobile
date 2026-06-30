import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_screen.dart';
import 'billing_screen.dart';
import 'catalog_screen.dart';
import 'more_screen.dart';
import 'invoices_history_screen.dart';
import 'package:provider/provider.dart';
import '../providers/billing_provider.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  late int _currentIndex;
  late List<bool> _visited;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _visited = List.generate(5, (index) => index == _currentIndex);
  }

  @override
  void didUpdateWidget(covariant MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the widget is updated with a new initialIndex (e.g. from pushReplacementNamed), switch to it.
    if (oldWidget.initialIndex != widget.initialIndex) {
      _currentIndex = widget.initialIndex;
      _visited[_currentIndex] = true;
    }
  }

  void switchTab(int index) {
    setState(() {
      _currentIndex = index;
      _visited[index] = true;
    });
  }

  final List<Widget> _screens = const [
    DashboardScreen(),
    CatalogScreen(),
    BillingScreen(),
    InvoicesHistoryScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(_screens.length, (index) {
          return _visited[index] ? _screens[index] : const SizedBox.shrink();
        }),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, -2),
              blurRadius: 10,
            ),
          ],
          border: const Border(
            top: BorderSide(color: Color(0xFFF0F0F0), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              _visited[index] = true;
            });
            Provider.of<BillingProvider>(context, listen: false).triggerRefresh();
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF006A61),
          unselectedItemColor: const Color(0xFF7C839B),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.grid_view_rounded, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.grid_view_rounded, size: 22),
              ),
              label: 'Overview',
            ),
            const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.inventory_2_outlined, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.inventory_2_rounded, size: 22),
              ),
              label: 'Catalog',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _currentIndex == 2 ? const Color(0xFF006A61) : const Color(0xFFE8F5F3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.point_of_sale_rounded,
                  size: 20,
                  color: _currentIndex == 2 ? Colors.white : const Color(0xFF006A61),
                ),
              ),
              label: 'Billing',
            ),
            const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.receipt_long_outlined, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.receipt_long_rounded, size: 22),
              ),
              label: 'Invoices',
            ),
            const BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.menu_rounded, size: 22),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4.0),
                child: Icon(Icons.menu_rounded, size: 22),
              ),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}
