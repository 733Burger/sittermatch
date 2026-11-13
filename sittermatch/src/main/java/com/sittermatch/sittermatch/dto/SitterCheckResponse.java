package com.sittermatch.sittermatch.dto;

import com.sittermatch.sittermatch.model.VerificationStatus;

// Same JSON shape as HomeownerCheckResponse, so the app reads both checklists the same way.
public record SitterCheckResponse(
    boolean success,
    CheckTile idCheck,
    CheckTile addressCheck,
    CheckTile emergencyContactCheck,
    String emergencyContactName,
    String emergencyContactNumber,
    int verificationCount,
    String verificationStatus,
    String message
) {
    public static SitterCheckResponse failure(String message) {
        return new SitterCheckResponse(
            false,
            CheckTile.of("error", message),
            CheckTile.of("error", message),
            CheckTile.of("error", message),
            "",
            "",
            0,
            VerificationStatus.INCOMPLETE.name(),
            message
        );
    }

    public static SitterCheckResponse noChecksFound() {
        return new SitterCheckResponse(
            true,
            CheckTile.of("incomplete", "No ID Uploaded"),
            CheckTile.of("incomplete", "No Address Uploaded"),
            CheckTile.of("incomplete", "No Emergency Contact Uploaded"),
            "",
            "",
            0,
            VerificationStatus.INCOMPLETE.name(),
            "Checks retrieved"
        );
    }

    public record CheckTile(String status, String subtitle) {
        public static CheckTile of(String status, String subtitle) {
            return new CheckTile(status, subtitle);
        }
    }
}
