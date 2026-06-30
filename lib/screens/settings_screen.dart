import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/business.dart';
import '../services/business_service.dart';
import 'settings/business_profile_page.dart';
import 'settings/tax_billing_page.dart';
import 'settings/receipt_print_page.dart';
import 'settings/printer_page.dart';
import 'settings/about_page.dart';

import '../services/api_client.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BusinessService _businessService = BusinessService();

  Business? _businessProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final profile = await _businessService.getProfile();

      if (!mounted) return;
      setState(() {
        _businessProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load settings: $e')),
      );
    }
  }

  void _navigateTo(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF006A61)),
            )
          : ListView(
              children: [
                const SizedBox(height: 8),

                // Business profile header card
                _buildProfileHeader(),

                const SizedBox(height: 24),

                // Business section
                _buildSectionLabel('Business'),
                _buildSettingsTile(
                  icon: Icons.storefront_rounded,
                  iconBg: const Color(0xFFE8F5F3),
                  iconColor: const Color(0xFF006A61),
                  title: 'Business profile',
                  subtitle: _businessProfile?.legalName ?? 'Set up your business',
                  onTap: () => _navigateTo(BusinessProfilePage(
                    businessProfile: _businessProfile,
                    onSaved: _fetchSettings,
                  )),
                ),
                const Divider(height: 1, indent: 72),
                _buildSettingsTile(
                  icon: Icons.percent_rounded,
                  iconBg: const Color(0xFFFFF7ED),
                  iconColor: const Color(0xFFD97706),
                  title: 'Tax & billing',
                  subtitle: '${_businessProfile?.defaultTaxRate.toInt() ?? 18}% GST${_businessProfile?.pricesIncludeTax == true ? ' (inclusive)' : ''}',
                  onTap: () => _navigateTo(TaxBillingPage(
                    businessProfile: _businessProfile,
                    onSaved: _fetchSettings,
                  )),
                ),

                const SizedBox(height: 24),

                // Printing section
                _buildSectionLabel('Printing'),
                _buildSettingsTile(
                  icon: Icons.receipt_long_rounded,
                  iconBg: const Color(0xFFEFF6FF),
                  iconColor: const Color(0xFF2563EB),
                  title: 'Receipt & print',
                  subtitle: _getReceiptSubtitle(),
                  onTap: () => _navigateTo(ReceiptPrintPage(
                    businessProfile: _businessProfile,
                    onSaved: _fetchSettings,
                  )),
                ),
                const Divider(height: 1, indent: 72),
                _buildSettingsTile(
                  icon: Icons.print_rounded,
                  iconBg: const Color(0xFFF3F4F6),
                  iconColor: const Color(0xFF6B7280),
                  title: 'Printer',
                  subtitle: _getPrinterSubtitle(),
                  onTap: () => _navigateTo(PrinterPage(
                    businessProfile: _businessProfile,
                  )),
                ),

                const SizedBox(height: 24),

                // Integrations section
                _buildSectionLabel('Integrations'),
                _buildSettingsTile(
                  icon: Icons.chat_rounded,
                  iconBg: const Color(0xFFF0FDF4),
                  iconColor: const Color(0xFF16A34A),
                  title: 'WhatsApp',
                  subtitle: 'Coming Soon',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('WhatsApp Integration is coming soon!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // About section
                _buildSectionLabel('App'),
                _buildSettingsTile(
                  icon: Icons.info_outline_rounded,
                  iconBg: const Color(0xFFF3F4F6),
                  iconColor: const Color(0xFF6B7280),
                  title: 'About',
                  subtitle: 'Version 1.0.4',
                  onTap: () => _navigateTo(const AboutPage()),
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildProfileHeader() {
    final name = _businessProfile?.tradingName ?? _businessProfile?.legalName ?? 'Your Business';
    final logoUrl = _businessProfile?.logoUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: ApiClient.resolveUrl(logoUrl).isNotEmpty
                  ? Image.network(
                      ApiClient.resolveUrl(logoUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.storefront_rounded,
                        color: Color(0xFF9CA3AF),
                        size: 24,
                      ),
                    )
                  : const Icon(
                      Icons.storefront_rounded,
                      color: Color(0xFF9CA3AF),
                      size: 24,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1C1E),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_businessProfile?.email != null && _businessProfile!.email!.isNotEmpty)
                    Text(
                      _businessProfile!.email!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFD1D5DB),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 4),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF1A1C1E),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: const Color(0xFF6B7280),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFFD1D5DB),
        size: 22,
      ),
      onTap: onTap,
    );
  }

  String _getReceiptSubtitle() {
    final type = _businessProfile?.receiptTemplateType ?? 'Thermal80mm';
    switch (type) {
      case 'Thermal58mm':
        return 'Thermal 58mm';
      case 'StandardA4':
        return 'Standard A4';
      default:
        return 'Thermal 80mm';
    }
  }

  String _getPrinterSubtitle() {
    // This is a static check -- the printer provider has the actual state
    return 'Bluetooth thermal printer';
  }
}
