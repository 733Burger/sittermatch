package com.sittermatch.sittermatch.dto;

public record EmergencyCheckRequest(
    String email,
    String name,
    String phoneNumber
) {}