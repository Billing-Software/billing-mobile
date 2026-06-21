import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  Future<User> login(String username, String password) async {
    final response = await _client.post('/auth/login', {
      'username': username,
      'password': password,
    });
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      final user = User.fromJson(json);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ApiClient.keyAuthData, response.body);
      return user;
    } else {
      throw Exception(response.body.isNotEmpty ? response.body : 'Login failed');
    }
  }

  Future<User> register(Map<String, dynamic> registerData) async {
    final response = await _client.post('/auth/register', registerData);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      final user = User.fromJson(json);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(ApiClient.keyAuthData, response.body);
      return user;
    } else {
      throw Exception(response.body.isNotEmpty ? response.body : 'Registration failed');
    }
  }

  Future<User?> getCurrentSessionUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(ApiClient.keyAuthData);
    if (data != null && data.isNotEmpty) {
      try {
        return User.fromJson(jsonDecode(data));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ApiClient.keyAuthData);
  }

  Future<bool> checkUsernameExists(String username) async {
    final response = await _client.get('/auth/check-username?username=${Uri.encodeComponent(username)}');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.trim().toLowerCase() == 'true';
    }
    throw Exception('Failed to check username availability');
  }

  Future<bool> checkEmailExists(String email) async {
    final response = await _client.get('/auth/check-email?email=${Uri.encodeComponent(email)}');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.trim().toLowerCase() == 'true';
    }
    throw Exception('Failed to check email availability');
  }
}
