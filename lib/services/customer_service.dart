import 'dart:convert';
import '../models/customer.dart';
import 'api_client.dart';

class CustomerService {
  final ApiClient _client = ApiClient();

  Future<List<Customer>> getAll() async {
    final response = await _client.get('/customers');
    if (response.statusCode == 200) {
      final List jsonList = jsonDecode(response.body);
      return jsonList.map((j) => Customer.fromJson(j)).toList();
    } else {
      throw Exception('Failed to fetch customers');
    }
  }

  Future<Customer> getById(int id) async {
    final response = await _client.get('/customers/$id');
    if (response.statusCode == 200) {
      return Customer.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch customer detail');
    }
  }

  Future<Customer> create(Map<String, dynamic> data) async {
    final response = await _client.post('/customers', data);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Customer.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body.isNotEmpty ? response.body : 'Failed to create customer');
    }
  }

  Future<Customer> update(int id, Map<String, dynamic> data) async {
    final response = await _client.put('/customers/$id', data);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Customer.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body.isNotEmpty ? response.body : 'Failed to update customer');
    }
  }

  Future<void> delete(int id) async {
    final response = await _client.delete('/customers/$id');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to delete customer');
    }
  }
}
