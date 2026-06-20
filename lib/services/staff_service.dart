import 'dart:convert';
import '../models/staff.dart';
import 'api_client.dart';

class StaffService {
  final ApiClient _client = ApiClient();

  Future<List<StaffMember>> getAll() async {
    final response = await _client.get('/staff');
    if (response.statusCode == 200) {
      final List jsonList = jsonDecode(response.body);
      return jsonList.map((j) => StaffMember.fromJson(j)).toList();
    } else {
      throw Exception('Failed to fetch staff members');
    }
  }

  Future<StaffMember> getById(int id) async {
    final response = await _client.get('/staff/$id');
    if (response.statusCode == 200) {
      return StaffMember.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch staff detail');
    }
  }

  Future<StaffMember> create(Map<String, dynamic> data) async {
    final response = await _client.post('/staff', data);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return StaffMember.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body.isNotEmpty ? response.body : 'Failed to create staff member');
    }
  }

  Future<StaffMember> update(int id, Map<String, dynamic> data) async {
    final response = await _client.put('/staff/$id', data);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return StaffMember.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body.isNotEmpty ? response.body : 'Failed to update staff member');
    }
  }

  Future<void> delete(int id) async {
    final response = await _client.delete('/staff/$id');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to delete staff member');
    }
  }
}
