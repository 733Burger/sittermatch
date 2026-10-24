package com.sittermatch.sittermatch.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record BookingResponse(
    Integer id,
    Integer listingId,
    String listingTitle,
    Integer sitterId,
    String sitterName,
    Integer homeownerId,
    String homeownerName,
    String bookingType,
    LocalDateTime startDate,
    LocalDateTime endDate,
    String notes,
    String status,
    LocalDateTime confirmedAt,
    BigDecimal pricePerNight,
    BigDecimal pricePerVisit,
    BigDecimal pricePerWalk,
    // Sitters' offers while the booking is pending. A sitter only sees their own.
    List<BookingOfferResponse> offers,
    // Whether each side has written a review for this booking (approved or not).
    boolean homeownerReviewed,
    boolean sitterReviewed
) {}
