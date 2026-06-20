import 'dart:convert';
import '../models/service.dart';
import 'api_client.dart';

class ServiceCatalogService {
  final ApiClient _client = ApiClient();

  Future<List<Service>> getAll() async {
    final response = await _client.get('/services');
    if (response.statusCode == 200) {
      final List jsonList = jsonDecode(response.body);
      return jsonList.map((j) => Service.fromJson(j)).toList();
    } else {
      throw Exception('Failed to fetch services');
    }
  }

  Future<Service> getById(int id) async {
    final response = await _client.get('/services/$id');
    if (response.statusCode == 200) {
      return Service.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch service detail');
    }
  }

  Future<Service> create(Map<String, dynamic> data) async {
    final response = await _client.post('/services', data);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Service.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body.isNotEmpty ? response.body : 'Failed to create service');
    }
  }

  Future<Service> update(int id, Map<String, dynamic> data) async {
    final response = await _client.put('/services/$id', data);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Service.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body.isNotEmpty ? response.body : 'Failed to update service');
    }
  }

  Future<void> delete(int id) async {
    final response = await _client.delete('/services/$id');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to delete service');
    }
  }
}
