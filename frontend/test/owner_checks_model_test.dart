import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/owner_checks_model.dart';
import 'package:frontend/models/sitter_listing.dart';

void main() {
  group('OwnerChecks.fromJson', () {
    test('parses a full response', () {
      final checks = OwnerChecks.fromJson({
        'success': true,
        'idCheck': {'status': 'completed', 'subtitle': 'Verified'},
        'addressCheck': {'status': 'pending', 'subtitle': '1 Main Rd'},
        'emergencyContactCheck': {'status': 'incomplete', 'subtitle': ''},
        'emergencyContactName': 'Jane',
        'emergencyContactNumber': '0820000000',
        'verificationCount': 2,
        'verificationStatus': 'pending',
      });

      expect(checks.idCheck.status, CheckStatus.completed);
      expect(checks.addressCheck.status, CheckStatus.pending);
      expect(checks.addressCheck.subtitle, '1 Main Rd');
      expect(checks.emergencyContactCheck.status, CheckStatus.incomplete);
      expect(checks.emergencyContactName, 'Jane');
      expect(checks.emergencyContactNumber, '0820000000');
      expect(checks.verificationCount, 2);
      expect(checks.verificationStatus, VerificationStatus.pending);
      expect(checks.totalChecks, 3);
      expect(checks.allDone, isFalse);
    });

    test('falls back to defaults when keys are missing or malformed', () {
      final checks = OwnerChecks.fromJson({
        'idCheck': null,
        'addressCheck': 'oops',
        'verificationCount': 'x',
      });

      expect(checks.idCheck.status, CheckStatus.incomplete);
      expect(checks.idCheck.subtitle, '');
      expect(checks.addressCheck.status, CheckStatus.incomplete);
      expect(checks.emergencyContactCheck.status, CheckStatus.incomplete);
      expect(checks.emergencyContactName, '');
      expect(checks.verificationCount, 0);
      expect(checks.verificationStatus, VerificationStatus.incomplete);
      expect(checks.progress, 0.0);
    });
  });

  test('SitterListing.listFromJson skips invalid entries', () {
    final sitters = SitterListing.listFromJson([
      {
        'id': 1,
        'name': 'Sam',
        'suburb': 'Rondebosch',
        'rating': 4,
        'totalReviews': 3,
        'nightRate': 200,
        'completedChecks': ['SA ID Verified'],
      },
      'not a sitter',
    ]);

    expect(sitters, hasLength(1));
    expect(sitters.first.rating, 4.0);
    expect(sitters.first.imageUrl, isNull);
    expect(sitters.first.completedChecks, ['SA ID Verified']);
    expect(SitterListing.listFromJson(null), isEmpty);
  });
}
