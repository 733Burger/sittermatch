package com.sittermatch.sittermatch.dto.verificationChecks;

public record EmergencyCheckRequest(
    String email,
    String name,
    String phoneNumber
) {}