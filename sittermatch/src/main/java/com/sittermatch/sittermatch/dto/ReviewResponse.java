package com.sittermatch.sittermatch.dto;

import java.time.LocalDateTime;

public record ReviewResponse(
    Integer id,
    Integer bookingId,
    Integer sitterId,
    Integer homeownerId,
    String reviewedBy,
    Integer rating,
    String comments,
    String status,
    String reviewerName,
    String revieweeName,
    LocalDateTime createdAt
) {}
