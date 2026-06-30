import 'dart:convert';
import '../models/expense.dart';
import 'api_client.dart';

class ExpenseService {
  final ApiClient _client = ApiClient();

  Future<List<Expense>> getAll() async {
    final response = await _client.get('/expenses');
    if (response.statusCode == 200) {
      final List jsonList = jsonDecode(response.body);
      return jsonList.map((j) => Expense.fromJson(j)).toList();
    } else {
      throw Exception('Failed to fetch expenses');
    }
  }

  Future<Expense> create(Map<String, dynamic> data) async {
    final response = await _client.post('/expenses', data);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Expense.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body.isNotEmpty ? response.body : 'Failed to register expense');
    }
  }

  Future<void> delete(int id) async {
    final response = await _client.delete('/expenses/$id');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to delete expense');
    }
  }
}
