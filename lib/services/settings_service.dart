import 'dart:convert';
import '../models/settings.dart';
import 'api_client.dart';

class SettingsService {
  final ApiClient _client = ApiClient();

  Future<WhatsAppSettings> getWhatsAppSettings() async {
    final response = await _client.get('/settings/whatsapp');
    if (response.statusCode == 200) {
      return WhatsAppSettings.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch WhatsApp settings');
    }
  }

  Future<WhatsAppSettings> updateWhatsAppSettings(Map<String, dynamic> settingsData) async {
    final response = await _client.put('/settings/whatsapp', settingsData);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return WhatsAppSettings.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body.isNotEmpty ? response.body : 'Failed to update WhatsApp settings');
    }
  }

  Future<WhatsAppSettings> addWhatsAppTemplate(Map<String, dynamic> templateData) async {
    final response = await _client.post('/settings/whatsapp/templates', templateData);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return WhatsAppSettings.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body.isNotEmpty ? response.body : 'Failed to add template');
    }
  }

  Future<void> deleteWhatsAppTemplate(int id) async {
    final response = await _client.delete('/settings/whatsapp/templates/$id');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to delete template');
    }
  }
}
