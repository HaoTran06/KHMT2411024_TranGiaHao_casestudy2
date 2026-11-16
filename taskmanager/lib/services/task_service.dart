
import 'dart:convert';
import 'package:http/http.dart' as http;

class TaskService {
  static const String baseUrl = 'http://10.0.2.2:3000/api/tasks';

  final String token;

  TaskService({required this.token});

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // Lấy danh sách công việc
  Future<List<dynamic>> getTasks() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['tasks'] ?? [];
    }

    throw Exception('Không thể tải công việc: ${response.body}');
  }

  // Xem chi tiết công việc
  Future<Map<String, dynamic>> getTaskDetail(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data['task']);
    }

    throw Exception('Không thể tải chi tiết: ${response.body}');
  }

  // Tìm người dùng theo tên hoặc email
  Future<List<dynamic>> searchUsers(String keyword) async {
    final uri = Uri.parse('$baseUrl/users/search').replace(
      queryParameters: {'q': keyword},
    );

    final response = await http.get(
      uri,
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['users'] ?? [];
    }

    throw Exception('Không thể tìm người dùng: ${response.body}');
  }

  // Giao công việc cho nhiều người
  Future<Map<String, dynamic>> assignTask({
    required String taskId,
    required List<String> assignees,
    String? primaryAssignee,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$taskId/assign'),
      headers: headers,
      body: jsonEncode({
        'assignees': assignees,
        'primaryAssignee': primaryAssignee,
      }),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Giao công việc thất bại: ${response.body}');
  }

  // Chia sẻ công việc và phân quyền
  Future<Map<String, dynamic>> shareTask({
    required String taskId,
    required String userId,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$taskId/share'),
      headers: headers,
      body: jsonEncode({
        'userId': userId,
        'role': role,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Chia sẻ công việc thất bại: ${response.body}');
  }

  // Thu hồi quyền chia sẻ
  Future<void> removeSharedUser({
    required String taskId,
    required String userId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$taskId/share/$userId'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Thu hồi quyền thất bại: ${response.body}');
    }
  }

  // Tạo công việc
  Future<Map<String, dynamic>> createTask({
    required String title,
    required String description,
    DateTime? startDate,
    DateTime? dueDate,
    required String priority,
    required String status,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: jsonEncode({
        'title': title,
        'description': description,
        'startDate': startDate?.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'priority': priority,
        'status': status,
      }),
    );

    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Tạo công việc thất bại: ${response.body}');
  }

  // Cập nhật công việc
  Future<Map<String, dynamic>> updateTask({
    required String id,
    required String title,
    required String description,
    required String status,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
      body: jsonEncode({
        'title': title,
        'description': description,
        'status': status,
      }),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }

    throw Exception('Cập nhật thất bại: ${response.body}');
  }

  // Xóa công việc
  Future<void> deleteTask(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Xóa công việc thất bại: ${response.body}');
    }
  }
}
