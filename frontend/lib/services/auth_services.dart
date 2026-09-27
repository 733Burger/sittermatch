import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/preference_keys.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8080';

  Future<void> saveSession(String email, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PreferenceKeys.isLoggedIn, true);
    await prefs.setBool(PreferenceKeys.hasActiveAccount, true);
    await prefs.setString(PreferenceKeys.userEmail, email);
    await prefs.setString(PreferenceKeys.userRole, role);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PreferenceKeys.isLoggedIn);
    await prefs.remove(PreferenceKeys.userEmail);
    await prefs.remove(PreferenceKeys.userRole);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PreferenceKeys.isLoggedIn) ?? false;
  }

  Future<bool> hasActiveAccount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PreferenceKeys.hasActiveAccount) ?? false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PreferenceKeys.isLoggedIn, false);
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PreferenceKeys.userEmail);
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PreferenceKeys.userRole);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        await saveSession(email, json['role'] ?? '');
        return {'success': true, 'message': json['message']};
      } else {
        return {'success': false, 'message': json['message'] ?? 'Login failed.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error. Please try again later.'};
    }
  }

  Future<Map<String, dynamic>> signup({required String fullName, required String email, required String phoneNumber, required String password, required String role}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName.trim(),
          'email': email.trim(),
          'phoneNumber': phoneNumber.trim(),
          'password': password,
          'role': role,
        }),
      ).timeout(const Duration(seconds: 10));

      final json = jsonDecode(response.body);

      if (response.statusCode == 201 && json['success'] == true) {
        return {'success': true, 'message': json['message']};
      } else {
        return {'success': false, 'message': json['message'] ?? 'Signup failed.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error. Please try again later.'};
    }
  }
}