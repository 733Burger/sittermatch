import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:frontend/models/login_request.dart';
import 'package:frontend/models/login_response.dart';
import 'package:frontend/models/signUp_response.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8080';

  Future<LoginResponse> login(String email, String password) async {
    try{
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': email.trim(), 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return LoginResponse.fromJson(jsonResponse);
      }

      return const LoginResponse(success: false, message: 'Invalid email or password.');

    } catch (_) {
      return const LoginResponse(success: false, message: 'Network error. Please try again later.');
    }
  }

  Future<SignupResponse> signup(String fullName, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/signup'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'fullName': fullName.trim(),
          'email': email.trim(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return SignupResponse.fromJson(jsonResponse);
      }

      return const SignupResponse(success: false, message: 'Failed to create account.');

    } catch (_) {
      return const SignupResponse(success: false, message: 'Network error. Please try again later.');
    }
  }
}