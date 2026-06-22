import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  static const String keyBaseUrl = 'api_base_url';
  static const String keyAuthData = 'auth_data';

  // Callback to trigger logout globally when 401 Unauthorized occurs
  VoidCallback? onUnauthorized;

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    String? saved = prefs.getString(keyBaseUrl);
    
    // Automatically migrate old default/localhost URLs to the new ngrok URL
    if (saved != null && (saved.contains('localhost') || saved.contains('192.168.'))) {
      saved = 'https://test.iamyourdad.site/api';
      await prefs.setString(keyBaseUrl, saved);
    }

    if (saved != null && saved.isNotEmpty) {
      return saved;
    }
    return 'https://test.iamyourdad.site/api';
  }

  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyBaseUrl, url);
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    String? authDataStr = prefs.getString(keyAuthData);
    if (authDataStr != null) {
      try {
        final authData = jsonDecode(authDataStr);
        String? token = authData['token'];
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      } catch (e) {
        debugPrint('Error parsing auth token: $e');
      }
    }
    return headers;
  }

  void _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      debugPrint('401 Unauthorized detected in ApiClient. Triggering logout callback.');
      if (onUnauthorized != null) {
        onUnauthorized!();
      }
    }
  }

  Future<http.Response> get(String path) async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders();
    final response = await http.get(uri, headers: headers);
    _handleResponse(response);
    return response;
  }

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders();
    final response = await http.post(uri, headers: headers, body: jsonEncode(body));
    _handleResponse(response);
    return response;
  }

  Future<http.Response> put(String path, Map<String, dynamic> body) async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders();
    final response = await http.put(uri, headers: headers, body: jsonEncode(body));
    _handleResponse(response);
    return response;
  }

  Future<http.Response> delete(String path) async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl$path');
    final headers = await _getHeaders();
    final response = await http.delete(uri, headers: headers);
    _handleResponse(response);
    return response;
  }
}
