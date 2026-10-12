package com.sittermatch.sittermatch.dto;

public record SitterListResponse (
    Integer id,
    String name,
    Double rating,
    Integer totalReviews,
    Double dayRate,
    Double nightRate,
    Boolean isVerified
) {}