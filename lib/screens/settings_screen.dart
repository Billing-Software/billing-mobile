import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/settings.dart';
import '../models/business.dart';
import '../services/settings_service.dart';
import '../services/business_service.dart';
import '../services/api_client.dart';
import '../widgets/sidebar_drawer.dart';
import '../widgets/custom_text_field.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final BusinessService _businessService = BusinessService();

  WhatsAppSettings? _whatsAppSettings;
  Business? _businessProfile;
  bool _isLoading = true;

  final _apiKeyController = TextEditingController();
  final _newTemplateController = TextEditingController();
  final _serverUrlController = TextEditingController();

  // Corporate Profile controllers
  final _legalNameController = TextEditingController();
  final _tradingNameController = TextEditingController();
  final _logoUrlController = TextEditingController();
  final _websiteController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _gstInController = TextEditingController();

  double _defaultTaxRate = 18.0;
  bool _pricesIncludeTax = true;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final settings = await _settingsService.getWhatsAppSettings();
      final profile = await _businessService.getProfile();
      final url = await ApiClient().getBaseUrl();
      if (!mounted) return;
      setState(() {
        _whatsAppSettings = settings;
        _apiKeyController.text = settings.apiKey;
        _serverUrlController.text = url;

        _businessProfile = profile;
        _legalNameController.text = profile.legalName;
        _tradingNameController.text = profile.tradingName ?? '';
        _logoUrlController.text = profile.logoUrl ?? '';
        _websiteController.text = profile.website ?? '';
        _phoneController.text = profile.phone ?? '';
        _emailController.text = profile.email ?? '';
        _addressController.text = profile.address ?? '';
        _cityController.text = profile.city ?? '';
        _stateController.text = profile.state ?? '';
        _postalCodeController.text = profile.postalCode ?? '';
        _gstInController.text = profile.gstIn ?? '';
        _defaultTaxRate = profile.defaultTaxRate;
        _pricesIncludeTax = profile.pricesIncludeTax;

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load settings: $e')),
      );
    }
  }

  Future<void> _updateWhatsAppSettings() async {
    final key = _apiKeyController.text.trim();
    try {
      final updated = await _settingsService.updateWhatsAppSettings({
        'apiKey': key,
        'isConnected': key.isNotEmpty,
      });
      if (mounted) {
        setState(() {
          _whatsAppSettings = updated;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp Settings updated successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update WhatsApp settings: $e')),
        );
      }
    }
  }

  Future<void> _updateBusinessProfile() async {
    if (_legalNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Legal Company Name is required')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final updated = await _businessService.updateProfile({
        'id': _businessProfile?.id ?? 0,
        'ownerId': _businessProfile?.ownerId ?? 0,
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
        'defaultTaxRate': _defaultTaxRate,
        'pricesIncludeTax': _pricesIncludeTax,
      });
      if (mounted) {
        setState(() {
          _businessProfile = updated;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business profile settings saved securely!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update business profile: $e')),
        );
      }
    }
  }

  Future<void> _addNewTemplate() async {
    final text = _newTemplateController.text.trim();
    if (text.isEmpty) return;

    try {
      final updated = await _settingsService.addWhatsAppTemplate({
        'template': text,
      });
      if (mounted) {
        setState(() {
          _whatsAppSettings = updated;
          _newTemplateController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New template registered.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add template: $e')),
        );
      }
    }
  }

  Future<void> _deleteTemplate(int index) async {
    try {
      await _settingsService.deleteWhatsAppTemplate(index);
      _fetchSettings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete template: $e')),
        );
      }
    }
  }

  Future<void> _saveServerUrl() async {
    final url = _serverUrlController.text.trim();
    if (url.isNotEmpty) {
      await ApiClient().setBaseUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server endpoint updated to: $url')),
        );
      }
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _newTemplateController.dispose();
    _serverUrlController.dispose();
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

  Widget _buildDropdownField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            color: const Color(0xFF7C839B),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFC6C6CD), width: 1.0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(child: child),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF006A61), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            color: const Color(0xFF0B1C30),
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _whatsAppSettings?.isConnected ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text('System Settings', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchSettings),
        ],
      ),
      drawer: const SidebarDrawer(activeRoute: '/settings'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF006A61)))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      if (width > 900) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 8,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: _buildSettingsPanels(isConnected, width),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 4,
                              child: _buildMetaDetailsPanel(),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ..._buildSettingsPanels(isConnected, width),
                            const SizedBox(height: 20),
                            _buildMetaDetailsPanel(),
                          ],
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
    );
  }

  List<Widget> _buildSettingsPanels(bool isConnected, double width) {
    return [
      // API URL settings
      _buildSectionHeader('API SERVER CONFIGURATION', Icons.settings_ethernet),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Configure the backend C# Server IP Address here to synchronize all POS client transactions.',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF7C839B)),
            ),
            const SizedBox(height: 10), // Shrank from 14
            CustomTextField(
              controller: _serverUrlController,
              label: 'Server Endpoint URL',
              placeholder: 'http://localhost:5208/api',
            ),
            const SizedBox(height: 10), // Shrank from 12
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006A61),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _saveServerUrl,
              child: Text('Save Server URL', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),

      // Corporate Entity Profile Form
      _buildSectionHeader('LEGAL BUSINESS NODE', Icons.business_outlined),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Define corporate credentials, tax rules, and registration codes.',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF7C839B)),
            ),
            const SizedBox(height: 12), // Shrank from 16
            _buildResponsiveRow(
              width,
              child1: CustomTextField(
                controller: _legalNameController,
                label: 'Legal Company Name',
                placeholder: 'e.g. Acme Corp Private Ltd',
              ),
              child2: CustomTextField(
                controller: _tradingNameController,
                label: 'Trading Name (Brand Name)',
                placeholder: 'e.g. Acme Brand',
              ),
            ),
            const SizedBox(height: 12), // Shrank from 16

            // Logo Preview and URL input
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEFF4FF)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _logoUrlController.text.trim().isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _logoUrlController.text.trim(),
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, st) => Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFFC6C6CD)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.business, color: Color(0xFF7C839B)),
                            ),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFC6C6CD)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.business_outlined, color: Color(0xFF7C839B), size: 24),
                        ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BUSINESS LOGO IMAGE',
                          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0B1C30)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Configure the image URL of your brand logo to render on client invoices and receipts.',
                          style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF7C839B), height: 1.3),
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _logoUrlController,
                          label: 'Logo Image URL',
                          placeholder: 'https://acme.com/assets/logo.png',
                          onChanged: (_) {
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildResponsiveRow(
              width,
              child1: CustomTextField(
                controller: _websiteController,
                label: 'Website URL',
                placeholder: 'https://example.com',
              ),
              child2: CustomTextField(
                controller: _phoneController,
                label: 'Business Phone Number',
                placeholder: '+91 98765 43210',
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _emailController,
              label: 'Business Email Address',
              placeholder: 'info@business.com',
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _addressController,
              label: 'Headquarters Street Address',
              placeholder: '123 Enterprise Blvd',
            ),
            const SizedBox(height: 16),
            _buildResponsiveRow(
              width,
              child1: CustomTextField(
                controller: _cityController,
                label: 'Corporate City',
                placeholder: 'e.g. Hyderabad',
              ),
              child2: CustomTextField(
                controller: _stateController,
                label: 'Corporate State',
                placeholder: 'e.g. Telangana',
              ),
            ),
            const SizedBox(height: 16),
            _buildResponsiveRow(
              width,
              child1: CustomTextField(
                controller: _postalCodeController,
                label: 'Postal Code (ZIP)',
                placeholder: 'e.g. 500081',
              ),
              child2: CustomTextField(
                controller: _gstInController,
                label: 'GSTIN Registration Code',
                placeholder: 'GSTIN Code or N/A',
              ),
            ),
            const SizedBox(height: 16),

            _buildDropdownField(
              label: 'Primary CGST/SGST Tax Range',
              child: DropdownButton<double>(
                value: _defaultTaxRate,
                isExpanded: true,
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _defaultTaxRate = val;
                    });
                  }
                },
                items: [
                  DropdownMenuItem(value: 18.0, child: Text('18% Standard GST Rule', style: GoogleFonts.inter())),
                  DropdownMenuItem(value: 5.0, child: Text('5% Food & Beauty Services', style: GoogleFonts.inter())),
                  DropdownMenuItem(value: 0.0, child: Text('0% Tax Exempt AMC Rule', style: GoogleFonts.inter())),
                ],
              ),
            ),
            const SizedBox(height: 12), // Shrank from 16
 
            Row(
              children: [
                Checkbox(
                  value: _pricesIncludeTax,
                  activeColor: const Color(0xFF006A61),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _pricesIncludeTax = val;
                      });
                    }
                  },
                ),
                Expanded(
                  child: Text(
                    'Advertised menu prices automatically include regional CGST/SGST tax contributions.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0B1C30),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12), // Shrank from 16
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006A61),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _updateBusinessProfile,
              child: Text('Save Corporate Entity Parameters', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),

      // WhatsApp integration HUD
      _buildSectionHeader('WHATSAPP INTEGRATION GATEWAY', Icons.message_outlined),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status row
            Row(
              children: [
                Text('Gateway Status: ', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isConnected ? const Color(0xFFE6F4EA) : const Color(0xFFFFDAD6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isConnected ? 'CONNECTED' : 'DISCONNECTED',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isConnected ? const Color(0xFF1E8E3E) : const Color(0xFFBA1A1A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12), // Shrank from 14
            CustomTextField(
              controller: _apiKeyController,
              label: 'WhatsApp API Secret Key',
              placeholder: 'Enter API Key...',
              obscureText: true,
            ),
            const SizedBox(height: 10), // Shrank from 12
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006A61),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _updateWhatsAppSettings,
              child: Text('Update Secret Key', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),

      // WhatsApp templates list
      _buildSectionHeader('NOTIFICATION MESSAGES TEMPLATES', Icons.dashboard_customize_outlined),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Add template Form
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _newTemplateController,
                    label: 'New Template Text',
                    placeholder: 'Configure new automated messages template...',
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEFF4FF),
                    foregroundColor: const Color(0xFF006A61),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onPressed: _addNewTemplate,
                  child: Text('Add', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12), // Shrank from 16
            // List
            _whatsAppSettings == null || _whatsAppSettings!.templates.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No message templates configured yet.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: const Color(0xFF7C839B), fontSize: 12),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _whatsAppSettings!.templates.length,
                    separatorBuilder: (c, i) => const Divider(height: 12), // Shrank from 16
                    itemBuilder: (ctx, idx) {
                      final template = _whatsAppSettings!.templates[idx];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.description_outlined, size: 18, color: Color(0xFF7C839B)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              template,
                              style: GoogleFonts.inter(fontSize: 12, height: 1.4, color: const Color(0xFF0B1C30)),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            icon: const Icon(Icons.delete_outline, color: Color(0xFFBA1A1A), size: 18),
                            onPressed: () => _deleteTemplate(idx),
                          ),
                        ],
                      );
                    },
                  ),
          ],
        ),
      ),
    ];
  }

  Widget _buildResponsiveRow(double width, {required Widget child1, required Widget child2}) {
    if (width > 600) {
      return Row(
        children: [
          Expanded(child: child1),
          const SizedBox(width: 12),
          Expanded(child: child2),
        ],
      );
    } else {
      return Column(
        children: [
          child1,
          const SizedBox(height: 12),
          child2,
        ],
      );
    }
  }

  Widget _buildMetaDetailsPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PLATFORM META DETAILS',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11, color: const Color(0xFF0B1C30), letterSpacing: 1.0),
          ),
          const SizedBox(height: 10), // Shrank from 12
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEFF4FF)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.query_stats, color: Color(0xFF006A61), size: 16),
                    const SizedBox(width: 8),
                    Text('Engine Hub', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0B1C30))),
                  ],
                ),
                Text('Live v1.0.4-POS', style: GoogleFonts.shareTechMono(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF006A61))),
              ],
            ),
          ),
          const SizedBox(height: 8), // Shrank from 10
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEFF4FF)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock_outline, color: Color(0xFF006A61), size: 16),
                    const SizedBox(width: 8),
                    Text('Terminal Encrypt', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0B1C30))),
                  ],
                ),
                Text('SHA256 Ready', style: GoogleFonts.shareTechMono(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF006A61))),
              ],
            ),
          ),
          const SizedBox(height: 10), // Shrank from 12
          Text(
            'Workspace updates undergo real time validation against system rules. Audit trails are compiled securely.',
            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF7C839B), height: 1.3),
          ),
        ],
      ),
    );
  }
}
