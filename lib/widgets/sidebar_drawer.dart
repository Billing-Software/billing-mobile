import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../screens/settings/about_page.dart';

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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE8F5F3) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
        leading: Icon(
          icon,
          color: isActive ? const Color(0xFF006A61) : const Color(0xFF6B7280),
          size: 20,
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: isActive ? const Color(0xFF006A61) : const Color(0xFF374151),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop();
          if (title == 'Help') {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutPage()),
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
          // Top branding
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1C1E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: Color(0xFF86F2E4),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BillCom',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1C1E),
                          ),
                        ),
                        Text(
                          user?.businessName ?? 'Admin',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w400,
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

          // New Bill button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006A61),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (activeRoute != '/billing') {
                    Navigator.of(context).pushReplacementNamed('/billing');
                  }
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'New Bill',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  context: context,
                  icon: Icons.grid_view_rounded,
                  title: 'Dashboard',
                  routeName: '/dashboard',
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.receipt_long_rounded,
                  title: 'Billing',
                  routeName: '/billing',
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.inventory_2_rounded,
                  title: 'Catalog',
                  routeName: '/catalog',
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.receipt_long_outlined,
                  title: 'Invoices',
                  routeName: '/invoices',
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Expenses',
                  routeName: '/expenses',
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.badge_rounded,
                  title: 'Staff',
                  routeName: '/staff',
                ),
                _buildMenuItem(
                  context: context,
                  icon: Icons.settings_rounded,
                  title: 'Settings',
                  routeName: '/settings',
                ),
              ],
            ),
          ),

          // Bottom section
          Container(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFF0F0F0)),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMenuItem(
                  context: context,
                  icon: Icons.help_outline_rounded,
                  title: 'Help',
                  routeName: '/help',
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person_rounded,
                            color: Color(0xFF6B7280),
                            size: 18,
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
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1C1E),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              user?.role ?? 'Manager',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF6B7280),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFF6B7280),
                          size: 18,
                        ),
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
