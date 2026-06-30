import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../widgets/confirm_sheet.dart';
import 'settings/about_page.dart';
import 'invoices_history_screen.dart';
import 'customer_screen.dart';
import '../widgets/custom_text_field.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({Key? key}) : super(key: key);

  Widget _buildMenuCard({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF7C839B),
              letterSpacing: 1.0,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0B1C30),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: const Color(0xFF7C839B),
          fontWeight: FontWeight.w400,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFFC6C6CD),
        size: 20,
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text(
          'More Options',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 12),

          // User Profile Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF006A61), Color(0xFF004D46)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF006A61).withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      (user?.username ?? 'U').substring(0, 1).toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.username ?? 'Employee',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                user?.role ?? 'Manager',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF86F2E4).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${authProvider.currentBranch} Branch (ID: ${user?.businessId ?? 0})',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF86F2E4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // CRM & Operations Section
          _buildMenuCard(
            title: 'CRM & Operations',
            children: [
              _buildMenuItem(
                context: context,
                icon: Icons.people_outline_rounded,
                iconColor: const Color(0xFF006A61),
                iconBg: const Color(0xFFE8F5F3),
                title: 'Customers Directory',
                subtitle: 'Manage client accounts and CRM details',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const CustomerScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Business Administration Section (Only for Owner)
          if (user?.role == 'Owner')
            _buildMenuCard(
              title: 'Business Administration',
              children: [
                _buildMenuItem(
                  context: context,
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: const Color(0xFFD97706),
                  iconBg: const Color(0xFFFFF7ED),
                  title: 'Expenses',
                  subtitle: 'Log and review operational store costs',
                  onTap: () {
                    Navigator.of(context).pushNamed('/expenses');
                  },
                ),
                const Divider(height: 1, indent: 70),
                _buildMenuItem(
                  context: context,
                  icon: Icons.badge_rounded,
                  iconColor: const Color(0xFF2563EB),
                  iconBg: const Color(0xFFEFF6FF),
                  title: 'Staff Management',
                  subtitle: 'Manage roles and system credentials',
                  onTap: () {
                    Navigator.of(context).pushNamed('/staff');
                  },
                ),
              ],
            ),
 
          // System Settings Section
          _buildMenuCard(
            title: 'System Settings',
            children: [
              if (user?.role == 'Owner') ...[
                _buildMenuItem(
                  context: context,
                  icon: Icons.settings_rounded,
                  iconColor: const Color(0xFF006A61),
                  iconBg: const Color(0xFFE8F5F3),
                  title: 'Settings',
                  subtitle: 'Configure billing, printer, taxes, and profile',
                  onTap: () {
                    Navigator.of(context).pushNamed('/settings');
                  },
                ),
                const Divider(height: 1, indent: 70),
              ],
              _buildMenuItem(
                context: context,
                icon: Icons.help_outline_rounded,
                iconColor: const Color(0xFF4B5563),
                iconBg: const Color(0xFFF3F4F6),
                title: 'Help & About',
                subtitle: 'View documentation, license, and version',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AboutPage()),
                  );
                },
              ),
              const Divider(height: 1, indent: 70),
              _buildMenuItem(
                context: context,
                icon: Icons.lock_outline_rounded,
                iconColor: const Color(0xFFBA1A1A),
                iconBg: const Color(0xFFFFDAD6),
                title: 'Change Password',
                subtitle: 'Update account password credentials',
                onTap: () {
                  _showChangePasswordDialog(context);
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Logout Action Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
                foregroundColor: const Color(0xFFBA1A1A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () async {
                final confirm = await ConfirmSheet.show(
                  context: context,
                  title: 'Confirm Logout',
                  message: 'Are you sure you want to end your active session?',
                  confirmText: 'Logout',
                  cancelText: 'Cancel',
                  isDestructive: true,
                );

                if (confirm == true) {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                }
              },
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: Text(
                'End Active Session',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Change Password',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: const Color(0xFF0B1C30),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: currentPasswordController,
                label: 'Current Password',
                placeholder: 'Enter current password',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: newPasswordController,
                label: 'New Password',
                placeholder: 'Enter new password (min 6 chars)',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006A61),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final currPass = currentPasswordController.text;
                  final newPass = newPasswordController.text;
                  if (currPass.isEmpty || newPass.length < 6) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Please enter valid inputs (min 6 chars for new password)')),
                    );
                    return;
                  }
                  try {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    await authProvider.changePassword(currPass, newPass);
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password updated successfully!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: Text(
                  'Change Password',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
