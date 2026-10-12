import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/preference_keys.dart';
import '../config/api_config.dart';


class AuthService {
  final String _baseUrl = ApiConfig.baseUrl;

  Future<void> saveSession(String email, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PreferenceKeys.isLoggedIn, true);
    await prefs.setBool(PreferenceKeys.isActiveUser, true);
    await prefs.setString(PreferenceKeys.userEmail, email);
    await prefs.setString(PreferenceKeys.userRole, role);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PreferenceKeys.isLoggedIn);
    await prefs.remove(PreferenceKeys.userEmail);
    await prefs.remove(PreferenceKeys.userRole);
  }

  Future<void> activateAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PreferenceKeys.isActiveUser, true);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PreferenceKeys.isLoggedIn) ?? false;
  }

  Future<bool> isActiveUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PreferenceKeys.isActiveUser) ?? false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PreferenceKeys.isLoggedIn, false);
    await prefs.remove(PreferenceKeys.userEmail);
    await prefs.remove(PreferenceKeys.userRole);
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PreferenceKeys.userEmail);
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PreferenceKeys.userRole);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  Future<void> setUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PreferenceKeys.userRole, role);
  }

  Future<bool> validateSession() async {
    final loggedIn = await isLoggedIn();
    final email = await getUserEmail();
    final role = await getUserRole();

    if (!loggedIn || email == null || email.isEmpty || role == null || role.isEmpty) {
      return false;
    } else {
      return true;
    }
    // commented out because I couldn't find the api it was calling and it was causing a delay on flutter frames
    // try {
    //   final response = await http.get(
    //     Uri.parse('$_baseUrl/api/auth/validate?email=${Uri.encodeComponent(email)}'),
    //     headers: {'Content-Type': 'application/json'},
    //   ).timeout(const Duration(seconds: 5));

    //   if (response.statusCode == 200) {
    //     final json = jsonDecode(response.body);
    //     if (json['valid'] == true) {
    //       return true;
    //     }
    //   }

    //   await logout();
    //   return false;
    // } catch (e) {
    //   return loggedIn;
    // }
  }

  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      final json = jsonDecode(response.body);

      if (response.statusCode == 200 && json['success'] == true) {
        await saveSession(email, json['role'] ?? '');
  
        // Save user/sitter ID to SharedPreferences so SitterHomeScreen can read it
        final prefs = await SharedPreferences.getInstance();
        if (json['userId'] != null) {
          await prefs.setInt('userId', json['userId']);
        } else if (json['id'] != null) {
          await prefs.setInt('userId', json['id']);
        }

        return {'success': true, 'message': json['message'], 'role': json['role']};
      }else {
        return {'success': false, 'message': json['message'] ?? 'Login failed.'};
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> signup({required String fullName, required String email, required String phoneNumber, required String password,required String role,}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/signup'),
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

      if ((response.statusCode == 200 || response.statusCode == 201) && json['success'] == true) {
        activateAccount();
        return {'success': true, 'message': json['message']};
      } else {
        return {'success': false, 'message': json['message'] ?? 'Signup failed.'};
      }
    } catch (e) {
      debugPrint('Signup error: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}