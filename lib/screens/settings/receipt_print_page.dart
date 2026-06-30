import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/business.dart';
import '../../services/business_service.dart';
import '../../widgets/custom_text_field.dart';

class ReceiptPrintPage extends StatefulWidget {
  final Business? businessProfile;
  final VoidCallback onSaved;

  const ReceiptPrintPage({
    Key? key,
    required this.businessProfile,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<ReceiptPrintPage> createState() => _ReceiptPrintPageState();
}

class _ReceiptPrintPageState extends State<ReceiptPrintPage> {
  final BusinessService _businessService = BusinessService();
  bool _isSaving = false;

  late final TextEditingController _receiptHeaderController;
  late final TextEditingController _receiptFooterController;
  late bool _showLogoOnReceipt;
  late String _receiptTemplateType;

  @override
  void initState() {
    super.initState();
    final p = widget.businessProfile;
    _receiptHeaderController = TextEditingController(text: p?.receiptHeader ?? '');
    _receiptFooterController = TextEditingController(text: p?.receiptFooter ?? '');
    _showLogoOnReceipt = p?.showLogoOnReceipt ?? true;
    _receiptTemplateType = p?.receiptTemplateType ?? 'Thermal80mm';
  }

  @override
  void dispose() {
    _receiptHeaderController.dispose();
    _receiptFooterController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      final p = widget.businessProfile;
      await _businessService.updateProfile({
        'id': p?.id ?? 0,
        'ownerId': p?.ownerId ?? 0,
        'legalName': p?.legalName ?? '',
        'tradingName': p?.tradingName,
        'logoUrl': p?.logoUrl,
        'website': p?.website,
        'phone': p?.phone,
        'email': p?.email,
        'address': p?.address,
        'city': p?.city,
        'state': p?.state,
        'postalCode': p?.postalCode,
        'gstIn': p?.gstIn,
        'defaultTaxRate': p?.defaultTaxRate ?? 18.0,
        'pricesIncludeTax': p?.pricesIncludeTax ?? true,
        'receiptHeader': _receiptHeaderController.text.trim().isEmpty ? null : _receiptHeaderController.text.trim(),
        'receiptFooter': _receiptFooterController.text.trim().isEmpty ? null : _receiptFooterController.text.trim(),
        'showLogoOnReceipt': _showLogoOnReceipt,
        'receiptTemplateType': _receiptTemplateType,
      });

      if (mounted) {
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt settings saved')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Receipt & print', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: ListView(
          children: [
            const SizedBox(height: 8),

            // Template type selection
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Paper size',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),

            _buildTemplateOption(
              title: 'Thermal 80mm',
              subtitle: '48 characters per line',
              value: 'Thermal80mm',
            ),
            _buildTemplateOption(
              title: 'Thermal 58mm',
              subtitle: '32 characters per line',
              value: 'Thermal58mm',
            ),
            _buildTemplateOption(
              title: 'Standard A4',
              subtitle: 'Full page invoice',
              value: 'StandardA4',
            ),

            const Divider(height: 32),

            // Show logo toggle
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              title: Text(
                'Show logo on receipt',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Print your business logo at the top',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
              ),
              value: _showLogoOnReceipt,
              onChanged: (val) {
                setState(() => _showLogoOnReceipt = val);
              },
            ),

            const Divider(height: 32),

            // Header and footer text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CustomTextField(
                controller: _receiptHeaderController,
                label: 'Header text',
                placeholder: 'Welcome message at the top of receipt',
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CustomTextField(
                controller: _receiptFooterController,
                label: 'Footer text',
                placeholder: 'Thank you message at the bottom',
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateOption({
    required String title,
    required String subtitle,
    required String value,
  }) {
    final isSelected = _receiptTemplateType == value;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isSelected ? const Color(0xFF006A61) : const Color(0xFF1A1C1E),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
      ),
      trailing: Radio<String>(
        value: value,
        groupValue: _receiptTemplateType,
        activeColor: const Color(0xFF006A61),
        onChanged: (val) {
          if (val != null) setState(() => _receiptTemplateType = val);
        },
      ),
      onTap: () {
        setState(() => _receiptTemplateType = value);
      },
    );
  }
}
