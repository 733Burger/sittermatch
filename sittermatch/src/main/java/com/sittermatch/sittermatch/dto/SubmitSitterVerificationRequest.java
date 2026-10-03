package com.sittermatch.sittermatch.dto;

public record SubmitSitterVerificationRequest (
    String type,
    String idPhotoUrl,
    String references
) {}
