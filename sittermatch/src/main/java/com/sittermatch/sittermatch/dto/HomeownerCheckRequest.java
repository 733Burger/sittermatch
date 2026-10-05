package com.sittermatch.sittermatch.dto;

public record HomeownerCheckRequest(
    String type,
    String idPhoto,
    String textDetails,
    String status
) {}