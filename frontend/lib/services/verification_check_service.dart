import 'dart:typed_data';

/// The profile checks (ID, home address, emergency contact) that both homeowners and sitters
/// complete. Each call returns a map with `success` and `message`; [fetchChecks] also returns
/// the fields read by `OwnerChecks.fromJson`.
abstract class VerificationCheckService {
  Future<Map<String, dynamic>> fetchChecks();

  Future<Map<String, dynamic>> submitIdentityCheck({
    required String email,
    required Uint8List bytes,
    required String filename,
  });

  Future<Map<String, dynamic>> submitResidenceCheck({
    required String email,
    required String address,
  });

  Future<Map<String, dynamic>> submitEmergencyCheck({
    required String email,
    required String name,
    required String phoneNumber,
  });
}
