package com.sittermatch.sittermatch.dto;

public record ResidenceCheckRequest(
    String email,
    String address
) {}