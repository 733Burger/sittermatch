package com.sittermatch.sittermatch.dto;

public record IdentityCheckSubmitResponse(
    boolean success,
    String message,
    IdCheck idCheck
) {
    public record IdCheck(String status) {}
}
