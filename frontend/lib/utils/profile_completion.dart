import 'package:flutter/foundation.dart';

import '../services/auth_services.dart';
import '../services/profile_service.dart';

/// What the signed-in user still has to fill in on their profile before they can use the rest
/// of the app, e.g. ['your phone number', 'at least one pet']. Empty when the profile is complete.
///
/// If the profile can't be loaded (no connection, say) this returns an empty list, so a network
/// problem never locks someone out of the app.
Future<List<String>> missingProfileItems() async {
  final auth = AuthService();
  final userId = await auth.getUserId();
  final role = (await auth.getUserRole() ?? '').toUpperCase();
  if (userId == null) return const [];

  try {
    if (role == 'HOMEOWNER') return await _missingForHomeowner(userId);
    if (role == 'SITTER') return await _missingForSitter(userId);
  } catch (e) {
    debugPrint('Could not check the profile: $e');
  }
  return const [];
}

bool _blank(Object? value) => (value ?? '').toString().trim().isEmpty;

Future<List<String>> _missingForHomeowner(int userId) async {
  final service = ProfileService();
  final profile = await service.fetchProfile(userId: userId);
  if (profile['success'] != true) return const [];
  final pets = await service.fetchPets(homeownerId: userId);

  return [
    if (_blank(profile['name'])) 'your name',
    if (_blank(profile['phone'])) 'your phone number',
    // The address has to be picked from the suggestions so its location is saved.
    if (_blank(profile['address']) || profile['latitude'] == null || profile['longitude'] == null)
      'your home address',
    if (_blank(profile['requirements'])) 'house sitting notes',
    if (pets['success'] == true && (pets['pets'] as List).isEmpty) 'at least one pet',
  ];
}

Future<List<String>> _missingForSitter(int userId) async {
  final details = await ProfileService().fetchSitterProfile(userId: userId);
  if (details['success'] != true) return const [];

  return [
    if (_blank(details['name'])) 'your name',
    if (_blank(details['phone'])) 'your phone number',
    // The area has to be picked from the suggestions so its location is saved.
    if (_blank(details['serviceArea']) || details['latitude'] == null || details['longitude'] == null)
      'your area of service',
    if (_blank(details['experience'])) 'an About me',
    if (((details['services'] as List?) ?? []).isEmpty) 'at least one service with a price',
    if (((details['petPreferences'] as List?) ?? []).isEmpty) 'the pets you look after',
  ];
}

/// "your name, your phone number and at least one pet"
String describeMissing(List<String> missing) {
  if (missing.length <= 1) return missing.join();
  return '${missing.sublist(0, missing.length - 1).join(', ')} and ${missing.last}';
}
