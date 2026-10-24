package com.sittermatch.sittermatch.dto;

import java.math.BigDecimal;

/** Prices the homeowner sets on a requested booking. Send only the ones that change. */
public record BookingPricesRequest(
    BigDecimal pricePerNight,
    BigDecimal pricePerVisit,
    BigDecimal pricePerWalk
) {}