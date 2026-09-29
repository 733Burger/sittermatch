import 'package:flutter/foundation.dart';
import '../models/saved_sitter_model.dart';

class SavedSitterService {
  static Future<List<SavedSitterModel>> getSavedSitters() async {
    debugPrint('FRONTEND LOG: Calling Get /api/sitters/saved');
    await Future.delayed(const Duration(seconds: 1));

    return [
      SavedSitterModel(
        id: 'sitter_1',
        name: 'Lerato Khum...',
        price: 320,
        location: 'Camps Bay, Cape Town',
        verficationBadge: 'SAPS VERIFIED',
        rating: 4.95,
        reviewCount: 38,
        bioSnippet: '"Specialized in sensitive seniors, daily..."',
      ),
      SavedSitterModel(
        id: 'sitter_2',
        name: 'David Marais',
        price: 350,
        location: 'Constantia, Cape Town',
        verficationBadge: 'SAPS VERIFIED',
        rating: 5.0,
        reviewCount: 42,
        bioSnippet: '"Estate surveillance accredited. Highly..."',
      ),
      SavedSitterModel(
        id: 'sitter_3',
        name: 'Nomvula Sit...',
        price: 300,
        location: 'Rondebosch, Cape Town',
        verficationBadge: 'VET NURSE • POLICE CHECKED',
        rating: 4.98,
        reviewCount: 29,
        bioSnippet: '"Post-operative care, subcutaneous..."',
        isVetNurse: true,
      ),
    ];
  }
}