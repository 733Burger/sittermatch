enum CheckStatus {
  incomplete,
  pending,
  completed;

  static CheckStatus fromString(String? value) {
    switch (value) {
      case 'completed':
        return CheckStatus.completed;
      case 'pending':
        return CheckStatus.pending;
      default:
        return CheckStatus.incomplete;
    }
  }
}

enum VerificationStatus {
  incomplete,
  pending,
  approved,
  rejected;

  static VerificationStatus fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'APPROVED':
        return VerificationStatus.approved;
      case 'PENDING':
        return VerificationStatus.pending;
      case 'REJECTED':
        return VerificationStatus.rejected;
      default:
        return VerificationStatus.incomplete;
    }
  }
}

class VerificationCheck {
  final CheckStatus status;
  final String subtitle;

  const VerificationCheck({
    this.status = CheckStatus.incomplete,
    this.subtitle = '',
  });

  factory VerificationCheck.fromJson(Object? json) {
    if (json is! Map) return const VerificationCheck();
    return VerificationCheck(
      status: CheckStatus.fromString(json['status']?.toString()),
      subtitle: json['subtitle']?.toString() ?? '',
    );
  }
}

class OwnerChecks {
  final VerificationCheck idCheck;
  final VerificationCheck addressCheck;
  final VerificationCheck emergencyContactCheck;
  final String emergencyContactName;
  final String emergencyContactNumber;
  final int verificationCount;
  final VerificationStatus verificationStatus;

  const OwnerChecks({
    this.idCheck = const VerificationCheck(),
    this.addressCheck = const VerificationCheck(),
    this.emergencyContactCheck = const VerificationCheck(),
    this.emergencyContactName = '',
    this.emergencyContactNumber = '',
    this.verificationCount = 0,
    this.verificationStatus = VerificationStatus.incomplete,
  });

  factory OwnerChecks.fromJson(Map<String, dynamic> json) {
    final count = json['verificationCount'];
    return OwnerChecks(
      idCheck: VerificationCheck.fromJson(json['idCheck']),
      addressCheck: VerificationCheck.fromJson(json['addressCheck']),
      emergencyContactCheck: VerificationCheck.fromJson(json['emergencyContactCheck']),
      emergencyContactName: json['emergencyContactName']?.toString() ?? '',
      emergencyContactNumber: json['emergencyContactNumber']?.toString() ?? '',
      verificationCount: (count is num) ? count.toInt() : int.tryParse(count?.toString() ?? '') ?? 0,
      verificationStatus: VerificationStatus.fromString(json['verificationStatus']?.toString()),
    );
  }

  List<VerificationCheck> get all => [
        idCheck,
        addressCheck,
        emergencyContactCheck,
      ];

  int get totalChecks => all.length;
  bool get allDone => verificationCount >= totalChecks;
  double get progress => (verificationCount / totalChecks).clamp(0.0, 1.0);
}