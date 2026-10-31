import 'dart:convert';
import 'package:http/http.dart' as http;

class TaskService {
  static const String baseUrl = 'http://10.0.2.2:3000/api/tasks';

  Future<List<dynamic>> getTasks() async {
    final response = await http.get(
      Uri.parse(baseUrl),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['tasks'];
    } else {
      throw Exception('Không thể tải danh sách công việc');
    }
  }

  Future<Map<String, dynamic>> getTaskDetail(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$id'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['task'];
    } else {
      throw Exception('Không thể tải chi tiết công việc');
    }
  }
}