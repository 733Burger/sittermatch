package com.sittermatch.sittermatch.dto;

import java.time.LocalDateTime;

public record BookingCreateRequest(
    Integer listingId,
    Integer sitterId,
    String bookingType,
    LocalDateTime startDate,
    LocalDateTime endDate,
    String notes,
    Integer homeownerId) {
}
