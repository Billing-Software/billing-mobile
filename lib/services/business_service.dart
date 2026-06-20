import 'dart:convert';
import '../models/business.dart';
import 'api_client.dart';

class BusinessService {
  final ApiClient _client = ApiClient();

  Future<Business> getProfile() async {
    final response = await _client.get('/business');
    if (response.statusCode == 200) {
      return Business.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch business profile');
    }
  }

  Future<Business> updateProfile(Map<String, dynamic> businessData) async {
    final response = await _client.put('/business', businessData);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Business.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body.isNotEmpty ? response.body : 'Failed to update business profile');
    }
  }
}
