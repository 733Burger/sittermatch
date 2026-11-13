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
    String area,
    String bookingType,
    LocalDateTime startDate,
    LocalDateTime endDate,
    String notes,
    String status,
    LocalDateTime confirmedAt,
    BigDecimal pricePerNight,
    BigDecimal pricePerVisit,
    BigDecimal pricePerWalk,
    List<BookingOfferResponse> offers,
    boolean homeownerReviewed,
    boolean sitterReviewed
) {}
