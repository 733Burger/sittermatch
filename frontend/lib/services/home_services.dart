import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/preference_keys.dart';
import '../config/api_config.dart';

class HomeService {
  final String _baseUrl = ApiConfig.baseUrl;

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PreferenceKeys.userEmail);
  }

  // Future<Map<String, dynamic>> fetchChecks({required String email}) async {
  //   final encodedEmail = Uri.encodeComponent(email);
  //   try {
  //     final response = await http.get(
  //       Uri.parse('$_baseUrl/api/home/$encodedEmail/verification'),
  //       headers: {'Content-Type': 'application/json'},
  //     ).timeout(const Duration(seconds: 10));

  //     final json = jsonDecode(response.body);

  //   } catch (e) {
  //     debugPrint('Error fetching checks: $e');
  //   }
  // }
}