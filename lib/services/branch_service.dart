import 'dart:convert';
import 'api_client.dart';

class BranchService {
  final ApiClient _client = ApiClient();

  Future<List<Map<String, dynamic>>> getAll() async {
    final response = await _client.get('/branches');
    if (response.statusCode == 200) {
      final List jsonList = jsonDecode(response.body);
      return jsonList.map((j) => Map<String, dynamic>.from(j)).toList();
    } else {
      throw Exception('Failed to fetch branches');
    }
  }

  Future<Map<String, dynamic>> getById(int id) async {
    final response = await _client.get('/branches/$id');
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch branch detail');
    }
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final response = await _client.post('/branches', data);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception(response.body.isNotEmpty ? response.body : 'Failed to create branch');
    }
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> data) async {
    final response = await _client.put('/branches/$id', data);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception(response.body.isNotEmpty ? response.body : 'Failed to update branch');
    }
  }

  Future<void> delete(int id) async {
    final response = await _client.delete('/branches/$id');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to delete branch');
    }
  }
}
