import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/business.dart';
import '../../services/business_service.dart';

class TaxBillingPage extends StatefulWidget {
  final Business? businessProfile;
  final VoidCallback onSaved;

  const TaxBillingPage({
    Key? key,
    required this.businessProfile,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<TaxBillingPage> createState() => _TaxBillingPageState();
}

class _TaxBillingPageState extends State<TaxBillingPage> {
  final BusinessService _businessService = BusinessService();
  bool _isSaving = false;

  late double _defaultTaxRate;
  late bool _pricesIncludeTax;

  @override
  void initState() {
    super.initState();
    _defaultTaxRate = widget.businessProfile?.defaultTaxRate ?? 18.0;
    _pricesIncludeTax = widget.businessProfile?.pricesIncludeTax ?? true;
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
        'defaultTaxRate': _defaultTaxRate,
        'pricesIncludeTax': _pricesIncludeTax,
        'receiptHeader': p?.receiptHeader,
        'receiptFooter': p?.receiptFooter,
        'showLogoOnReceipt': p?.showLogoOnReceipt ?? true,
        'receiptTemplateType': p?.receiptTemplateType ?? 'Thermal80mm',
      });

      if (mounted) {
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tax settings saved')),
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
        title: Text('Tax & billing', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // Tax rate selection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'Default tax rate',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),

          _buildTaxOption(
            title: '18% GST',
            subtitle: 'Standard goods and services tax',
            value: 18.0,
          ),
          _buildTaxOption(
            title: '5% GST',
            subtitle: 'Food and essential services',
            value: 5.0,
          ),
          _buildTaxOption(
            title: '0% Tax exempt',
            subtitle: 'No tax applied',
            value: 0.0,
          ),

          const Divider(height: 32),

          // Prices include tax toggle
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            title: Text(
              'Prices include tax',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'Menu prices already include GST',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
            ),
            value: _pricesIncludeTax,
            onChanged: (val) {
              setState(() => _pricesIncludeTax = val);
            },
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
    );
  }

  Widget _buildTaxOption({
    required String title,
    required String subtitle,
    required double value,
  }) {
    final isSelected = _defaultTaxRate == value;

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
      trailing: Radio<double>(
        value: value,
        groupValue: _defaultTaxRate,
        activeColor: const Color(0xFF006A61),
        onChanged: (val) {
          if (val != null) setState(() => _defaultTaxRate = val);
        },
      ),
      onTap: () {
        setState(() => _defaultTaxRate = value);
      },
    );
  }
}
