package com.sittermatch.sittermatch.dto;

public record IdentityCheckSubmitResponse(
    boolean success,
    String message
) {
    public record IdCheck(String status) {}

    public static IdentityCheckSubmitResponse failure (String message) {
        return new IdentityCheckSubmitResponse(false, message);
    }
}
