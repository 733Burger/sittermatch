package com.sittermatch.sittermatch.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/** One sitter's offer on a booking, as the homeowner sees it when choosing a sitter. */
public record BookingOfferResponse(
    Integer sitterId,
    String sitterName,
    Double sitterRating,
    Integer sitterReviewCount,
    BigDecimal pricePerNight,
    BigDecimal pricePerVisit,
    BigDecimal pricePerWalk,
    LocalDateTime createdAt
) {}
