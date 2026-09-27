import 'dart:convert';
import 'package:http/http.dart' as http;

class UserServices {
  static const String baseUrl = 'http://10.0.2.2:8080';

  Future<Map<String, dynamic>?> getUserRoles(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$email/roles'),
      ).timeout(const Duration(seconds: 10));

      final json = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return json;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}