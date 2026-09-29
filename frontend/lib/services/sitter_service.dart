import 'dart:async';
import 'package:flutter/foundation.dart'; // Required for debugPrint

class SitterService {
  static Future<Map<String, dynamic>> getSitterProfile(String sitterId) async {
    debugPrint('FRONTEND LOG: Calling GET /api/sitters/$sitterId');
    await Future.delayed(const Duration(seconds: 1)); 
    return {'status': 'success', 'message': 'Profile loaded'};
  }

  static Future<void> initiateChat(String sitterId) async {
    debugPrint('FRONTEND LOG: Calling POST /api/messages/send for Sitter $sitterId');
    await Future.delayed(const Duration(seconds: 1));
    debugPrint('FRONTEND LOG: Backend acknowledged chat initiation.');
  }
}