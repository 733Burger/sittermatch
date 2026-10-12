package com.sittermatch.sittermatch.dto.verificationChecks;

public record HomeownerCheckRequest(
    String type,
    String idPhoto,
    String textDetails,
    String status
) {}