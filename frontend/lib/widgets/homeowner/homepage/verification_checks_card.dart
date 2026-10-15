import 'package:flutter/material.dart';

import '../../../models/homeowner_checks_model.dart';
import '../../../theme/app_colors.dart';
import '../../verification_check_tile.dart';

class VerificationChecksCard extends StatefulWidget {
  const VerificationChecksCard({
    super.key,
    required this.checks,
    required this.onIdentityTap,
    required this.onAddressTap,
    required this.onEmergencyContactTap,
  });

  final OwnerChecks checks;
  final VoidCallback onIdentityTap;
  final VoidCallback onAddressTap;
  final VoidCallback onEmergencyContactTap;

  @override
  State<VerificationChecksCard> createState() => _VerificationChecksCardState();
}

class _VerificationChecksCardState extends State<VerificationChecksCard> {
  bool _expanded = false;

  String get _title {
    switch (widget.checks.verificationStatus) {
      case VerificationStatus.approved:
        return 'Profile checks complete';
      case VerificationStatus.pending:
        return 'Profile checks under review';
      case VerificationStatus.rejected:
        return 'Profile checks need attention';
      case VerificationStatus.incomplete:
        return 'Complete your profile';
    }
  }

  String get _subtitle {
    final checks = widget.checks;
    final done = checks.verificationCount;
    final total = checks.totalChecks;
    switch (checks.verificationStatus) {
      case VerificationStatus.approved:
        return 'You’re ready to book sitters';
      case VerificationStatus.pending:
        return '$done of $total submitted — Waiting for admin review';
      case VerificationStatus.rejected:
        return 'One or more checks were rejected — Please update and resubmit';
      case VerificationStatus.incomplete:
        return '$done of $total checks done';
    }
  }

  @override
  Widget build(BuildContext context) {
    final checks = widget.checks;

    return Material(
      color: Colors.white,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryRust.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      checks.allDone
                          ? Icons.verified_rounded
                          : Icons.shield_outlined,
                      color: AppColors.primaryRust,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: checks.progress,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            color: AppColors.primaryRust,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      children: [
                        Divider(height: 1, color: Colors.grey.shade200),
                        const SizedBox(height: 4),
                        VerificationCheckTile(
                          title: 'Identity / SA ID Verification',
                          subtitle: checks.idCheck.subtitle,
                          status: checks.idCheck.status,
                          onTap: widget.onIdentityTap,
                        ),
                        VerificationCheckTile(
                          title: 'Home Address / Proof of Residence',
                          subtitle: checks.addressCheck.subtitle,
                          status: checks.addressCheck.status,
                          onTap: widget.onAddressTap,
                        ),
                        VerificationCheckTile(
                          title: 'Emergency Contact Details',
                          subtitle: checks.emergencyContactCheck.subtitle,
                          status: checks.emergencyContactCheck.status,
                          onTap: widget.onEmergencyContactTap,
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}