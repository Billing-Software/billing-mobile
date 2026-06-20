import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';

class SidebarDrawer extends StatelessWidget {
  final String activeRoute;

  const SidebarDrawer({
    Key? key,
    required this.activeRoute,
  }) : super(key: key);

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String routeName,
  }) {
    final isActive = activeRoute == routeName;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF86F2E4).withValues(alpha: 0.3) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
        leading: Icon(
          icon,
          color: isActive ? const Color(0xFF006F66) : const Color(0xFF76777D),
          size: 18,
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: isActive ? const Color(0xFF006F66) : const Color(0xFF45464D),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop(); // Close drawer
          if (title == 'Help Center') {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Help Center', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                content: Text(
                  'Need assistance? Access our online user guides or reach out directly to customer support at info@smartbill.com.',
                  style: GoogleFonts.inter(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK', style: TextStyle(color: Color(0xFF006A61), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
            return;
          }
          if (!isActive) {
            Navigator.of(context).pushReplacementNamed(routeName);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Custom Top Branding Area (No bulky DrawerHeader)
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.terminal,
                        color: Color(0xFF86F2E4),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SmartBill Pro',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0B1C30),
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          user?.businessName ?? 'Admin Terminal',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF7C839B),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quick Action Plus Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006A61),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Close drawer
                  if (activeRoute != '/billing') {
                    Navigator.of(context).pushReplacementNamed('/billing');
                  }
                },
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  'New Bill',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Menu Navigation Tabs
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  context: context,
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  routeName: '/dashboard',
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.receipt_long_outlined,
                  title: 'Billing',
                  routeName: '/billing',
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.people_outline,
                  title: 'Customers',
                  routeName: '/customers',
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.auto_awesome_outlined,
                  title: 'Services',
                  routeName: '/services',
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.inventory_2_outlined,
                  title: 'Inventory',
                  routeName: '/inventory',
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.badge_outlined,
                  title: 'Staff',
                  routeName: '/staff',
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  routeName: '/settings',
                ),
              ],
            ),
          ),

          // Help Center & Profile Footer
          Container(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMenuItem(
                  context: context,
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  routeName: '/help',
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF4FF),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFC6C6CD)),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.storefront,
                            color: Color(0xFF006A61),
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.username ?? 'Employee',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0B1C30),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              user?.role ?? 'Manager',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF45464D),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: const Icon(
                          Icons.logout,
                          color: Color(0xFF76777D),
                          size: 16,
                        ),
                        hoverColor: const Color(0xFFFFDAD6).withValues(alpha: 0.4),
                        onPressed: () async {
                          await authProvider.logout();
                          if (context.mounted) {
                            Navigator.of(context).pushReplacementNamed('/login');
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
