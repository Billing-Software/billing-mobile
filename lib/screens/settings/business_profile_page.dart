import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/business.dart';
import '../../services/business_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/api_client.dart';

class BusinessProfilePage extends StatefulWidget {
  final Business? businessProfile;
  final VoidCallback onSaved;

  const BusinessProfilePage({
    Key? key,
    required this.businessProfile,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
  final BusinessService _businessService = BusinessService();
  bool _isSaving = false;

  late final TextEditingController _legalNameController;
  late final TextEditingController _tradingNameController;
  late final TextEditingController _logoUrlController;
  late final TextEditingController _websiteController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _gstInController;

  @override
  void initState() {
    super.initState();
    final p = widget.businessProfile;
    _legalNameController = TextEditingController(text: p?.legalName ?? '');
    _tradingNameController = TextEditingController(text: p?.tradingName ?? '');
    _logoUrlController = TextEditingController(text: p?.logoUrl ?? '');
    _websiteController = TextEditingController(text: p?.website ?? '');
    _phoneController = TextEditingController(text: p?.phone ?? '');
    _emailController = TextEditingController(text: p?.email ?? '');
    _addressController = TextEditingController(text: p?.address ?? '');
    _cityController = TextEditingController(text: p?.city ?? '');
    _stateController = TextEditingController(text: p?.state ?? '');
    _postalCodeController = TextEditingController(text: p?.postalCode ?? '');
    _gstInController = TextEditingController(text: p?.gstIn ?? '');
  }

  @override
  void dispose() {
    _legalNameController.dispose();
    _tradingNameController.dispose();
    _logoUrlController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _gstInController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_legalNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Legal name is required')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _businessService.updateProfile({
        'id': widget.businessProfile?.id ?? 0,
        'ownerId': widget.businessProfile?.ownerId ?? 0,
        'legalName': _legalNameController.text.trim(),
        'tradingName': _tradingNameController.text.trim().isEmpty ? null : _tradingNameController.text.trim(),
        'logoUrl': _logoUrlController.text.trim().isEmpty ? null : _logoUrlController.text.trim(),
        'website': _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'city': _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        'state': _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        'postalCode': _postalCodeController.text.trim().isEmpty ? null : _postalCodeController.text.trim(),
        'gstIn': _gstInController.text.trim().isEmpty ? null : _gstInController.text.trim(),
        'defaultTaxRate': widget.businessProfile?.defaultTaxRate ?? 18.0,
        'pricesIncludeTax': widget.businessProfile?.pricesIncludeTax ?? true,
        'receiptHeader': widget.businessProfile?.receiptHeader,
        'receiptFooter': widget.businessProfile?.receiptFooter,
        'showLogoOnReceipt': widget.businessProfile?.showLogoOnReceipt ?? true,
        'receiptTemplateType': widget.businessProfile?.receiptTemplateType ?? 'Thermal80mm',
      });

      if (mounted) {
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business profile saved')),
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
        title: Text('Business profile', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Logo preview
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ApiClient.resolveUrl(_logoUrlController.text.trim()).isNotEmpty
                        ? Image.network(
                            ApiClient.resolveUrl(_logoUrlController.text.trim()),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.storefront_rounded,
                              color: Color(0xFF9CA3AF),
                              size: 32,
                            ),
                          )
                        : const Icon(
                            Icons.storefront_rounded,
                            color: Color(0xFF9CA3AF),
                            size: 32,
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Business logo',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            CustomTextField(
              controller: _logoUrlController,
              label: 'Logo URL',
              placeholder: 'https://example.com/logo.png',
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _legalNameController,
              label: 'Legal name',
              placeholder: 'Company Pvt Ltd',
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.organizationName],
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _tradingNameController,
              label: 'Trading name',
              placeholder: 'Brand name',
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _phoneController,
              label: 'Phone',
              placeholder: '+91 98765 43210',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _emailController,
              label: 'Email',
              placeholder: 'info@business.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 16),

            CustomTextField(
              controller: _websiteController,
              label: 'Website',
              placeholder: 'https://example.com',
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.url],
            ),
            const SizedBox(height: 24),

            // Address section header
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Address',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),

            CustomTextField(
              controller: _addressController,
              label: 'Street address',
              placeholder: '123 Main Street',
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.streetAddressLine1],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _cityController,
                    label: 'City',
                    placeholder: 'Hyderabad',
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.addressCity],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: _stateController,
                    label: 'State',
                    placeholder: 'Telangana',
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.addressState],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _postalCodeController,
                    label: 'Postal code',
                    placeholder: '500081',
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.postalCode],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: _gstInController,
                    label: 'GSTIN',
                    placeholder: 'GST number',
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _save(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
