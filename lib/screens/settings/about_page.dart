import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 32),

          // App icon and name
          Center(
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1C1E),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFF86F2E4),
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'BillCom',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1C1E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.4',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          const Divider(),

          _buildInfoTile(
            icon: Icons.verified_rounded,
            title: 'Build',
            value: 'v1.0.4-POS',
          ),
          const Divider(height: 1, indent: 72),
          _buildInfoTile(
            icon: Icons.shield_rounded,
            title: 'Encryption',
            value: 'SHA256',
          ),
          const Divider(height: 1, indent: 72),
          _buildInfoTile(
            icon: Icons.code_rounded,
            title: 'Platform',
            value: 'Flutter',
          ),
          const Divider(),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'All data is transmitted securely and validated against system rules. Audit trails are compiled automatically.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF9CA3AF),
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Help section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Need help?',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Contact support at info@billcom.com or visit our online guides.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF6B7280), size: 18),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      trailing: Text(
        value,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFF6B7280),
        ),
      ),
    );
  }
}
