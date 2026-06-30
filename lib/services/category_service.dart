import 'dart:convert';
import '../models/category.dart';
import 'api_client.dart';

class CategoryService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Category>> getAll() async {
    final response = await _apiClient.get('/categories');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories: ${response.body}');
    }
  }

  Future<Category> create(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/categories', data);
    if (response.statusCode == 200) {
      return Category.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create category: ${response.body}');
    }
  }

  Future<void> delete(int id) async {
    final response = await _apiClient.delete('/categories/$id');
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete category: ${response.body}');
    }
  }
}
