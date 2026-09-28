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

  Future<Map<String, dynamic>> switchActiveRole(String email, String role) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/users/$email/role-switch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'role': role}),
      ).timeout(const Duration(seconds: 10));

      final json = jsonDecode(response.body);
      return{
        'success': json['success'] ?? false,
        'message': json['message'] ?? 'Something went wrong',
        'activeRole': json['activeRole'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error. Please try again later'};
    }
  }

  Future<Map<String, dynamic>> addRole(String email, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/$email/roles'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'role': role}),
      ).timeout(const Duration(seconds: 10));

      final json = jsonDecode(response.body);
      return{
        'success': json['success'] ?? false,
        'message': json['message'] ?? 'Something went wrong',
        'activeRole': json['activeRole'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Network error. Please try again later'};
    }
  }
}