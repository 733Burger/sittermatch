package com.sittermatch.sittermatch.dto;

import com.sittermatch.sittermatch.model.VerificationStatus;

public record HomeownerCheckResponse(
    boolean success,
    String message,
    CheckTile idCheck,
    CheckTile addressCheck,
    CheckTile emergencyContactCheck,
    String emergencyContactName,
    String emergencyContactNumber,
    int verificationCount,
    String verificationStatus
) {
    public record CheckTile(String status, String subtitle) {
        public static CheckTile of(String status, String subtitle) {
            return new CheckTile(status, subtitle);
        }
    }

    public static HomeownerCheckResponse noChecksFound() {
        return new HomeownerCheckResponse(
                false,
                "No checks found for this homeowner",
                CheckTile.of("incomplete", "No ID Uploaded"),
                CheckTile.of("incomplete", "No Address Uploaded"),
                CheckTile.of("incomplete", "No Emergency Contact Uploaded"),
                "",
                "",
                0,
                VerificationStatus.INCOMPLETE.name()
        );
    }

    public static HomeownerCheckResponse failure(String message) {
        return new HomeownerCheckResponse(
                false,
                message,
                CheckTile.of("error", message),
                CheckTile.of("error", message),
                CheckTile.of("error", message),
                "",
                "",
                0,
                VerificationStatus.INCOMPLETE.name()
        );
    }
}