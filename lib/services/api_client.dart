import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  static const String keyBaseUrl = 'api_base_url';
  static const String keyAuthData = 'auth_data';

  // Cache base URL for synchronous access
  static String cachedBaseUrl = 'https://api.chubbycat.fun/api';

  static String resolveUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    if (trimmed.startsWith('/uploads/')) {
      final serverBase = cachedBaseUrl.replaceAll('/api', '');
      return '$serverBase$trimmed';
    }
    if (trimmed.contains('localhost') || trimmed.contains('127.0.0.1')) {
      final serverBase = cachedBaseUrl.replaceAll('/api', '');
      final uploadsIndex = trimmed.indexOf('/uploads/');
      if (uploadsIndex != -1) {
        return '$serverBase${trimmed.substring(uploadsIndex)}';
      }
    }
    return trimmed;
  }

  // Callback to trigger logout globally when 401 Unauthorized occurs
  VoidCallback? onUnauthorized;

  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    String? saved = prefs.getString(keyBaseUrl);
    
    // Automatically migrate old default/localhost/staging URLs to the new production URL
    if (saved != null && (saved.contains('localhost') || saved.contains('192.168.') || saved.contains('test.iamyourdad.site') || saved.contains('chubbycat.fun') && !saved.contains('https://api.chubbycat.fun/api'))) {
      saved = 'https://api.chubbycat.fun/api';
      await prefs.setString(keyBaseUrl, saved);
    }

    if (saved != null && saved.isNotEmpty) {
      cachedBaseUrl = saved;
      return saved;
    }
    cachedBaseUrl = 'https://api.chubbycat.fun/api';
    return 'https://api.chubbycat.fun/api';
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

  Future<http.Response> uploadImage(String path, Uint8List bytes, String filename) async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri);
    
    final headers = await _getHeaders();
    request.headers.addAll(headers);
    request.headers.remove('Content-Type'); // Handled automatically by MultipartRequest

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    _handleResponse(response);
    return response;
  }
}
