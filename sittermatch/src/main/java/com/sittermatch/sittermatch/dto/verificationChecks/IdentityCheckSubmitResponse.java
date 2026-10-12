package com.sittermatch.sittermatch.dto.verificationChecks;

public record IdentityCheckSubmitResponse(
    boolean success,
    String message
) {
    public record IdCheck(String status) {}

    public static IdentityCheckSubmitResponse failure (String message) {
        return new IdentityCheckSubmitResponse(false, message);
    }
}
