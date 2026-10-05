package com.sittermatch.sittermatch.dto;

public record EmergencyCheckResponse(
    boolean success,
    String message
    // HomeownerCheckResponse.CheckTile emergencyContactCheck
) {}