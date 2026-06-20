import 'dart:convert';
import 'api_client.dart';

class DashboardService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> getDashboardData() async {
    final response = await _client.get('/dashboard');
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch dashboard metrics');
    }
  }
}
