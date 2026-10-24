package com.sittermatch.sittermatch.dto.admin;

/** A review waiting for an admin to approve or remove it. */
public record AdminReviewDto(
    Integer id,
    String reviewerName,
    String reviewerRole,
    String revieweeName,
    Double rating,
    String comment,
    String date,
    String flagReason
) {}
