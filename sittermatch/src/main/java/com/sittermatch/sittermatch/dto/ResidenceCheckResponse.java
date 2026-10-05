package com.sittermatch.sittermatch.dto;

public record ResidenceCheckResponse(
    boolean success,
    String message
    // HomeownerCheckResponse.CheckTile addressCheck
) {}