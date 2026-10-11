package com.sittermatch.sittermatch.dto;


public record SitterCheckResponse(
    boolean success,
    CheckTile idCheck,
    CheckTile residenceCheck,
    CheckTile emergencyCheck,
    String emergencyContactName,
    String emergencyContactPhone,
    int completedChecksCount,
    String overallStatus,
    String message
) {
    public static SitterCheckResponse failure(String message) {
        return new SitterCheckResponse(false, null, null, null, null, null, 0, null, message);
    }

    public static SitterCheckResponse noChecksFound() {
        return new SitterCheckResponse(
            true,
            CheckTile.of("incomplete", "No ID uploaded"),
            CheckTile.of("incomplete", "No address provided"),
            CheckTile.of("incomplete", "No Emergency Contact Uploaded"),
            "",
            "",
            0,
            "INCOMPLETE",
            "Checks retrieved"
        );
    }

    public record CheckTile(String status, String subtitle) {
        public static CheckTile of(String status, String subtitle) {
            return new CheckTile(status, subtitle);
        }
    }
}
