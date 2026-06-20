import 'dart:convert';
import '../models/inventory.dart';
import 'api_client.dart';

class InventoryService {
  final ApiClient _client = ApiClient();

  Future<List<InventoryItem>> getAll() async {
    final response = await _client.get('/inventory');
    if (response.statusCode == 200) {
      final List jsonList = jsonDecode(response.body);
      return jsonList.map((j) => InventoryItem.fromJson(j)).toList();
    } else {
      throw Exception('Failed to fetch inventory');
    }
  }

  Future<InventoryItem> getById(int id) async {
    final response = await _client.get('/inventory/$id');
    if (response.statusCode == 200) {
      return InventoryItem.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch inventory item');
    }
  }

  Future<InventoryItem> create(Map<String, dynamic> data) async {
    final response = await _client.post('/inventory', data);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return InventoryItem.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body.isNotEmpty ? response.body : 'Failed to create inventory item');
    }
  }

  Future<InventoryItem> update(int id, Map<String, dynamic> data) async {
    final response = await _client.put('/inventory/$id', data);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return InventoryItem.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body.isNotEmpty ? response.body : 'Failed to update inventory item');
    }
  }

  Future<void> delete(int id) async {
    final response = await _client.delete('/inventory/$id');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to delete inventory item');
    }
  }
}
