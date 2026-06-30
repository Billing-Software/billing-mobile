import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/settings.dart';
import '../../services/settings_service.dart';
import '../../widgets/custom_text_field.dart';

class WhatsappPage extends StatefulWidget {
  final WhatsAppSettings? settings;
  final VoidCallback onSaved;

  const WhatsappPage({
    Key? key,
    required this.settings,
    required this.onSaved,
  }) : super(key: key);

  @override
  State<WhatsappPage> createState() => _WhatsappPageState();
}

class _WhatsappPageState extends State<WhatsappPage> {
  final SettingsService _settingsService = SettingsService();

  late final TextEditingController _apiKeyController;
  late final TextEditingController _newTemplateController;
  late WhatsAppSettings? _settings;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _apiKeyController = TextEditingController(text: _settings?.apiKey ?? '');
    _newTemplateController = TextEditingController();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _newTemplateController.dispose();
    super.dispose();
  }

  Future<void> _updateApiKey() async {
    final key = _apiKeyController.text.trim();
    setState(() => _isSaving = true);

    try {
      final updated = await _settingsService.updateWhatsAppSettings({
        'apiKey': key,
        'isConnected': key.isNotEmpty,
      });

      if (mounted) {
        setState(() {
          _settings = updated;
          _isSaving = false;
        });
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API key updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  Future<void> _addTemplate() async {
    final text = _newTemplateController.text.trim();
    if (text.isEmpty) return;

    try {
      final updated = await _settingsService.addWhatsAppTemplate({
        'template': text,
      });

      if (mounted) {
        setState(() {
          _settings = updated;
          _newTemplateController.clear();
        });
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template added')),
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
      final updated = await _settingsService.getWhatsAppSettings();

      if (mounted) {
        setState(() => _settings = updated);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _settings?.isConnected ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text('WhatsApp', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: ListView(
          children: [
            const SizedBox(height: 8),

            // Connection status
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isConnected ? const Color(0xFFF0FDF4) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isConnected ? Icons.check_circle_rounded : Icons.link_off_rounded,
                      color: isConnected ? const Color(0xFF16A34A) : const Color(0xFF6B7280),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gateway status',
                          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isConnected ? 'Connected' : 'Not connected',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isConnected ? const Color(0xFF16A34A) : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // API Key
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CustomTextField(
                controller: _apiKeyController,
                label: 'API key',
                placeholder: 'Enter your WhatsApp API key',
                obscureText: true,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                onFieldSubmitted: (_) => _updateApiKey(),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _updateApiKey,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text('Save key', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ),

            const Divider(height: 40),

            // Templates section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Message templates',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Add template
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _newTemplateController,
                      label: 'New template',
                      placeholder: 'Type your message template...',
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF006A61),
                        foregroundColor: Colors.white,
                        fixedSize: const Size(48, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _addTemplate,
                      icon: const Icon(Icons.add_rounded, size: 22),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Template list
            if (_settings == null || _settings!.templates.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Center(
                  child: Text(
                    'No templates yet',
                    style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 14),
                  ),
                ),
              )
            else
              ...List.generate(_settings!.templates.length, (idx) {
                final template = _settings!.templates[idx];
                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.article_rounded, color: Color(0xFF6B7280), size: 18),
                      ),
                      title: Text(
                        template,
                        style: GoogleFonts.inter(fontSize: 14, height: 1.4),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626), size: 20),
                        onPressed: () => _deleteTemplate(idx),
                      ),
                    ),
                    if (idx < _settings!.templates.length - 1)
                      const Divider(height: 1, indent: 72),
                  ],
                );
              }),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
