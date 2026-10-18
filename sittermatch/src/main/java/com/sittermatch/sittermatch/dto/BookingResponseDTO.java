package com.sittermatch.sittermatch.dto;

import java.time.LocalDateTime;

public record BookingResponseDTO (

    Integer id,
    Integer listingId,
    String listingTitle,
    Integer sitterId,
    String sitterName,
    String bookingType,
    LocalDateTime startDate,
    LocalDateTime endDate,
    String notes,
    String status,
    LocalDateTime confirmedAt

)

{}
