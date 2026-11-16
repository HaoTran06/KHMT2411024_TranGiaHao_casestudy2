
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileService {
  static const String baseUrl =
      'http://10.0.2.2:3000/api/profile';

  final String token;

  ProfileService({required this.token});

  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Không thể tải hồ sơ: ${response.body}',
    );
  }
}
