import 'dart:convert';
import '../models/bill.dart';
import 'api_client.dart';

class BillService {
  final ApiClient _client = ApiClient();

  Future<List<Bill>> getAll() async {
    final response = await _client.get('/bills');
    if (response.statusCode == 200) {
      final List jsonList = jsonDecode(response.body);
      return jsonList.map((j) => Bill.fromJson(j)).toList();
    } else {
      throw Exception('Failed to fetch bills');
    }
  }

  Future<Bill> getById(int id) async {
    final response = await _client.get('/bills/$id');
    if (response.statusCode == 200) {
      return Bill.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch bill detail');
    }
  }

  Future<Bill> create(Map<String, dynamic> data) async {
    final response = await _client.post('/bills', data);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Bill.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(response.body.isNotEmpty ? response.body : 'Failed to create bill');
    }
  }

  Future<void> delete(int id) async {
    final response = await _client.delete('/bills/$id');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to delete bill');
    }
  }
}
