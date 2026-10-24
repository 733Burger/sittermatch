package com.sittermatch.sittermatch.dto;

import java.util.List;

public record ReviewRequest(
    Integer bookingId,
    Integer sitterId,
    Integer homeownerId,
    String reviewedBy, // "SITTER" or "HOMEOWNER"
    Integer rating,
    String comments,
    List<PetReviewDto> petReviews
) {}