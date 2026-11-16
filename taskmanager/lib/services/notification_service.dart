
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String baseUrl =
      'http://10.0.2.2:3000/api/notifications';

  final String token;

  NotificationService({required this.token});

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // Lấy danh sách thông báo
  Future<List<dynamic>> getNotifications() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data;
      }

      throw Exception('Dữ liệu thông báo không hợp lệ');
    }

    throw Exception(
      'Không thể tải thông báo: ${response.body}',
    );
  }

  // Đánh dấu thông báo đã đọc
  Future<void> markAsRead(String notificationId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$notificationId/read'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Không thể đánh dấu đã đọc: ${response.body}',
      );
    }
  }
}
