package com.sittermatch.sittermatch.dto;

public record HomeownerCheckResponse(
    boolean success,
    String message,
    CheckTile idCheck,
    CheckTile addressCheck,
    CheckTile emergencyContactCheck,
    String emergencyContactName,
    String emergencyContactNumber
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
                ""
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
                ""
        );
    }

    // public static HomeownerCheckResponse success(
    //         String idStatus, String idSubtitle,
    //         String addressStatus, String addressSubtitle,
    //         String emergencyContactStatus, String emergencyContactSubtitle,
    //         String emergencyContactName, String emergencyContactNumber) {
    //     return new HomeownerCheckResponse(
    //             true,
    //             "Checks retrieved successfully",
    //             CheckTile.of(idStatus, idSubtitle),
    //             CheckTile.of(addressStatus, addressSubtitle),
    //             CheckTile.of(emergencyContactStatus, emergencyContactSubtitle),
    //             emergencyContactName,
    //             emergencyContactStatus
    //     );
    // }
}